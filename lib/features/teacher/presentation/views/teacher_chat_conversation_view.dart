import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';

class TeacherChatConversationView extends StatefulWidget {
  static const routeName = '/teacher/chat-conversation';
  const TeacherChatConversationView({super.key});

  @override
  State<TeacherChatConversationView> createState() =>
      _TeacherChatConversationViewState();
}

class _TeacherChatConversationViewState
    extends State<TeacherChatConversationView> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = true;
  bool _sending = false;
  String? _sessionId;
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _student;
  String? _courseId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _initChat());
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  TeacherRepository get _repo => context.read<TeacherRepository>();

  void _initChat() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      _loading = false;
      return;
    }
    _student = args['student'] as Map<String, dynamic>?;
    _courseId = args['courseId'] as String?;

    final session = args['session'] as Map<String, dynamic>?;
    if (session != null) {
      _sessionId = (session['id'] ?? session['_id'] ?? '') as String;
      _fetchMessages();
    } else {
      _openNewSession();
    }
  }

  Future<void> _openNewSession() async {
    try {
      final studentId =
          (_student?['userId'] ?? _student?['studentId'] ?? '') as String;
      final result = await _repo.openSessionWithStudent(
        studentUserId: studentId,
        courseId: _courseId ?? '',
      );
      if (mounted) {
        _sessionId = (result['id'] ?? result['_id'] ?? '') as String;
        _fetchMessages();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('فشل فتح المحادثة');
      }
    }
  }

  Future<void> _fetchMessages() async {
    if (_sessionId == null) return;
    try {
      final msgs = await _repo.getChatMessages(_sessionId!);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _loading = false;
        });
        _scrollToBottom();
        _startPolling();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('فشل تحميل الرسائل');
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_sessionId != null) {
        _refreshOnDemand();
      }
    });
  }

  Future<void> _refreshOnDemand() async {
    if (_sessionId == null) return;
    try {
      final msgs = await _repo.getChatMessages(_sessionId!);
      if (mounted && msgs.length > _messages.length) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty || _sessionId == null || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await _repo.sendChatMessage(
        sessionId: _sessionId!,
        message: msg,
      );
      if (mounted) {
        _msgCtrl.clear();
        setState(() {
          _messages.add(sent);
          _sending = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        _showError('فشل إرسال الرسالة');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }

  // ── Theme ──────────────────────────────────────────────────────
  Color _fieldBorder() =>
      context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  Color _fieldLabel() =>
      context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

  String get _studentName =>
      (_student?['name'] ?? (_student?['user'] as Map?)?['name'] ?? 'طالب')
          as String;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context, true),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                _studentName.isNotEmpty ? _studentName[0] : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(_studentName,
                  style: TextStyles.semiBold16
                      .copyWith(color: Colors.white)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchMessages,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessionId == null
              ? Center(
                  child: Text('لا توجد محادثة مفتوحة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                        color: _fieldLabel(),
                      )),
                )
              : Column(
                  children: [
                    Expanded(child: _buildMessageList(isDark)),
                    _buildInputBar(isDark),
                  ],
                ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 48,
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text('لا توجد رسائل بعد، أرسل أول رسالة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  color: _fieldLabel(),
                )),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: EdgeInsets.all(16.w),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(msg, isDark);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isDark) {
    final text = (msg['message'] ?? msg['text'] ?? '') as String;
    final isTeacher = msg['isTeacher'] == true ||
        (msg['role'] ?? '') == 'teacher' ||
        _isFromTeacher(msg);
    final createdAt = msg['createdAt'] as String?;
    final time = createdAt != null && createdAt.length >= 16
        ? createdAt.substring(11, 16)
        : '';

    return Align(
      alignment:
          isTeacher ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        decoration: BoxDecoration(
          color: isTeacher
              ? (context.isDark
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                  : const Color(0xFF7C3AED).withValues(alpha: 0.1))
              : (context.isDark
                  ? const Color(0xFF1E293B)
                  : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: isTeacher
                ? const Radius.circular(4)
                : const Radius.circular(10),
            bottomRight: isTeacher
                ? const Radius.circular(10)
                : const Radius.circular(4),
          ),
          border: Border.all(
              color: context.isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                color: context.isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              ),
            ),
            if (time.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(time,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9.sp,
                      color: _fieldLabel(),
                    )),
              ),
          ],
        ),
      ),
    );
  }

  bool _isFromTeacher(Map<String, dynamic> msg) {
    final sender =
        (msg['sender'] as Map<String, dynamic>?) ?? msg['user'] as Map<String, dynamic>?;
    if (sender == null) return false;
    final role = (sender['role'] ?? '') as String;
    return role == 'teacher';
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(color: _fieldBorder()),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 12.h),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1F2937)),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    color: _fieldLabel().withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide(color: _fieldBorder()),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide(color: _fieldBorder()),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 10.h),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 44.w,
              height: 44.w,
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sending ? null : _sendMessage,
                icon: _sending
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
