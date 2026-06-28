import 'package:flutter/material.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../services/ai_exam_service.dart';

class AiExamReviewView extends StatefulWidget {
  final String examId;
  const AiExamReviewView({super.key, required this.examId});

  @override
  State<AiExamReviewView> createState() => _AiExamReviewViewState();
}

class _AiExamReviewViewState extends State<AiExamReviewView> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _reviewData;

  @override
  void initState() {
    super.initState();
    _fetchReview();
  }

  Future<void> _fetchReview() async {
    try {
      _loading = true;
      _error = '';
      if (mounted) setState(() {});
      final data = await AiExamService().getAiExamReview(widget.examId);
      if (data['questions'] != null) {
        if (mounted) setState(() { _reviewData = data; _loading = false; });
      } else {
        if (mounted) setState(() { _error = 'لم يتم العثور على بيانات الاختبار.'; _loading = false; });
      }
    } catch (err) {
      if (mounted) {
        final msg = err.toString().replaceFirst('Exception: ', '');
        setState(() { _error = msg; _loading = false; });
      }
    }
  }

  Color _gradeColor(double score) {
    if (score >= 90) return const Color(0xFF059669);
    if (score >= 80) return const Color(0xFF2563EB);
    if (score >= 70) return const Color(0xFF7C3AED);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF7C3AED)),
              const SizedBox(height: 16),
              Text('جاري تحميل المراجعة...',
                style: TextStyle(fontSize: 16, fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_rounded, size: 64, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text('تعذر تحميل المراجعة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Text(_error, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('العودة للاختبارات',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_reviewData == null) return const SizedBox.shrink();

    final rd = _reviewData!;
    final score = (rd['score'] as num?)?.toDouble() ?? 0;
    final totalMarks = (rd['totalMarks'] as num?)?.toDouble() ?? 0;
    final scorePct = totalMarks > 0 ? (score / totalMarks * 100).round() : 0;
    final gradeColor = _gradeColor(scorePct.toDouble());
    final passed = rd['passed'] as bool? ?? false;
    final questions = (rd['questions'] as List<dynamic>?) ?? [];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: passed
                        ? [const Color(0xFF059669), const Color(0xFF047857)]
                        : [const Color(0xFFF59E0B), const Color(0xFFDC2626)],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.quiz_rounded, color: Colors.white, size: 32),
                        const SizedBox(width: 8),
                        const Text('مراجعة الاختبار',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(passed ? '🎉' : '😔', style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(passed ? 'مبروك! لقد نجحت 🎉' : 'لم تحقق الدرجة المطلوبة',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: Colors.white),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('${rd['subject']} - ${rd['chapter']}',
                      style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.9))),
                    Text('${rd['grade']} • ${rd['difficulty']}',
                      style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: -16),
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: gradeColor.withValues(alpha: 0.1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${score.round()}',
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: gradeColor, height: 1)),
                                Text('من ${totalMarks.round()}',
                                  style: TextStyle(fontSize: 11, fontFamily: 'Cairo',
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('$scorePct%',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: gradeColor)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: passed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  size: 18, color: passed ? const Color(0xFF059669) : const Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                Text(passed ? 'ناجح ✓' : 'لم تنجح',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 13,
                                    color: passed ? const Color(0xFF059669) : const Color(0xFFF59E0B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('جميع الأسئلة مع الإجابات',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                          const SizedBox(height: 16),
                          ...questions.asMap().entries.map((entry) {
                            final i = entry.key;
                            final q = entry.value as Map<String, dynamic>;
                            final qText = q['questionText'] as String? ?? '';
                            final options = (q['options'] as List<dynamic>?)?.cast<String>() ?? [];
                            final correctAnswer = q['correctAnswer'] as String? ?? '';
                            final studentAnswer = q['studentAnswer'] as String? ?? '';
                            final isCorrect = q['isCorrect'] as bool?;
                            final marks = q['marks'] as num? ?? 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isCorrect == true
                                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4))
                                    : (isCorrect == false
                                        ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
                                        : (isDark ? const Color(0xFF1E293B) : Colors.white)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCorrect == true
                                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                                      : (isCorrect == false
                                          ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
                                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCorrect == true ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('سؤال ${i + 1}',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Cairo',
                                            color: isCorrect == true ? const Color(0xFF059669) : const Color(0xFFF59E0B))),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB)),
                                        ),
                                        child: Text('$marks درجة',
                                          style: TextStyle(fontSize: 11, fontFamily: 'Cairo',
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                      ),
                                      const Spacer(),
                                      if (isCorrect != null)
                                        Icon(
                                          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                          color: isCorrect ? const Color(0xFF059669) : const Color(0xFFEF4444),
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(qText,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Cairo',
                                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                      height: 1.6)),
                                  const SizedBox(height: 12),
                                  if (options.isNotEmpty)
                                    ...options.map((opt) {
                                      final isCorrectAnswer = opt == correctAnswer;
                                      final isStudentAns = opt == studentAnswer;
                                      Color bgColor = Colors.transparent;
                                      Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
                                      Color textColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
                                      if (isCorrectAnswer) {
                                        bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
                                        borderColor = const Color(0xFF059669);
                                        textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF065F46);
                                      } else if (isStudentAns && isCorrect == false) {
                                        bgColor = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
                                        borderColor = const Color(0xFFEF4444);
                                        textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF991B1B);
                                      }
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: borderColor, width: 2),
                                        ),
                                        child: Row(
                                          children: [
                                            if (isCorrectAnswer)
                                              const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                                            if (isStudentAns && isCorrect == false)
                                              const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20),
                                            if (!isCorrectAnswer && !(isStudentAns && isCorrect == false))
                                              const SizedBox(width: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(opt,
                                                style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textColor)),
                                            ),
                                            if (isCorrectAnswer)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF059669),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('الإجابة الصحيحة',
                                                  style: TextStyle(fontSize: 9, fontFamily: 'Cairo',
                                                    fontWeight: FontWeight.w600, color: Colors.white)),
                                              ),
                                            if (isStudentAns && isCorrect == false)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEF4444),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('إجابتك',
                                                  style: TextStyle(fontSize: 9, fontFamily: 'Cairo',
                                                    fontWeight: FontWeight.w600, color: Colors.white)),
                                              ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.visibility_rounded, size: 20),
                          label: const Text('العودة للاختبارات',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('إنشاء اختبار جديد',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
