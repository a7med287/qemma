import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';
import 'widgets/teacher_grade_student_list.dart';
import 'widgets/teacher_grade_dialogs.dart';

class TeacherGradeExamsView extends StatefulWidget {
  static const routeName = '/teacher/grade-exams';
  const TeacherGradeExamsView({super.key});

  @override
  State<TeacherGradeExamsView> createState() => _TeacherGradeExamsViewState();
}

class _TeacherGradeExamsViewState extends State<TeacherGradeExamsView> {
  String _selectedExam = '';
  String _selectedStatus = 'pending';
  int _page = 1;
  static const int _limit = 20;

  List<Map<String, dynamic>> _stats = [];
  List<Map<String, dynamic>> _attempts = [];
  int _totalPages = 1;
  bool _loadingList = false;
  bool _loadingStats = false;

  TeacherRepository get _repo => context.read<TeacherRepository>();

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
        page: _page, limit: _limit,
        examId: _selectedExam.isNotEmpty ? _selectedExam : null,
        status: _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _attempts = (result['attempts'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ?? [];
          final pagination = result['pagination'] as Map<String, dynamic>?;
          _totalPages = pagination != null
              ? (pagination['totalPages'] as int? ?? 1)
              : 1;
          _loadingList = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _reload() async { _fetchStats(); _fetchAttempts(); }

  void _handleTabChange(int index) {
    setState(() { _selectedStatus = index == 0 ? 'pending' : 'graded'; _page = 1; });
    _fetchAttempts();
  }

  Future<void> _handleAutoGrade(String attemptId) async {
    try {
      await _repo.autoGradeAttempt(attemptId);
      _reload();
    } catch (_) {
      if (mounted) buildSnackBar(context, 'فشل التصحيح التلقائي', isError: true);
    }
  }

  Future<void> _handleOpenView(String attemptId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TeacherGradeDetailDialog(repo: _repo, attemptId: attemptId),
    );
  }

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
      ),
      body: Column(
        children: [
          _buildStatsSection(),
          _buildTabs(),
          Expanded(child: TeacherGradeStudentList(
            attempts: _attempts,
            isPending: _selectedStatus == 'pending',
            loading: _loadingList,
            onRefresh: _reload,
            onAutoGrade: _handleAutoGrade,
            onView: _handleOpenView,
            page: _page,
            totalPages: _totalPages,
            onPreviousPage: () { setState(() => _page--); _fetchAttempts(); },
            onNextPage: () { setState(() => _page++); _fetchAttempts(); },
          )),
        ],
      ),
    );
  }

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
              Expanded(child: _buildStatCard('قيد التصحيح', _totalPending, Icons.hourglass_empty, const Color(0xFFF59E0B), isDark)),
              SizedBox(width: 8.w),
              Expanded(child: _buildStatCard('تم التصحيح', _totalGraded, Icons.check_circle, const Color(0xFF10B981), isDark)),
              SizedBox(width: 8.w),
              Expanded(child: _buildStatCard('الاختبارات', _totalExams, Icons.assignment, const Color(0xFF3B82F6), isDark)),
              SizedBox(width: 8.w),
              Expanded(child: _buildStatCard('إجمالي المحاولات', _totalAttempts, Icons.people, const Color(0xFF8B5CF6), isDark)),
            ],
          ),
          SizedBox(height: 12.h),
          _buildMiniChart(isDark),
          SizedBox(height: 12.h),
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
              ? SizedBox(width: 16.w, height: 16.w, child: CircularProgressIndicator(strokeWidth: 2, color: color))
              : Text('$value', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: color)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8.sp, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
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
              decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
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
          hint: Text('جميع الاختبارات', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: _fieldLabel())),
          dropdownColor: _cardBg(),
          style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: _fieldText()),
          items: [
            DropdownMenuItem(value: '', child: Text('جميع الاختبارات', style: TextStyle(fontFamily: 'Cairo', color: _fieldLabel()))),
            ..._examOptions.map((e) {
              final id = (e['id'] ?? '') as String;
              final title = (e['title'] ?? '') as String;
              return DropdownMenuItem(value: id, child: Text(title));
            }),
          ],
          onChanged: (v) {
            setState(() { _selectedExam = v ?? ''; _page = 1; });
            _fetchAttempts();
          },
        ),
      ),
    );
  }

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
          Expanded(child: _buildTabButton('قيد التصحيح ($_totalPending)', tabIndex == 0, isDark, () => _handleTabChange(0))),
          Expanded(child: _buildTabButton('تم التصحيح ($_totalGraded)', tabIndex == 1, isDark, () => _handleTabChange(1))),
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
          border: Border(bottom: BorderSide(color: active ? const Color(0xFF3B82F6) : Colors.transparent, width: 3)),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold,
                color: active ? const Color(0xFF3B82F6) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))),
      ),
    );
  }
}
