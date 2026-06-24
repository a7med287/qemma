import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../data/repositories/assistant_repository.dart';

class AttemptCard extends StatelessWidget {
  final Map<String, dynamic> attempt;
  final bool isDark;
  final Color fieldBorder;
  final Color fieldLabel;
  final Color fieldText;
  final Color cardBg;
  final VoidCallback onTap;

  const AttemptCard({
    super.key,
    required this.attempt,
    required this.isDark,
    required this.fieldBorder,
    required this.fieldLabel,
    required this.fieldText,
    required this.cardBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final student = attempt['student'] as Map? ?? {};
    final studentName = (student['name'] ?? (student['user'] as Map?)?['name'] ?? 'طالب') as String;
    final exam = attempt['exam'] as Map? ?? {};
    final examTitle = (exam['title'] ?? 'اختبار') as String;
    final submittedAt = attempt['submittedAt'] as String? ?? '';
    final date = submittedAt.length >= 10 ? submittedAt.substring(0, 10) : submittedAt;
    final autoScore = attempt['autoScore'];
    final totalMarks = exam['totalMarks'];
    final hasEssay = (exam['questions'] as List?)?.any((q) {
      final qMap = q as Map<String, dynamic>;
      return qMap['type'] == 'essay';
    }) ?? true;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: fieldBorder)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20, backgroundColor: const Color(0xFFF59E0B),
                    child: Text(studentName.isNotEmpty ? studentName[0] : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(studentName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, fontFamily: 'Cairo', color: fieldText)),
                        Text(examTitle,
                            style: TextStyle(fontSize: 11.sp, fontFamily: 'Cairo', color: fieldLabel)),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text('تصحيح',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: const Color(0xFFF59E0B))),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: fieldLabel),
                  SizedBox(width: 4.w),
                  Text(date, style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: fieldLabel)),
                  if (autoScore != null && totalMarks != null) ...[
                    SizedBox(width: 12.w),
                    Icon(Icons.score, size: 12, color: const Color(0xFF059669)),
                    SizedBox(width: 4.w),
                    Text('الدرجة الآلية: $autoScore/$totalMarks',
                        style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: const Color(0xFF059669))),
                  ],
                  const Spacer(),
                  if (!hasEssay)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text('بدون مقالي',
                          style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w600, fontFamily: 'Cairo', color: const Color(0xFF10B981))),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GradingDialog extends StatefulWidget {
  final AssistantRepository repo;
  final String attemptId;

  const GradingDialog({
    super.key,
    required this.repo,
    required this.attemptId,
  });

  @override
  State<GradingDialog> createState() => _GradingDialogState();
}

