import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';

class TeacherGradeExamsView extends StatefulWidget {
  static const routeName = '/teacher/grade-exams';
  const TeacherGradeExamsView({super.key});

  @override
  State<TeacherGradeExamsView> createState() => _TeacherGradeExamsViewState();
}

class _TeacherGradeExamsViewState extends State<TeacherGradeExamsView> {
  // ── Filters ────────────────────────────────────────────────────
  String _selectedExam = '';
  String _selectedStatus = 'pending';
  int _page = 1;
  static const int _limit = 20;

  // ── Data ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> _stats = [];
  List<Map<String, dynamic>> _attempts = [];
  int _totalPages = 1;
  bool _loadingList = false;
  bool _loadingStats = false;

  TeacherRepository get _repo => context.read<TeacherRepository>();

  // ── Derived ─────────────────────────────────────────────────────
  int get _totalPending =>
      _stats.fold(0, (sum, s) => sum + ((s['pending'] ?? 0) as int));
  int get _totalGraded =>
      _stats.fold(0, (sum, s) => sum + ((s['graded'] ?? 0) as int));
  int get _totalExams => _stats.length;
  int get _totalAttempts =>
      _stats.fold(0, (sum, s) => sum + ((s['submitted'] ?? 0) as int));

  List<Map<String, dynamic>> get _examOptions =>
      _stats.map((s) => {'id': s['examId'], 'title': s['title']}).toList();

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchAttempts();
  }

  // ── Data fetching ───────────────────────────────────────────────
  Future<void> _fetchStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _repo.getAttemptStats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
    if (mounted) setState(() => _loadingStats = false);
  }

  Future<void> _fetchAttempts() async {
    setState(() => _loadingList = true);
    try {
      final result = await _repo.getAttempts(
        page: _page,
        limit: _limit,
        examId: _selectedExam.isNotEmpty ? _selectedExam : null,
        status: _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _attempts = (result['attempts'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          _totalPages = (result['pagination'] as Map<String, dynamic>?)
                  ?.let((p) => (p['totalPages'] as int?) ?? 1) ??
              1;
          _loadingList = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  void _reload() {
    _fetchStats();
    _fetchAttempts();
  }

  // ── Tab change ──────────────────────────────────────────────────
  void _handleTabChange(int index) {
    setState(() {
      _selectedStatus = index == 0 ? 'pending' : 'graded';
      _page = 1;
    });
    _fetchAttempts();
  }

  // ── Auto-grade ──────────────────────────────────────────────────
  Future<void> _handleAutoGrade(String attemptId) async {
    try {
      await _repo.autoGradeAttempt(attemptId);
      _reload();
    } catch (_) {
      if (mounted) _showError('فشل التصحيح التلقائي');
    }
  }

  // ── View attempt dialog ─────────────────────────────────────────
  Future<void> _handleOpenView(String attemptId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AttemptDetailDialog(
        repo: _repo,
        attemptId: attemptId,
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────
  void _showError(String msg) {
    buildSnackBar(context, msg, isError: true);
  }

  String _getStudentName(Map<String, dynamic> a) =>
      (a['student'] as Map?)?['user']?['name'] ?? '—';
  String _getStudentAvatar(Map<String, dynamic> a) {
    final name = _getStudentName(a);
    return name.isNotEmpty ? name[0] : '؟';
  }

  String _getExamTitle(Map<String, dynamic> a) =>
      (a['exam'] as Map?)?['title'] ?? '—';
  String _getScore(Map<String, dynamic> a) {
    final score = a['score'];
    final totalMarks = (a['exam'] as Map?)?['totalMarks'];
    return score != null ? '$score/$totalMarks' : '—';
  }

  String _getDate(Map<String, dynamic> a) {
    final submittedAt = a['submittedAt'] as String?;
    if (submittedAt == null) return '—';
    try {
      if (submittedAt.length >= 16) {
        return submittedAt.substring(0, 16).replaceAll('T', ' ');
      }
      return submittedAt;
    } catch (_) {
      return '—';
    }
  }

  int _getPercentage(Map<String, dynamic> a) {
    final score = (a['score'] as num?)?.toDouble() ?? 0;
    final totalMarks = (a['exam'] as Map?)?['totalMarks'] as num?;
    if (totalMarks == null || totalMarks == 0) return 0;
    return ((score / totalMarks) * 100).round();
  }

  // ── Theme ───────────────────────────────────────────────────────
  Color _fieldBorder() =>
      context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  Color _fieldText() =>
      context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
  Color _fieldLabel() =>
      context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  Color _cardBg() =>
      context.isDark ? const Color(0xFF1E293B) : Colors.white;
  Color _bgColor() =>
      context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('مراجعة الاختبارات',
            style: TextStyles.semiBold16.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats cards + chart
          _buildStatsSection(),
          // Tabs
          _buildTabs(),
          // List / Table
          Expanded(child: _buildAttemptsList()),
        ],
      ),
    );
  }

  // ── Stats section ───────────────────────────────────────────────
  Widget _buildStatsSection() {
    final isDark = context.isDark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _cardBg(),
        border: Border(bottom: BorderSide(color: _fieldBorder())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'قيد التصحيح',
                  _totalPending,
                  Icons.hourglass_empty,
                  const Color(0xFFF59E0B),
                  isDark,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildStatCard(
                  'تم التصحيح',
                  _totalGraded,
                  Icons.check_circle,
                  const Color(0xFF10B981),
                  isDark,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildStatCard(
                  'الاختبارات',
                  _totalExams,
                  Icons.assignment,
                  const Color(0xFF3B82F6),
                  isDark,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildStatCard(
                  'إجمالي المحاولات',
                  _totalAttempts,
                  Icons.people,
                  const Color(0xFF8B5CF6),
                  isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Bar chart (simple visual)
          _buildMiniChart(isDark),
          SizedBox(height: 12.h),
          // Exam filter
          _buildExamFilter(isDark),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(height: 4.h),
          _loadingStats
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Text('$value',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    color: color,
                  )),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.sp,
                fontFamily: 'Cairo',
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              )),
        ],
      ),
    );
  }

  Widget _buildMiniChart(bool isDark) {
    final total = _totalPending + _totalGraded;
    if (total == 0) return const SizedBox.shrink();
    final pendingRatio = _totalPending / total;

    return Container(
      height: 24.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: const Color(0xFF10B981).withValues(alpha: 0.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (pendingRatio > 0)
            Container(
              width: (1.sw - 64.w) * pendingRatio,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExamFilter(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _fieldBorder()),
        color: _bgColor(),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedExam.isNotEmpty ? _selectedExam : null,
          isExpanded: true,
          hint: Text('جميع الاختبارات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                color: _fieldLabel(),
              )),
          dropdownColor: _cardBg(),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.sp,
            color: _fieldText(),
          ),
          items: [
            DropdownMenuItem(
                value: '',
                child: Text('جميع الاختبارات',
                    style: TextStyle(
                        fontFamily: 'Cairo', color: _fieldLabel()))),
            ..._examOptions.map((e) {
              final id = (e['id'] ?? '') as String;
              final title = (e['title'] ?? '') as String;
              return DropdownMenuItem(value: id, child: Text(title));
            }),
          ],
          onChanged: (v) {
            setState(() {
              _selectedExam = v ?? '';
              _page = 1;
            });
            _fetchAttempts();
          },
        ),
      ),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────
  Widget _buildTabs() {
    final isDark = context.isDark;
    final tabIndex = _selectedStatus == 'pending' ? 0 : 1;
    return Container(
      decoration: BoxDecoration(
        color: _cardBg(),
        border: Border(bottom: BorderSide(color: _fieldBorder())),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'قيد التصحيح ($_totalPending)',
              tabIndex == 0,
              isDark,
              () => _handleTabChange(0),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'تم التصحيح ($_totalGraded)',
              tabIndex == 1,
              isDark,
              () => _handleTabChange(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool active, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF3B82F6) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: active
                ? const Color(0xFF3B82F6)
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  // ── Attempts list ──────────────────────────────────────────────
  Widget _buildAttemptsList() {
    if (_loadingList) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment,
                size: 48,
                color: _fieldLabel()),
            SizedBox(height: 12.h),
            Text('لا توجد بيانات لعرضها حالياً',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  color: _fieldLabel(),
                )),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: _attempts.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final attempt = _attempts[index];
              return _buildAttemptCard(attempt);
            },
          ),
        ),
        // Pagination
        if (_totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _buildAttemptCard(Map<String, dynamic> attempt) {
    final isPending = _selectedStatus == 'pending';
    final percentage = _getPercentage(attempt);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isPending
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF8B5CF6),
                  child: Text(
                    _getStudentAvatar(attempt),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getStudentName(attempt),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            color: _fieldText(),
                          )),
                      Text(_getExamTitle(attempt),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.sp,
                            color: _fieldLabel(),
                          )),
                    ],
                  ),
                ),
                if (!isPending)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: percentage >= 70
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _getScore(attempt),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        color:
                            percentage >= 70 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 12, color: _fieldLabel()),
                SizedBox(width: 4.w),
                Text(_getDate(attempt),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.sp,
                      color: _fieldLabel(),
                    )),
                const Spacer(),
                if (isPending)
                  SizedBox(
                    height: 32.h,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAutoGrade(attempt['id']),
                      icon: const Icon(Icons.auto_fix_high, size: 14),
                      label: Text('تصحيح تلقائي',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 32.h,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _handleOpenView(attempt['id']),
                      icon: const Icon(Icons.visibility, size: 14),
                      label: Text('عرض',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: EdgeInsets.all(12.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _page > 1
                ? () {
                    setState(() => _page--);
                    _fetchAttempts();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
          Text('$_page / $_totalPages',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                color: _fieldText(),
              )),
          IconButton(
            onPressed: _page < _totalPages
                ? () {
                    setState(() => _page++);
                    _fetchAttempts();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
    );
  }

}

class _AttemptDetailDialog extends StatefulWidget {
  final TeacherRepository repo;
  final String attemptId;
  const _AttemptDetailDialog({required this.repo, required this.attemptId});

  @override
  State<_AttemptDetailDialog> createState() => _AttemptDetailDialogState();
}

class _AttemptDetailDialogState extends State<_AttemptDetailDialog> {
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

  // ── Theme ───────────────────────────────────────────────────────
  Color _fieldBorder() =>
      context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  Color _fieldText() =>
      context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
  Color _fieldLabel() =>
      context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  Color _cardBg() =>
      context.isDark ? const Color(0xFF1E293B) : Colors.white;

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
          color: _cardBg(),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _fieldBorder())),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _attempt != null
                          ? '${_getStudentName(_attempt!)} — ${_getExamTitle(_attempt!)}'
                          : 'تفاصيل المحاولة',
                      style:
                          TextStyles.semiBold16.copyWith(color: _fieldText()),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: _fieldLabel()),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _attempt == null
                      ? Center(
                          child: Text('تعذّر تحميل تفاصيل المحاولة',
                              style: TextStyle(
                                  fontFamily: 'Cairo', color: _fieldLabel())))
                      : _buildDetail(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail() {
    final attempt = _attempt!;
    final exam = attempt['exam'] as Map<String, dynamic>? ?? {};
    final questions =
        (exam['questions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
    final answers = attempt['answers'] as Map<String, dynamic>? ?? {};
    final isPassed = attempt['isPassed'] == true;
    final score = attempt['score'];
    final totalMarks = exam['totalMarks'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _chip('الدرجة: $score / $totalMarks',
                  isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              _chip(isPassed ? 'ناجح' : 'راسب',
                  isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            ],
          ),
          SizedBox(height: 16.h),
          if (questions.isEmpty)
            Center(
              child: Text('لا توجد أسئلة مرتبطة بهذا الاختبار',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      color: _fieldLabel())),
            )
          else
            ...questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              final qId = (q['id'] ?? q['_id'] ?? '') as String;
              final studentAnswer = answers[qId];
              final correctAnswer = q['correctAnswer'];
              final isCorrect =
                  studentAnswer != null && studentAnswer == correctAnswer;
              final qText = (q['text'] ?? q['questionText'] ?? '') as String;

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: _fieldBorder()),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('سؤال ${i + 1}: $qText',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          color: _fieldText(),
                        )),
                    SizedBox(height: 8.h),
                    if ((q['type'] == 'mcq' || q['type'] == 'multiple_choice') &&
                        q['options'] is List)
                      ...((q['options'] as List).map((opt) {
                        final optStr = opt.toString();
                        final isCorrectOpt =
                            optStr == correctAnswer?.toString();
                        final isStudentOpt =
                            optStr == studentAnswer?.toString();
                        return Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Text('• $optStr',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12.sp,
                                color: isCorrectOpt
                                    ? const Color(0xFF10B981)
                                    : _fieldText(),
                                fontWeight: isStudentOpt
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                decoration: isStudentOpt
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              )),
                        );
                      })),
                    if (q['type'] == 'true-false') ...[
                      Text('إجابة الطالب: ${studentAnswer ?? "لم يجب"}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: _fieldLabel(),
                          )),
                      Text('الإجابة الصحيحة: $correctAnswer',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: const Color(0xFF10B981),
                          )),
                    ],
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text('الدرجة: ${q['marks'] ?? '?'}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.sp,
                              color: _fieldLabel(),
                            )),
                        SizedBox(width: 8.w),
                        _chip(isCorrect ? 'صح' : 'خطأ',
                            isCorrect
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          SizedBox(height: 16.h),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('إغلاق'),
              style: TextButton.styleFrom(foregroundColor: _fieldLabel()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: color,
          )),
    );
  }
}

extension _MapExtension on Map<String, dynamic> {
  T? let<T>(T Function(Map<String, dynamic>) f) => f(this);
}
