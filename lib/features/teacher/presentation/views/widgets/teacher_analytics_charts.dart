import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'teacher_theme_helpers.dart';

class TeacherAnalyticsCharts extends StatelessWidget {
  const TeacherAnalyticsCharts({
    super.key,
    required this.enrollmentTrend,
    required this.scoreDist,
    required this.topStudents,
    required this.coursePerformance,
    required this.summary,
  });

  final List<dynamic> enrollmentTrend;
  final List<dynamic> scoreDist;
  final List<dynamic> topStudents;
  final List<dynamic> coursePerformance;
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChartsRow1(context),
        SizedBox(height: 20.h),
        _buildChartsRow2(context),
        SizedBox(height: 20.h),
        _buildCourseTable(context),
      ],
    );
  }

  Widget _buildChartsRow1(BuildContext context) {
    return Column(
      children: [
        _buildChartCard(
          context,
          title: 'تطور التسجيلات (آخر 6 أشهر)',
          flex: 2,
          child: enrollmentTrend.isEmpty
              ? _emptyChart(context)
              : SizedBox(
            height: 260.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32.w, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= enrollmentTrend.length) return const SizedBox();
                    final m = enrollmentTrend[i]['month'] ?? '';
                    return Padding(padding: EdgeInsets.only(top: 6.h), child: Text('$m', style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))));
                  })),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: enrollmentTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['students'] as num).toDouble())).toList(),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF2563EB),
                    barWidth: 3,
                    dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: const Color(0xFF2563EB), strokeWidth: 0)),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF2563EB).withValues(alpha: .1)),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) => LineTooltipItem('${s.y.toInt()} طالب', TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)))).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildChartCard(
          context,
          title: 'توزيع النتائج',
          flex: 1,
          child: scoreDist.every((s) => (s['value'] ?? 0) == 0)
              ? _emptyChart(context)
              : SizedBox(
            height: 260.h,
            child: Column(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: scoreDist.asMap().entries.map((e) {
                        final s = e.value as Map<String, dynamic>;
                        final colorHex = s['color'] as String? ?? '#2563eb';
                        final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                        return PieChartSectionData(
                          value: (s['value'] as num).toDouble(),
                          color: color,
                          radius: 60,
                          title: '${((s['value'] as num) / (scoreDist.fold(0.0, (sum, x) => sum + (x['value'] as num).toDouble())) * 100).toStringAsFixed(0)}%',
                          titleStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 11.sp, color: Colors.white),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                ...scoreDist.map((s) {
                  final colorHex = s['color'] as String? ?? '#2563eb';
                  final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        SizedBox(width: 6.w),
                        Text(s['name'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartsRow2(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      children: [
        _buildChartCard(
          context,
          title: 'توزيع الطلاب على الكورسات',
          child: coursePerformance.isEmpty
              ? _emptyChart(context)
              : SizedBox(
            height: 240.h,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32.w, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= coursePerformance.length) return const SizedBox();
                    return Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Text(
                        coursePerformance[i]['name'] ?? '',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 8.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
                      ),
                    );
                  })),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                barGroups: coursePerformance.asMap().entries.map((e) =>
                    BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(
                        toY: (e.value['students'] as num).toDouble(),
                        color: const Color(0xFF7C3AED),
                        width: 16.w,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6.r),
                          topRight: Radius.circular(6.r),
                        ),
                      ),
                    ])
                ).toList(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem('${rod.toY.toInt()} طالب', TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED))),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildChartCard(
          context,
          title: 'أفضل الطلاب',
          child: topStudents.isEmpty
              ? _emptyChart(context)
              : Column(
            children: topStudents.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value as Map<String, dynamic>;
              return Container(
                margin: EdgeInsets.only(bottom: 6.h),
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28.w, height: 28.w,
                      decoration: BoxDecoration(
                        color: i == 0 ? const Color(0xFFFBBF24) : i == 1 ? const Color(0xFF94A3B8) : i == 2 ? const Color(0xFFC2410C) : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Center(child: Text('${i + 1}', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.white))),
                    ),
                    SizedBox(width: 8.w),
                    CircleAvatar(
                      radius: 16.r,
                      backgroundColor: const Color(0xFF2563EB),
                      child: Text(s['avatar'] ?? (s['name']?.toString().isNotEmpty == true ? s['name'][0] : '?'), style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name'] ?? '', style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                          Text('${s['examsCount'] ?? 0} اختبار', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(16.r)),
                      child: Text('${s['avgScore'] ?? 0}', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w900, color: const Color(0xFF059669))),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseTable(BuildContext context) {
    final isDark = context.isDark;
    final totalStudentsNum = (summary['totalStudents'] as num?) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('أداء الكورسات', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 16.h),
          if (coursePerformance.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.h),
                child: Text('لا توجد بيانات لعرضها', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
              ),
            )
          else
            ...coursePerformance.map((c) {
              final course = c as Map<String, dynamic>;
              final pct = totalStudentsNum > 0 ? min(100, ((course['students'] as num? ?? 0) / totalStudentsNum * 100).round()) : 0;
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80.w,
                      child: Text(course['name'] ?? '', style: TextStyles.semiBold13.copyWith(color: context.textPrimary)),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _tableCell(context, '${course['students'] ?? 0}', 'طلاب'),
                              _tableCell(context, '${course['exams'] ?? '—'}', 'اختبارات'),
                              _tableCell(context, '${course['lessons'] ?? '—'}', 'دروس'),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                              minHeight: 6.h,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _tableCell(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyles.semiBold13.copyWith(color: context.textPrimary)),
        Text(label, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
      ],
    );
  }

  Widget _emptyChart(BuildContext context) {
    return SizedBox(
      height: 200.h,
      child: Center(
        child: Text('لا توجد بيانات كافية', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, {required String title, required Widget child, int flex = 1}) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}
