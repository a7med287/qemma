import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'teacher_theme_helpers.dart';

class AssignmentGradeDialog extends StatelessWidget {
  const AssignmentGradeDialog({
    super.key,
    required this.submission,
    required this.gradeScoreCtrl,
    required this.gradeFeedbackCtrl,
    required this.grading,
    required this.onGrade,
    required this.onClose,
  });

  final Map<String, dynamic>? submission;
  final TextEditingController gradeScoreCtrl;
  final TextEditingController gradeFeedbackCtrl;
  final bool grading;
  final VoidCallback onGrade;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = submission;
    return Dialog(
      insetPadding: EdgeInsets.all(16.w),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  const Icon(Icons.grade,
                      color: Color(0xFF8B5CF6), size: 24),
                  SizedBox(width: 8.w),
                  Text('تصحيح الواجب',
                      style: TextStyles.semiBold16.copyWith(
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1F2937),
                      )),
                ],
              ),
            ),
            if (s != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الطالب: ${s['studentName'] ?? ''}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        )),
                    if (s['fileUrl'] != null)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: 8.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description,
                                size: 18,
                                color: const Color(0xFF8B5CF6)),
                            SizedBox(width: 6.w),
                            Text('عرض ملف الطالب',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                  color: const Color(0xFF8B5CF6),
                                )),
                          ],
                        ),
                      ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: gradeScoreCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF1F2937)),
                      decoration: InputDecoration(
                        labelText: 'الدرجة',
                        labelStyle: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: fieldLabelColor(context)),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide:
                                BorderSide(color: fieldBorderColor(context))),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: gradeFeedbackCtrl,
                      maxLines: 3,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF1F2937)),
                      decoration: InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        labelStyle: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: fieldLabelColor(context)),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide:
                                BorderSide(color: fieldBorderColor(context))),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onClose,
                    child: Text('إلغاء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        )),
                  ),
                  SizedBox(width: 8.w),
                  FilledButton.icon(
                    onPressed: grading ? null : onGrade,
                    icon: grading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.grade, size: 18),
                    label: Text('حفظ التصحيح',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        )),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
