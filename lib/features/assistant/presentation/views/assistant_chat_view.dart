import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/assistant_repository.dart';
import 'widgets/assistant_chat_body.dart';

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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          ChatFilters(
                            isDark: isDark,
                            fieldBorder: _fieldBorder(),
                            fieldLabel: _fieldLabel(),
                            fieldText: _fieldText(),
                            cardBg: _cardBg(),
                            selectedCourse: _selectedCourse,
                            onCourseChanged: (v) => setState(() => _selectedCourse = v),
                            courses: _courses,
                            searchController: _searchCtrl,
                            onSearchChanged: () => setState(() {}),
                          ),
                          SizedBox(height: 16.h),
                          ChatStudentList(
                            isDark: isDark,
                            fieldBorder: _fieldBorder(),
                            fieldLabel: _fieldLabel(),
                            cardBg: _cardBg(),
                            sessions: _sessions,
                            selectedCourse: _selectedCourse,
                            filteredStudents: _filteredStudents,
                            onSessionTap: _openSession,
                            onStudentTap: _openNewSession,
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
                Expanded(
                  child: ChatMessageList(
                    isDark: isDark,
                    fieldLabel: _fieldLabel(),
                    scrollController: _scrollCtrl,
                    messages: _messages,
                    isFromTeacher: _isFromTeacher,
                    isFromAssistant: _isFromAssistant,
                    getSenderLabel: _getSenderLabel,
                  ),
                ),
                ChatInputBar(
                  isDark: isDark,
                  fieldBorder: _fieldBorder(),
                  controller: _msgCtrl,
                  focusNode: _focusNode,
                  sending: _sending,
                  onSend: _sendMessage,
                ),
              ],
            ),
    );
  }
}
