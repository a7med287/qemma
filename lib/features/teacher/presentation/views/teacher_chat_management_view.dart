import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';
import 'teacher_chat_conversation_view.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  Map<String, Map<String, dynamic>> _groupSessionsByCourse() {
    final courseMap = <String, String>{};
    for (final c in _courses) {
      final id = (c['id'] ?? c['_id'] ?? '') as String;
      final title = (c['title'] ?? '') as String;
      courseMap[id] = title;
    }
    final grouped = <String, Map<String, dynamic>>{};
    for (final s in _sessions) {
      final cId = (s['courseId'] ?? 'no-course') as String;
      final cTitle =
          (s['courseTitle'] ?? courseMap[cId] ?? 'بدون كورس') as String;
      if (!grouped.containsKey(cId)) {
        grouped[cId] = {
          'courseTitle': cTitle,
          'courseId': cId,
          'sessions': <Map<String, dynamic>>[],
        };
      }
      (grouped[cId]!['sessions'] as List<Map<String, dynamic>>).add(s);
    }
    return grouped;
  }

  int get _statsTotalStudents => _allStudents.length;
  int get _statsActiveChats =>
      _sessions.where((s) => (s['messagesCount'] ?? 0) > 0).length;
  int get _statsCourses => _courses.length;

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
                  Expanded(child: _buildBody(isDark)),
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

  Widget _buildBody(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildStatsRow(isDark),
          SizedBox(height: 16.h),
          _buildFilters(isDark),
          SizedBox(height: 16.h),
          if (_selectedCourse.isNotEmpty)
            _buildCourseStudentList(isDark)
          else
            _buildCourseGroupedList(isDark),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        _statCard('$_statsTotalStudents', 'إجمالي الطلاب',
            Icons.people, const Color(0xFF7C3AED), isDark),
        SizedBox(width: 8.w),
        _statCard('$_statsActiveChats', 'محادثات نشطة',
            Icons.chat_bubble_outline, const Color(0xFF2563EB), isDark),
        // SizedBox(width: 8.w),
        // _statCard('$_statsCourses', 'الكورسات', Icons.school,
        //     const Color(0xFF059669), isDark),
      ],
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: _cardBg(),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _fieldBorder()),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyles.bold20.copyWith(
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1F2937),
                    )),
                Text(label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.sp,
                      color: _fieldLabel(),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Column(
        children: [
          // Course filter
          _buildCourseDropdown(isDark),
          SizedBox(height: 8.h),
          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
                fontFamily: 'Cairo', fontSize: 14.sp, color: _fieldText()),
            decoration: InputDecoration(
              hintText: 'ابحث عن طالب بالاسم...',
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                color: _fieldLabel().withValues(alpha: 0.5),
              ),
              prefixIcon:
                  Icon(Icons.search, size: 20, color: _fieldLabel()),
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown(bool isDark) {
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
          hint: Text('تصفية بالكورس',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: _fieldLabel().withValues(alpha: 0.5),
              )),
          dropdownColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: _fieldText(),
          ),
          items: [
            DropdownMenuItem(
                value: '',
                child: Text('كل الكورسات',
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

  // ── Course student list (when course filter active) ─────────────
  Widget _buildCourseStudentList(bool isDark) {
    final students = _filteredStudents;
    return Container(
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text('طلاب الكورس (${students.length})',
                style: TextStyles.semiBold16.copyWith(
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                )),
          ),
          if (students.isEmpty)
            Padding(
              padding: EdgeInsets.all(32.w),
              child: Center(
                child: Text(
                    _searchCtrl.text.isNotEmpty
                        ? 'لا توجد نتائج'
                        : 'لا يوجد طلاب في هذا الكورس',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      color: _fieldLabel(),
                    )),
              ),
            )
          else
            ...students.asMap().entries.map((entry) {
              final i = entry.key;
              final student = entry.value;
              return Column(
                children: [
                  _buildStudentRow(student, isDark),
                  if (i < students.length - 1)
                    Divider(
                        height: 1,
                        color: _fieldBorder()),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStudentRow(Map<String, dynamic> student, bool isDark) {
    final name = (student['name'] ?? 'طالب') as String;
    final userId =
        (student['userId'] ?? student['studentId'] ?? '') as String;
    final session = _sessions.cast<Map<String, dynamic>?>().firstWhere(
          (s) =>
              (s?['student'] as Map?)?['id'] == userId &&
              s?['courseId'] == _selectedCourse,
          orElse: () => null,
        );

    return InkWell(
      onTap: () => _openConversation(student, session),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Badge(
              isLabelVisible: (session?['messagesCount'] ?? 0) > 0,
              label: Text(
                '${session?['messagesCount'] ?? 0}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF7C3AED),
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      )),
                  if (session?['lastMessage'] != null)
                    Text(
                      'آخر رسالة: ${(session!['lastMessage'] as Map)['message'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
                        color: _fieldLabel(),
                      ),
                    ),
                  if ((session?['messagesCount'] ?? 0) == 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text('لا توجد رسائل بعد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10.sp,
                            color: _fieldLabel(),
                          )),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_left,
                size: 20, color: _fieldLabel()),
          ],
        ),
      ),
    );
  }

  // ── Course-grouped sessions ─────────────────────────────────────
  Widget _buildCourseGroupedList(bool isDark) {
    final grouped = _groupSessionsByCourse();
    if (grouped.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 48,
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text('لا توجد محادثات بعد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  color: _fieldLabel(),
                )),
          ],
        ),
      );
    }

    return Column(
      children: grouped.values.map((group) {
        return _buildCourseGroup(group, isDark);
      }).toList(),
    );
  }

  Widget _buildCourseGroup(Map<String, dynamic> group, bool isDark) {
    final sessions = (group['sessions'] as List<Map<String, dynamic>>);
    final courseTitle = (group['courseTitle'] ?? '') as String;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                  : const Color(0xFF7C3AED).withValues(alpha: 0.05),
              border: Border(bottom: BorderSide(color: _fieldBorder())),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school,
                    size: 20, color: Color(0xFF7C3AED)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(courseTitle,
                      style: TextStyles.semiBold14.copyWith(
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      )),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text('${sessions.length} طالب',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 10.sp,
                        color: const Color(0xFF7C3AED),
                      )),
                ),
              ],
            ),
          ),
          // Sessions
          ...sessions.asMap().entries.map((entry) {
            final i = entry.key;
            final session = entry.value;
            return Column(
              children: [
                _buildSessionRow(session, isDark),
                if (i < sessions.length - 1)
                  Divider(height: 1, color: _fieldBorder()),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSessionRow(Map<String, dynamic> session, bool isDark) {
    final student =
        (session['student'] as Map<String, dynamic>?) ?? {};
    final name = (student['name'] ?? 'طالب') as String;
    final lastMessage = session['lastMessage'] as Map?;
    final messagesCount = session['messagesCount'] ?? 0;
    final lastActive = session['lastActive'] as String?;

    return InkWell(
      onTap: () => _openConversationFromSession(session),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Badge(
              isLabelVisible: messagesCount > 0,
              label: Text(
                '$messagesCount',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF7C3AED),
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      )),
                  if (lastMessage != null)
                    Text(
                      'آخر رسالة: ${lastMessage['message'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
                        color: _fieldLabel(),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              _formatDate(lastActive),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.sp,
                color: _fieldLabel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'جديد';
    try {
      return dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
    } catch (_) {
      return 'جديد';
    }
  }

  // ── Navigation ─────────────────────────────────────────────────
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
