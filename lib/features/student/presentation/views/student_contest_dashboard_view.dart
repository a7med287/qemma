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
                    backgroundColor: Colors.amber.shade100,
                    child: Text('${data.currentRating}',
                        style: TextStyles.bold20.copyWith(color: Colors.amber.shade800)),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تقييمك الحالي', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                        Text('أفضل ترتيب #${data.stats.bestRank}', style: TextStyles.regular14.copyWith(color: context.textSecondary)),
                        if (history.isNotEmpty && history.first.ratingChange != 0)
                          Text('${history.first.ratingChange > 0 ? '+' : ''}${history.first.ratingChange} من آخر مسابقة',
                              style: TextStyles.regular13.copyWith(
                                color: history.first.ratingChange > 0 ? Colors.green : Colors.red,
                              )),
                      ],
                    ),
                  ),
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
                              color: const Color(0xFFF59E0B),
                              isCurved: true,
                              belowBarData: BarAreaData(
                                  show: true, color: const Color(0xFFF59E0B).withValues(alpha: .1)),
                            ),
                          ],
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
                _statCard('${data.stats.totalContests}', 'مسابقات'),
                _statCard('${data.stats.totalSolved}', 'مسائل محلولة'),
                _statCard('#${data.stats.avgRank}', 'متوسط الترتيب'),
                _statCard('#${data.stats.bestRank}', 'أفضل ترتيب'),
              ],
            ),
            SizedBox(height: 16.h),
            if (history.isNotEmpty)
              StudentGlassCard(
                title: '📋 سجل المسابقات',
                child: Column(
                  children: history.map((ContestHistoryItem h) => ListTile(
                        title: Text(h.contestName),
                        subtitle: Text('${h.date} • ${_difficultyLabel(h.difficulty)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('#${h.rank}', style: TextStyles.semiBold14.copyWith(color: Colors.amber)),
                            Text('${h.score} نقطة', style: TextStyles.regular13),
                          ],
                        ),
                        onTap: () => setState(() => _selected = h),
                      )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
    return StudentPageShell(
      title: h.contestName,
      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      onBack: () => setState(() => _selected = null),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48.r,
              backgroundColor: Colors.amber.shade100,
              child: Text('#${h.rank}',
                  style: TextStyles.bold25.copyWith(color: Colors.amber.shade800)),
            ),
            SizedBox(height: 16.h),
            Text('من ${h.totalParticipants} مشارك', style: TextStyles.regular14),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _detailStat('${h.score}', 'النقاط'),
                _detailStat('${h.solvedProblems}/${h.totalProblems}', 'محلولة'),
                _detailStat(h.duration, 'المدة'),
                _detailStat('${h.ratingChange > 0 ? '+' : ''}${h.ratingChange}', 'التقييم'),
              ],
            ),
            SizedBox(height: 24.h),
            Text('التقييم الجديد: ${h.newRating}', style: TextStyles.bold18),
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
