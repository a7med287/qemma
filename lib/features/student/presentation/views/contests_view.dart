import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../widgets/student_shared_widgets.dart';

class ContestsView extends StatefulWidget {
  const ContestsView({super.key});

  @override
  State<ContestsView> createState() => _ContestsViewState();
}

class _ContestsViewState extends State<ContestsView> {
  int _tab = 0;

  List<ContestItem> _upcoming = [];
  bool _upcomingLoading = true;
  String? _upcomingError;

  List<ContestHistoryItem> _past = [];
  bool _pastLoading = true;
  String? _pastError;

  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  static const _streamLabels = {
    'Literary': 'أدبي',
    'Science-Maths': 'علمي رياضة',
    'Science-Biology': 'علمي علوم',
  };

  @override
  void initState() {
    super.initState();
    _loadUpcoming();
    _loadPast();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _streamLabel(String s) => _streamLabels[s] ?? s;

  Future<void> _loadUpcoming() async {
    setState(() { _upcomingLoading = true; _upcomingError = null; });
    try {
      final data = await context.read<StudentRepository>().getAvailableContests();
      if (mounted) setState(() { _upcoming = data; _upcomingLoading = false; });
    } on Failure catch (e) {
      if (mounted) setState(() { _upcomingError = e.message; _upcomingLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _upcomingError = 'فشل تحميل المسابقات'; _upcomingLoading = false; });
    }
  }

  Future<void> _loadPast() async {
    setState(() { _pastLoading = true; _pastError = null; });
    try {
      final data = await context.read<StudentRepository>().getContestHistory();
      if (mounted) setState(() { _past = data; _pastLoading = false; });
    } on Failure catch (e) {
      if (mounted) setState(() { _pastError = e.message; _pastLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _pastError = 'فشل تحميل المسابقات السابقة'; _pastLoading = false; });
    }
  }

  Color _difficultyColor(String d) => switch (d) {
        'easy' => Colors.green,
        'hard' => Colors.red,
        _ => Colors.orange,
      };

  String _difficultyLabel(String d) => switch (d) {
        'easy' => 'سهل',
        'hard' => 'صعب',
        _ => 'متوسط',
      };

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '$h ساعة $m دقيقة';
    if (h > 0) return '$h ساعة';
    return '$m دقيقة';
  }

  String _getTimeUntil(DateTime date) {
    final diff = date.difference(_now);
    if (diff.isNegative) return 'انتهت';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return '$days يوم${hours > 0 ? ' $hours ساعة' : ''}';
    if (hours > 0) return '$hours ساعة';
    return '$minutes دقيقة';
  }

