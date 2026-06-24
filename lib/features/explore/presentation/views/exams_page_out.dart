import 'package:flutter/material.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../explore_colors.dart';
import 'widgets/exam_selection_widgets.dart';

class ExamsPageOut extends StatefulWidget {
  const ExamsPageOut({super.key});

  @override
  State<ExamsPageOut> createState() => _ExamsPageOutState();
}

class _ExamsPageOutState extends State<ExamsPageOut> {
  int _activeStep = 0;
  String? _selectedGrade;
  String? _selectedSubject;
  String? _selectedChapter;
  String? _selectedDifficulty;

  static const List<String> steps = ['اختر الصف', 'اختر المادة', 'اختر الفصل', 'اختر الصعوبة', 'ملخص الاختبار'];

  static const List<String> grades = [
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
  ];

  static const Map<String, List<String>> subjects = {
    'الصف الأول الثانوي': ['الرياضيات', 'الفيزياء', 'الكيمياء', 'الأحياء', 'اللغة العربية', 'اللغة الإنجليزية', 'التاريخ', 'الجغرافيا'],
    'الصف الثاني الثانوي': ['الرياضيات', 'الفيزياء', 'الكيمياء', 'الأحياء', 'اللغة العربية', 'اللغة الإنجليزية', 'التاريخ', 'الجغرافيا', 'الفلسفة'],
    'الصف الثالث الثانوي': ['الرياضيات', 'الفيزياء', 'الكيمياء', 'الأحياء', 'اللغة العربية', 'اللغة الإنجليزية', 'التاريخ', 'الجغرافيا', 'الفلسفة', 'علم النفس'],
  };

  static const Map<String, List<String>> chapters = {
    'الرياضيات': ['الجبر', 'الهندسة', 'التفاضل والتكامل', 'الإحصاء', 'المثلثات'],
    'الفيزياء': ['الميكانيكا', 'الكهربية', 'المغناطيسية', 'الضوء', 'الصوت'],
    'الكيمياء': ['الكيمياء العضوية', 'الكيمياء غير العضوية', 'الكيمياء الفيزيائية', 'الكيمياء التحليلية'],
    'الأحياء': ['علم النبات', 'علم الحيوان', 'الوراثة', 'البيئة', 'التشريح'],
    'اللغة العربية': ['النحو', 'البلاغة', 'الأدب', 'النصوص', 'القراءة'],
    'اللغة الإنجليزية': ['Grammar', 'Vocabulary', 'Reading', 'Writing', 'Literature'],
    'التاريخ': ['التاريخ القديم', 'التاريخ الإسلامي', 'التاريخ الحديث', 'تاريخ مصر'],
    'الجغرافيا': ['الجغرافيا الطبيعية', 'الجغرافيا البشرية', 'جغرافيا مصر', 'الخرائط'],
    'الفلسفة': ['الفلسفة القديمة', 'الفلسفة الحديثة', 'المنطق', 'علم الجمال'],
    'علم النفس': ['علم النفس العام', 'علم النفس التربوي', 'علم النفس الاجتماعي'],
  };

