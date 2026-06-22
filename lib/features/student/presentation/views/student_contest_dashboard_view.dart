import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/mock/student_mock_data.dart';
import '../../data/models/student_models.dart';
import '../widgets/student_shared_widgets.dart';

class StudentContestDashboardView extends StatefulWidget {
  const StudentContestDashboardView({super.key});

  @override
  State<StudentContestDashboardView> createState() => _StudentContestDashboardViewState();
}

class _StudentContestDashboardViewState extends State<StudentContestDashboardView> {
  ContestHistoryItem? _selected;

  @override
  Widget build(BuildContext context) {
    if (_selected != null) return _buildDetail(context, _selected!);
    final history = StudentMockData.contestHistory;
    final rating = StudentMockData.ratingHistory;

    return StudentPageShell(
      title: '🏆 لوحة المسابقات',
      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      headerChild: Wrap(
        spacing: 8.w,
        children: ['علمي رياضة', 'علمي علوم', 'أدبي']
            .map((s) => Chip(label: Text(s), backgroundColor: Colors.white24, labelStyle: const TextStyle(color: Colors.white)))
            .toList(),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          StudentGlassCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40.r,
                  backgroundColor: Colors.amber.shade100,
                  child: Text('1547', style: TextStyles.bold20.copyWith(color: Colors.amber.shade800)),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تقييمك الحالي', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                      Text('ترتيب #12 • Expert', style: TextStyles.regular14.copyWith(color: context.textSecondary)),
                      Text('+45 من آخر مسابقة', style: TextStyles.regular13.copyWith(color: Colors.green)),
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
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(rating.length, (i) => FlSpot(i.toDouble(), rating[i].rating.toDouble())),
                      color: const Color(0xFFF59E0B),
                      isCurved: true,
                      belowBarData: BarAreaData(show: true, color: const Color(0xFFF59E0B).withValues(alpha: .1)),
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
              _statCard('5', 'مسابقات'),
              _statCard('23', 'مسائل محلولة'),
              _statCard('#12', 'متوسط الترتيب'),
              _statCard('#5', 'أفضل ترتيب'),
            ],
          ),
          SizedBox(height: 16.h),
          StudentGlassCard(
            title: '📋 سجل المسابقات',
            child: Column(
              children: history.map((ContestHistoryItem h) => ListTile(
                    title: Text(h.contestName),
                    subtitle: Text('${h.date} • ${h.difficulty}'),
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
              child: Text('#${h.rank}', style: TextStyles.bold25.copyWith(color: Colors.amber.shade800)),
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
}
