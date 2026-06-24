import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'teacher_theme_helpers.dart';

class TeacherChatRoomList extends StatelessWidget {
  const TeacherChatRoomList({
    super.key,
    required this.sessions,
    required this.selectedCourse,
    required this.filteredStudents,
    required this.searchQuery,
    required this.courses,
    required this.onStudentTap,
    required this.onSessionTap,
  });

  final List<Map<String, dynamic>> sessions;
  final String selectedCourse;
  final List<Map<String, dynamic>> filteredStudents;
  final String searchQuery;
  final List<Map<String, dynamic>> courses;
  final void Function(Map<String, dynamic> student, Map<String, dynamic>? session) onStudentTap;
  final void Function(Map<String, dynamic> session) onSessionTap;

  Map<String, Map<String, dynamic>> _groupSessionsByCourse() {
    final courseMap = <String, String>{};
    for (final c in courses) {
      final id = (c['id'] ?? c['_id'] ?? '') as String;
      final title = (c['title'] ?? '') as String;
      courseMap[id] = title;
    }
    final grouped = <String, Map<String, dynamic>>{};
    for (final s in sessions) {
      final cId = (s['courseId'] ?? 'no-course') as String;
      final cTitle = (s['courseTitle'] ?? courseMap[cId] ?? 'بدون كورس') as String;
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'جديد';
    try {
      return dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
    } catch (_) {
      return 'جديد';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedCourse.isNotEmpty) {
      return _buildCourseStudentList(context);
    }
    return _buildCourseGroupedList(context);
  }

  Widget _buildCourseStudentList(BuildContext context) {
    final isDark = context.isDark;
    final students = filteredStudents;
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text('طلاب الكورس (${students.length})',
                style: TextStyles.semiBold16.copyWith(
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                )),
          ),
          if (students.isEmpty)
            Padding(
              padding: EdgeInsets.all(32.w),
              child: Center(
                child: Text(
                    searchQuery.isNotEmpty ? 'لا توجد نتائج' : 'لا يوجد طلاب في هذا الكورس',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      color: fieldLabelColor(context),
                    )),
              ),
            )
          else
            ...students.asMap().entries.map((entry) {
              final i = entry.key;
              final student = entry.value;
              return Column(
                children: [
                  _buildStudentRow(context, student, isDark),
                  if (i < students.length - 1)
                    Divider(height: 1, color: fieldBorderColor(context)),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStudentRow(BuildContext context, Map<String, dynamic> student, bool isDark) {
    final name = (student['name'] ?? 'طالب') as String;
    final userId = (student['userId'] ?? student['studentId'] ?? '') as String;
    final session = sessions.cast<Map<String, dynamic>?>().firstWhere(
          (s) =>
              (s?['student'] as Map?)?['id'] == userId &&
              s?['courseId'] == selectedCourse,
          orElse: () => null,
        );

    return InkWell(
      onTap: () => onStudentTap(student, session),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Badge(
              isLabelVisible: (session?['messagesCount'] ?? 0) > 0,
              label: Text(
                '${session?['messagesCount'] ?? 0}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF7C3AED),
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      )),
                  if (session?['lastMessage'] != null)
                    Text(
                      'آخر رسالة: ${(session!['lastMessage'] as Map)['message'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
                        color: fieldLabelColor(context),
                      ),
                    ),
                  if ((session?['messagesCount'] ?? 0) == 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text('لا توجد رسائل بعد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10.sp,
                            color: fieldLabelColor(context),
                          )),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, size: 20, color: fieldLabelColor(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseGroupedList(BuildContext context) {
    final isDark = context.isDark;
    final grouped = _groupSessionsByCourse();
    if (grouped.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 48,
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text('لا توجد محادثات بعد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  color: fieldLabelColor(context),
                )),
          ],
        ),
      );
    }

    return Column(
      children: grouped.values.map((group) {
        return _buildCourseGroup(context, group, isDark);
      }).toList(),
    );
  }

  Widget _buildCourseGroup(BuildContext context, Map<String, dynamic> group, bool isDark) {
    final sessionsList = (group['sessions'] as List<Map<String, dynamic>>);
    final courseTitle = (group['courseTitle'] ?? '') as String;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                  : const Color(0xFF7C3AED).withValues(alpha: 0.05),
              border: Border(bottom: BorderSide(color: fieldBorderColor(context))),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school, size: 20, color: Color(0xFF7C3AED)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(courseTitle,
                      style: TextStyles.semiBold14.copyWith(
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      )),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text('${sessionsList.length} طالب',
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
          ...sessionsList.asMap().entries.map((entry) {
            final i = entry.key;
            final ses = entry.value;
            return Column(
              children: [
                _buildSessionRow(context, ses, isDark),
                if (i < sessionsList.length - 1)
                  Divider(height: 1, color: fieldBorderColor(context)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSessionRow(BuildContext context, Map<String, dynamic> session, bool isDark) {
    final student = (session['student'] as Map<String, dynamic>?) ?? {};
    final name = (student['name'] ?? 'طالب') as String;
    final lastMessage = session['lastMessage'] as Map?;
    final messagesCount = session['messagesCount'] ?? 0;
    final lastActive = session['lastActive'] as String?;

    return InkWell(
      onTap: () => onSessionTap(session),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Badge(
              isLabelVisible: messagesCount > 0,
              label: Text(
                '$messagesCount',
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF7C3AED),
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      )),
                  if (lastMessage != null)
                    Text(
                      'آخر رسالة: ${lastMessage['message'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
                        color: fieldLabelColor(context),
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
                color: fieldLabelColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
