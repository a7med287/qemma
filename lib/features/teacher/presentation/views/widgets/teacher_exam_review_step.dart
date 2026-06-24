import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import 'teacher_theme_helpers.dart';
import 'teacher_form_fields.dart';

class QuestionReviewData {
  final String text;
  final String type;
  final int marks;
  final int correctAnswerIndex;
  final List<String> options;
  final String gradingCriteria;

  const QuestionReviewData({
    required this.text,
    required this.type,
    required this.marks,
    required this.correctAnswerIndex,
    required this.options,
    required this.gradingCriteria,
  });
}

class ExamReviewStep extends StatelessWidget {
  const ExamReviewStep({
    super.key,
    required this.title,
    required this.courseName,
    required this.durationMinutes,
    required this.totalMarks,
    required this.passingMarks,
    required this.questions,
    required this.isPublished,
    required this.questionTypeLabel,
    required this.questionTypeColor,
  });

  final String title;
  final String courseName;
  final int durationMinutes;
  final int totalMarks;
  final int passingMarks;
  final List<QuestionReviewData> questions;
  final bool isPublished;
  final String Function(String type) questionTypeLabel;
  final Color Function(String type) questionTypeColor;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final mcqCount = questions.where((q) => q.type == 'multiple-choice').length;
    final tfCount = questions.where((q) => q.type == 'true-false').length;
    final essayCount = questions.where((q) => q.type == 'essay').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('مراجعة الاختبار',
            style: TextStyles.bold18.copyWith(
              color: isDark
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFF1F2937),
            )),
        SizedBox(height: 12.h),
        _buildPublishBadge(isDark),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildTypeChip('اختيار من متعدد', mcqCount, const Color(0xFF2563EB), isDark),
            _buildTypeChip('صح أو خطأ', tfCount, const Color(0xFF0891B2), isDark),
            _buildTypeChip('مقالي', essayCount, const Color(0xFF7C3AED), isDark),
          ],
        ),
        SizedBox(height: 16.h),
        TeacherCard(
          isDark: isDark,
          children: [
            Text('معلومات الاختبار:',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1F2937),
                )),
            SizedBox(height: 12.h),
            _infoRow('العنوان', title, isDark, context),
            _infoRow('الكورس', courseName, isDark, context),
            _infoRow('المدة', '$durationMinutes دقيقة', isDark, context),
            _infoRow('إجمالي الدرجات', '$totalMarks', isDark, context),
            _infoRow('درجة النجاح', '$passingMarks', isDark, context),
            _infoRow('عدد الأسئلة', '${questions.length}', isDark, context),
          ],
        ),
        SizedBox(height: 16.h),
        ...List.generate(questions.length, (i) {
          return _buildQuestionReview(i, isDark, context);
        }),
      ],
    );
  }

  Widget _buildPublishBadge(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isPublished
            ? (isDark
            ? const Color(0xFF059669).withValues(alpha: 0.15)
            : const Color(0xFFDCFCE7))
            : (isDark
            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
            : const Color(0xFFFEF3C7)),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isPublished
              ? const Color(0xFF059669)
              : const Color(0xFFF59E0B),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPublished ? Icons.check_circle : Icons.warning,
            size: 18,
            color: isPublished
                ? const Color(0xFF059669)
                : const Color(0xFFF59E0B),
          ),
          SizedBox(width: 8.w),
          Text(
            isPublished
                ? 'سيتم نشر الاختبار فور الحفظ وسيظهر للطلاب المسجلين'
                : 'سيُحفظ الاختبار كمسودة ولن يظهر للطلاب',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
              color: isPublished
                  ? const Color(0xFF059669)
                  : const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, int count, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
          color: color,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                color: fieldLabelColor(context),
              )),
          Text(value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              )),
        ],
      ),
    );
  }

  Widget _buildQuestionReview(int index, bool isDark, BuildContext context) {
    final q = questions[index];
    final typeColor = questionTypeColor(q.type);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF020617) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${index + 1}. ${q.text}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1F2937),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  questionTypeLabel(q.type),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: fieldBorderColor(context)),
                ),
                child: Text(
                  '${q.marks} درجة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                    color: fieldLabelColor(context),
                  ),
                ),
              ),
            ],
          ),
          if (q.type != 'essay') ...[
            SizedBox(height: 8.h),
            ...q.options.asMap().entries.map((entry) {
              final optIndex = entry.key;
              final opt = entry.value;
              final correct = optIndex == q.correctAnswerIndex;
              return Padding(
                padding: EdgeInsets.only(right: 12.w, top: 4.h),
                child: Row(
                  children: [
                    Icon(
                      correct ? Icons.check : Icons.circle,
                      size: 12,
                      color: correct
                          ? const Color(0xFF22C55E)
                          : fieldLabelColor(context),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      opt,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                        color: correct
                            ? const Color(0xFF22C55E)
                            : fieldLabelColor(context),
                        fontWeight: correct
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (q.type == 'essay') ...[
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Text(
                '[سيكتب الطالب إجابته المقالية هنا]',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: fieldLabelColor(context),
                ),
              ),
            ),
            if (q.gradingCriteria.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFFEFCE8),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF854D0E)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('معايير التصحيح:',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                          color: const Color(0xFFF59E0B),
                        )),
                    SizedBox(height: 4.h),
                    Text(q.gradingCriteria,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF78716C),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
