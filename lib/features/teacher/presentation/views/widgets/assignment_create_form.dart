import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'teacher_form_fields.dart';
import 'teacher_theme_helpers.dart';

class AssignmentCreateForm extends StatelessWidget {
  const AssignmentCreateForm({
    super.key,
    required this.isDark,
    required this.courses,
    required this.coursesLoading,
    required this.lessons,
    required this.lessonsLoading,
    required this.formCourse,
    required this.formLesson,
    required this.formTitleCtrl,
    required this.formDescCtrl,
    required this.formDueDate,
    required this.formMaxScore,
    required this.formPublished,
    required this.submitting,
    required this.onCourseChanged,
    required this.onLessonChanged,
    required this.onDueDateChanged,
    required this.onMaxScoreChanged,
    required this.onPublishedChanged,
    required this.onCreate,
    required this.onCancel,
  });

  final bool isDark;
  final List<Map<String, dynamic>> courses;
  final bool coursesLoading;
  final List<Map<String, dynamic>> lessons;
  final bool lessonsLoading;
  final String formCourse;
  final String formLesson;
  final TextEditingController formTitleCtrl;
  final TextEditingController formDescCtrl;
  final String formDueDate;
  final int formMaxScore;
  final bool formPublished;
  final bool submitting;
  final ValueChanged<String> onCourseChanged;
  final ValueChanged<String> onLessonChanged;
  final ValueChanged<String> onDueDateChanged;
  final ValueChanged<int> onMaxScoreChanged;
  final ValueChanged<bool> onPublishedChanged;
  final VoidCallback onCreate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إنشاء واجب جديد',
              style: TextStyles.bold18.copyWith(
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              )),
          SizedBox(height: 16.h),
          _buildFormSection(context),
          SizedBox(height: 16.h),
          _buildTipsCard(context),
        ],
      ),
    );
  }

  Widget _buildFormSection(BuildContext context) {
    return TeacherCard(
      isDark: isDark,
      children: [
        _buildDropdown(
          value: formCourse,
          loading: coursesLoading,
          placeholder: 'اختر الكورس',
          items: courses.map((c) {
            final id = (c['id'] ?? c['_id'] ?? '') as String;
            final title = (c['title'] ?? '') as String;
            return DropdownMenuItem(value: id, child: Text(title));
          }).toList(),
          onChanged: onCourseChanged,
          context: context,
        ),
        SizedBox(height: 12.h),
        _buildDropdown(
          value: formLesson,
          loading: lessonsLoading,
          placeholder: 'بدون درس محدد',
          enabled: formCourse.isNotEmpty,
          items: [
            const DropdownMenuItem(
                value: '', child: Text('بدون درس محدد')),
            ...lessons.map((l) {
              final id = (l['id'] ?? l['_id'] ?? '') as String;
              final title = (l['title'] ?? '') as String;
              final order = l['order'] ?? 0;
              return DropdownMenuItem(
                  value: id, child: Text('$order - $title'));
            }),
          ],
          onChanged: onLessonChanged,
          context: context,
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: formTitleCtrl,
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              color: fieldTextColor(context)),
          decoration: inpDecoration(context, 'عنوان الواجب', required: true),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: formDescCtrl,
          maxLines: 3,
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              color: fieldTextColor(context)),
          decoration: inpDecoration(context, 'وصف الواجب'),
        ),
        SizedBox(height: 12.h),
        _buildDateField(context),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: TeacherNumberField(
                value: formMaxScore,
                label: 'الدرجة القصوى',
                onChanged: onMaxScoreChanged,
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _buildPublishToggle(context),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: submitting ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: BorderSide(color: fieldBorderColor(context)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text('إلغاء',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    )),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed:
                    (submitting || coursesLoading) ? null : onCreate,
                icon: submitting
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 18),
                label: Text(
                    submitting ? 'جاري الإنشاء...' : 'إنشاء الواجب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    )),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onDueDateChanged(
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          );
        }
      },
      child: InputDecorator(
        decoration: inpDecoration(context, 'تاريخ التسليم'),
        child: Text(
          formDueDate.isEmpty ? 'اختر تاريخ' : formDueDate,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: formDueDate.isEmpty
                ? fieldLabelColor(context).withValues(alpha: 0.5)
                : fieldTextColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPublishToggle(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('نشر الواجب فوراً للطلاب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1F2937),
                )),
          ),
          Switch(
            value: formPublished,
            onChanged: onPublishedChanged,
            activeThumbColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    final tips = [
      'اختر كورساً محدداً للواجب',
      'اربط الواجب بدرس معين إن أمكن',
      'حدد تاريخ تسليم واضح',
      'اكتب وصفاً مفصلاً للمطلوب',
      'يمكنك النشر فوراً أو لاحقاً',
    ];
    return TeacherCard(
      isDark: isDark,
      children: [
        Text('نصائح',
            style: TextStyles.semiBold16.copyWith(
              color: isDark
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFF1F2937),
            )),
        SizedBox(height: 12.h),
        ...tips.map((t) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle,
                      size: 18, color: Color(0xFF059669)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(t,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.sp,
                          color: fieldLabelColor(context),
                        )),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String> onChanged,
    bool loading = false,
    String placeholder = '',
    bool enabled = true,
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
          hint: Text(loading ? 'جاري التحميل...' : placeholder,
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
          onChanged: enabled && !loading
              ? (v) {
                  if (v != null) onChanged(v);
                }
              : null,
        ),
      ),
    );
  }
}
