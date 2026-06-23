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

class TeacherLiveClassView extends StatefulWidget {
  static const routeName = '/teacher/live-class';
  const TeacherLiveClassView({super.key});

  @override
  State<TeacherLiveClassView> createState() => _TeacherLiveClassViewState();
}

class _TeacherLiveClassViewState extends State<TeacherLiveClassView> {
  // ── Step ───────────────────────────────────────────────────────
  String _step = 'setup'; // setup | created | live

  // ── Setup form ─────────────────────────────────────────────────
  List<Map<String, dynamic>> _courses = [];
  bool _loadingCourses = true;
  bool _loading = false;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCourse = '';
  int _maxCapacity = 100;
  String _scheduledTime = _getNowLocal();

  // ── Room data ──────────────────────────────────────────────────
  Map<String, dynamic>? _createdRoom;

  // ── WebRTC ─────────────────────────────────────────────────────
  MediaStream? _localStream;
  final _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, RTCRtpSender> _screenSenders = {};
  io.Socket? _socket;
  bool _micOn = true;
  bool _camOn = true;
  bool _screenShareOn = false;
  MediaStream? _screenStream;

  // ── Participants / Chat ───────────────────────────────────────
  final List<Map<String, dynamic>> _participants = [];
  final List<Map<String, dynamic>> _messages = [];
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _chatOpen = false;
  int _chatUnread = 0;
  final List<Map<String, dynamic>> _raiseHands = [];

  // ── Timer ──────────────────────────────────────────────────────
  int _duration = 0;
  Timer? _timer;

  TeacherRepository get _repo => context.read<TeacherRepository>();