class _GradingDialogState extends State<GradingDialog> {
  Map<String, dynamic>? _attempt;
  bool _loading = true;
  bool _submitting = false;
  final Map<String, TextEditingController> _scoreControllers = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final detail = await widget.repo.getAttemptDetail(widget.attemptId);
      if (mounted) {
        setState(() {
          _attempt = detail;
          _loading = false;
          _initControllers();
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'فشل تحميل تفاصيل المحاولة'; });
    }
  }

  void _initControllers() {
    final exam = _attempt?['exam'] as Map<String, dynamic>? ?? {};
    final questions = (exam['questions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final q in questions) {
      if (q['type'] == 'essay') {
        final qId = (q['id'] ?? q['_id'] ?? '') as String;
        _scoreControllers[qId] = TextEditingController();
      }
    }
  }

  Color _fieldBorder() => context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  Color _fieldLabel() => context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  Color _fieldText() => context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
  Color _cardBg() => context.isDark ? const Color(0xFF1E293B) : Colors.white;

  void _showError(String msg) {
    setState(() => _error = msg);
  }

  Future<void> _submit() async {
    final essayScores = <Map<String, dynamic>>[];
    for (final entry in _scoreControllers.entries) {
      final scoreText = entry.value.text.trim();
      if (scoreText.isEmpty) {
        _showError('يرجى إدخال جميع الدرجات');
        return;
      }
      final score = int.tryParse(scoreText);
      if (score == null || score < 0) {
        _showError('الدرجات يجب أن تكون أرقاماً موجبة');
        return;
      }
      essayScores.add({'questionId': entry.key, 'score': score});
    }

    setState(() { _submitting = true; _error = null; });
    try {
      await widget.repo.gradeEssays(widget.attemptId, essayScores);
      if (mounted) {
        final sb = ScaffoldMessenger.of(context);
        sb.showSnackBar(const SnackBar(content: Text('تم التصحيح بنجاح')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() { _submitting = false; _error = 'فشل حفظ التصحيح'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Dialog(
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: 0.9.sh),
        decoration: BoxDecoration(color: _cardBg(), borderRadius: BorderRadius.circular(16.r)),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _fieldBorder()))),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _attempt != null
                          ? 'تصحيح: ${(_attempt!['student'] as Map?)?['name'] ?? (() { final u = (_attempt!['student'] as Map?)?['user'] as Map?; return u?['name'] ?? ''; })()}'
                          : 'تصحيح المقالات',
                      style: TextStyles.semiBold16.copyWith(color: _fieldText()),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: _fieldLabel()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _attempt == null
                      ? Center(child: Text(_error!, style: TextStyle(fontFamily: 'Cairo', color: _fieldLabel())))
                      : _GradingBody(
                          attempt: _attempt!,
                          scoreControllers: _scoreControllers,
                          error: _error,
                          submitting: _submitting,
                          onFieldBorder: _fieldBorder,
                          onFieldLabel: _fieldLabel,
                          onFieldText: _fieldText,
                          onSubmit: _submit,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradingBody extends StatelessWidget {
  final Map<String, dynamic> attempt;
  final Map<String, TextEditingController> scoreControllers;
  final String? error;
  final bool submitting;
  final Color Function() onFieldBorder;
  final Color Function() onFieldLabel;
  final Color Function() onFieldText;
  final VoidCallback onSubmit;

  const _GradingBody({
    required this.attempt,
    required this.scoreControllers,
    this.error,
    required this.submitting,
    required this.onFieldBorder,
    required this.onFieldLabel,
    required this.onFieldText,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final exam = attempt['exam'] as Map<String, dynamic>? ?? {};
    final questions = (exam['questions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final answers = attempt['answers'] as Map<String, dynamic>? ?? {};
    final isDark = context.isDark;
    final fieldBorder = onFieldBorder();
    final fieldLabel = onFieldLabel();
    final fieldText = onFieldText();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attempt['autoScore'] != null || attempt['score'] != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: .3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.score, color: Color(0xFF059669), size: 20),
                  SizedBox(width: 8.w),
                  Text('الدرجة الآلية: ${attempt['autoScore'] ?? attempt['score']} / ${exam['totalMarks'] ?? '?'}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13.sp, color: const Color(0xFF059669))),
                ],
              ),
            ),
          SizedBox(height: 16.h),

          if (questions.isEmpty)
            Center(child: Text('لا توجد أسئلة في هذا الاختبار', style: TextStyle(fontFamily: 'Cairo', color: fieldLabel)))
          else
            ...questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              final qId = (q['id'] ?? q['_id'] ?? '') as String;
              final qText = (q['text'] ?? q['questionText'] ?? '') as String;
              final isEssay = q['type'] == 'essay';
              final studentAnswer = answers[qId];
              final maxMarks = q['marks'] ?? 0;

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: fieldBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('سؤال ${i + 1}${isEssay ? ' (مقالي)' : ''}: $qText',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, fontFamily: 'Cairo', color: fieldText)),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isEssay ? const Color(0xFFF59E0B).withValues(alpha: .15) : const Color(0xFF3B82F6).withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(isEssay ? 'مقالي' : q['type'] ?? '',
                              style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w600, fontFamily: 'Cairo',
                                  color: isEssay ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6))),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text('إجابة الطالب:',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, fontFamily: 'Cairo', color: fieldLabel)),
                    SizedBox(height: 4.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: fieldBorder),
                      ),
                      child: Text(studentAnswer?.toString() ?? 'لم يجب',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: fieldText)),
                    ),
                    if (isEssay) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: scoreControllers[qId],
                              keyboardType: TextInputType.number,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: fieldText),
                              decoration: InputDecoration(
                                labelText: 'الدرجة (من $maxMarks)',
                                labelStyle: TextStyle(fontFamily: 'Cairo', color: fieldLabel, fontSize: 12.sp),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: fieldBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: fieldBorder)),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),

          if (error != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(error!,
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.red, fontSize: 12.sp)),
            ),

          if (scoreControllers.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('حفظ التصحيح ✅', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}
