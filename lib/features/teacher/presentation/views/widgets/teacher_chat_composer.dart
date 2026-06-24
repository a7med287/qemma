import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'teacher_theme_helpers.dart';

class TeacherChatComposer extends StatelessWidget {
  const TeacherChatComposer({
    super.key,
    required this.courses,
    required this.selectedCourse,
    required this.searchController,
    required this.onCourseChanged,
    required this.onSearchChanged,
  });

  final List<Map<String, dynamic>> courses;
  final String selectedCourse;
  final TextEditingController searchController;
  final ValueChanged<String> onCourseChanged;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        children: [
          _buildCourseDropdown(context, isDark),
          SizedBox(height: 8.h),
          TextField(
            controller: searchController,
            onChanged: (_) => onSearchChanged(),
            style: TextStyle(
                fontFamily: 'Cairo', fontSize: 14.sp, color: fieldTextColor(context)),
            decoration: InputDecoration(
              hintText: 'ابحث عن طالب بالاسم...',
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                color: fieldLabelColor(context).withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(Icons.search, size: 20, color: fieldLabelColor(context)),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: fieldBorderColor(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: fieldBorderColor(context)),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fieldBorderColor(context)),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCourse.isNotEmpty ? selectedCourse : null,
          isExpanded: true,
          hint: Text('تصفية بالكورس',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: fieldLabelColor(context).withValues(alpha: 0.5),
              )),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: fieldTextColor(context),
          ),
          items: [
            DropdownMenuItem(
                value: '',
                child: Text('كل الكورسات',
                    style: TextStyle(color: fieldLabelColor(context)))),
            ...courses.map((c) {
              final id = (c['id'] ?? c['_id'] ?? '') as String;
              final title = (c['title'] ?? '') as String;
              return DropdownMenuItem(value: id, child: Text(title));
            }),
          ],
          onChanged: (v) => onCourseChanged(v ?? ''),
        ),
      ),
    );
  }
}
