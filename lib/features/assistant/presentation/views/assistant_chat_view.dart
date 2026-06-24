import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/assistant_repository.dart';

class AssistantChatView extends StatefulWidget {
  static const routeName = '/assistant-teacher/chat';
  const AssistantChatView({super.key});

  @override
  State<AssistantChatView> createState() => _AssistantChatViewState();
}

class _AssistantChatViewState extends State<AssistantChatView> {
  final _searchCtrl = TextEditingController();
  String _selectedCourse = '';
  bool _loading = true;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _sessions = [];

  // Chat view
  String? _chatSessionId;
  Map<String, dynamic>? _chatStudent;
  List<Map<String, dynamic>> _messages = [];
  bool _chatLoading = false;
  bool _sending = false;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _pollTimer;

  AssistantRepository get _repo => context.read<AssistantRepository>();

  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _chatSessionId != null) {
        _scrollToBottom();
      }
    });
    _fetchData();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchCtrl.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getChatCourses(),
        _repo.getChatStudents(),
        _repo.getSessions(),
      ]);
      if (mounted) {
        setState(() {
          _courses = results[0];
          _allStudents = results[1];
          _sessions = results[2];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('حدث خطأ في تحميل البيانات');
      }
    }
  }

  void _showError(String msg) => buildSnackBar(context, msg, isError: true);

  List<Map<String, dynamic>> get _filteredStudents {
    var list = _allStudents;
    if (_selectedCourse.isNotEmpty) {
      list = list.where((s) {
        final courses = s['courses'] as List? ?? [];
        return courses.any((c) {
          final cMap = c as Map?;
          return cMap?['id'] == _selectedCourse;
        });
      }).toList();
    }
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((s) => (s['name'] ?? '').toString().toLowerCase().contains(query)).toList();
    }
    return list;
  }

  // ── Chat logic ──────────────────────────────────────────────────
  void _openNewSession(Map<String, dynamic> student) async {
    final studentId = (student['userId'] ?? student['studentId'] ?? '') as String;
    if (studentId.isEmpty) { _showError('بيانات الطالب غير مكتملة'); return; }
    setState(() => _chatLoading = true);
    try {
      final result = await _repo.openSessionWithStudent(
        studentUserId: studentId,
        courseId: _selectedCourse,
      );
      if (mounted) {
        _chatSessionId = (result['id'] ?? result['_id'] ?? '') as String;
        _chatStudent = student;
        _fetchMessages();
      }
    } catch (e) {
      if (mounted) { setState(() => _chatLoading = false); _showError('فشل فتح المحادثة'); }
    }
  }

  void _openSession(Map<String, dynamic> session) {
    final student = (session['student'] as Map<String, dynamic>?) ?? {};
    setState(() {
      _chatSessionId = (session['id'] ?? session['_id'] ?? '') as String;
      _chatStudent = student;
    });
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    if (_chatSessionId == null) return;
    setState(() => _chatLoading = true);
    try {
      final msgs = await _repo.getChatMessages(_chatSessionId!);
      if (mounted) {
        setState(() { _messages = msgs; _chatLoading = false; });
        _scrollToBottom();
        _startPolling();
      }
    } catch (_) {
      if (mounted) { setState(() => _chatLoading = false); _showError('فشل تحميل الرسائل'); }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_chatSessionId != null) _refreshMessages();
    });
  }

  Future<void> _refreshMessages() async {
    if (_chatSessionId == null) return;
    try {
      final msgs = await _repo.getChatMessages(_chatSessionId!);
      if (mounted && msgs.length > _messages.length) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty || _chatSessionId == null || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await _repo.sendChatMessage(sessionId: _chatSessionId!, message: msg);
      if (mounted) {
        _msgCtrl.clear();
        setState(() { _messages.add(sent); _sending = false; });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) { setState(() => _sending = false); _showError('فشل إرسال الرسالة'); }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  bool _isFromTeacher(Map<String, dynamic> msg) {
    final sender = (msg['sender'] as Map<String, dynamic>?) ?? msg['user'] as Map<String, dynamic>?;
    if (sender == null) return (msg['role'] ?? '') == 'teacher';
    final role = (sender['role'] ?? '') as String;
    return role == 'teacher';
  }

  bool _isFromAssistant(Map<String, dynamic> msg) {
    final sender = (msg['sender'] as Map<String, dynamic>?) ?? msg['user'] as Map<String, dynamic>?;
    if (sender == null) return false;
    final role = (sender['role'] ?? '') as String;
    return role == 'assistant_teacher' || role == 'assistant';
  }

  String _getSenderLabel(Map<String, dynamic> msg) {
    if (_isFromTeacher(msg)) return '👨‍🏫 مدرس';
    if (_isFromAssistant(msg)) return '🧑‍🏫 مساعد';
    return '👨‍🎓 طالب';
  }

  // ── Theme ───────────────────────────────────────────────────────
  Color _fieldBorder() => context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  Color _fieldLabel() => context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  Color _fieldText() => context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
  Color _cardBg() => context.isDark ? const Color(0xFF1E293B) : Colors.white;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    if (_chatSessionId != null) return _buildChatView(isDark);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isDark),
                  Expanded(child: _buildBody(isDark)),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]),
      ),
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white12),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Container(
                width: 44.w, height: 44.w,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white.withValues(alpha: .2)),
                child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المحادثات', style: TextStyles.bold20.copyWith(color: Colors.white)),
                    Text('تواصل مع الطلاب والمدرس', style: TextStyles.regular13.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildFilters(isDark),
          SizedBox(height: 16.h),
          _buildStudentList(isDark),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: _cardBg(), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _fieldBorder())),
      child: Column(
        children: [
          _buildCourseDropdown(isDark),
          SizedBox(height: 8.h),
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: _fieldText()),
            decoration: InputDecoration(
              hintText: 'ابحث عن طالب بالاسم...',
              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: _fieldLabel().withValues(alpha: .5)),
              prefixIcon: Icon(Icons.search, size: 20, color: _fieldLabel()),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: _fieldBorder())),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: _fieldBorder())),
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r), border: Border.all(color: _fieldBorder()),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCourse.isNotEmpty ? _selectedCourse : null,
          isExpanded: true,
          hint: Text('تصفية بالكورس', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: _fieldLabel().withValues(alpha: .5))),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: _fieldText()),
          items: [
            DropdownMenuItem(value: '', child: Text('كل الكورسات', style: TextStyle(color: _fieldLabel()))),
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

  Widget _buildStudentList(bool isDark) {
    final hasSession = _sessions.where((s) {
      final cId = (s['courseId'] ?? '') as String;
      return _selectedCourse.isEmpty || cId == _selectedCourse;
    }).toList();

    if (hasSession.isNotEmpty) {
      return Column(
        children: [
          _buildSectionTitle('المحادثات النشطة', isDark),
          SizedBox(height: 8.h),
          ...hasSession.map((s) => _buildSessionRow(s, isDark)),
          SizedBox(height: 16.h),
        ],
      );
    }

    final students = _filteredStudents;
    if (students.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text('لا توجد محادثات بعد', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: _fieldLabel())),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSectionTitle('جميع الطلاب', isDark),
        SizedBox(height: 8.h),
        ...students.map((s) => _buildStudentRow(s, isDark)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(title, style: TextStyles.semiBold14.copyWith(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
    );
  }

  Widget _buildStudentRow(Map<String, dynamic> student, bool isDark) {
    final name = (student['name'] ?? 'طالب') as String;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(color: _cardBg(), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _fieldBorder())),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => _openNewSession(student),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20, backgroundColor: const Color(0xFF059669),
                child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, fontFamily: 'Cairo',
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text('فتح محادثة',
                    style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: const Color(0xFF059669))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionRow(Map<String, dynamic> session, bool isDark) {
    final student = (session['student'] as Map<String, dynamic>?) ?? {};
    final name = (student['name'] ?? 'طالب') as String;
    final lastMessage = session['lastMessage'] as Map?;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(color: _cardBg(), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _fieldBorder())),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => _openSession(session),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20, backgroundColor: const Color(0xFF059669),
                child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, fontFamily: 'Cairo',
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                    if (lastMessage != null)
                      Text('${lastMessage['message'] ?? ''}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.sp, fontFamily: 'Cairo', color: _fieldLabel())),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, size: 20, color: _fieldLabel()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chat View ──────────────────────────────────────────────────
  Widget _buildChatView(bool isDark) {
    final studentName = (_chatStudent?['name'] ?? (_chatStudent?['user'] as Map?)?['name'] ?? 'طالب') as String;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => setState(() {
            _chatSessionId = null; _chatStudent = null; _messages = []; _pollTimer?.cancel();
          }),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18, backgroundColor: Colors.white.withValues(alpha: .2),
              child: Text(studentName.isNotEmpty ? studentName[0] : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            SizedBox(width: 10.w),
            Expanded(child: Text(studentName, style: TextStyles.semiBold16.copyWith(color: Colors.white))),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchMessages),
        ],
      ),
      body: _chatLoading
          ? const Center(child: CircularProgressIndicator())
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
            Icon(Icons.chat_bubble_outline, size: 48, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text('لا توجد رسائل بعد، أرسل أول رسالة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: _fieldLabel())),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: EdgeInsets.all(16.w),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildMessageBubble(_messages[i], isDark),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isDark) {
    final text = (msg['message'] ?? msg['text'] ?? '') as String;
    final isTeacher = _isFromTeacher(msg);
    final isAssistant = _isFromAssistant(msg);
    final isMine = isAssistant || msg['isAssistant'] == true;
    final createdAt = msg['createdAt'] as String?;
    final time = createdAt != null && createdAt.length >= 16 ? createdAt.substring(11, 16) : '';
    final senderLabel = _getSenderLabel(msg);

    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 0.8.sw),
        decoration: BoxDecoration(
          color: isMine
              ? (context.isDark ? const Color(0xFF059669).withValues(alpha: .3) : const Color(0xFF059669).withValues(alpha: .1))
              : (context.isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: isMine ? const Radius.circular(4) : const Radius.circular(10),
            bottomRight: isMine ? const Radius.circular(10) : const Radius.circular(4),
          ),
          border: Border.all(color: context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTeacher || isAssistant)
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Text(senderLabel,
                    style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isTeacher ? const Color(0xFF7C3AED) : const Color(0xFF059669))),
              ),
            Text(text,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp,
                    color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937))),
            if (time.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(time, style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp,
                      color: _fieldLabel().withValues(alpha: .8), fontWeight: FontWeight.w500)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(top: BorderSide(color: _fieldBorder())),
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
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937)),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: _fieldLabel().withValues(alpha: .5)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: BorderSide(color: _fieldBorder())),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: BorderSide(color: _fieldBorder())),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 44.w, height: 44.w,
              decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
              child: IconButton(
                onPressed: _sending ? null : _sendMessage,
                icon: _sending
                    ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
