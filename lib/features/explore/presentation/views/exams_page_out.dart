import 'package:flutter/material.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/services/shared_preferences_singleton.dart';
import '../../explore_colors.dart';
import '../../services/ai_exam_service.dart';
import 'take_ai_exam_view.dart';

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

  bool _generating = false;
  String _error = '';
  bool _showHistory = false;
  Map<String, dynamic>? _limitInfo;
  List<dynamic> _history = [];

  bool _isLoggedIn = false;

  static const List<String> steps = ['اختر الصف', 'اختر المادة', 'اختر الفصل', 'اختر الصعوبة'];

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
  void initState() {
    super.initState();
    _isLoggedIn = Prefs.getString('token') != null;
    if (_isLoggedIn) _fetchLimitAndHistory();
  }

  Future<void> _fetchLimitAndHistory() async {
    try {
      final results = await Future.wait([
        AiExamService().checkAiExamLimit(),
        AiExamService().getMyAiExams(),
      ]);
      if (mounted) {
        setState(() {
          _limitInfo = results[0] as Map<String, dynamic>;
          _history = results[1] as List<dynamic>;
        });
      }
    } catch (_) {
      // ignore: empty_catches
    }
  }

  bool get _canStartExam =>
      _selectedGrade != null &&
      _selectedSubject != null &&
      _selectedChapter != null &&
      _selectedDifficulty != null;

  void _handleGradeSelect(String grade) {
    setState(() {
      _selectedGrade = grade;
      _selectedSubject = null;
      _selectedChapter = null;
      _selectedDifficulty = null;
      _activeStep = 1;
    });
  }

  void _handleSubjectSelect(String subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedChapter = null;
      _selectedDifficulty = null;
      _activeStep = 2;
    });
  }

  void _handleChapterSelect(String chapter) {
    setState(() {
      _selectedChapter = chapter;
      _selectedDifficulty = null;
      _activeStep = 3;
    });
  }

  void _handleDifficultySelect(String difficulty) {
    setState(() => _selectedDifficulty = difficulty);
  }

  Future<void> _handleStartExam() async {
    final token = Prefs.getString('token');
    if (token == null) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => _buildLoginDialog(context.isDark),
      );
      return;
    }
    setState(() { _error = ''; _generating = true; });
    try {
      final exam = await AiExamService().generateAiExam(
        grade: _selectedGrade!,
        subject: _selectedSubject!,
        chapter: _selectedChapter!,
        difficulty: _selectedDifficulty!,
      );
      final examId = exam['id'];
      if (examId != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TakeAiExamView(examId: examId),
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        setState(() => _error = err.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildStepIndicator(isDark),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAlert(isDark),
                    ),
                  if (_isLoggedIn && _limitInfo != null && !(_limitInfo!['canGenerate'] as bool? ?? true))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildLimitAlert(isDark),
                    ),
                  if (_isLoggedIn && _limitInfo != null && (_limitInfo!['canGenerate'] as bool? ?? true))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRemainingAlert(isDark),
                    ),
                  if (_isLoggedIn && _showHistory && _history.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildHistory(isDark),
                    ),
                  _buildSelectionPanel(isDark),
                  const SizedBox(height: 12),
                  _buildSummaryPanel(isDark),
                  const SizedBox(height: 16),
                  _buildStartButton(isDark),
                  if (!_canStartExam)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('يرجى إكمال جميع الخطوات للبدء',
                        style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      ),
                    ),
                  if (_canStartExam) ...[
                    const SizedBox(height: 12),
                    _buildExamInfo(isDark),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 28),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: ExploreColors.pinkGradient)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎯 الاختبارات والتدريبات',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                const SizedBox(height: 4),
                Text('اختبر نفسك واعرف مستواك الحقيقي',
                  style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          if (_isLoggedIn)
            IconButton(
              icon: Icon(_showHistory ? Icons.close_rounded : Icons.history_rounded, color: Colors.white),
              onPressed: () => setState(() => _showHistory = !_showHistory),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _activeStep;
          final isCompleted = i < _activeStep;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? ExploreColors.success : (isActive ? ExploreColors.accent : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text('${i + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              fontWeight: FontWeight.bold, fontSize: 12,
                            )),
                  ),
                ),
                const SizedBox(height: 4),
                Text(steps[i],
                  style: TextStyle(
                    fontSize: 9, fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                    color: isCompleted ? ExploreColors.success : (isActive ? ExploreColors.accent : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAlert(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (ExploreColors.error).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ExploreColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: ExploreColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error,
              style: const TextStyle(fontSize: 13, fontFamily: 'Cairo', color: ExploreColors.error),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _error = ''),
            child: const Icon(Icons.close, color: ExploreColors.error, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitAlert(bool isDark) {
    final limitInfo = _limitInfo!;
    final hasPurchases = limitInfo['hasPurchases'] as bool? ?? false;
    final usedToday = limitInfo['usedToday'] as int? ?? 0;
    final maxPerDay = limitInfo['maxPerDay'] as int? ?? 1;
    final message = hasPurchases
        ? 'لقد وصلت إلى الحد الأقصى لإنشاء الاختبارات لهذا اليوم ($usedToday/$maxPerDay).'
        : 'يمكنك إنشاء اختبار واحد فقط. قم بشراء كورس أو كتاب لإنشاء المزيد من الاختبارات. ($usedToday/$maxPerDay)';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ExploreColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ExploreColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: ExploreColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
              style: TextStyle(fontSize: 12, fontFamily: 'Cairo',
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingAlert(bool isDark) {
    final limitInfo = _limitInfo!;
    final hasPurchases = limitInfo['hasPurchases'] as bool? ?? false;
    final usedToday = limitInfo['usedToday'] as int? ?? 0;
    final maxPerDay = limitInfo['maxPerDay'] as int? ?? 1;
    final remaining = maxPerDay - usedToday;
    final icon = hasPurchases ? Icons.emoji_events_rounded : Icons.quiz_rounded;
    final message = hasPurchases
        ? 'يمكنك إنشاء $remaining اختبارات من أصل $maxPerDay اليوم.'
        : 'يمكنك إنشاء $remaining اختبار. قم بشراء كورس أو كتاب لزيادة الحد اليومي.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ExploreColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ExploreColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: ExploreColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
              style: TextStyle(fontSize: 12, fontFamily: 'Cairo',
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(bool isDark) {
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
          Text('اختباراتي السابقة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          ..._history.map((exam) {
            final e = exam as Map<String, dynamic>;
            final isCompleted = e['isCompleted'] as bool? ?? false;
            final passed = e['passed'] as bool? ?? false;
            Color chipBg;
            Color chipColor;
            String statusLabel;
            if (isCompleted) {
              if (passed) {
                chipBg = const Color(0xFFDCFCE7);
                chipColor = const Color(0xFF059669);
                statusLabel = 'ناجح';
              } else {
                chipBg = const Color(0xFFFEF3C7);
                chipColor = const Color(0xFFF59E0B);
                statusLabel = 'مكتمل';
              }
            } else {
              chipBg = const Color(0xFFE5E7EB);
              chipColor = const Color(0xFF64748B);
              statusLabel = 'لم يكتمل';
            }
            return GestureDetector(
              onTap: () {
                // Navigate to review/take
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e['subject']} - ${e['chapter']}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Text('${e['difficulty']} • ${e['questionsCount']} أسئلة',
                            style: TextStyle(fontSize: 11, fontFamily: 'Cairo',
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(statusLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Cairo', color: chipColor)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectionPanel(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: ExploreColors.pinkGradient)),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(steps[_activeStep],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                    Text('الخطوة ${_activeStep + 1} من ${steps.length}',
                      style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStepContent(isDark),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_activeStep) {
      case 0:
        return _buildGradeStep(isDark);
      case 1:
        return _buildSubjectStep(isDark);
      case 2:
        return _buildChapterStep(isDark);
      case 3:
        return _buildDifficultyStep(isDark);
      default:
        return const SizedBox();
    }
  }

  Widget _buildGradeStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر الصف الدراسي',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
        const SizedBox(height: 16),
        ...grades.map((grade) {
          final isSelected = _selectedGrade == grade;
          return GestureDetector(
            onTap: () => _handleGradeSelect(grade),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0x1ADB2777) : const Color(0x1AFDF2F8))
                    : (isDark ? const Color(0xFF0F172A) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? ExploreColors.accent : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: ExploreColors.pinkGradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(grade,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubjectStep(bool isDark) {
    final items = subjects[_selectedGrade] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر المادة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
        const SizedBox(height: 16),
        ...items.map((subject) {
          final isSelected = _selectedSubject == subject;
          return GestureDetector(
            onTap: () => _handleSubjectSelect(subject),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0x1ADB2777) : const Color(0x1AFDF2F8))
                    : (isDark ? const Color(0xFF0F172A) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? ExploreColors.accent : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: ExploreColors.pinkGradient),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(subject,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _activeStep = 0),
          child: Text('رجوع',
            style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ),
      ],
    );
  }

  Widget _buildChapterStep(bool isDark) {
    final items = chapters[_selectedSubject] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر الفصل',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
        const SizedBox(height: 16),
        ...items.map((chapter) {
          final isSelected = _selectedChapter == chapter;
          return GestureDetector(
            onTap: () => _handleChapterSelect(chapter),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0x1ADB2777) : const Color(0x1AFDF2F8))
                    : (isDark ? const Color(0xFF0F172A) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? ExploreColors.accent : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: ExploreColors.pinkGradient),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(chapter,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _activeStep = 1),
          child: Text('رجوع',
            style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ),
      ],
    );
  }

  Widget _buildDifficultyStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر مستوى الصعوبة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
        const SizedBox(height: 16),
        ...difficultyLevels.map((level) {
          final isSelected = _selectedDifficulty == level['value'];
          return GestureDetector(
            onTap: () => _handleDifficultySelect(level['value'] as String),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(level['label'] as String,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                        Text(level['desc'] as String,
                          style: TextStyle(fontSize: 11, fontFamily: 'Cairo',
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
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
      ],
    );
  }

  Widget _buildSummaryPanel(bool isDark) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: ExploreColors.pinkGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text('ملخص الاختيار',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 20),
          _summaryField('الصف الدراسي', _selectedGrade ?? 'لم يتم الاختيار', isDark),
          const SizedBox(height: 12),
          _summaryField('المادة', _selectedSubject ?? 'لم يتم الاختيار', isDark),
          const SizedBox(height: 12),
          _summaryField('الفصل', _selectedChapter ?? 'لم يتم الاختيار', isDark),
          const SizedBox(height: 12),
          _summaryDifficulty(isDark),
        ],
      ),
    );
  }

  Widget _summaryField(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: TextStyle(fontSize: 11, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _summaryDifficulty(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('مستوى الصعوبة',
          style: TextStyle(fontSize: 11, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        if (_selectedDifficulty != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: difficultyLevels.firstWhere((d) => d['value'] == _selectedDifficulty)['color'].withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_selectedDifficulty!,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                color: difficultyLevels.firstWhere((d) => d['value'] == _selectedDifficulty)['color'] as Color)),
          )
        else
          Text('لم يتم الاختيار',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildStartButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _canStartExam && !_generating ? _handleStartExam : null,
        icon: _generating
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.play_arrow_rounded),
        label: Text(_generating ? 'جاري إنشاء الاختبار...' : 'ابدأ الامتحان',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ExploreColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: _canStartExam ? 8 : 0,
          shadowColor: ExploreColors.accent.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildExamInfo(bool isDark) {
    return Container(
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
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: ExploreColors.warning, size: 20),
              const SizedBox(width: 8),
              Text('معلومات الامتحان',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          _examInfoRow(Icons.timer_rounded, 'المدة: 60 دقيقة', isDark),
          const SizedBox(height: 8),
          _examInfoRow(Icons.quiz_rounded, 'عدد الأسئلة: 20 سؤال', isDark),
          const SizedBox(height: 8),
          _examInfoRow(Icons.emoji_events_rounded, 'الدرجة النهائية: 100 درجة', isDark),
        ],
      ),
    );
  }

  Widget _examInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(text,
          style: TextStyle(fontSize: 13, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildLoginDialog(bool isDark) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.login_rounded, size: 48, color: ExploreColors.accent),
          const SizedBox(height: 12),
          Text('تسجيل الدخول مطلوب',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text('يجب تسجيل الدخول أولاً لإنشاء اختبار باستخدام الذكاء الاصطناعي.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontFamily: 'Cairo',
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to login
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('تسجيل الدخول',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ExploreColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
