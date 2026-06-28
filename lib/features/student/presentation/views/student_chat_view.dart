import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/services/socket_service.dart';
import '../../data/models/student_models.dart';
import '../../data/models/student_model_json.dart';
import '../../data/repositories/student_repository.dart';

class StudentChatView extends StatefulWidget {
  const StudentChatView({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.teacherName,
    this.teacherAvatar,
    required this.teacherUserId,
  });

  final String courseId;
  final String courseTitle;
  final String teacherName;
  final String? teacherAvatar;
  final String teacherUserId;

  @override
  State<StudentChatView> createState() => _StudentChatViewState();
}

class _StudentChatViewState extends State<StudentChatView> {
  ChatSession? _chatSession;
  List<ChatMessage> _chatMessages = [];
  bool _chatLoading = false;
  bool _sendingMsg = false;
  String? _chatError;
  final _messageController = TextEditingController();
  final _chatScrollController = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _chatSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCourseChat());
    _chatSub = SocketService().chatMessageStream.listen(_onChatMessage);
  }

  @override
  void dispose() {
    if (_chatSession != null) SocketService().leaveChatSession(_chatSession!.id);
    _chatSub?.cancel();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _onChatMessage(dynamic data) {
    final map = data as Map<String, dynamic>;
    final sessionId = map['sessionId']?.toString();
    if (sessionId != null && sessionId == _chatSession?.id) {
      final msg = StudentModelJson.chatMessageFromJson(map);
      if (!_chatMessages.any((m) => m.id == msg.id)) {
        setState(() => _chatMessages.add(msg));
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_chatScrollController.hasClients) {
            _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
          }
        });
      }
    }
  }

  Future<void> _startCourseChat() async {
    setState(() { _chatLoading = true; _chatError = null; });
    try {
      final repo = context.read<StudentRepository>();
      final sessions = await repo.getChatSessions();
      final existing = sessions.where((s) => s.courseId == widget.courseId).toList();
      if (existing.isNotEmpty) {
        _chatSession = existing.first;
        _chatMessages = await repo.getChatMessages(_chatSession!.id);
        SocketService().joinChatSession(_chatSession!.id);
      } else {
        final session = await repo.createChatSession(
          teacherUserId: widget.teacherUserId,
          courseId: widget.courseId,
        );
        _chatSession = session;
        _chatMessages = [];
        SocketService().joinChatSession(session.id);
      }
    } catch (e) {
      _chatError = 'حدث خطأ في تحميل المحادثة';
    }
    setState(() { _chatLoading = false; });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sendingMsg) return;
    if (_chatSession == null) {
      await _startCourseChat();
      if (_chatSession == null) return;
    }
    setState(() { _sendingMsg = true; });
    try {
      final repo = context.read<StudentRepository>();
      final msg = await repo.sendChatMessage(_chatSession!.id, text);
      setState(() {
        _chatMessages.add(msg);
        _messageController.clear();
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_chatScrollController.hasClients) {
          _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (mounted) buildSnackBar(context, 'فشل إرسال الرسالة', isError: true);
    }
    setState(() { _sendingMsg = false; });
  }

  Widget _buildImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover, Widget? fallback}) {
    if (url.startsWith('data:')) {
      final parts = url.split(',');
      if (parts.length >= 2) {
        try {
          return Image.memory(base64Decode(parts[1]), fit: fit, width: width, height: height);
        } catch (_) {
          return fallback ?? const SizedBox.shrink();
        }
      }
    }
    return Image.network(url, fit: fit, width: width, height: height,
      errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accent = const Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: Text('التواصل مع المدرس', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            // Teacher header
            Card(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: accent,
                      child: widget.teacherAvatar != null && widget.teacherAvatar!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child: _buildImage(widget.teacherAvatar!, fit: BoxFit.cover, fallback: Icon(Icons.person_rounded, color: Colors.white, size: 20.r)),
                            )
                          : Icon(Icons.person_rounded, color: Colors.white, size: 20.r),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.teacherName,
                            style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: textColor)),
                          Row(
                            children: [
                              Text('مدرس الكورس', style: TextStyle(fontSize: 11.sp, fontFamily: 'Cairo', color: const Color(0xFF059669))),
                              Text(' • ${widget.courseTitle}', style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: subTextColor), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text('3-way', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: accent)),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Messages
            Expanded(
              child: Card(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(color: borderColor),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: _chatError != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_rounded, size: 56.r, color: borderColor),
                                  SizedBox(height: 8.h),
                                  Text(_chatError!, style: TextStyle(fontFamily: 'Cairo', color: subTextColor)),
                                ],
                              ),
                            )
                          : _chatLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _chatSession == null
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.chat_rounded, size: 56.r, color: borderColor),
                                          SizedBox(height: 16.h),
                                          Text('ابدأ محادثة مع مدرس الكورس',
                                            style: TextStyle(fontFamily: 'Cairo', color: subTextColor)),
                                          SizedBox(height: 16.h),
                                          ElevatedButton.icon(
                                            onPressed: _startCourseChat,
                                            icon: const Icon(Icons.chat_rounded, size: 18),
                                            label: const Text('بدء محادثة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: accent,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : _chatMessages.isEmpty
                                      ? Center(
                                          child: Text('لا توجد رسائل. اكتب أول رسالة!',
                                            style: TextStyle(fontFamily: 'Cairo', color: subTextColor)),
                                        )
                                      : ListView.builder(
                                          controller: _chatScrollController,
                                          padding: EdgeInsets.all(12.r),
                                          itemCount: _chatMessages.length,
                                          itemBuilder: (_, i) {
                                            final msg = _chatMessages[i];
                                            final isMine = msg.senderUserId == SocketService().userId;
                                            return Align(
                                              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                                              child: Container(
                                                margin: EdgeInsets.only(bottom: 8.h),
                                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                                decoration: BoxDecoration(
                                                  color: isMine ? accent : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                                  borderRadius: BorderRadius.only(
                                                    topLeft: const Radius.circular(18),
                                                    topRight: const Radius.circular(18),
                                                    bottomLeft: isMine ? const Radius.circular(18) : const Radius.circular(4),
                                                    bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(18),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (!isMine && msg.senderName != null) ...[
                                                      Text(msg.senderName!,
                                                        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700,
                                                          color: msg.senderRole == 'teacher' ? const Color(0xFF7C3AED) : const Color(0xFF059669)),
                                                      ),
                                                      if (msg.senderRole != null)
                                                        Text(
                                                          msg.senderRole == 'teacher' ? 'مدرس' : 'مدرس مساعد',
                                                          style: TextStyle(fontSize: 8.sp, color: msg.senderRole == 'teacher' ? const Color(0xFF7C3AED).withValues(alpha: 0.7) : const Color(0xFF059669).withValues(alpha: 0.7)),
                                                        ),
                                                    ],
                                                    Text(msg.message,
                                                      style: TextStyle(color: isMine ? Colors.white : textColor, fontFamily: 'Cairo')),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                    ),
                    // Input
                    if (_chatSession != null)
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'اكتب رسالتك للمدرس...',
                                  hintStyle: TextStyle(fontFamily: 'Cairo', color: subTextColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                ),
                                style: TextStyle(fontFamily: 'Cairo', color: textColor),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                                child: _sendingMsg
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
