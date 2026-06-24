import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/repositories/teacher_repository.dart';
import 'widgets/assignment_header.dart';
import 'widgets/assignment_create_form.dart';
import 'widgets/assignment_view_list.dart';
import 'widgets/assignment_detail_dialog.dart';
import 'widgets/assignment_grade_dialog.dart';

class TeacherAssignmentsView extends StatefulWidget {
  static const routeName = '/teacher/assignments';
  const TeacherAssignmentsView({super.key});

  @override
  State<TeacherAssignmentsView> createState() => _TeacherAssignmentsViewState();
}

class _TeacherAssignmentsViewState extends State<TeacherAssignmentsView> {
  int _tab = 0;

  // Courses & lessons
  List<Map<String, dynamic>> _courses = [];
  bool _coursesLoading = true;
  List<Map<String, dynamic>> _lessons = [];
  bool _lessonsLoading = false;

  // Create form
  String _formCourse = '';
  String _formLesson = '';
  final _formTitleCtrl = TextEditingController();
  final _formDescCtrl = TextEditingController();
  String _formDueDate = '';
  int _formMaxScore = 100;
  bool _formPublished = true;
  bool _submitting = false;

  // Assignments list
  List<Map<String, dynamic>> _assignments = [];
  bool _assignmentsLoading = false;
  String _filterCourse = '';

  // Detail dialog
  Map<String, dynamic>? _selectedAssignment;
  bool _detailLoading = false;

