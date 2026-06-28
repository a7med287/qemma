import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../services/ai_exam_service.dart';
import 'ai_exam_review_view.dart';

class TakeAiExamView extends StatefulWidget {
  final String examId;
  const TakeAiExamView({super.key, required this.examId});

  @override
  State<TakeAiExamView> createState() => _TakeAiExamViewState();
}

class _TakeAiExamViewState extends State<TakeAiExamView> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _examData;
  final _answers = <String, String>{};
  bool _submitting = false;
  Map<String, dynamic>? _result;
  int _activeQ = 0;
  int _timeLeft = 1800;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchExam() async {
    try {
      _loading = true;
      _error = '';
      if (mounted) setState(() {});
      final list = await AiExamService().getMyAiExams();
      final exam = list.cast<Map<String, dynamic>>().firstWhere(
        (e) => e['id'] == widget.examId,
        orElse: () => <String, dynamic>{},
      );
      if (exam.isEmpty) {
        if (mounted) setState(() { _error = 'الاختبار غير موجود.'; _loading = false; });
        return;
      }
      if (exam['isCompleted'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AiExamReviewView(examId: widget.examId)),
        );
        return;
      }
      final detail = await AiExamService().getAiExamReview(widget.examId);
      if (detail['questions'] != null) {
        if (mounted) {
          setState(() { _examData = detail; _loading = false; });
          _startTimer();
        }
      } else {
        if (mounted) setState(() { _error = 'لم يتم تحميل بيانات الاختبار.'; _loading = false; });
      }
    } catch (err) {
      if (mounted) {
        final msg = err.toString().replaceFirst('Exception: ', '');
        setState(() { _error = msg; _loading = false; });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft <= 1) {
        _timer?.cancel();
        if (_result == null) _handleSubmit();
      } else {
        if (mounted) setState(() => _timeLeft--);
      }
    });
  }

  String get _timeFormatted {
    final m = _timeLeft ~/ 60;
    final s = _timeLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isTimerWarning => _timeLeft <= 300;
  bool get _isTimerCritical => _timeLeft <= 60;

  List<dynamic> get _questions => (_examData?['questions'] as List<dynamic>?) ?? [];
  int get _totalQ => _questions.length;
  int get _answered => _answers.length;
  int get _timerPct => ((_timeLeft / 1800) * 100).round();

  void _handleAnswer(String questionId, String value) {
    setState(() => _answers[questionId] = value);
  }

  Future<void> _handleSubmit() async {
    if (_submitting || _examData == null) return;
    _timer?.cancel();
    setState(() => _submitting = true);
    try {
      final data = await AiExamService().submitAiExam(widget.examId, _answers);
      if (mounted) setState(() { _result = data; _submitting = false; });
    } catch (err) {
      if (mounted) {
        final msg = err.toString().replaceFirst('Exception: ', '');
        setState(() { _error = msg; _submitting = false; });
        _startTimer();
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

  static const List<Color> _questionColors = [
    Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFF059669),
    Color(0xFFDB2777), Color(0xFFF59E0B), Color(0xFF0891B2),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    if (_result != null) return _buildResult(isDark);
    if (_loading || _examData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF7C3AED)),
              const SizedBox(height: 16),
              Text('جاري تحميل الاختبار...',
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
                Text('تعذر تحميل الاختبار',
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            Expanded(
              child: _buildContent(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    final examData = _examData!;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFDB2777), Color(0xFF7C3AED)]),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => _showExitDialog(isDark),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1)),
              ),
              const Icon(Icons.quiz_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${examData['subject']} - ${examData['chapter']}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                    Text('${examData['grade']} • ${examData['difficulty']}',
                      style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(_timeFormatted,
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'monospace',
                          color: _isTimerCritical ? const Color(0xFFFCA5A5) : (_isTimerWarning ? const Color(0xFFFBBF24) : Colors.white),
                        )),
                    ],
                  ),
                  Text('الوقت المتبقي',
                    style: TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _timerPct / 100.0,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isTimerCritical ? const Color(0xFFEF4444) : (_isTimerWarning ? const Color(0xFFF59E0B) : const Color(0xFF34D399)),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$_answered / $_totalQ تمت الإجابة',
                style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildQuestionList(isDark),
          const SizedBox(height: 12),
          _buildQuestionCard(isDark),
          const SizedBox(height: 12),
          _buildQuestionNav(isDark),
        ],
      ),
    );
  }

  Widget _buildQuestionList(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('قائمة الأسئلة',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_totalQ, (i) {
              final q = _questions[i] as Map<String, dynamic>;
              final isAnswered = _answers[q['id']] != null && _answers[q['id']]!.isNotEmpty;
              final isActive = i == _activeQ;
              Color bgColor;
              Color fgColor;
              if (isActive) {
                bgColor = const Color(0xFF7C3AED);
                fgColor = Colors.white;
              } else if (isAnswered) {
                bgColor = const Color(0xFF059669);
                fgColor = Colors.white;
              } else {
                bgColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
                fgColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
              }
              return GestureDetector(
                onTap: () => setState(() => _activeQ = i),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Cairo', color: fgColor)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(const Color(0xFF059669), 'تمت الإجابة', isDark),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFF7C3AED), 'الحالي', isDark),
              const SizedBox(width: 12),
              _legendDot(isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), 'لم تُجب', isDark),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : () => _showConfirmSubmitDialog(isDark),
              icon: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(_submitting ? 'جاري التقديم...' : 'تقديم الاختبار',
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 4),
        Text(label,
          style: TextStyle(fontSize: 10, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildQuestionNav(bool isDark) {
    return Row(
      children: [
        if (_activeQ > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _activeQ--),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('السابق',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 12),
        if (_activeQ < _totalQ - 1)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _activeQ++),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('التالي',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _questionColors[_activeQ % _questionColors.length],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          )
        else
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : () => _showConfirmSubmitDialog(isDark),
              icon: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_submitting ? 'جاري...' : 'تقديم',
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionCard(bool isDark) {
    final q = _questions[_activeQ] as Map<String, dynamic>;
    final color = _questionColors[_activeQ % _questionColors.length];
    final options = (q['options'] as List<dynamic>?)?.cast<String>() ?? [];
    final answer = _answers[q['id']];
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: color),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('سؤال ${_activeQ + 1} من $_totalQ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Cairo', color: color)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${q['marks']} درجة',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Cairo', color: Color(0xFFF59E0B))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(q['questionText'] ?? '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      height: 1.8)),
                  const SizedBox(height: 20),
                  if (options.isNotEmpty)
                    ...options.map((opt) {
                      final isSelected = answer == opt;
                      return GestureDetector(
                        onTap: () => _handleAnswer(q['id'], opt),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: opt,
                                groupValue: answer,
                                onChanged: (v) {
                                  if (v != null) _handleAnswer(q['id'], v);
                                },
                                fillColor: WidgetStatePropertyAll(color),
                              ),
                              Expanded(
                                child: Text(opt,
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14,
                                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155))),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmSubmitDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text('تأكيد التقديم',
          style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
        content: Text('هل أنت متأكد من تقديم الاختبار؟ لا يمكنك العودة بعد التقديم.',
          style: TextStyle(fontFamily: 'Cairo',
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
              style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSubmit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('تقديم',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                boxShadow: const [BoxShadow(color: Color(0x4CEF4444), blurRadius: 16, offset: Offset(0, 8))],
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text('تأكيد الخروج',
              style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 18,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text('هل أنت متأكد من رغبتك في مغادرة الاختبار؟',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x1AEF4444) : const Color(0x0EEF4444),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0x33EF4444) : const Color(0x26EF4444)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('سيتم فقدان أي تقدم لم تقم بحفظه إذا غادرت الآن.',
                      style: TextStyle(fontSize: 12, fontFamily: 'Cairo',
                        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                        fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('استمرار الاختبار',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155))),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                  label: const Text('مغادرة الاختبار',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(bool isDark) {
    final result = _result!;
    final scorePct = ((result['totalMarks'] as num?)?.toDouble() ?? 0) > 0
        ? (((result['score'] as num?)?.toDouble() ?? 0) / (result['totalMarks'] as num?)!.toDouble() * 100).round()
        : 0;
    final gradeColor = _gradeColor(scorePct.toDouble());
    final passed = result['passed'] as bool? ?? false;
    final gradedDetails = (result['gradedDetails'] as List<dynamic>?) ?? [];
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: passed
                        ? [const Color(0xFF059669), const Color(0xFF047857)]
                        : [const Color(0xFFF59E0B), const Color(0xFFDC2626)],
                  ),
                ),
                child: Column(
                  children: [
                    Text(passed ? '🎉' : '😔', style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(passed ? 'مبروك! لقد نجحت في الاختبار 🎉' : 'لم تحقق الدرجة المطلوبة',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white),
                      textAlign: TextAlign.center),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: gradeColor.withValues(alpha: 0.1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${(result['score'] as num?)?.toDouble().round() ?? 0}',
                                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: gradeColor, height: 1)),
                                Text('من ${(result['totalMarks'] as num?)?.toDouble().round() ?? 0}',
                                  style: TextStyle(fontSize: 12, fontFamily: 'Cairo',
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('$scorePct%',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: gradeColor)),
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
                    if (gradedDetails.isNotEmpty) ...[
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
                            Text('تفاصيل الإجابات',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                            const SizedBox(height: 12),
                            ...gradedDetails.map((d) {
                              final detail = d as Map<String, dynamic>;
                              final correct = detail['correct'] as bool? ?? false;
                              final qText = detail['questionText'] as String? ?? '';
                              final marks = detail['marks'] as num? ?? 0;
                              final maxMarks = detail['maxMarks'] as num? ?? 0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: correct
                                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4))
                                      : (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      color: correct ? const Color(0xFF059669) : const Color(0xFFEF4444),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(qText.length > 50 ? '${qText.substring(0, 50)}...' : qText,
                                            style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo', fontSize: 12,
                                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155))),
                                          Text(
                                            correct
                                                ? '✓ الإجابة صحيحة ($marks/$maxMarks)'
                                                : '✗ إجابة خاطئة (0/$maxMarks)',
                                            style: TextStyle(fontSize: 11, fontFamily: 'Cairo',
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      correct ? '$marks/$maxMarks' : '0/$maxMarks',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                                        color: correct ? const Color(0xFF059669) : const Color(0xFFEF4444)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.quiz_rounded, size: 20),
                          label: const Text('العودة للاختبارات',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
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
