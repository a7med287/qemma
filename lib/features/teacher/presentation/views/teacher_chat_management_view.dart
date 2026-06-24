import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';
import 'teacher_chat_conversation_view.dart';
import 'widgets/teacher_chat_message_area.dart';

class TeacherChatManagementView extends StatefulWidget {
  static const routeName = '/teacher/chat-management';
  const TeacherChatManagementView({super.key});

  @override
  State<TeacherChatManagementView> createState() =>
      _TeacherChatManagementViewState();
}

class _TeacherChatManagementViewState
    extends State<TeacherChatManagementView> {
  final _searchCtrl = TextEditingController();
  String _selectedCourse = '';
  bool _loading = true;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  TeacherRepository get _repo => context.read<TeacherRepository>();

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

  void _showError(String msg) {
    buildSnackBar(context, msg, isError: true);
  }

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
      list = list
          .where((s) =>
              (s['name'] ?? '').toString().toLowerCase().contains(query))
          .toList();
    }
    return list;
  }

  int get _statsTotalStudents => _allStudents.length;
  int get _statsActiveChats =>
      _sessions.where((s) => (s['messagesCount'] ?? 0) > 0).length;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isDark),
                  Expanded(
                    child: TeacherChatMessageArea(
                      totalStudents: _statsTotalStudents,
                      activeChats: _statsActiveChats,
                      courses: _courses,
                      selectedCourse: _selectedCourse,
                      searchController: _searchCtrl,
                      sessions: _sessions,
                      filteredStudents: _filteredStudents,
                      searchQuery: _searchCtrl.text,
                      onCourseChanged: (v) =>
                          setState(() => _selectedCourse = v),
                      onSearchChanged: () => setState(() {}),
                      onStudentTap: _openConversation,
                      onSessionTap: _openConversationFromSession,
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
        gradient:
            LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
      ),
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white12),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.chat_bubble_outline,
                    color: Colors.white, size: 24),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إدارة المحادثات',
                        style: TextStyles.bold20
                            .copyWith(color: Colors.white)),
                    Text('كل كورس له غرفة محادثة منفصلة',
                        style: TextStyles.regular13
                            .copyWith(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  void _openConversation(Map<String, dynamic> student,
      Map<String, dynamic>? session) async {
    final result = await Navigator.pushNamed(
      context,
      TeacherChatConversationView.routeName,
      arguments: {
        'student': student,
        'courseId': _selectedCourse,
      },
    );
    if (result == true) _fetchData();
  }

  void _openConversationFromSession(Map<String, dynamic> session) async {
    final student = (session['student'] as Map<String, dynamic>?) ?? {};
    final courseId = (session['courseId'] ?? '') as String;
    final result = await Navigator.pushNamed(
      context,
      TeacherChatConversationView.routeName,
      arguments: {
        'session': session,
        'student': student,
        'courseId': courseId,
      },
    );
    if (result == true) _fetchData();
  }
}
