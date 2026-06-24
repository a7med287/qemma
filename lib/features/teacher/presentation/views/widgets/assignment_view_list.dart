import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'teacher_form_fields.dart';
import 'teacher_theme_helpers.dart';

class AssignmentViewList extends StatelessWidget {
  const AssignmentViewList({
    super.key,
    required this.isDark,
    required this.courses,
    required this.assignments,
    required this.assignmentsLoading,
    required this.filterCourse,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onViewDetail,
    required this.onCreateTab,
  });

  final bool isDark;
  final List<Map<String, dynamic>> courses;
  final List<Map<String, dynamic>> assignments;
  final bool assignmentsLoading;
  final String filterCourse;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onViewDetail;
  final VoidCallback onCreateTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(context),
        Expanded(child: _buildAssignmentList(context)),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.school, size: 20, color: fieldLabelColor(context)),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildDropdown(
              value: filterCourse,
              placeholder: 'جميع الكورسات',
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('جميع الكورسات')),
                ...courses.map((c) {
                  final id = (c['id'] ?? c['_id'] ?? '') as String;
                  final title = (c['title'] ?? '') as String;
                  return DropdownMenuItem(
                      value: id, child: Text(title));
                }),
              ],
              onChanged: onFilterChanged,
              context: context,
            ),
          ),
          SizedBox(width: 8.w),
          FilledButton.icon(
            onPressed: onCreateTab,
            icon: const Icon(Icons.add, size: 16),
            label: Text('جديد',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentList(BuildContext context) {
    if (assignmentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (assignments.isEmpty) {
      return _buildEmptyState(context);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: assignments.length,
        itemBuilder: (_, i) =>
            _buildAssignmentCard(assignments[i], context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: cardBgColor(context),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: fieldBorderColor(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment,
                size: 64,
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1)),
            SizedBox(height: 16.h),
            Text('لا توجد واجبات بعد',
                style: TextStyles.bold18.copyWith(
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                )),
            SizedBox(height: 8.h),
            Text('أنشئ أول واجب الآن',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  color: fieldLabelColor(context),
                )),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: onCreateTab,
              icon: const Icon(Icons.add, size: 18),
              label: Text('إنشاء واجب',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> a, BuildContext context) {
    final id = (a['id'] ?? a['_id'] ?? '') as String;
    final title = (a['title'] ?? '') as String;
    final courseTitle = (a['courseTitle'] ?? '') as String;
    final lessonTitle = a['lessonTitle'] as String?;
    final description = a['description'] as String?;
    final maxScore = a['maxScore'] ?? 0;
    final submissionsCount = a['submissionsCount'] ?? 0;
    final dueDate = a['dueDate'] as String?;
    final graded = a['gradedCount'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
              gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.assignment,
                        size: 22, color: const Color(0xFF8B5CF6)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyles.semiBold14.copyWith(
                                color: isDark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF1E293B),
                              )),
                          SizedBox(height: 4.h),
                          Wrap(
                            spacing: 4.w,
                            children: [
                              teacherChip(courseTitle,
                                  const Color(0xFF8B5CF6), isDark),
                              if (lessonTitle != null)
                                teacherChip(lessonTitle,
                                    const Color(0xFF6366F1), isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                    teacherChip('$maxScore درجات',
                        const Color(0xFF059669), isDark),
                  ],
                ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                          color: fieldLabelColor(context),
                        )),
                  ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_actions,
                          size: 18, color: Color(0xFF8B5CF6)),
                      SizedBox(width: 6.w),
                      Text('التسليمات: $submissionsCount',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF1E293B),
                          )),
                      SizedBox(width: 16.w),
                      Text('تم التصحيح: $graded',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: const Color(0xFF059669),
                          )),
                      const Spacer(),
                      Icon(Icons.calendar_today,
                          size: 14, color: fieldLabelColor(context)),
                      SizedBox(width: 4.w),
                      Text(
                        dueDate != null
                            ? dueDate.length >= 10
                                ? dueDate.substring(0, 10)
                                : dueDate
                            : '',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: fieldLabelColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => onViewDetail(id),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: Text('عرض التسليمات',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B5CF6),
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String> onChanged,
    String placeholder = '',
    required BuildContext context,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fieldBorderColor(context)),
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isNotEmpty ? value : null,
          isExpanded: true,
          hint: Text(placeholder,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: fieldLabelColor(context).withValues(alpha: 0.5),
              )),
          dropdownColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: fieldTextColor(context),
          ),
          items: items,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
