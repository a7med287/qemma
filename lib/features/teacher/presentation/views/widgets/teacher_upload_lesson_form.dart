import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../data/models/teacher_models.dart';
import 'teacher_theme_helpers.dart';

class TeacherUploadLessonTips extends StatelessWidget {
  const TeacherUploadLessonTips({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final tips = [
      'استخدم عناوين واضحة ووصفية للدروس',
      'تأكد من جودة الفيديو والصوت قبل الرفع',
      'أضف ملف PDF للملاحظات والتمارين',
      'رتّب الدروس بشكل منطقي ومتسلسل',
      'اكتب ملخصاً مختصراً ليستفيد منه الطالب',
    ];
    final formats = ['MP4', 'AVI', 'MOV', 'WMV'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نصائح لرفع الدروس',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          SizedBox(height: 12.h),
          ...tips.map((tip) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: const Color(0xFF059669), size: 16),
                SizedBox(width: 8.w),
                Expanded(child: Text(tip,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))),
              ],
            ),
          )),
          SizedBox(height: 12.h),
          Text('صيغ الملفات المدعومة:',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w, runSpacing: 6.h,
            children: [
              ...formats.map((f) => Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(f,
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 10.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
              )),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text('PDF',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 10.sp,
                        color: Color(0xFFDC2626))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TeacherUploadLessonForm extends StatelessWidget {
  const TeacherUploadLessonForm({
    super.key,
    required this.courses,
    required this.coursesLoading,
    required this.coursesError,
    required this.courseId,
    required this.titleController,
    required this.summaryController,
    required this.contentController,
    required this.orderController,
    required this.isPublished,
    required this.onCourseChanged,
    required this.onPublishedChanged,
    required this.onRefreshCourses,
  });

  final List<TeacherCourse> courses;
  final bool coursesLoading;
  final String? coursesError;
  final String courseId;
  final TextEditingController titleController;
  final TextEditingController summaryController;
  final TextEditingController contentController;
  final TextEditingController orderController;
  final bool isPublished;
  final ValueChanged<String> onCourseChanged;
  final ValueChanged<bool> onPublishedChanged;
  final VoidCallback onRefreshCourses;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, 'معلومات الدرس'),
          SizedBox(height: 16.h),
          _buildCourseSelector(context),
          SizedBox(height: 16.h),
          _buildField(context, label: 'عنوان الدرس', controller: titleController, required: true, hint: 'مثال: المعادلات من الدرجة الأولى'),
          SizedBox(height: 12.h),
          _buildField(context, label: 'ملخص الدرس', controller: summaryController, multiline: true, maxLines: 2, hint: 'ملخص مختصر عن محتوى الدرس...'),
          SizedBox(height: 12.h),
          _buildField(context, label: 'محتوى الدرس (اختياري)', controller: contentController, multiline: true, maxLines: 4, hint: 'اكتب شرح تفصيلي أو ملاحظات عن الدرس...'),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _buildField(context, label: 'ترتيب الدرس', controller: orderController, keyboardType: TextInputType.number)),
              SizedBox(width: 12.w),
              Expanded(child: _buildPublishToggle(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final isDark = context.isDark;
    return Text(title,
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)));
  }

  Widget _buildCourseSelector(BuildContext context) {
    final isDark = context.isDark;
    if (coursesLoading) {
      return Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            SizedBox(width: 20.w, height: 20.w, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12.w),
            Text('جاري تحميل الكورسات...',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: fieldLabelColor(context))),
          ],
        ),
      );
    }
    if (coursesError != null) {
      return Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8.r)),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 8.w),
            Expanded(child: Text(coursesError!, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: const Color(0xFFDC2626)))),
            TextButton(onPressed: onRefreshCourses, child: const Text('إعادة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11))),
          ],
        ),
      );
    }
    if (courses.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8.r)),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Color(0xFFF59E0B), size: 18),
            SizedBox(width: 8.w),
            Expanded(child: Text('لا توجد كورسات بعد. أنشئ كورساً أولاً ثم ارفع الدروس.',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: const Color(0xFFB45309)))),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/teacher/courses/create'),
              child: const Text('إنشاء كورس', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: courseId.isNotEmpty && courses.any((c) => c.id == courseId) ? courseId : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'اختر الكورس *',
        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: fieldLabelColor(context)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: fieldBorderColor(context)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      ),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: fieldTextColor(context)),
      items: courses.map((course) {
        final subtitle = [course.category, course.level].whereType<String>().join(' - ');
        final label = subtitle.isNotEmpty ? '${course.title} ($subtitle)' : course.title;
        return DropdownMenuItem<String>(
          value: course.id,
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
        );
      }).toList(),
      onChanged: (v) => onCourseChanged(v ?? ''),
    );
  }

  Widget _buildField(BuildContext context, {
    required String label,
    required TextEditingController controller,
    bool multiline = false,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
    String? hint,
  }) {
    final isDark = context.isDark;
    return TextField(
      controller: controller,
      maxLines: multiline ? maxLines : 1,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: fieldTextColor(context)),
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: fieldLabelColor(context)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: fieldBorderColor(context)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      ),
    );
  }

  Widget _buildPublishToggle(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('نشر الدرس فوراً',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)))),
          Switch.adaptive(
            value: isPublished,
            onChanged: onPublishedChanged,
            activeTrackColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }
}
