import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/models/student_model_json.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../routes/student_routes.dart';
import '../widgets/student_async_body.dart';

class TakeExamView extends StatefulWidget {
  const TakeExamView({super.key, required this.examId});

  final String examId;

  @override
  State<TakeExamView> createState() => _TakeExamViewState();
}

class _TakeExamViewState extends State<TakeExamView> {
  ExamStartData? _data;
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;
  final _answers = <String, dynamic>{};
  int _secondsLeft = 0;
  Timer? _timer;
  ExamSubmitResult? _result;

  @override
  void initState() {
    super.initState();
    _startExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startExam() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<StudentRepository>().startExam(widget.examId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _secondsLeft = data.durationMinutes * 60;
        _loading = false;
      });
      _startTimer();
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ غير متوقع أثناء تحميل الامتحان، حاول مرة أخرى';
        _loading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0 && _result == null) {
        setState(() => _secondsLeft--);
      } else if (_secondsLeft == 0 && _result == null) {
        _submit();
      }
    });
  }

  Future<void> _submit() async {
    if (_loading) return; // avoid overlapping submissions (manual tap + timer)
    _timer?.cancel();
    setState(() => _loading = true);
    try {
      final result = await context.read<StudentRepository>().submitExam(widget.examId, _answers);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      _handleSubmitFailure(e.message);
    } catch (e) {
      if (!mounted) return;
      const message = 'حدث خطأ غير متوقع أثناء تسليم الامتحان';
      setState(() {
        _error = message;
        _loading = false;
      });
      _handleSubmitFailure(message);
    }
  }

  /// Surfaces a submit failure to the student (the full-screen error view
  /// only shows before the exam loads) and resumes the countdown so they
  /// can try submitting again, unless time has already run out.
  void _handleSubmitFailure(String message) {
    if (!mounted) return;
    buildSnackBar(context, 'تعذر تسليم الامتحان: $message', isError: true);
    if (_secondsLeft > 0) {
      _startTimer();
    }
  }

  String get _timeFormatted {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تحميل الامتحان')),
        body: StudentAsyncBody(loading: true, child: const SizedBox.shrink()),
      );
    }
    if (_error != null && _data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: StudentAsyncBody(error: _error, onRetry: _startExam, loading: false, child: const SizedBox.shrink()),
      );
    }
    if (_result != null) return _buildResult(context);
    final data = _data!;

    final question = data.questions[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.title, style: TextStyles.semiBold14),
            Text(data.courseTitle, style: TextStyles.regular13),
          ],
        ),
        actions: [
          Chip(label: Text('⏱ $_timeFormatted')),
          Padding(padding: EdgeInsets.all(8.r), child: Chip(label: Text('${_answers.length}/${data.questions.length}'))),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('السؤال ${_currentIndex + 1}', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
            Text(question.questionText, style: TextStyles.bold18.copyWith(color: context.textPrimary)),
            SizedBox(height: 16.h),
            Expanded(child: _questionBody(question)),
            Row(
              children: [
                OutlinedButton(onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null, child: const Text('السابق')),
                const Spacer(),
                if (_currentIndex < data.questions.length - 1)
                  ElevatedButton(onPressed: () => setState(() => _currentIndex++), child: const Text('التالي'))
                else
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('تسليم'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionBody(ExamQuestion question) {
    if (question.type == 'essay') {
      // Keyed by question id + given an initialValue so the previously
      // typed answer reappears when the student navigates back to it,
      // instead of showing an empty field.
      return TextFormField(
        key: ValueKey(question.id),
        initialValue: _answers[question.id] as String? ?? '',
        maxLines: 8,
        onChanged: (v) => _answers[question.id] = v,
        decoration: InputDecoration(
          hintText: 'اكتب إجابتك...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    }
    return ListView(
      children: question.options.map((opt) {
        return RadioListTile<String>(
          value: opt,
          groupValue: _answers[question.id] as String?,
          onChanged: (v) => setState(() => _answers[question.id] = v),
          title: Text(opt),
        );
      }).toList(),
    );
  }

  Widget _buildResult(BuildContext context) {
    final result = _result!;
    return Scaffold(
      appBar: AppBar(title: const Text('نتيجة الامتحان')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48.r,
                backgroundColor: result.isPassed ? Colors.green.shade100 : Colors.red.shade100,
                child: Text(
                  '${result.score.round()}/${result.totalMarks.round()}',
                  style: TextStyles.bold20.copyWith(color: result.isPassed ? Colors.green : Colors.red),
                ),
              ),
              SizedBox(height: 16.h),
              Text(result.isPassed ? 'نجحت! 🎉' : 'لم تنجح', style: TextStyles.bold23),
              if (result.hasEssayQuestions)
                Padding(padding: EdgeInsets.only(top: 12.h), child: const Text('⏳ أسئلة مقالية قيد التصحيح')),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => StudentRoutes.pushExamReview(context, widget.examId),
                child: const Text('مراجعة الإجابات'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  StudentRoutes.exams,
                      (r) => r.settings.name == StudentRoutes.dashboard || r.isFirst,
                ),
                child: const Text('العودة للاختبارات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}