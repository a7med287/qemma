import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/student_model_json.dart';
import '../../data/repositories/student_repository.dart';
import '../routes/student_routes.dart';
import '../widgets/student_async_body.dart';

class ExamReviewView extends StatefulWidget {
  const ExamReviewView({super.key, required this.examId});

  final String examId;

  @override
  State<ExamReviewView> createState() => _ExamReviewViewState();
}

class _ExamReviewViewState extends State<ExamReviewView> {
  ExamReviewData? _review;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<StudentRepository>().getExamReview(widget.examId);
      if (!mounted) return;
      setState(() {
        _review = data;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      // Catch-all so unexpected errors (parsing, network, etc.) don't leave
      // the view stuck on the loading indicator forever.
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ غير متوقع، حاول مرة أخرى';
        _loading = false;
      });
    }
  }

  /// Background color for an answer option based on whether it's the
  /// correct answer and/or the answer the student picked.
  Color? _optionBackgroundColor(bool isCorrect, bool isStudent) {
    if (isCorrect) return Colors.green.shade50;
    if (isStudent) return Colors.red.shade50;
    return null;
  }

  /// Border color for an answer option based on whether it's the
  /// correct answer and/or the answer the student picked.
  Color _optionBorderColor(bool isCorrect, bool isStudent) {
    if (isCorrect) return Colors.green;
    if (isStudent) return Colors.red;
    return context.borderColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة الامتحان')),
      body: StudentAsyncBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: _review == null
            ? const SizedBox.shrink()
            : ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _review!.isPassed
                      ? const [Color(0xFF059669), Color(0xFF047857)]
                      : const [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_review!.examTitle, style: TextStyles.bold18.copyWith(color: Colors.white)),
                        Text(_review!.courseTitle, style: TextStyles.regular14.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Text('${_review!.score.round()}/${_review!.totalMarks}', style: TextStyles.bold25.copyWith(color: Colors.white)),
                ],
              ),
            ),
            if (_review!.questions.any((q) => q.pending))
              Card(
                color: Colors.orange.shade50,
                child: const ListTile(
                  leading: Icon(Icons.hourglass_empty, color: Colors.orange),
                  title: Text('أسئلة مقالية قيد التصحيح'),
                ),
              ),
            SizedBox(height: 16.h),
            ..._review!.questions.asMap().entries.map((e) {
              final q = e.value;
              final color = q.pending ? Colors.orange : (q.isCorrect ? Colors.green : Colors.red);
              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16.r,
                            backgroundColor: color.withValues(alpha: .15),
                            child: Text('${e.key + 1}', style: TextStyle(color: color)),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(child: Text(q.questionText, style: TextStyles.semiBold16.copyWith(color: context.textPrimary))),
                          Text('${q.marksAwarded}/${q.marks}', style: TextStyles.semiBold14.copyWith(color: color)),
                        ],
                      ),
                      if (q.type == 'multiple-choice' || q.type == 'true-false') ...[
                        SizedBox(height: 12.h),
                        ...q.options.map((opt) {
                          final isStudent = opt == q.studentAnswer;
                          final isCorrect = opt == q.correctAnswer;
                          return Container(
                            margin: EdgeInsets.only(bottom: 4.h),
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: _optionBackgroundColor(isCorrect, isStudent),
                              border: Border.all(color: _optionBorderColor(isCorrect, isStudent)),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(opt),
                          );
                        }),
                      ],
                      if (q.isEssay) ...[
                        SizedBox(height: 12.h),
                        Text('إجابتك:', style: TextStyles.semiBold14),
                        Text(q.studentAnswer, style: TextStyles.regular14.copyWith(color: context.textSecondary)),
                      ],
                    ],
                  ),
                ),
              );
            }),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, StudentRoutes.exams),
              child: const Text('العودة للاختبارات'),
            ),
          ],
        ),
      ),
    );
  }
}