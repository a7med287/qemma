import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/repositories/teacher_repository.dart';
import 'widgets/question_data_model.dart';
import 'widgets/exam_header.dart';
import 'widgets/exam_questions_step.dart';
import 'widgets/exam_actions_bar.dart';
import 'widgets/teacher_exam_basic_info_step.dart';
import 'widgets/teacher_exam_review_step.dart';

class TeacherCreateExamView extends StatefulWidget {
  static const routeName = '/teacher/create-exam';
  const TeacherCreateExamView({super.key});

  @override
  State<TeacherCreateExamView> createState() => _TeacherCreateExamViewState();
}

class _TeacherCreateExamViewState extends State<TeacherCreateExamView> {
  int _activeStep = 0;
  bool _loading = false;
  bool _loadingCourses = false;
  List<Map<String, dynamic>> _courses = [];

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _courseId = '';
  int _durationMinutes = 60;
  int _totalMarks = 100;
  int _passingMarks = 50;
  String _availableFrom = '';
  String _availableTo = '';
  bool _proctored = false;
  bool _isPublished = true;

  final _availableFromCtrl = TextEditingController();
  final _availableToCtrl = TextEditingController();

  List<QuestionData> _questions = [];

  static const _steps = ['معلومات الاختبار', 'إضافة الأسئلة', 'المراجعة والنشر'];

  @override
  void initState() {
    super.initState();
    _resetQuestions();
    _fetchCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _availableFromCtrl.dispose();
    _availableToCtrl.dispose();
    for (final q in _questions) {
      q.textCtrl.dispose();
      for (final o in q.optionCtrls) {
        o.dispose();
      }
      q.gradingCtrl.dispose();
    }
    super.dispose();
  }

  void _resetQuestions() {
    _questions = [QuestionData()];
  }