  // ── Helpers ────────────────────────────────────────────────────
  static String _getNowLocal() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)}T${_pad(now.hour)}:${_pad(now.minute)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  String get _roomName =>
      (_createdRoom?['roomName'] ?? _createdRoom?['name'] ?? '') as String;

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

  void _cleanup() {
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;
    _screenStream?.getTracks().forEach((t) => t.stop());
    _screenStream = null;
    for (final pc in _peers.values) {
      pc.close();
    }
    _peers.clear();
    for (final r in _remoteRenderers.values) {
      r.dispose();
    }
    _remoteRenderers.clear();
    _socket?.disconnect();
    _socket = null;
  }

  // ── Fetch ──────────────────────────────────────────────────────
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

  // ── Create room ────────────────────────────────────────────────
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

  // ── Request permissions ────────────────────────────────────────
  Future<bool> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      buildSnackBar(context, 'يرجى السماح بالكاميرا والميكروفون من إعدادات الجهاز', isError: true);
      await openAppSettings();
      return false;
    }

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      buildSnackBar(context, 'يرجى السماح بالوصول للكاميرا والميكروفون', isError: true);
      return false;
    }

    return true;
  }

  // ── Start live ─────────────────────────────────────────────────
  Future<void> _handleStartLive() async {
    // 1. Request permissions first
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) return;

    // 2. Activate the room on the server
    try {
      await _repo.startLiveRoom(_createdRoom!['id']);
    } catch (_) {
      buildSnackBar(context, 'فشل تنشيط الحصة، حاول مرة أخرى', isError: true);
      return;
    }

    setState(() => _step = 'live');
    _startTimer();

    // 3. Get camera & mic stream
    try {
      // Re-initialize renderer to be safe
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
      buildSnackBar(context, 'فشل الوصول للكاميرا أو الميكروفون: ${e.toString()}', isError: true);
      if (mounted) setState(() => _step = 'created');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duration++);
    });
  }

  String _formatDuration(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return h > 0
        ? '${_pad(h)}:${_pad(m)}:${_pad(s)}'
        : '${_pad(m)}:${_pad(s)}';
  }

  // ── Socket ─────────────────────────────────────────────────────
  void _connectSocket() {
    final baseUrl = 'http://localhost:5000';
    _socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
    });

    final socket = _socket!;

    socket.onConnect((_) {
      socket.emit('live_class:join', {'roomName': _roomName});
      setState(() {
        _participants.add({
          'userId': 'teacher',
          'name': 'المدرس',
          'role': 'teacher',
          'isLocal': true,
        });
      });
    });

    socket.on('live_class:student_joined', (data) {
      final userId = data['userId'] as String;
      final name = data['name'] as String? ?? 'طالب';
      setState(() {
        _participants.removeWhere((p) => p['userId'] == userId);
        _participants.add({'userId': userId, 'name': name, 'role': 'student'});
      });

      _createPeerConnection(userId, socket).then((pc) {
        _peers[userId] = pc;
        pc.createOffer().then((offer) {
          pc.setLocalDescription(offer);
          socket.emit('webrtc:offer', {
            'roomName': _roomName,
            'targetUserId': userId,
            'offer': offer.toMap(),
          });
        });
      });
    });

    socket.on('live_class:student_left', (data) {
      final userId = data['userId'] as String;
      setState(() => _participants.removeWhere((p) => p['userId'] == userId));
      _peers[userId]?.close();
      _peers.remove(userId);
      _remoteRenderers[userId]?.dispose();
      _remoteRenderers.remove(userId);
    });

    socket.on('webrtc:offer', (data) async {
      final fromUserId = data['fromUserId'] as String;
      final offer = RTCSessionDescription(
        data['offer']['sdp'] as String,
        data['offer']['type'] as String,
      );

      var pc = _peers[fromUserId];
      if (pc != null) {
        await pc.setRemoteDescription(offer);
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        socket.emit('webrtc:answer', {
          'roomName': _roomName,
          'targetUserId': fromUserId,
          'answer': answer.toMap(),
        });
        return;
      }

      pc = await _createPeerConnection(fromUserId, socket);
      _peers[fromUserId] = pc;
      await pc.setRemoteDescription(offer);
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      socket.emit('webrtc:answer', {
        'roomName': _roomName,
        'targetUserId': fromUserId,
        'answer': answer.toMap(),
      });
    });

    socket.on('webrtc:answer', (data) async {
      final fromUserId = data['fromUserId'] as String;
      final answer = RTCSessionDescription(
        data['answer']['sdp'] as String,
        data['answer']['type'] as String,
      );
      final pc = _peers[fromUserId];
      if (pc != null) {
        await pc.setRemoteDescription(answer);
      }
    });

    socket.on('webrtc:ice-candidate', (data) async {
      final fromUserId = data['fromUserId'] as String;
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'] as String,
        data['candidate']['sdpMid'] as String?,
        (data['candidate']['sdpMLineIndex'] as num?)?.toInt() ?? 0,
      );
      final pc = _peers[fromUserId];
      if (pc != null) {
        await pc.addCandidate(candidate);
      }
    });

    socket.on('live_class:chat_message', (data) {
      final senderName = data['senderName'] as String? ?? 'طالب';
      final message = data['message'] as String? ?? '';
      setState(() {
        _messages.add({
          'sender': senderName,
          'message': message,
          'time': _formatTime(DateTime.now()),
          'isTeacher': false,
        });
      });
      if (!_chatOpen) {
        _chatUnread++;
      }
    });

    socket.on('live_class:hand_raised', (data) {
      final userId = data['userId'] as String;
      final name = data['name'] as String? ?? 'طالب';
      setState(() {
        if (!_raiseHands.any((h) => h['userId'] == userId)) {
          _raiseHands.add({'userId': userId, 'name': name});
        }
      });
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted) {
          setState(() => _raiseHands.removeWhere((h) => h['userId'] == userId));
        }
      });
    });

    socket.on('live_class:screen_share_started', (_) {});
    socket.on('live_class:screen_share_stopped', (_) {});
  }

  String _formatTime(DateTime dt) {
    return '${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  Future<RTCPeerConnection> _createPeerConnection(
      String userId, io.Socket socket) async {
    const config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ]
    };

    final pc = await createPeerConnection(config);
    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    _remoteRenderers[userId] = renderer;

    pc.onIceCandidate = (candidate) {
      socket.emit('webrtc:ice-candidate', {
        'roomName': _roomName,
        'targetUserId': userId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    pc.onTrack = (event) {
      if (event.track.kind == 'video') {
        if (mounted) {
          setState(() {
            _remoteRenderers[userId]?.srcObject = event.streams[0];
          });
        }
      }
    };

    // FIX #2: Handle renegotiation automatically when tracks are added/removed
    pc.onRenegotiationNeeded = () async {
      if (!(_peers.containsKey(userId))) return;
      try {
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        socket.emit('webrtc:offer', {
          'roomName': _roomName,
          'targetUserId': userId,
          'offer': offer.toMap(),
        });
      } catch (e) {
        debugPrint('Renegotiation error for $userId: $e');
      }
    };

    pc.onRemoveTrack = (stream, track) {};

    return pc;
  }

  // ── Controls ───────────────────────────────────────────────────
  void _toggleMic() {
    _localStream?.getAudioTracks().forEach((t) {
      t.enabled = !t.enabled;
    });
    setState(() => _micOn = !_micOn);
  }

  void _toggleCam() {
    _localStream?.getVideoTracks().forEach((t) {
      t.enabled = !t.enabled;
    });
    setState(() => _camOn = !_camOn);
  }

  Future<void> _toggleScreenShare() async {
    if (_screenShareOn) {
      for (final entry in _peers.entries) {
        try {
          await entry.value.removeTrack(_screenSenders[entry.key]!);
        } catch (_) {}
      }
      _screenSenders.clear();
      _screenStream?.getTracks().forEach((t) => t.stop());
      _screenStream = null;
      setState(() => _screenShareOn = false);
      _socket?.emit('live_class:screen_share_stopped', {
        'roomName': _roomName,
      });
    } else {
      try {
        final screenStream = await navigator.mediaDevices.getDisplayMedia({
          'video': {'cursor': 'always'},
          'audio': false,
        });
        _screenStream = screenStream;
        final screenTrack = screenStream.getVideoTracks()[0];

        setState(() => _screenShareOn = true);

        for (final entry in _peers.entries) {
          final sender = await entry.value.addTrack(screenTrack, screenStream);
          _screenSenders[entry.key] = sender;
        }

        _socket?.emit('live_class:screen_share_started', {
          'roomName': _roomName,
        });
      } catch (e) {
        buildSnackBar(context, 'فشل مشاركة الشاشة', isError: true);
      }
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

  // ── End class ──────────────────────────────────────────────────
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

  // ── Cancel scheduled room ──────────────────────────────────────
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

  // ── Theme ──────────────────────────────────────────────────────
  Color _fieldBorder() =>
      context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  Color _fieldText() =>
      context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
  Color _fieldLabel() =>
      context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  Color _cardBg() =>
      context.isDark ? const Color(0xFF1E293B) : Colors.white;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    if (_step == 'live') return _buildLiveScreen(isDark);
    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
            ? _buildSetupScreen(isDark)
            : _buildCreatedScreen(isDark),
      ),
    );
  }

  // ── Setup screen ───────────────────────────────────────────────
  Widget _buildSetupScreen(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('أنشئ حصة أونلاين مباشرة لطلابك',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13.sp,
              color: _fieldLabel(),
            )),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _cardBg(),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _fieldBorder()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    color: _fieldText()),
                decoration: InputDecoration(
                  labelText: 'عنوان الحصة *',
                  labelStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _fieldLabel(),
                  ),
                  hintText: 'مثال: مراجعة الوحدة الأولى',
                  prefixIcon: const Icon(Icons.video_call,
                      color: Color(0xFF7C3AED)),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: _fieldBorder()),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: _fieldBorder()),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 12.h),
              _buildCourseDropdown(isDark),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: [
                  SizedBox(
                    width: 0.4.sw,
                    child: _buildDateTimeField(isDark),
                  ),
                  SizedBox(
                    width: 0.4.sw,
                    child: _buildCapacityField(isDark),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    color: _fieldText()),
                decoration: InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  labelStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _fieldLabel(),
                  ),
                  hintText: 'أضف تفاصيل عن الحصة...',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: _fieldBorder()),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: _fieldBorder()),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: _loading ? null : _handleCreateRoom,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                              : Text('إنشاء الحصة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseDropdown(bool isDark) {
    if (_loadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _fieldBorder()),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCourse.isNotEmpty ? _selectedCourse : null,
          isExpanded: true,
          hint: Row(
            children: [
              const Icon(Icons.school, size: 20, color: Color(0xFF7C3AED)),
              SizedBox(width: 8.w),
              Text('اختر الكورس',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    color: _fieldLabel(),
                  )),
            ],
          ),
          dropdownColor: _cardBg(),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.sp,
            color: _fieldText(),
          ),
          items: [
            DropdownMenuItem(
                value: '',
                child: Text('بدون كورس محدد',
                    style: TextStyle(color: _fieldLabel()))),
            ..._courses.map((c) {
              final id = (c['id'] ?? c['_id'] ?? '') as String;
              final title = (c['title'] ?? '') as String;
              return DropdownMenuItem(value: id, child: Text(title));
            }),
          ],
          onChanged: (v) => setState(() => _selectedCourse = v ?? ''),
        ),
      ),
    );
  }

  Widget _buildDateTimeField(bool isDark) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(_scheduledTime) ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time == null) return;
        setState(() {
          _scheduledTime =
          '${date.year}-${_pad(date.month)}-${_pad(date.day)}T${_pad(time.hour)}:${_pad(time.minute)}';
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: _fieldBorder()),
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الوقت المحدد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10.sp,
                  color: _fieldLabel(),
                )),
            Text(_scheduledTime.replaceAll('T', ' '),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _fieldText(),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityField(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _fieldBorder()),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, size: 20, color: Color(0xFF10B981)),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعة القصوى',
                border: InputBorder.none,
              ),
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  color: _fieldText()),
              onChanged: (v) => _maxCapacity = int.tryParse(v) ?? 100,
            ),
          ),
        ],
      ),
    );
  }

  // ── Created screen ─────────────────────────────────────────────
  Widget _buildCreatedScreen(bool isDark) {
    final roomCode = (_createdRoom?['roomCode'] ??
        _createdRoom?['code'] ??
        _createdRoom?['id'] ??
        '') as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.white, size: 36),
              ),
              SizedBox(height: 12.h),
              Text('تم إنشاء الحصة بنجاح!',
                  style: TextStyles.bold18.copyWith(color: Colors.white)),
              SizedBox(height: 8.h),
              Text('يمكنك الآن بدء الحصة أو مشاركة الكود مع الطلاب',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.sp,
                    color: Colors.white70,
                  )),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text('كود الحصة: $roomCode',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    )),
              ),
              SizedBox(height: 8.h),
              TextButton.icon(
                onPressed: () => _copyToClipboard(roomCode, 'كود الحصة'),
                icon: const Icon(Icons.copy, color: Colors.white70, size: 16),
                label: Text('نسخ الكود',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white70,
                    )),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _cardBg(),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _fieldBorder()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تفاصيل الحصة',
                  style: TextStyles.semiBold16.copyWith(color: _fieldText())),
              SizedBox(height: 8.h),
              _detailRow('العنوان',
                  (_createdRoom?['title'] ?? '') as String),
              _detailRow('الحالة', 'بانتظار البدء'),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48.h,
                child: ElevatedButton.icon(
                  onPressed: _handleStartLive,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: Text('بدء الحصة الآن',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: SizedBox(
                height: 48.h,
                child: OutlinedButton.icon(
                  onPressed: _handleCancelRoom,
                  icon: const Icon(Icons.close, color: Color(0xFFEF4444)),
                  label: Text('إلغاء الحصة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      )),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                color: _fieldLabel(),
              )),
          Text(value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _fieldText(),
              )),
        ],
      ),
    );
  }

  // ── Live screen ────────────────────────────────────────────────
  Widget _buildLiveScreen(bool isDark) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildLiveAppBar(isDark),
            Expanded(child: _buildVideoGrid(isDark)),
            _buildControlBar(isDark),
            // FIX #1: Flexible instead of bare widget to prevent RenderFlex overflow
            if (_chatOpen) Flexible(child: _buildChatPanel(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveAppBar(bool isDark) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
          SizedBox(width: 8.w),
          Text('مباشر',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              )),
          SizedBox(width: 12.w),
          Text(_formatDuration(_duration),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
          const Spacer(),
          if (_raiseHands.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: IconButton(
                onPressed: () => _showRaiseHandsDialog(),
                icon: Badge(
                  label: Text('${_raiseHands.length}',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white)),
                  child: const Icon(Icons.pan_tool,
                      color: Color(0xFFF59E0B), size: 22),
                ),
              ),
            ),
          IconButton(
            onPressed: () => _showEndConfirmDialog(),
            icon: const Icon(Icons.call_end, color: Colors.red, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(bool isDark) {
    return Stack(
      children: [
        if (_remoteRenderers.isNotEmpty)
          GridView.builder(
            padding: EdgeInsets.all(4.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _remoteRenderers.length > 1 ? 2 : 1,
              childAspectRatio: 4 / 3,
            ),
            itemCount: _remoteRenderers.length,
            itemBuilder: (_, i) {
              final entry = _remoteRenderers.entries.elementAt(i);
              return Container(
                margin: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: RTCVideoView(entry.value,
                      objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
              );
            },
          ),
        Positioned(
          right: 12.w,
          bottom: 12.h,
          child: GestureDetector(
            onTap: _toggleCam,
            child: Container(
              width: 100.w,
              height: 140.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white38, width: 2),
                color: Colors.black,
              ),
              child: _localStream != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: RTCVideoView(_localRenderer,
                    objectFit: RTCVideoViewObjectFit
                        .RTCVideoViewObjectFitCover),
              )
                  : Center(
                  child: Icon(Icons.videocam_off,
                      color: Colors.white38, size: 32.w)),
            ),
          ),
        ),
        if (_remoteRenderers.isEmpty)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, color: Colors.white38, size: 48),
                SizedBox(height: 8),
                Text('بانتظار انضمام الطلاب...',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white54,
                        fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildControlBar(bool isDark) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(
            icon: _micOn ? Icons.mic : Icons.mic_off,
            color: _micOn ? Colors.white : Colors.red,
            onTap: _toggleMic,
          ),
          _controlButton(
            icon: _camOn ? Icons.videocam : Icons.videocam_off,
            color: _camOn ? Colors.white : Colors.red,
            onTap: _toggleCam,
          ),
          _controlButton(
            icon: _screenShareOn
                ? Icons.stop_screen_share
                : Icons.screen_share,
            color: _screenShareOn
                ? const Color(0xFF10B981)
                : Colors.white,
            onTap: _toggleScreenShare,
          ),
          _controlButton(
            icon: Icons.chat,
            color: _chatUnread > 0
                ? const Color(0xFFF59E0B)
                : Colors.white,
            onTap: () {
              setState(() {
                _chatOpen = !_chatOpen;
                if (_chatOpen) _chatUnread = 0;
              });
            },
            badge: _chatUnread > 0 ? '$_chatUnread' : null,
          ),
          _controlButton(
            icon: Icons.people,
            color: Colors.white,
            onTap: _showParticipantsDialog,
            badge: '${_participants.length}',
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Badge(
      isLabelVisible: badge != null,
      label: badge != null
          ? Text(badge,
          style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold))
          : null,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 26),
      ),
    );
  }

  // ── Chat panel ─────────────────────────────────────────────────
  Widget _buildChatPanel(bool isDark) {
    return Container(
      height: 0.4.sh,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: const BoxDecoration(
              border:
              Border(bottom: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat,
                    color: Color(0xFF94A3B8), size: 18),
                SizedBox(width: 8.w),
                Text('المحادثة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _chatOpen = false),
                  icon: const Icon(Icons.close,
                      color: Color(0xFF94A3B8), size: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Text('لا توجد رسائل بعد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                  )),
            )
                : ListView.builder(
              controller: _scrollCtrl,
              padding: EdgeInsets.all(8.w),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isTeacher = msg['isTeacher'] == true;
                return Align(
                  alignment: isTeacher
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    constraints:
                    BoxConstraints(maxWidth: 0.7.sw),
                    decoration: BoxDecoration(
                      color: isTeacher
                          ? const Color(0xFF7C3AED)
                          .withValues(alpha: 0.3)
                          : const Color(0xFF334155),
                      borderRadius:
                      BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${msg['sender']}: ${msg['message']}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.sp,
                              color: Colors.white,
                            )),
                        if (msg['time'] != null)
                          Text(msg['time'],
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9.sp,
                                color:
                                const Color(0xFF64748B),
                              )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    onSubmitted: (_) => _sendMessage(),
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 8.h),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded,
                      color: Color(0xFF7C3AED), size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────
  void _showEndConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الحصة',
            style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من إنهاء الحصة؟',
            style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleEndClass();
            },
            child: const Text('إنهاء',
                style: TextStyle(
                    fontFamily: 'Cairo', color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showParticipantsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('المشتركين (${_participants.length})',
            style: const TextStyle(fontFamily: 'Cairo')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _participants.map((p) {
              final name = (p['name'] ?? '') as String;
              final role = (p['role'] ?? '') as String;
              final isLocal = p['isLocal'] == true;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: role == 'teacher'
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF2563EB),
                  radius: 18,
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(name,
                    style: const TextStyle(fontFamily: 'Cairo')),
                subtitle: Text(
                  isLocal
                      ? '${role == 'teacher' ? 'مدرس' : 'طالب'} (أنت)'
                      : role == 'teacher'
                      ? 'مدرس'
                      : 'طالب',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showRaiseHandsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفع اليد',
            style: TextStyle(fontFamily: 'Cairo')),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _raiseHands.map((h) {
              final name = (h['name'] ?? '') as String;
              return ListTile(
                leading: const Icon(Icons.pan_tool,
                    color: Color(0xFFF59E0B)),
                title: Text(name,
                    style: const TextStyle(fontFamily: 'Cairo')),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}