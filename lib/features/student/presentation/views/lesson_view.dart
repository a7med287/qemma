import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/mock/student_mock_data.dart';

class LessonView extends StatefulWidget {
  const LessonView({super.key, required this.courseId, required this.lessonId});

  final String courseId;
  final String lessonId;

  @override
  State<LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends State<LessonView> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _completed = false;
  double _progress = 0.3;
  late TabController _tabController;

  // Quiz state.
  static const List<String> _quizOptions = ['2x', 'x', 'x²'];
  static const String _correctAnswer = '2x';
  String? _selectedAnswer;
  bool _answerChecked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_selectedAnswer == null) return;
    setState(() => _answerChecked = true);
  }

  void _resetQuiz() {
    setState(() {
      _selectedAnswer = null;
      _answerChecked = false;
    });
  }

  /// Highlight color for a quiz option once the student has checked their answer:
  /// green for the correct option, red for a wrong option the student picked.
  Color? _quizOptionColor(String option) {
    if (!_answerChecked) return null;
    if (option == _correctAnswer) return Colors.green.shade50;
    if (option == _selectedAnswer) return Colors.red.shade50;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final course = StudentMockData.courseById(widget.courseId);
    final lessons = course?.lessons ?? [];
    final lesson = lessons.where((l) => l.id == widget.lessonId).firstOrNull;
    final title = lesson?.title ?? 'الدرس';

    final currentIndex = lessons.indexWhere((l) => l.id == widget.lessonId);
    final hasNextLesson = currentIndex != -1 && currentIndex < lessons.length - 1;

    final isCorrect = _selectedAnswer == _correctAnswer;

    return Scaffold(
      backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course?.title ?? '', style: TextStyles.regular13),
            Text(title, style: TextStyles.semiBold16),
          ],
        ),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.play_circle_outline, size: 64.sp, color: Colors.white54),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        LinearProgressIndicator(value: _progress, backgroundColor: Colors.white24, color: Colors.red),
                        Container(
                          color: Colors.black54,
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => setState(() => _isPlaying = !_isPlaying),
                                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _progress,
                                  onChanged: (v) => setState(() => _progress = v),
                                  activeColor: Colors.red,
                                ),
                              ),
                              const Icon(Icons.fullscreen, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'الملاحظات'), Tab(text: 'اختبار قصير')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: EdgeInsets.all(16.r),
                  children: [
                    Text('ملاحظات الدرس', style: TextStyles.bold18.copyWith(color: context.textPrimary)),
                    SizedBox(height: 12.h),
                    ...['مقدمة في الموضوع', 'التعريفات الأساسية', 'أمثلة تطبيقية']
                        .map((n) => Card(child: ListTile(title: Text(n), leading: const Icon(Icons.note)))),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    children: [
                      Text('ما مشتقة x²؟', style: TextStyles.semiBold16),
                      SizedBox(height: 8.h),
                      ..._quizOptions.map((o) => RadioListTile<String>(
                        value: o,
                        groupValue: _selectedAnswer,
                        onChanged: _answerChecked ? null : (v) => setState(() => _selectedAnswer = v),
                        title: Text(o),
                        tileColor: _quizOptionColor(o),
                      )),
                      SizedBox(height: 8.h),
                      if (_answerChecked)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Text(
                            isCorrect ? 'إجابة صحيحة! 🎉' : 'إجابة غير صحيحة، الإجابة الصحيحة هي $_correctAnswer',
                            style: TextStyles.semiBold14.copyWith(color: isCorrect ? Colors.green : Colors.red),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _answerChecked || _selectedAnswer == null ? null : _checkAnswer,
                              child: const Text('تحقق من الإجابة'),
                            ),
                          ),
                          if (_answerChecked) ...[
                            SizedBox(width: 8.w),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _resetQuiz,
                                child: const Text('إعادة المحاولة'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('السابق')),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _completed = true),
                    child: Text(_completed ? '✓ مكتمل' : 'إكمال الدرس'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasNextLesson
                        ? () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LessonView(
                          courseId: widget.courseId,
                          lessonId: lessons[currentIndex + 1].id,
                        ),
                      ),
                    )
                        : null,
                    child: const Text('التالي'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}