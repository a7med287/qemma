import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'teacher_theme_helpers.dart';
import 'teacher_chat_composer.dart';
import 'teacher_chat_room_list.dart';

class TeacherChatMessageArea extends StatelessWidget {
  const TeacherChatMessageArea({
    super.key,
    required this.totalStudents,
    required this.activeChats,
    required this.courses,
    required this.selectedCourse,
    required this.searchController,
    required this.sessions,
    required this.filteredStudents,
    required this.searchQuery,
    required this.onCourseChanged,
    required this.onSearchChanged,
    required this.onStudentTap,
    required this.onSessionTap,
  });

  final int totalStudents;
  final int activeChats;
  final List<Map<String, dynamic>> courses;
  final String selectedCourse;
  final TextEditingController searchController;
  final List<Map<String, dynamic>> sessions;
  final List<Map<String, dynamic>> filteredStudents;
  final String searchQuery;
  final ValueChanged<String> onCourseChanged;
  final VoidCallback onSearchChanged;
  final void Function(Map<String, dynamic> student, Map<String, dynamic>? session) onStudentTap;
  final void Function(Map<String, dynamic> session) onSessionTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildStatsRow(context),
          SizedBox(height: 16.h),
          TeacherChatComposer(
            courses: courses,
            selectedCourse: selectedCourse,
            searchController: searchController,
            onCourseChanged: onCourseChanged,
            onSearchChanged: onSearchChanged,
          ),
          SizedBox(height: 16.h),
          TeacherChatRoomList(
            sessions: sessions,
            selectedCourse: selectedCourse,
            filteredStudents: filteredStudents,
            searchQuery: searchQuery,
            courses: courses,
            onStudentTap: onStudentTap,
            onSessionTap: onSessionTap,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final isDark = context.isDark;
    return Row(
      children: [
        _statCard(context, '$totalStudents', 'إجمالي الطلاب',
            Icons.people, const Color(0xFF7C3AED), isDark),
        SizedBox(width: 8.w),
        _statCard(context, '$activeChats', 'محادثات نشطة',
            Icons.chat_bubble_outline, const Color(0xFF2563EB), isDark),
      ],
    );
  }

  Widget _statCard(BuildContext context,
      String value, String label, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: cardBgColor(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: fieldBorderColor(context)),
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
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
                    )),
                Text(label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.sp,
                      color: fieldLabelColor(context),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
