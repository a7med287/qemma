import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';
import 'widgets/teacher_theme_helpers.dart';
import 'widgets/live_class_setup_form.dart';
import 'widgets/live_class_created_screen.dart';
import 'widgets/live_class_live_screen.dart';
import 'widgets/live_class_dialogs.dart';

part 'widgets/live_class_rtc_helper.dart';

String _pad(int n) => n.toString().padLeft(2, '0');

class TeacherLiveClassView extends StatefulWidget {
  static const routeName = '/teacher/live-class';
  const TeacherLiveClassView({super.key});

  @override
  State<TeacherLiveClassView> createState() => _TeacherLiveClassViewState();
}

class _TeacherLiveClassViewState extends State<TeacherLiveClassView>
    with LiveClassRtcMixin {
  // ── Step ───────────────────────────────────────────────────────
  String _step = 'setup';

  // ── Setup form ─────────────────────────────────────────────────
  List<Map<String, dynamic>> _courses = [];
  bool _loadingCourses = true;
  bool _loading = false;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCourse = '';
  int _maxCapacity = 100;
  String _scheduledTime = _getNowLocal();

  TeacherRepository get _repo => context.read<TeacherRepository>();

  static String _getNowLocal() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)}T${_pad(now.hour)}:${_pad(now.minute)}';
  }

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    _fetchCourses();
    _checkActiveRoom();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    _localRenderer.dispose();
    _timer?.cancel();
    _cleanup();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    try {
      final courses = await _repo.getLiveClassCourses();
      if (mounted) setState(() => _courses = courses);
    } catch (_) {}
    if (mounted) setState(() => _loadingCourses = false);
  }

  Future<void> _checkActiveRoom() async {
    try {
      final room = await _repo.getActiveRoom();
      if (room != null && mounted) {
        setState(() {
          _createdRoom = room;
          _step = 'created';
        });
      }
    } catch (_) {}
  }

  Future<void> _handleCreateRoom() async {
    if (_titleCtrl.text.trim().isEmpty) {
      buildSnackBar(context, 'يرجى إدخال عنوان الحصة', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final room = await _repo.createLiveRoom({
        'courseId': _selectedCourse,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'maxCapacity': _maxCapacity,
        'scheduledTime': _scheduledTime,
        'enableChat': true,
        'enableScreenShare': true,
        'recordSession': true,
        'waitingRoom': false,
      });
      if (mounted) {
        setState(() {
          _createdRoom = room;
          _step = 'created';
          _loading = false;
        });
        buildSnackBar(context, 'تم إنشاء الحصة بنجاح! 🎉');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        buildSnackBar(context, 'فشل إنشاء الحصة', isError: true);
      }
    }
  }

  Future<void> _handleStartLive() async {
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) return;

    try {
      await _repo.startLiveRoom(_createdRoom!['id']);
    } catch (_) {
      buildSnackBar(context, 'فشل تنشيط الحصة، حاول مرة أخرى', isError: true);
      return;
    }

    setState(() => _step = 'live');
    _startTimer();

    try {
      await _localRenderer.initialize();
      final stream = await navigator.mediaDevices.getUserMedia({
        'video': {'width': 1280, 'height': 720},
        'audio': true,
      });
      if (!mounted) return;
      setState(() {
        _localStream = stream;
        _localRenderer.srcObject = stream;
      });
      _connectSocket();
    } catch (e) {
      debugPrint('Camera/Mic error: $e');
      buildSnackBar(
          context, 'فشل الوصول للكاميرا أو الميكروفون: ${e.toString()}',
          isError: true);
      if (mounted) setState(() => _step = 'created');
    }
  }

  void _sendMessage() {
    final msg = _chatCtrl.text.trim();
    if (msg.isEmpty) return;
    _socket?.emit('live_class:chat_message', {
      'roomName': _roomName,
      'senderName': 'المدرس',
      'message': msg,
    });
    setState(() {
      _messages.add({
        'sender': 'أنت',
        'message': msg,
        'time': _formatTime(DateTime.now()),
        'isTeacher': true,
      });
    });
    _chatCtrl.clear();
  }

  Future<void> _handleEndClass() async {
    try {
      _localStream?.getTracks().forEach((t) => t.stop());
      for (final pc in _peers.values) pc.close();
      _peers.clear();
      _socket?.disconnect();
      _timer?.cancel();

      await _repo.endLiveRoom(_createdRoom!['id']);
      buildSnackBar(context, 'انتهت الحصة بنجاح');
      if (mounted) Navigator.maybePop(context, true);
    } catch (_) {
      buildSnackBar(context, 'حدث خطأ أثناء إنهاء الحصة', isError: true);
      if (mounted) Navigator.maybePop(context, true);
    }
  }

  Future<void> _handleCancelRoom() async {
    try {
      await _repo.cancelLiveRoom(_createdRoom!['id']);
      buildSnackBar(context, 'تم إلغاء الحصة بنجاح');
      if (mounted) {
        setState(() {
          _createdRoom = null;
          _step = 'setup';
        });
      }
    } catch (_) {
      buildSnackBar(context, 'فشل إلغاء الحصة', isError: true);
    }
  }

  void _copyToClipboard(String text, String label) {
    buildSnackBar(context, 'تم نسخ $label!');
  }

  void _showEndConfirmDialog() =>
      showEndConfirmDialog(context, _handleEndClass);

  void _showParticipantsDialog() =>
      showParticipantsDialog(context, _participants);

  void _showRaiseHandsDialog() =>
      showRaiseHandsDialog(context, _raiseHands);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    if (_step == 'live') {
      return LiveClassLiveScreen(
        duration: _duration,
        formatDuration: _formatDuration,
        raiseHands: _raiseHands,
        participants: _participants,
        remoteRenderers: _remoteRenderers,
        localRenderer: _localRenderer,
        localStream: _localStream,
        micOn: _micOn,
        camOn: _camOn,
        screenShareOn: _screenShareOn,
        chatOpen: _chatOpen,
        chatUnread: _chatUnread,
        messages: _messages,
        chatCtrl: _chatCtrl,
        scrollCtrl: _scrollCtrl,
        onToggleMic: _toggleMic,
        onToggleCam: _toggleCam,
        onToggleScreenShare: _toggleScreenShare,
        onSendMessage: _sendMessage,
        onToggleChat: () => setState(() {
          _chatOpen = !_chatOpen;
          if (_chatOpen) _chatUnread = 0;
        }),
        onShowEndConfirmDialog: _showEndConfirmDialog,
        onShowParticipantsDialog: _showParticipantsDialog,
        onShowRaiseHandsDialog: _showRaiseHandsDialog,
        onCloseChat: () => setState(() => _chatOpen = false),
      );
    }
    return Scaffold(
      backgroundColor: bgColor(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('بدء حصة مباشرة',
            style: TextStyles.semiBold16.copyWith(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: _step == 'setup'
            ? LiveClassSetupForm(
                titleCtrl: _titleCtrl,
                descCtrl: _descCtrl,
                selectedCourse: _selectedCourse,
                maxCapacity: _maxCapacity,
                scheduledTime: _scheduledTime,
                courses: _courses,
                loadingCourses: _loadingCourses,
                loading: _loading,
                onCreateRoom: _handleCreateRoom,
                onCourseChanged: (v) => setState(() => _selectedCourse = v),
                onCapacityChanged: (v) => setState(() => _maxCapacity = v),
                onDateTimeChanged: (v) => setState(() => _scheduledTime = v),
                isDark: isDark,
              )
            : LiveClassCreatedScreen(
                createdRoom: _createdRoom,
                onStartLive: _handleStartLive,
                onCancelRoom: _handleCancelRoom,
                onCopyToClipboard: _copyToClipboard,
                isDark: isDark,
              ),
      ),
    );
  }
}
