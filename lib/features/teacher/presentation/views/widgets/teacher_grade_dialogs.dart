import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../data/repositories/teacher_repository.dart';
import 'teacher_theme_helpers.dart';
import 'teacher_grade_question_view.dart';

class TeacherGradeDetailDialog extends StatefulWidget {
  final TeacherRepository repo;
  final String attemptId;
  const TeacherGradeDetailDialog({super.key, required this.repo, required this.attemptId});

  @override
  State<TeacherGradeDetailDialog> createState() => _TeacherGradeDetailDialogState();
}

class _TeacherGradeDetailDialogState extends State<TeacherGradeDetailDialog> {
  Map<String, dynamic>? _attempt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await widget.repo.getAttemptDetail(widget.attemptId);
      if (mounted) setState(() => _attempt = detail);
    } catch (_) {
      if (mounted) setState(() => _attempt = null);
    }
    if (mounted) setState(() => _loading = false);
  }

  String _getStudentName(Map<String, dynamic> a) =>
      (a['student'] as Map?)?['user']?['name'] ?? '—';
  String _getExamTitle(Map<String, dynamic> a) =>
      (a['exam'] as Map?)?['title'] ?? '—';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: 0.9.sh),
        decoration: BoxDecoration(
          color: cardBgColor(context),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: fieldBorderColor(context))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _attempt != null
                          ? '${_getStudentName(_attempt!)} — ${_getExamTitle(_attempt!)}'
                          : 'تفاصيل المحاولة',
                      style: TextStyles.semiBold16.copyWith(color: fieldTextColor(context)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: fieldLabelColor(context)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _attempt == null
                      ? Center(
                          child: Text('تعذّر تحميل تفاصيل المحاولة',
                              style: TextStyle(fontFamily: 'Cairo', color: fieldLabelColor(context))))
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final attempt = _attempt!;
    final exam = attempt['exam'] as Map<String, dynamic>? ?? {};
    final questions =
        (exam['questions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final answers = attempt['answers'] as Map<String, dynamic>? ?? {};
    final isPassed = attempt['isPassed'] == true;
    final score = attempt['score'];
    final totalMarks = exam['totalMarks'];

    return Column(
      children: [
        Expanded(
          child: TeacherGradeQuestionView(
            questions: questions,
            answers: answers,
            score: score,
            totalMarks: totalMarks,
            isPassed: isPassed,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('إغلاق'),
              style: TextButton.styleFrom(foregroundColor: fieldLabelColor(context)),
            ),
          ),
        ),
      ],
    );
  }
}