  // Grade dialog
  Map<String, dynamic>? _gradingSubmission;
  final _gradeScoreCtrl = TextEditingController();
  final _gradeFeedbackCtrl = TextEditingController();
  bool _grading = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _formTitleCtrl.dispose();
    _formDescCtrl.dispose();
    _gradeScoreCtrl.dispose();
    _gradeFeedbackCtrl.dispose();
    super.dispose();
  }

  TeacherRepository get _repo => context.read<TeacherRepository>();

  Future<void> _fetchCourses() async {
    setState(() => _coursesLoading = true);
    try {
      final courses = await _repo.getTeacherCourses();
      if (mounted) setState(() => _courses = courses);
    } catch (_) {
      if (mounted) _showError('فشل تحميل الكورسات');
    } finally {
      if (mounted) setState(() => _coursesLoading = false);
    }
  }

  Future<void> _fetchLessons(String courseId) async {
    if (courseId.isEmpty) {
      setState(() => _lessons = []);
      return;
    }
    setState(() => _lessonsLoading = true);
    try {
      final lessons = await _repo.getCourseLessons(courseId);
      if (mounted) setState(() => _lessons = lessons);
    } catch (_) {
      if (mounted) setState(() => _lessons = []);
    } finally {
      if (mounted) setState(() => _lessonsLoading = false);
    }
  }

  Future<void> _fetchAssignments() async {
    setState(() => _assignmentsLoading = true);
    try {
      final assignments = await _repo.getTeacherAssignments(
        courseId: _filterCourse.isNotEmpty ? _filterCourse : null,
      );
      if (mounted) setState(() => _assignments = assignments);
    } catch (_) {
      if (mounted) _showError('فشل تحميل الواجبات');
    } finally {
      if (mounted) setState(() => _assignmentsLoading = false);
    }
  }

  void _onTabChanged(int v) {
    setState(() => _tab = v);
    if (v == 1) _fetchAssignments();
  }

  void _onFilterChanged(String v) {
    setState(() => _filterCourse = v);
    _fetchAssignments();
  }

  void _onCourseChanged(String v) {
    setState(() {
      _formCourse = v;
      _formLesson = '';
    });
    _fetchLessons(v);
  }

  bool _validateForm() {
    if (_formCourse.isEmpty) {
      _showError('اختر الكورس');
      return false;
    }
    if (_formTitleCtrl.text.trim().isEmpty) {
      _showError('عنوان الواجب مطلوب');
      return false;
    }
    if (_formMaxScore < 1) {
      _showError('الدرجة القصوى يجب أن تكون 1 على الأقل');
      return false;
    }
    return true;
  }

  Future<void> _handleCreate() async {
    if (!_validateForm()) return;
    setState(() => _submitting = true);
    try {
      await _repo.createAssignment(
        title: _formTitleCtrl.text.trim(),
        courseId: _formCourse,
        lessonId: _formLesson.isNotEmpty ? _formLesson : null,
        description: _formDescCtrl.text.trim(),
        dueDate: _formDueDate,
        totalMarks: _formMaxScore,
        isPublished: _formPublished,
      );
      if (mounted) {
        buildSnackBar(context, 'تم إنشاء الواجب بنجاح!');
        _resetForm();
        _onTabChanged(1);
      }
    } on ServerFailure catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('فشل إنشاء الواجب');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    _formCourse = '';
    _formLesson = '';
    _formTitleCtrl.clear();
    _formDescCtrl.clear();
    _formDueDate = '';
    _formMaxScore = 100;
    _formPublished = true;
    _lessons = [];
  }

  Future<void> _viewDetail(String assignmentId) async {
    setState(() => _detailLoading = true);
    try {
      final detail = await _repo.getAssignmentDetail(assignmentId);
      if (mounted) {
        setState(() {
          _selectedAssignment = detail;
          _detailLoading = false;
        });
        _showDetailDialog();
      }
    } catch (_) {
      if (mounted) _showError('فشل تحميل تفاصيل الواجب');
      if (mounted) setState(() => _detailLoading = false);
    }
  }

  void _showDetailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AssignmentDetailDialog(
        assignment: _selectedAssignment,
        detailLoading: _detailLoading,
        onGradeSubmission: (submission) {
          Navigator.of(ctx).pop();
          _openGradeDialog(submission);
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openGradeDialog(Map<String, dynamic> submission) {
    setState(() {
      _gradingSubmission = submission;
      _gradeScoreCtrl.text = (submission['score'] ?? '').toString();
      _gradeFeedbackCtrl.text = submission['feedback'] ?? '';
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AssignmentGradeDialog(
        submission: _gradingSubmission,
        gradeScoreCtrl: _gradeScoreCtrl,
        gradeFeedbackCtrl: _gradeFeedbackCtrl,
        grading: _grading,
        onGrade: _handleGrade,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _handleGrade() async {
    if (_gradingSubmission == null) return;
    setState(() => _grading = true);
    try {
      await _repo.gradeSubmission(
        submissionId: _gradingSubmission!['id'] ?? '',
        score: int.tryParse(_gradeScoreCtrl.text) ?? 0,
        feedback: _gradeFeedbackCtrl.text.isNotEmpty
            ? _gradeFeedbackCtrl.text
            : null,
      );
      if (mounted) {
        Navigator.of(context).pop();
        buildSnackBar(context, 'تم تصحيح الواجب');
        if (_selectedAssignment != null) {
          _viewDetail(_selectedAssignment!['id'] ?? '');
        }
      }
    } catch (_) {
      if (mounted) _showError('فشل التصحيح');
    } finally {
      if (mounted) setState(() => _grading = false);
    }
  }

  void _showError(String msg) {
    buildSnackBar(context, msg, isError: true);
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
            AssignmentHeader(
              currentTab: _tab,
              onTabChanged: _onTabChanged,
            ),
            Expanded(
              child: _tab == 0
                  ? AssignmentCreateForm(
                      isDark: isDark,
                      courses: _courses,
                      coursesLoading: _coursesLoading,
                      lessons: _lessons,
                      lessonsLoading: _lessonsLoading,
                      formCourse: _formCourse,
                      formLesson: _formLesson,
                      formTitleCtrl: _formTitleCtrl,
                      formDescCtrl: _formDescCtrl,
                      formDueDate: _formDueDate,
                      formMaxScore: _formMaxScore,
                      formPublished: _formPublished,
                      submitting: _submitting,
                      onCourseChanged: _onCourseChanged,
                      onLessonChanged: (v) =>
                          setState(() => _formLesson = v),
                      onDueDateChanged: (v) =>
                          setState(() => _formDueDate = v),
                      onMaxScoreChanged: (v) =>
                          setState(() => _formMaxScore = v),
                      onPublishedChanged: (v) =>
                          setState(() => _formPublished = v),
                      onCreate: _handleCreate,
                      onCancel: () => Navigator.maybePop(context),
                    )
                  : AssignmentViewList(
                      isDark: isDark,
                      courses: _courses,
                      assignments: _assignments,
                      assignmentsLoading: _assignmentsLoading,
                      filterCourse: _filterCourse,
                      onFilterChanged: _onFilterChanged,
                      onRefresh: _fetchAssignments,
                      onViewDetail: _viewDetail,
                      onCreateTab: () => _onTabChanged(0),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
