import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'teacher_theme_helpers.dart';

class TeacherCourseFilterBar extends StatelessWidget {
  const TeacherCourseFilterBar({
    super.key,
    required this.searchQuery,
    required this.tabValue,
    required this.totalCourses,
    required this.publishedCount,
    required this.draftCount,
    required this.onSearchChanged,
    required this.onTabChanged,
  });

  final String searchQuery;
  final int tabValue;
  final int totalCourses;
  final int publishedCount;
  final int draftCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.r),
            child: TextField(
              onChanged: onSearchChanged,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : null),
              decoration: InputDecoration(
                hintText: 'ابحث عن كورس...',
                hintTextDirection: TextDirection.rtl,
                hintStyle: TextStyle(fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
                prefixIcon: Icon(Icons.search,
                    color: isDark ? const Color(0xFF94A3B8) : null),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
          Row(
            children: [
              _buildTab(context, 0, 'الكل ($totalCourses)'),
              _buildTab(context, 1, 'منشور ($publishedCount)'),
              _buildTab(context, 2, 'مسودة ($draftCount)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, String label) {
    final isDark = context.isDark;
    final selected = tabValue == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF2563EB))
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 11.sp, fontWeight: FontWeight.w700,
                color: selected
                    ? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF2563EB))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
              )),
        ),
      ),
    );
  }
}