  static const List<Map<String, dynamic>> difficultyLevels = [
    {'value': 'سهل', 'label': 'سهل', 'color': Color(0xFF059669), 'icon': '😊', 'desc': 'مناسب للمبتدئين والمراجعة السريعة'},
    {'value': 'متوسط', 'label': 'متوسط', 'color': Color(0xFFF59E0B), 'icon': '🤔', 'desc': 'مستوى الامتحانات الشهرية'},
    {'value': 'صعب', 'label': 'صعب', 'color': Color(0xFFEF4444), 'icon': '😰', 'desc': 'مستوى امتحانات الثانوية العامة'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: ExploreColors.pinkGradient)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🎯 الاختبارات والتدريبات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                        Text('اختبر نفسك واعرف مستواك الحقيقي', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: List.generate(steps.length, (index) {
                        final isActive = index == _activeStep;
                        final isCompleted = index < _activeStep;
                        return Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted ? ExploreColors.success : (isActive ? ExploreColors.accent : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                                      : Text('${index + 1}', style: TextStyle(color: isActive ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(steps[index], style: TextStyle(
                                fontSize: 10, fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                                color: isCompleted ? ExploreColors.success : (isActive ? ExploreColors.accent : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              )),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0x33DB2777),
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(steps[_activeStep], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                                      Text('الخطوة ${_activeStep + 1} من ${steps.length}', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.9))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildStepContent(isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_activeStep) {
      case 0:
        return SelectionList(
          isDark: isDark,
          items: grades,
          selectedItem: _selectedGrade,
          icon: Icons.school_rounded,
          onSelect: (v) {
            setState(() {
              _selectedGrade = v;
              _selectedSubject = null;
              _selectedChapter = null;
              _selectedDifficulty = null;
              _activeStep = 1;
            });
          },
        );
      case 1:
        return Column(
          children: [
            SelectionGrid(
              isDark: isDark,
              items: subjects[_selectedGrade] ?? [],
              selectedItem: _selectedSubject,
              icon: Icons.menu_book_rounded,
              onSelect: (v) {
                setState(() {
                  _selectedSubject = v;
                  _selectedChapter = null;
                  _selectedDifficulty = null;
                  _activeStep = 2;
                });
              },
            ),
            TextButton(onPressed: () => setState(() => _activeStep = 0), child: Text('رجوع', style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))),
          ],
        );
      case 2:
        return Column(
          children: [
            SelectionGrid(
              isDark: isDark,
              items: chapters[_selectedSubject] ?? [],
              selectedItem: _selectedChapter,
              icon: Icons.description_rounded,
              onSelect: (v) {
                setState(() {
                  _selectedChapter = v;
                  _selectedDifficulty = null;
                  _activeStep = 3;
                });
              },
            ),
            TextButton(onPressed: () => setState(() => _activeStep = 1), child: Text('رجوع', style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))),
          ],
        );
      case 3:
        return Column(
          children: [
            Text('اختر مستوى الصعوبة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
            const SizedBox(height: 16),
            ...difficultyLevels.map((level) {
              final isSelected = _selectedDifficulty == level['value'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDifficulty = level['value'];
                    _activeStep = 4;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (level['color'] as Color).withValues(alpha: isDark ? 0.2 : 0.1)
                        : (isDark ? const Color(0xFF0F172A) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? level['color'] as Color : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(level['icon'] as String, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(level['label'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                            Text(level['desc'] as String, style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: level['color'] as Color, size: 28),
                    ],
                  ),
                ),
              );
            }),
            TextButton(onPressed: () => setState(() => _activeStep = 2), child: Text('رجوع', style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))),
          ],
        );
      case 4:
        return Column(
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFDF2F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ExploreColors.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: ExploreColors.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.quiz_rounded, color: ExploreColors.accent, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text('ملخص الاختيار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SummaryItem(label: 'الصف الدراسي', value: _selectedGrade ?? '', isDark: isDark),
                  const SizedBox(height: 16),
                  SummaryItem(label: 'المادة', value: _selectedSubject ?? '', isDark: isDark),
                  const SizedBox(height: 16),
                  SummaryItem(label: 'الفصل', value: _selectedChapter ?? '', isDark: isDark),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مستوى الصعوبة', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                      const SizedBox(height: 4),
                      if (_selectedDifficulty != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: difficultyLevels.firstWhere((d) => d['value'] == _selectedDifficulty)['color'].withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_selectedDifficulty!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: difficultyLevels.firstWhere((d) => d['value'] == _selectedDifficulty)['color'])),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  ExamInfoRow(icon: Icons.timer_rounded, text: 'المدة: 60 دقيقة', isDark: isDark),
                  const SizedBox(height: 12),
                  ExamInfoRow(icon: Icons.quiz_rounded, text: 'عدد الأسئلة: 20 سؤال', isDark: isDark),
                  const SizedBox(height: 12),
                  ExamInfoRow(icon: Icons.emoji_events_rounded, text: 'الدرجة النهائية: 100 درجة', isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('ابدأ الامتحان', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ExploreColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _activeStep = 3),
              child: Text('رجوع لتغيير الاختيارات', style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
