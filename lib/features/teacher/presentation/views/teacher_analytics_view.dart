import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';

class TeacherAnalyticsView extends StatefulWidget {
  static const routeName = '/teacher/analytics';
  const TeacherAnalyticsView({super.key});

  @override
  State<TeacherAnalyticsView> createState() => _TeacherAnalyticsViewState();
}

class _TeacherAnalyticsViewState extends State<TeacherAnalyticsView> {
  Map<String, dynamic>? _report;
  bool _loading = false;
  String? _error;
  String _period = 'month';

  static const _periods = [
    ('week', 'آخر أسبوع'),
    ('month', 'آخر شهر'),
    ('quarter', 'آخر 3 أشهر'),
    ('year', 'آخر سنة'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<TeacherRepository>().getAnalytics();
      if (!mounted) return;
      setState(() { _report = res; _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    }
  }

  Map<String, dynamic> get _summary => (_report?['summary'] as Map<String, dynamic>?) ?? {};
  List<dynamic> get _enrollmentTrend => (_report?['enrollmentTrend'] as List?) ?? [];
  List<dynamic> get _scoreDist => (_report?['scoreDist'] as List?) ?? [];
  List<dynamic> get _topStudents => (_report?['topStudents'] as List?) ?? [];
  List<dynamic> get _coursePerformance => (_report?['coursePerformance'] as List?) ?? [];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 20.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white12),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 44.w, height: 44.w,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  gradient: LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]),
                ),
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الإحصائيات والتحليلات',
                      style: TextStyles.bold20.copyWith(color: Colors.white)),
                  Text('تابع أداء طلابك وتحليلات شاملة',
                      style: TextStyles.regular13.copyWith(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              SizedBox(height: 12.h),
              Text(_error!, textAlign: TextAlign.center, style: TextStyles.regular14),
              SizedBox(height: 16.h),
              ElevatedButton(onPressed: _fetchReport, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        _buildToolbar(context),
        SizedBox(height: 20.h),
        _buildStatCards(context),
        SizedBox(height: 20.h),
        _buildChartsRow1(context),
        SizedBox(height: 20.h),
        _buildChartsRow2(context),
        SizedBox(height: 20.h),
        _buildCourseTable(context),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final isDark = context.isDark;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _period,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
              ),
              items: _periods.map((p) => DropdownMenuItem(value: p.$1, child: Text(p.$2))).toList(),
              onChanged: (v) => setState(() => _period = v ?? 'month'),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        IconButton(
          onPressed: _fetchReport,
          icon: const Icon(Icons.refresh),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            foregroundColor: isDark ? const Color(0xFFF1F5F9) : null,
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 18),
          label: Text('تصدير', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFFF1F5F9) : null,
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context) {
    final isDark = context.isDark;
    final cards = [
      _StatData('إجمالي الطلاب', '${_summary['totalStudents'] ?? '—'}', Icons.people, const Color(0xFF2563EB), _summary['passRate'] != null && _summary['passRate'] >= 70),
      _StatData('الاختبارات المنشورة', '${_summary['totalExams'] ?? '—'}', Icons.assignment, const Color(0xFF7C3AED), true),
      _StatData('معدل النجاح', _summary['passRate'] != null ? '${_summary['passRate']}%' : '—', Icons.check_circle, const Color(0xFF059669), (_summary['passRate'] ?? 0) >= 70),
      _StatData('متوسط الدرجات', '${_summary['avgScore'] ?? '—'}', Icons.school, const Color(0xFFF59E0B), (_summary['avgScore'] ?? 0) >= 70),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 1.4, crossAxisSpacing: 12.w, mainAxisSpacing: 12.h,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          ),
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36.w, height: 36.w,
                    decoration: BoxDecoration(
                      color: isDark ? c.color.withValues(alpha: .2) : c.color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(c.icon, color: c.color, size: 18.sp),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: c.trendUp ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      c.trendUp ? Icons.trending_up : Icons.trending_down,
                      size: 14.sp,
                      color: c.trendUp ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(c.value,
                  style: TextStyle(
                    fontSize: 20.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
                  )),
              SizedBox(height: 2.h),
              Text(c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp, fontWeight: FontWeight.w600, fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartsRow1(BuildContext context) {
    return Column(
      children: [
        _buildChartCard(
          context,
          title: 'تطور التسجيلات (آخر 6 أشهر)',
          flex: 2,
          child: _enrollmentTrend.isEmpty
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
                    if (i < 0 || i >= _enrollmentTrend.length) return const SizedBox();
                    final m = _enrollmentTrend[i]['month'] ?? '';
                    return Padding(padding: EdgeInsets.only(top: 6.h), child: Text('$m', style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))));
                  })),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: _enrollmentTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['students'] as num).toDouble())).toList(),
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
          child: _scoreDist.every((s) => (s['value'] ?? 0) == 0)
              ? _emptyChart(context)
              : SizedBox(
            height: 260.h,
            child: Column(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: _scoreDist.asMap().entries.map((e) {
                        final s = e.value as Map<String, dynamic>;
                        final colorHex = s['color'] as String? ?? '#2563eb';
                        final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                        return PieChartSectionData(
                          value: (s['value'] as num).toDouble(),
                          color: color,
                          radius: 60,
                          title: '${((s['value'] as num) / (_scoreDist.fold(0.0, (sum, x) => sum + (x['value'] as num).toDouble())) * 100).toStringAsFixed(0)}%',
                          titleStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 11.sp, color: Colors.white),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                ..._scoreDist.map((s) {
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
          child: _coursePerformance.isEmpty
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
                    if (i < 0 || i >= _coursePerformance.length) return const SizedBox();
                    return Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Text(
                        _coursePerformance[i]['name'] ?? '',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 8.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
                      ),
                    );
                  })),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                barGroups: _coursePerformance.asMap().entries.map((e) =>
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
          child: _topStudents.isEmpty
              ? _emptyChart(context)
              : Column(
            children: _topStudents.asMap().entries.map((entry) {
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
    final totalStudents = (_summary['totalStudents'] as num?) ?? 0;

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
          if (_coursePerformance.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.h),
                child: Text('لا توجد بيانات لعرضها', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
              ),
            )
          else
            ..._coursePerformance.map((c) {
              final course = c as Map<String, dynamic>;
              final pct = totalStudents > 0 ? min(100, ((course['students'] as num? ?? 0) / totalStudents * 100).round()) : 0;
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
                              _tableCell('${course['students'] ?? 0}', 'طلاب'),
                              _tableCell('${course['exams'] ?? '—'}', 'اختبارات'),
                              _tableCell('${course['lessons'] ?? '—'}', 'دروس'),
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

  Widget _tableCell(String value, String label) {
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

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool trendUp;
  const _StatData(this.title, this.value, this.icon, this.color, this.trendUp);
}