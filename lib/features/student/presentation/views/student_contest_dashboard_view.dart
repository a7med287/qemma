import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../widgets/student_shared_widgets.dart';

class _RatingInfo {
  final Color color;
  final String rank;
  const _RatingInfo({required this.color, required this.rank});
}

_RatingInfo _getRatingColor(int rating) {
  if (rating < 1000) return const _RatingInfo(color: Color(0xFF9CA3AF), rank: 'مبتدئ');
  if (rating < 1400) return const _RatingInfo(color: Color(0xFF06B6D4), rank: 'مبتدئ متقدم');
  if (rating < 1700) return const _RatingInfo(color: Color(0xFF3B82F6), rank: 'كفء');
  if (rating < 2000) return const _RatingInfo(color: Color(0xFF8B5CF6), rank: 'متقدم');
  if (rating < 2400) return const _RatingInfo(color: Color(0xFFF97316), rank: 'خبير');
  return const _RatingInfo(color: Color(0xFFEF4444), rank: 'خبير دولي');
}

class StudentContestDashboardView extends StatefulWidget {
  const StudentContestDashboardView({super.key});

  @override
  State<StudentContestDashboardView> createState() => _StudentContestDashboardViewState();
}

class _StudentContestDashboardViewState extends State<StudentContestDashboardView> {
  ContestHistoryItem? _selected;
  ContestDashboardData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await context.read<StudentRepository>().getContestDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } on Failure catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'فشل تحميل لوحة المسابقات'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return StudentPageShell(
        title: '🏆 لوحة المسابقات',
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return StudentPageShell(
        title: '🏆 لوحة المسابقات',
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: TextStyles.regular14, textAlign: TextAlign.center),
              SizedBox(height: 16.h),
              ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    if (_selected != null) return _buildDetail(context, _selected!);

    final data = _data!;
    final history = data.contests;
    final rating = data.ratingHistory;
    final ratingInfo = _getRatingColor(data.currentRating);

    return StudentPageShell(
      title: '🏆 لوحة المسابقات',
      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      headerChild: Wrap(
        spacing: 8.w,
        children: ['علمي رياضة', 'علمي علوم', 'أدبي']
            .map((s) => Chip(label: Text(s), backgroundColor: Colors.white24, labelStyle: const TextStyle(color: Colors.white)))
            .toList(),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            StudentGlassCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40.r,
                    backgroundColor: ratingInfo.color.withValues(alpha: .2),
                    child: Text('${data.currentRating}',
                        style: TextStyles.bold20.copyWith(color: ratingInfo.color)),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('التقييم الحالي', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                        SizedBox(height: 4.h),
                        Chip(
                          label: Text(ratingInfo.rank),
                          backgroundColor: ratingInfo.color,
                          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        SizedBox(height: 4.h),
                        Text('أفضل ترتيب #${data.stats.bestRank}', style: TextStyles.regular14.copyWith(color: context.textSecondary)),
                        if (history.isNotEmpty && history.first.ratingChange != null)
                          Row(
                            children: [
                              Icon(
                                history.first.ratingChange! > 0 ? Icons.trending_up : Icons.trending_down,
                                size: 16,
                                color: history.first.ratingChange! > 0 ? Colors.green : Colors.red,
                              ),
                              SizedBox(width: 4.w),
                              Text('${history.first.ratingChange! > 0 ? '+' : ''}${history.first.ratingChange} من آخر مسابقة',
                                  style: TextStyles.regular13.copyWith(
                                    color: history.first.ratingChange! > 0 ? Colors.green : Colors.red,
                                  )),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.emoji_events, size: 48.sp, color: ratingInfo.color.withValues(alpha: .3)),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            StudentGlassCard(
              title: '📈 منحنى التقييم',
              child: SizedBox(
                height: 200.h,
                child: rating.isEmpty
                    ? Center(child: Text('لا توجد بيانات كافية', style: TextStyles.regular14))
                    : LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(rating.length,
                                (i) => FlSpot(i.toDouble(), rating[i].rating.toDouble())),
                        color: ratingInfo.color,
                        isCurved: true,
                        belowBarData: BarAreaData(
                            show: true, color: ratingInfo.color.withValues(alpha: .1)),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28.h,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= rating.length) return const SizedBox.shrink();
                            return Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Text(
                                rating[i].contestName.length > 6
                                    ? '${rating[i].contestName.substring(0, 6)}..'
                                    : rating[i].contestName,
                                style: TextStyle(fontSize: 8.sp, color: context.textSecondary),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: context.borderColor,
                        strokeWidth: 0.5,
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final i = spot.spotIndex;
                            final name = i < rating.length ? rating[i].contestName : '';
                            return LineTooltipItem(
                              '$name\nالتقييم: ${spot.y.toInt()}',
                              TextStyle(color: ratingInfo.color, fontWeight: FontWeight.bold, fontSize: 12.sp, fontFamily: 'Cairo'),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _statCard('${data.stats.totalContests}', 'مسابقة ذهبية'),
                _statCard('${data.stats.totalSolved}', 'مسألة محلولة'),
                _statCard('#${data.stats.avgRank}', 'متوسط الترتيب'),
                _statCard('#${data.stats.bestRank}', 'أفضل ترتيب'),
              ],
            ),
            SizedBox(height: 16.h),
            if (history.isNotEmpty)
              StudentGlassCard(
                title: '📋 سجل المسابقات الذهبية',
                child: Column(
                  children: history.map((ContestHistoryItem h) {
                    return InkWell(
                      onTap: () => setState(() => _selected = h),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: context.borderColor, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.contestName,
                                    style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: 4.h),
                                  Wrap(
                                    spacing: 4.w,
                                    runSpacing: 2.h,
                                    children: [
                                      Chip(
                                        label: Text(_difficultyLabel(h.difficulty)),
                                        backgroundColor: _difficultyColor(h.difficulty).withValues(alpha: .15),
                                        labelStyle: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      Chip(
                                        label: Text(h.date),
                                        backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                        labelStyle: TextStyle(fontSize: 9.sp),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(h.rank != null ? '#${h.rank}' : '—',
                                      style: TextStyles.semiBold14.copyWith(color: Colors.amber)),
                                  Text(
                                    'من ${h.totalParticipants}',
                                    style: TextStyle(fontSize: 9.sp, color: context.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(h.score != null ? '${h.score}' : '—',
                                      style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                                  Text('نقطة', style: TextStyle(fontSize: 9.sp, color: context.textSecondary)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${h.solvedProblems}/${h.totalProblems}',
                                style: TextStyles.regular13.copyWith(color: context.textPrimary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: h.ratingChange != null
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (h.ratingChange ?? 0) > 0 ? Icons.trending_up : Icons.trending_down,
                                    size: 14,
                                    color: (h.ratingChange ?? 0) > 0 ? Colors.green : Colors.red,
                                  ),
                                  SizedBox(width: 2.w),
                                  Flexible(
                                    child: Text(
                                      '${(h.ratingChange ?? 0) > 0 ? '+' : ''}${h.ratingChange}',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        color: (h.ratingChange ?? 0) > 0 ? Colors.green : Colors.red,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                                  : Center(child: Text('—', style: TextStyle(color: context.textSecondary))),
                            ),
                            Icon(Icons.arrow_back_ios_new, size: 12, color: context.textSecondary),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _difficultyColor(String d) => switch (d) {
    'easy' => Colors.green,
    'hard' => Colors.red,
    _ => Colors.orange,
  };

  Widget _statCard(String value, String label) {
    return Container(
      margin: EdgeInsets.all(4.r),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyles.bold20.copyWith(color: context.textPrimary)),
          Text(label, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, ContestHistoryItem h) {
    final ratingInfo = _getRatingColor(h.newRating);
    final diffColor = _difficultyColor(h.difficulty);

    return StudentPageShell(
      title: h.contestName,
      gradient: LinearGradient(colors: [diffColor, diffColor.withValues(alpha: .7)]),
      onBack: () => setState(() => _selected = null),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48.r,
              backgroundColor: Colors.amber.shade100,
              child: Text('#${h.rank ?? '—'}',
                  style: TextStyles.bold25.copyWith(color: Colors.amber.shade800)),
            ),
            SizedBox(height: 8.h),
            Text('من ${h.totalParticipants} مشارك', style: TextStyles.regular14.copyWith(color: context.textSecondary)),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _detailStat('${h.score ?? '—'}', 'النقاط'),
                _detailStat('${h.solvedProblems}/${h.totalProblems}', 'محلولة'),
                _detailStat(h.duration, 'المدة'),
                _detailStat(
                  '${h.ratingChange != null ? ((h.ratingChange ?? 0) > 0 ? '+' : '') : ''}${h.ratingChange ?? '—'}',
                  'التقييم',
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  h.ratingChange != null
                      ? ((h.ratingChange ?? 0) > 0 ? Icons.trending_up : Icons.trending_down)
                      : Icons.remove,
                  color: h.ratingChange != null
                      ? ((h.ratingChange ?? 0) > 0 ? Colors.green : Colors.red)
                      : context.textSecondary,
                  size: 24,
                ),
                SizedBox(width: 8.w),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: ratingInfo.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: ratingInfo.color.withValues(alpha: .3)),
              ),
              child: Column(
                children: [
                  Text('التقييم الجديد', style: TextStyles.semiBold16.copyWith(color: context.textSecondary)),
                  SizedBox(height: 4.h),
                  Text('${h.newRating}', style: TextStyles.bold25.copyWith(color: ratingInfo.color)),
                  Chip(
                    label: Text(ratingInfo.rank),
                    backgroundColor: ratingInfo.color,
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyles.bold18.copyWith(color: context.textPrimary)),
        Text(label, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
      ],
    );
  }

  String _difficultyLabel(String d) => switch (d) {
    'easy' => 'سهل',
    'hard' => 'صعب',
    _ => 'متوسط',
  };
}