  String _formatDateTime(String startTime) {
    try {
      final dt = DateTime.parse(startTime);
      final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}، ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      if (startTime.length >= 16) return startTime.substring(0, 16);
      return startTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentPageShell(
      title: '🎯 جميع المسابقات الذهبية',
      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      headerChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الصف الثالث الثانوي • اكتشف المسابقات القادمة والسابقة',
              style: TextStyles.regular13.copyWith(color: Colors.white70)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 4.h,
            children: ['علمي رياضة', 'علمي علوم', 'أدبي']
                .map((s) => Chip(
                    label: Text(s, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: .3),
                    side: BorderSide(color: const Color(0xFFFCD34D).withValues(alpha: .5)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact))
                .toList(),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Builder(builder: (context) {
          final tabBar = TabBar(
            onTap: (i) => setState(() => _tab = i),
            tabs: [
              Tab(text: 'المسابقات القادمة (${_upcoming.length})'),
              Tab(text: 'المسابقات السابقة (${_past.length})'),
            ],
            indicatorColor: const Color(0xFFF59E0B),
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: context.textSecondary,
            labelStyle: TextStyles.semiBold14,
            unselectedLabelStyle: TextStyles.semiBold14,
          );
          return Column(
            children: [
              tabBar,
              Expanded(child: _tab == 0 ? _buildUpcoming() : _buildPast()),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildUpcoming() {
    if (_upcomingLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_upcomingError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_upcomingError!, style: TextStyles.regular14, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton(onPressed: _loadUpcoming, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (_upcoming.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📅', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 12.h),
            Text('لا توجد مسابقات قادمة', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
            Text('تابع لاحقاً لمعرفة المسابقات الجديدة', style: TextStyles.regular14.copyWith(color: context.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadUpcoming,
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: _upcoming.length,
        itemBuilder: (_, i) => _buildUpcomingCard(_upcoming[i]),
      ),
    );
  }

  Widget _buildPast() {
    if (_pastLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pastError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_pastError!, style: TextStyles.regular14, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton(onPressed: _loadPast, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (_past.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✅', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 12.h),
            Text('لا توجد مسابقات سابقة', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
            Text('لم تشارك في أي مسابقات بعد', style: TextStyles.regular14.copyWith(color: context.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPast,
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: _past.length,
        itemBuilder: (_, i) => _buildPastCard(_past[i]),
      ),
    );
  }

  Widget _buildUpcomingCard(ContestItem c) {
    final color = _difficultyColor(c.difficulty);
    final startDt = DateTime.tryParse(c.startTime);
    final isFuture = startDt != null && startDt.isAfter(_now);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 6.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: .7)]),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(c.title, style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                    ),
                    if (c.aiGenerated)
                      Chip(
                        label: Text('AI', style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo')),
                        backgroundColor: const Color(0xFFF5F3FF),
                        labelStyle: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: [
                    Chip(
                      label: Text(_difficultyLabel(c.difficulty)),
                      backgroundColor: color.withValues(alpha: .15),
                      labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    if (c.stream.isNotEmpty)
                      Chip(
                        label: Text(_streamLabel(c.stream)),
                        backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    Chip(
                      label: Text('الصف الثالث'),
                      backgroundColor: const Color(0xFFF59E0B).withValues(alpha: .15),
                      labelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _detailRow(Icons.calendar_today, _formatDateTime(c.startTime)),
                SizedBox(height: 4.h),
                _detailRow(Icons.timer, _formatDuration(c.duration)),
                SizedBox(height: 4.h),
                _detailRow(Icons.people, '${c.participants} مشارك'),
                SizedBox(height: 4.h),
                _detailRow(Icons.emoji_events, '${c.questionCount} أسئلة'),
                if (isFuture) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: .25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⏰ تبدأ خلال', style: TextStyles.regular13.copyWith(color: const Color(0xFF2563EB))),
                        Text(_getTimeUntil(startDt), style: TextStyles.bold18.copyWith(color: const Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                _buildActionButton(c, isFuture, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastCard(ContestHistoryItem c) {
    final color = _difficultyColor(c.difficulty);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 6.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: .7)]),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.contestName, style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: [
                    Chip(
                      label: Text(_difficultyLabel(c.difficulty)),
                      backgroundColor: color.withValues(alpha: .15),
                      labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    Chip(
                      label: Text(c.date),
                      backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(fontSize: 11.sp),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                _detailRow(Icons.emoji_events, 'الترتيب: ${c.rank != null ? '#${c.rank}' : '—'} من ${c.totalParticipants}'),
                SizedBox(height: 4.h),
                _detailRow(Icons.star, 'النقاط: ${c.score ?? '—'}'),
                SizedBox(height: 4.h),
                _detailRow(Icons.check_circle, 'المحلولة: ${c.solvedProblems}/${c.totalProblems}'),
                SizedBox(height: 4.h),
                _detailRow(Icons.timer, 'المدة: ${c.duration}'),
                if (c.ratingChange != null) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        c.ratingChange! > 0 ? Icons.trending_up : Icons.trending_down,
                        color: c.ratingChange! > 0 ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${c.ratingChange! > 0 ? '+' : ''}${c.ratingChange}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: c.ratingChange! > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text('التقييم الجديد: ${c.newRating}', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: context.textSecondary),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(text, style: TextStyles.regular13.copyWith(color: context.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildActionButton(ContestItem c, bool isFuture, Color color) {
    if (c.hasSubmitted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
            disabledBackgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
            disabledForegroundColor: context.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            minimumSize: Size(double.infinity, 40.h),
          ),
          child: Text('✅ تم التسليم', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
        ),
      );
    }

    if (!c.eligible) return const SizedBox.shrink();

    final hasNoQuestions = c.questionCount == 0;
    final startDisabled = isFuture || hasNoQuestions;
    final startReason = isFuture
        ? 'المسابقة لم تبدأ بعد'
        : 'المسابقة لا تحتوي على أسئلة';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: startDisabled
            ? () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('المسابقة غير متاحة'),
                  content: Text(startReason),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('حسناً'),
                    ),
                  ],
                ),
              )
            : () => Navigator.pushNamed(context, '/student/contests/${c.id}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: startDisabled ? null : color,
          foregroundColor: startDisabled ? null : Colors.white,
          disabledBackgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          disabledForegroundColor: context.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          minimumSize: Size(double.infinity, 40.h),
        ),
        child: Text(
          '🚀 بدء المسابقة',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp),
        ),
      ),
    );
  }

}
