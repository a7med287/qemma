import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import 'teacher_theme_helpers.dart';

class TeacherGradeQuestionView extends StatelessWidget {
  const TeacherGradeQuestionView({
    super.key,
    required this.questions,
    required this.answers,
    this.score,
    this.totalMarks,
    this.isPassed = false,
  });

  final List<Map<String, dynamic>> questions;
  final Map<String, dynamic> answers;
  final dynamic score;
  final dynamic totalMarks;
  final bool isPassed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.w, runSpacing: 8.h,
            children: [
              _chip('الدرجة: $score / $totalMarks',
                  isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              _chip(isPassed ? 'ناجح' : 'راسب',
                  isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            ],
          ),
          SizedBox(height: 16.h),
          if (questions.isEmpty)
            Center(
              child: Text('لا توجد أسئلة مرتبطة بهذا الاختبار',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: fieldLabelColor(context))),
            )
          else
            ...questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              final qId = (q['id'] ?? q['_id'] ?? '') as String;
              final studentAnswer = answers[qId];
              final correctAnswer = q['correctAnswer'];
              final isCorrect = studentAnswer != null && studentAnswer == correctAnswer;
              final qText = (q['text'] ?? q['questionText'] ?? '') as String;

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: fieldBorderColor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('سؤال ${i + 1}: $qText',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp, color: fieldTextColor(context))),
                    SizedBox(height: 8.h),
                    if ((q['type'] == 'mcq' || q['type'] == 'multiple_choice') && q['options'] is List)
                      ...((q['options'] as List).map((opt) {
                        final optStr = opt.toString();
                        final isCorrectOpt = optStr == correctAnswer?.toString();
                        final isStudentOpt = optStr == studentAnswer?.toString();
                        return Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Text('• $optStr',
                              style: TextStyle(
                                fontFamily: 'Cairo', fontSize: 12.sp,
                                color: isCorrectOpt ? const Color(0xFF10B981) : fieldTextColor(context),
                                fontWeight: isStudentOpt ? FontWeight.bold : FontWeight.normal,
                                decoration: isStudentOpt ? TextDecoration.underline : TextDecoration.none,
                              )),
                        );
                      })),
                    if (q['type'] == 'true-false') ...[
                      Text('إجابة الطالب: ${studentAnswer ?? "لم يجب"}',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: fieldLabelColor(context))),
                      Text('الإجابة الصحيحة: $correctAnswer',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: const Color(0xFF10B981))),
                    ],
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text('الدرجة: ${q['marks'] ?? '?'}',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: fieldLabelColor(context))),
                        SizedBox(width: 8.w),
                        _chip(isCorrect ? 'صح' : 'خطأ',
                            isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
