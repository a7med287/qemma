import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import 'teacher_theme_helpers.dart';
import 'teacher_form_fields.dart';

class ExamBasicInfoStep extends StatelessWidget {
  const ExamBasicInfoStep({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.courseId,
    required this.courses,
    required this.loadingCourses,
    required this.durationMinutes,
    required this.totalMarks,
    required this.passingMarks,
    required this.availableFrom,
    required this.availableTo,
    required this.availableFromCtrl,
    required this.availableToCtrl,
    required this.proctored,
    required this.isPublished,
    required this.selectedCourseName,
    required this.onCourseChanged,
    required this.onDurationChanged,
    required this.onTotalMarksChanged,
    required this.onPassingMarksChanged,
    required this.onAvailableFromChanged,
    required this.onAvailableToChanged,
    required this.onProctoredChanged,
    required this.onPublishedChanged,
  });

  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String courseId;
  final List<Map<String, dynamic>> courses;
  final bool loadingCourses;
  final int durationMinutes;
  final int totalMarks;
  final int passingMarks;
  final String availableFrom;
  final String availableTo;
  final TextEditingController availableFromCtrl;
  final TextEditingController availableToCtrl;
  final bool proctored;
  final bool isPublished;
  final String Function() selectedCourseName;
  final ValueChanged<String> onCourseChanged;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<int> onTotalMarksChanged;
  final ValueChanged<int> onPassingMarksChanged;
  final ValueChanged<String> onAvailableFromChanged;
  final ValueChanged<String> onAvailableToChanged;
  final ValueChanged<bool> onProctoredChanged;
  final ValueChanged<bool> onPublishedChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return TeacherCard(
      isDark: isDark,
      children: [
        Text('المعلومات الأساسية',
            style: TextStyles.bold18.copyWith(
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
            )),
        SizedBox(height: 16.h),
        _buildCourseDropdown(context, isDark),
        SizedBox(height: 12.h),
        TeacherTextField(
          controller: titleCtrl,
          label: 'عنوان الاختبار',
          hint: 'مثال: اختبار الفصل الأول - الجبر',
          required: true,
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        TeacherTextField(
          controller: descCtrl,
          label: 'وصف الاختبار (اختياري)',
          hint: 'اكتب وصفاً مختصراً عن الاختبار...',
          maxLines: 3,
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: TeacherNumberField(
                value: durationMinutes,
                label: 'مدة الاختبار (بالدقائق)',
                onChanged: onDurationChanged,
                isDark: isDark,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TeacherNumberField(
                value: totalMarks,
                label: 'إجمالي الدرجات',
                onChanged: onTotalMarksChanged,
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: TeacherNumberField(
                value: passingMarks,
                label: 'درجة النجاح',
                onChanged: onPassingMarksChanged,
                isDark: isDark,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(child: const SizedBox()),
          ],
        ),
        SizedBox(height: 12.h),
        TeacherDateTimeField(
          label: 'متاح من (اختياري)',
          value: availableFrom,
          controller: availableFromCtrl,
          onChanged: onAvailableFromChanged,
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        TeacherDateTimeField(
          label: 'متاح حتى (اختياري)',
          value: availableTo,
          controller: availableToCtrl,
          onChanged: onAvailableToChanged,
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        TeacherSwitchRow(
          value: isPublished,
          label: 'نشر الاختبار فور الحفظ',
          subtitle: isPublished
              ? 'سيظهر الاختبار للطلاب المسجلين في الكورس فور الحفظ'
              : 'الاختبار سيُحفظ كمسودة ولن يظهر للطلاب',
          onChanged: onPublishedChanged,
          isDark: isDark,
          activeColor: const Color(0xFF22C55E),
        ),
      ],
    );
  }

  Widget _buildCourseDropdown(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('اختر الكورس',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: fieldLabelColor(context),
                )),
            const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: fieldBorderColor(context)),
            color:
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: courseId.isEmpty ? null : courseId,
              isExpanded: true,
              hint: Text(
                loadingCourses ? 'جاري التحميل...' : 'اختر كورس',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: fieldLabelColor(context),
                ),
              ),
              dropdownColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
              items: courses.map<DropdownMenuItem<String>>((c) {
                final id = (c['id'] ?? c['_id'] ?? '') as String;
                final title = (c['title'] ?? '') as String;
                final count =
                ((c['_count'] as Map?) ?? {})['enrollments'];
                return DropdownMenuItem(
                  value: id,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: fieldTextColor(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (count != null)
                        Text(
                          '($count طالب)',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: fieldLabelColor(context),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: loadingCourses
                  ? null
                  : (v) => onCourseChanged(v ?? ''),
            ),
          ),
        ),
      ],
    );
  }
}
