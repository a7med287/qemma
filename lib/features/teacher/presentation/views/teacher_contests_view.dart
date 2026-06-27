import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import 'add_contest_questions_view.dart';

class TeacherContestsView extends StatefulWidget {
  static const routeName = '/teacher/contests';
  const TeacherContestsView({super.key});

  @override
  State<TeacherContestsView> createState() => _TeacherContestsViewState();
}

class _TeacherContestsViewState extends State<TeacherContestsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<TeacherContestItem> _assigned = [];
  List<TeacherContestItem> _past = [];
  bool _assignedLoading = true;
  bool _pastLoading = true;
  String? _assignedError;
  String? _pastError;

  static const _streamLabels = {
    'Literary': 'أدبي',
    'Science-Maths': 'علمي رياضة',
    'Science-Biology': 'علمي علوم',
    'general': 'عام',
    'science': 'علوم',
  };

  static const _difficultyColors = {
    'Easy': Color(0xFF059669),
    'Medium': Color(0xFFF59E0B),
    'Hard': Color(0xFFDC2626),
  };

  static const _difficultyBgColors = {
    'Easy': Color(0xFFDCFCE7),
    'Medium': Color(0xFFFEF3C7),
    'Hard': Color(0xFFFEE2E2),
  };

  static const _difficultyTextColors = {
    'Easy': Color(0xFF166534),
    'Medium': Color(0xFF92400E),
    'Hard': Color(0xFF991B1B),
  };

  static const _difficultyLabels = {
    'Easy': 'سهل',
    'Medium': 'متوسط',
    'Hard': 'صعب',
  };

  static const _requiredQuestions = {'Easy': 10, 'Medium': 30, 'Hard': 50};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAssigned();
    _fetchPast();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TeacherRepository get _repo => context.read<TeacherRepository>();

  Future<void> _fetchAssigned() async {
    setState(() { _assignedLoading = true; _assignedError = null; });
    try {
      final data = await _repo.getTeacherContests();
      if (mounted) setState(() { _assigned = data; _assignedLoading = false; });
    } on Failure catch (e) {
      if (mounted) setState(() { _assignedError = e.message; _assignedLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _assignedError = 'فشل تحميل المسابقات'; _assignedLoading = false; });
    }
  }

  Future<void> _fetchPast() async {
    setState(() { _pastLoading = true; _pastError = null; });
    try {
      final data = await _repo.getTeacherPastContests();
      if (mounted) setState(() { _past = data; _pastLoading = false; });
    } on Failure catch (e) {
      if (mounted) setState(() { _pastError = e.message; _pastLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _pastError = 'فشل تحميل المسابقات السابقة'; _pastLoading = false; });
    }
  }

  Color _diffColor(String d) => _difficultyColors[d] ?? const Color(0xFFF59E0B);
  Color _diffBg(String d) => _difficultyBgColors[d] ?? const Color(0xFFFEF3C7);
  Color _diffTextColor(String d) => _difficultyTextColors[d] ?? const Color(0xFF92400E);
  String _diffLabel(String d) => _difficultyLabels[d] ?? d;
  String _streamLabel(String s) => _streamLabels[s] ?? s;

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.year}/${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  ({bool disabled, String reason}) _addQuestionState(TeacherContestItem c) {
    final now = DateTime.now();
    final start = DateTime.tryParse(c.startTime);
    final maxQ = _requiredQuestions[c.difficulty] ?? 0;
    final currentQ = c.questionCount;
    final maxReached = maxQ > 0 && currentQ >= maxQ;
    final started = start != null && now.isAfter(start);
    final within60 = start != null && !started && start.difference(now).inMinutes <= 60;
    final timeBlocked = c.isTest ? false : (started || within60);
    final disabled = maxReached || timeBlocked;
    String reason = '';
    if (maxReached) reason = 'المسابقة وصلت إلى الحد الأقصى من الأسئلة';
    else if (timeBlocked) reason = 'المسابقة قد بدأت أو تبقى أقل من 60 دقيقة على بدئها';
    return (disabled: disabled, reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(isDark),
          _buildTabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssignedTab(isDark),
                _buildPastTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      ),
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 20.h),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .15)),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text('🏆 إدارة المسابقات الذهبية',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 20.sp, color: Colors.white)),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text('الصف الثالث الثانوي • أضف أسئلة وتابع المسابقات السابقة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.white70)),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: ['علمي رياضة', 'علمي علوم', 'أدبي']
                  .map((s) => Chip(
                        label: Text(s, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 10)),
                        backgroundColor: Colors.white24,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF2563EB),
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14),
        tabs: [
          Tab(text: 'مسابقاتي المخصصة (${_assigned.length})'),
          Tab(text: 'مسابقاتي السابقة (${_past.length})'),
        ],
      ),
    );
  }

  Widget _buildAssignedTab(bool isDark) {
    if (_assignedLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_assignedError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_assignedError!, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: context.textSecondary), textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton(onPressed: _fetchAssigned, child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo'))),
          ],
        ),
      );
    }
    if (_assigned.isEmpty) {
      return _emptyState('لا توجد مسابقات مخصصة', isDark);
    }
    return RefreshIndicator(
      onRefresh: () async { await Future.wait([_fetchAssigned(), _fetchPast()]); },
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: _assigned.length,
        itemBuilder: (_, i) => _buildAssignedCard(_assigned[i], isDark),
      ),
    );
  }

  Widget _buildPastTab(bool isDark) {
    if (_pastLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pastError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_pastError!, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: context.textSecondary), textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton(onPressed: _fetchPast, child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo'))),
          ],
        ),
      );
    }
    if (_past.isEmpty) {
      return _emptyState('لا توجد مسابقات سابقة', isDark);
    }
    return RefreshIndicator(
      onRefresh: () async { await Future.wait([_fetchAssigned(), _fetchPast()]); },
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: _past.length,
        itemBuilder: (_, i) => _buildPastCard(_past[i], isDark),
      ),
    );
  }

  Widget _emptyState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 64.r, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          SizedBox(height: 12.h),
          Text(message,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: context.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAssignedCard(TeacherContestItem c, bool isDark) {
    final color = _diffColor(c.difficulty);
    final bg = _diffBg(c.difficulty);
    final textColor = _diffTextColor(c.difficulty);
    final addState = _addQuestionState(c);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 6.h, color: color),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title,
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 15.sp, color: context.textPrimary)),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w, runSpacing: 6.h,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: isDark ? bg.withValues(alpha: 0.2) : bg,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(_diffLabel(c.difficulty),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w800, color: textColor)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(_streamLabel(c.stream),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school, size: 12.r, color: const Color(0xFFF59E0B)),
                          SizedBox(width: 4.w),
                          Text('الصف الثالث الثانوي',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, fontWeight: FontWeight.w800, color: const Color(0xFFF59E0B))),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(_formatDate(c.startTime),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, fontWeight: FontWeight.w600, color: context.textPrimary)),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  children: [
                    _outlinedChip('${c.questionCount} سؤال', isDark),
                    _outlinedChip('${c.duration} دقيقة', isDark),
                  ],
                ),
                SizedBox(height: 12.h),
                if (c.canManage)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: addState.disabled
                          ? () => buildSnackBar(context, addState.reason, isError: true)
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddContestQuestionsView(contestId: c.id),
                              )).then((_) { _fetchAssigned(); _fetchPast(); }),
                      icon: Icon(Icons.add, size: 18),
                      label: Text('إضافة سؤال', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: addState.disabled
                            ? (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))
                            : color,
                        foregroundColor: addState.disabled
                            ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                            : Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastCard(TeacherContestItem c, bool isDark) {
    final color = _diffColor(c.difficulty);
    final bg = _diffBg(c.difficulty);
    final textColor = _diffTextColor(c.difficulty);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 6.h, color: color),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title,
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 15.sp, color: context.textPrimary)),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w, runSpacing: 6.h,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: isDark ? bg.withValues(alpha: 0.2) : bg,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(_diffLabel(c.difficulty),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w800, color: textColor)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(_streamLabel(c.stream),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF059669).withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text('مكتملة',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _statBox(Icons.people_outline, '${c.participationCount}', 'مشارك', isDark),
                    SizedBox(width: 8.w),
                    _statBox(Icons.quiz_outlined, '${c.questionCount}', 'الأسئلة', isDark),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(_formatDate(c.startTime),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlinedChip(String label, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB)),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
    );
  }

  Widget _statBox(IconData icon, String value, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20.sp, color: const Color(0xFF2563EB)),
            SizedBox(height: 4.h),
            Text(value, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14.sp, color: context.textPrimary)),
            Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}
