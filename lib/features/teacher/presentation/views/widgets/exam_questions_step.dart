import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import 'teacher_theme_helpers.dart';
import 'teacher_form_fields.dart';
import 'question_data_model.dart';

Color _questionTypeColor(String type) {
  if (type == 'essay') return const Color(0xFF7C3AED);
  if (type == 'true-false') return const Color(0xFF0891B2);
  return const Color(0xFF2563EB);
}

String _questionTypeLabel(String type) {
  if (type == 'essay') return 'مقالي';
  if (type == 'true-false') return 'صح أو خطأ';
  return 'اختيار من متعدد';
}

class ExamQuestionsStep extends StatelessWidget {
  const ExamQuestionsStep({
    super.key,
    required this.questions,
    required this.onAddQuestion,
    required this.onRemoveQuestion,
    required this.onQuestionTypeChanged,
    required this.onQuestionMarksChanged,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onCorrectAnswerChanged,
  });

  final List<QuestionData> questions;
  final VoidCallback onAddQuestion;
  final ValueChanged<int> onRemoveQuestion;
  final void Function(int index, String type) onQuestionTypeChanged;
  final void Function(int index, int marks) onQuestionMarksChanged;
  final ValueChanged<int> onAddOption;
  final void Function(int questionIndex, int optionIndex) onRemoveOption;
  final void Function(int questionIndex, int correctIndex) onCorrectAnswerChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الأسئلة (${questions.length})',
                      style: TextStyles.bold18.copyWith(
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1F2937),
                      )),
                  Text(
                    'يدعم: اختيار من متعدد · صح أو خطأ · سؤال مقالي',
                    style: TextStyles.regular13.copyWith(
                      color: fieldLabelColor(context),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onAddQuestion,
              icon: const Icon(Icons.add, size: 18),
              label: Text('إضافة سؤال',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE0E7FF),
                foregroundColor: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF3730A3),
                padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ...List.generate(questions.length, (i) {
          return _buildQuestionCard(context, i);
        }),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, int index) {
    final isDark = context.isDark;
    final q = questions[index];
    final typeColor = _questionTypeColor(q.type);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text('السؤال ${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF3730A3),
                    )),
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
                  _questionTypeLabel(q.type),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              if (q.type == 'essay')
                Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border:
                      Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Text('تصحيح يدوي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                          color: const Color(0xFFF59E0B),
                        )),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => onRemoveQuestion(index),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: TeacherDropdown(
                  value: q.type,
                  items: const [
                    DropdownMenuItem(
                        value: 'multiple-choice',
                        child: Text('اختيار من متعدد')),
                    DropdownMenuItem(
                        value: 'true-false', child: Text('صح أو خطأ')),
                    DropdownMenuItem(
                        value: 'essay', child: Text('سؤال مقالي')),
                  ],
                  onChanged: (v) => onQuestionTypeChanged(index, v),
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 12.w),
              SizedBox(
                width: 100.w,
                child: TeacherNumberField(
                  value: q.marks,
                  label: 'الدرجة',
                  onChanged: (v) => onQuestionMarksChanged(index, v),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TeacherTextField(
            controller: q.textCtrl,
            label: 'نص السؤال',
            hint: 'اكتب السؤال هنا...',
            maxLines: 2,
            isDark: isDark,
          ),
          SizedBox(height: 12.h),
          if (q.type == 'essay') _buildEssaySection(context, q),
          if (q.type != 'essay') _buildOptionsSection(context, q, index),
        ],
      ),
    );
  }

  Widget _buildEssaySection(BuildContext context, QuestionData q) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFFEFCE8),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF854D0E)
                  : const Color(0xFFFDE68A),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: 6.w),
                  Text('سؤال مقالي — سيتم تصحيحه يدوياً من قِبَل المعلم',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        color: const Color(0xFFF59E0B),
                      )),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'يمكنك إضافة معايير التصحيح لمساعدتك أثناء المراجعة.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.sp,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF78716C),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        TeacherTextField(
          controller: q.gradingCtrl,
          label: 'معايير التصحيح / الإجابة النموذجية (اختياري)',
          hint:
          'اكتب النقاط الأساسية التي يجب أن تتضمنها إجابة الطالب...',
          maxLines: 4,
          isDark: isDark,
        ),
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            'هذه المعايير لن تظهر للطالب، فقط للمعلم أثناء التصحيح',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.sp,
              color: fieldLabelColor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection(BuildContext context, QuestionData q, int qIndex) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخيارات${q.type == 'true-false' ? ' (اختر الإجابة الصحيحة)' : ''}',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
            color:
            isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 8.h),
        ...List.generate(q.optionCtrls.length, (optIndex) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Radio<int>(
                  value: optIndex,
                  groupValue: q.correctAnswerIndex,
                  onChanged: (v) =>
                      onCorrectAnswerChanged(qIndex, v ?? -1),
                  activeColor: const Color(0xFF2563EB),
                ),
                Expanded(
                  child: TeacherTextField(
                    controller: q.optionCtrls[optIndex],
                    label: 'الخيار ${optIndex + 1}',
                    isDark: isDark,
                    enabled: q.type != 'true-false',
                  ),
                ),
                if (q.type == 'multiple-choice' &&
                    q.optionCtrls.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 20),
                    onPressed: () => onRemoveOption(qIndex, optIndex),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          );
        }),
        if (q.type == 'multiple-choice')
          TextButton.icon(
            onPressed: () => onAddOption(qIndex),
            icon: const Icon(Icons.add, size: 16),
            label: Text('إضافة خيار',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
            style:
            TextButton.styleFrom(foregroundColor: fieldTextColor(context)),
          ),
      ],
    );
  }
}
