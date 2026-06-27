import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../features/auth/data/models/auth_models.dart';
import '../../../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../data/services/ai_assistant_service.dart';

class AiAssistantView extends StatefulWidget {
  static const routeName = '/ai-assistant';
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  List<_ChatMessage> _messages = [];
  bool _loading = false;
  Map<String, dynamic>? _usageLimit;

  late final AiAssistantService _service;

  static const _labels = {
    UserRole.student: 'المساعد الذكي للطالب',
    UserRole.teacher: 'المساعد الذكي للمدرس',
    UserRole.assistantTeacher: 'المساعد الذكي للمدرس',
  };

  static const _welcome = {
    UserRole.student: 'مرحباً! أنا مساعدك التعليمي الذكي. كيف يمكنني مساعدتك اليوم؟',
    UserRole.teacher: 'مرحباً! أنا المساعد الذكي للمدرسين. كيف يمكنني مساعدتك في تحضير الدروس؟',
    UserRole.assistantTeacher: 'مرحباً! أنا المساعد الذكي للمدرسين. كيف يمكنني مساعدتك؟',
  };

  @override
  void initState() {
    super.initState();
    _service = AiAssistantService(context.read<ApiClient>());
    _initChat();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  UserRole get _role {
    final user = context.read<AuthCubit>().currentUser;
    return user?.role ?? UserRole.student;
  }

  String get _label => _labels[_role] ?? 'المساعد الذكي';
  String get _welcomeMsg => _welcome[_role] ?? 'مرحباً! كيف يمكنني مساعدتك؟';

  Future<void> _initChat() async {
    setState(() {
      _messages = [_ChatMessage(role: 'assistant', content: _welcomeMsg)];
    });
    await _fetchUsage();
  }

  Future<void> _fetchUsage() async {
    try {
      final usage = await _service.checkUsage();
      if (mounted) setState(() => _usageLimit = usage);
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _loading) return;

    _msgCtrl.clear();
    final userMsg = _ChatMessage(role: 'user', content: text);
    setState(() {
      _messages.add(userMsg);
      _loading = true;
    });
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => m.role != 'system')
          .toList()
          .reversed
          .take(10)
          .toList()
          .reversed
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final data = await _service.sendMessage(message: text, history: history);
      final reply = data['reply'] as String? ?? 'عذراً، لم أتمكن من الرد. حاول مرة أخرى.';
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: reply));
          if (data['limit'] != null) {
            _usageLimit = data['limit'] as Map<String, dynamic>;
          }
        });
        _scrollToBottom();
      }
    } on ServerFailure catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: e.message));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: 'عذراً، حدث خطأ في الاتصال. حاول مرة أخرى.'));
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final usagePercent = _usageLimit != null
        ? ((_usageLimit!['used'] as int? ?? 0) / (_usageLimit!['limit'] as int? ?? 10) * 100)
        : 0.0;
    final remaining = _usageLimit?['remaining'] as int?;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(_label,
                      style: TextStyles.semiBold16.copyWith(color: Colors.white)),
                ),
              ],
            ),
            if (remaining != null)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  '$remaining رسالة متبقية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
        bottom: _usageLimit != null
            ? PreferredSize(
                preferredSize: Size.fromHeight(6.h),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: LinearProgressIndicator(
                    value: (usagePercent / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      usagePercent >= 80
                          ? const Color(0xFFEF4444)
                          : usagePercent >= 60
                              ? const Color(0xFFF59E0B)
                              : Colors.white,
                    ),
                    minHeight: 3.h,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(isDark)),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: EdgeInsets.all(16.w),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _loading) {
          return _buildTypingIndicator(isDark);
        }
        final msg = _messages[index];
        final isUser = msg.role == 'user';

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              if (!isUser)
                Container(
                  width: 30.w,
                  height: 30.w,
                  margin: EdgeInsets.only(left: 8.w),
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C3AED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
                ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  constraints: BoxConstraints(maxWidth: 0.8.sw),
                  decoration: BoxDecoration(
                    color: isUser
                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFEDE9FE)),
                    borderRadius: BorderRadius.circular(12.r),
                    border: isUser
                        ? Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))
                        : null,
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      height: 1.7,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            margin: EdgeInsets.only(left: 8.w),
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(isDark),
                SizedBox(width: 4.w),
                _dot(isDark, delay: true),
                SizedBox(width: 4.w),
                _dot(isDark, delay: true, moreDelay: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool isDark, {bool delay = false, bool moreDelay = false}) {
    return Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF7C3AED),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          ),
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
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    color: (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)).withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
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
                onPressed: _loading ? null : _sendMessage,
                icon: _loading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;
  const _ChatMessage({required this.role, required this.content});
}