  Future<void> _fetchCourses() async {
    setState(() => _loadingCourses = true);
    try {
      final repo = context.read<TeacherRepository>();
      final courses = await repo.getNotificationCourses();
      if (mounted) setState(() => _courses = courses);
    } catch (_) {
      if (mounted) buildSnackBar(context, 'فشل تحميل الكورسات', isError: true);
    } finally {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  void _handleNext() {
    if (_activeStep == 0) {
      if (_titleCtrl.text.trim().isEmpty || _courseId.isEmpty) {
        _showError('يرجى ملء جميع الحقول المطلوبة');
        return;
      }
    } else if (_activeStep == 1) {
      final hasEmpty = _questions.any((q) => q.textCtrl.text.trim().isEmpty);
      if (hasEmpty) {
        _showError('يرجى ملء جميع الأسئلة');
        return;
      }
      final emptyOptions = _questions.any(
            (q) =>
        q.type == 'multiple-choice' &&
            q.optionCtrls.any((o) => o.text.trim().isEmpty),
      );
      if (emptyOptions) {
        _showError('يرجى ملء جميع الخيارات في أسئلة الاختيار من متعدد');
        return;
      }
    }
    setState(() => _activeStep++);
  }

  void _handleBack() {
    setState(() => _activeStep--);
  }

  Future<void> _handleSubmit() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<TeacherRepository>();
      await repo.createExam(
        title: _titleCtrl.text.trim(),
        courseId: _courseId,
        durationMinutes: _durationMinutes,
        totalMarks: _totalMarks,
        passingMarks: _passingMarks,
        description: _descCtrl.text.trim(),
        availableFrom: _availableFrom.isNotEmpty ? _availableFrom : null,
        availableTo: _availableTo.isNotEmpty ? _availableTo : null,
        proctored: _proctored,
        isPublished: _isPublished,
        questions: _questions.asMap().entries.map((e) {
          final q = e.value;
          final correctAnswerText = (q.type != 'essay' && q.correctAnswerIndex >= 0)
              ? q.optionCtrls[q.correctAnswerIndex].text.trim()
              : null;
          return {
            'type': q.type,
            'questionText': q.textCtrl.text.trim(),
            'marks': q.marks,
            'options': q.type == 'essay'
                ? []
                : q.optionCtrls.map((o) => o.text.trim()).toList(),
            'correctAnswer': q.type == 'essay' ? null : correctAnswerText,
            'gradingCriteria': q.type == 'essay'
                ? (q.gradingCtrl.text.trim().isNotEmpty
                ? q.gradingCtrl.text.trim()
                : null)
                : null,
            'order': e.key + 1,
          };
        }).toList(),
      );
      if (mounted) {
        buildSnackBar(context, 'تم إنشاء الاختبار ونشره بنجاح!');
        Navigator.maybePop(context);
      }
    } on ServerFailure catch (e) {
      if (mounted) buildSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (mounted) {
        buildSnackBar(context, 'فشل إنشاء الاختبار. حاول مرة أخرى.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    buildSnackBar(context, msg, isError: true);
  }

  String _selectedCourseName() {
    final c = _courses.cast<Map<String, dynamic>?>().firstWhere(
          (c) => c?['id'] == _courseId || c?['_id'] == _courseId,
      orElse: () => null,
    );
    return c?['title'] ?? _courseId;
  }

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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExamHeader(
              activeStep: _activeStep,
              stepLabels: _steps,
              onBack: () => Navigator.maybePop(context),
            ),
            Flexible(child: _buildBody()),
            ExamActionsBar(
              activeStep: _activeStep,
              totalSteps: _steps.length,
              loading: _loading,
              onBack: _handleBack,
              onNext: _handleNext,
              onSubmit: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          if (_activeStep == 0)
            ExamBasicInfoStep(
              titleCtrl: _titleCtrl,
              descCtrl: _descCtrl,
              courseId: _courseId,
              courses: _courses,
              loadingCourses: _loadingCourses,
              durationMinutes: _durationMinutes,
              totalMarks: _totalMarks,
              passingMarks: _passingMarks,
              availableFrom: _availableFrom,
              availableTo: _availableTo,
              availableFromCtrl: _availableFromCtrl,
              availableToCtrl: _availableToCtrl,
              proctored: _proctored,
              isPublished: _isPublished,
              selectedCourseName: _selectedCourseName,
              onCourseChanged: (v) => setState(() => _courseId = v),
              onDurationChanged: (v) => setState(() => _durationMinutes = v),
              onTotalMarksChanged: (v) => setState(() => _totalMarks = v),
              onPassingMarksChanged: (v) => setState(() => _passingMarks = v),
              onAvailableFromChanged: (v) => setState(() => _availableFrom = v),
              onAvailableToChanged: (v) => setState(() => _availableTo = v),
              onProctoredChanged: (v) => setState(() => _proctored = v),
              onPublishedChanged: (v) => setState(() => _isPublished = v),
            ),
          if (_activeStep == 1)
            ExamQuestionsStep(
              questions: _questions,
              onAddQuestion: () => setState(() => _questions.add(QuestionData())),
              onRemoveQuestion: (i) {
                if (_questions.length <= 1) {
                  _showError('يجب أن يحتوي الاختبار على سؤال واحد على الأقل');
                } else {
                  setState(() => _questions.removeAt(i));
                }
              },
              onQuestionTypeChanged: (i, type) => setState(() {
                final q = _questions[i];
                for (final c in q.optionCtrls) {
                  c.dispose();
                }
                q.type = type;
                q.correctAnswerIndex = 0;
                if (type == 'true-false') {
                  q.optionCtrls = [
                    TextEditingController(text: 'صح'),
                    TextEditingController(text: 'خطأ'),
                  ];
                } else if (type == 'multiple-choice') {
                  q.optionCtrls =
                      List.generate(4, (_) => TextEditingController());
                } else {
                  q.optionCtrls = [];
                }
              }),
              onQuestionMarksChanged: (i, marks) =>
                  setState(() => _questions[i].marks = marks),
              onAddOption: (i) =>
                  setState(() => _questions[i].optionCtrls.add(TextEditingController())),
              onRemoveOption: (i, optIndex) => setState(() {
                final q = _questions[i];
                q.optionCtrls[optIndex].dispose();
                q.optionCtrls.removeAt(optIndex);
                if (q.correctAnswerIndex == optIndex) {
                  q.correctAnswerIndex = -1;
                } else if (q.correctAnswerIndex > optIndex) {
                  q.correctAnswerIndex--;
                }
              }),
              onCorrectAnswerChanged: (i, idx) =>
                  setState(() => _questions[i].correctAnswerIndex = idx),
            ),
          if (_activeStep == 2)
            ExamReviewStep(
              title: _titleCtrl.text,
              courseName: _selectedCourseName(),
              durationMinutes: _durationMinutes,
              totalMarks: _totalMarks,
              passingMarks: _passingMarks,
              questions: _questions.map((q) => QuestionReviewData(
                text: q.textCtrl.text,
                type: q.type,
                marks: q.marks,
                correctAnswerIndex: q.correctAnswerIndex,
                options: q.optionCtrls.map((o) => o.text).toList(),
                gradingCriteria: q.gradingCtrl.text,
              )).toList(),
              isPublished: _isPublished,
              questionTypeLabel: _questionTypeLabel,
              questionTypeColor: _questionTypeColor,
            ),
        ],
      ),
    );
  }
}
