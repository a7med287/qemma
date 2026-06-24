import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';
import 'widgets/teacher_analytics_charts.dart';
import 'widgets/teacher_analytics_stats.dart';

class TeacherAnalyticsView extends StatefulWidget {
  static const routeName = '/teacher/analytics';
  const TeacherAnalyticsView({super.key});

  @override
  State<TeacherAnalyticsView> createState() =>
      _TeacherAnalyticsViewState();
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await context.read<TeacherRepository>().getAnalytics();
      if (!mounted) return;
      setState(() {
        _report = res;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Map<String, dynamic> get _summary =>
      (_report?['summary'] as Map<String, dynamic>?) ?? {};
  List<dynamic> get _enrollmentTrend =>
      (_report?['enrollmentTrend'] as List?) ?? [];
  List<dynamic> get _scoreDist =>
      (_report?['scoreDist'] as List?) ?? [];
  List<dynamic> get _topStudents =>
      (_report?['topStudents'] as List?) ?? [];
  List<dynamic> get _coursePerformance =>
      (_report?['coursePerformance'] as List?) ?? [];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
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
        gradient: LinearGradient(colors: [
          Color(0xFF2563EB),
          Color(0xFF7C3AED),
          Color(0xFFDB2777)
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
                backgroundColor: Colors.white12),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: const BoxDecoration(
                  borderRadius:
                      BorderRadius.all(Radius.circular(10)),
                  gradient: LinearGradient(
                      colors: [
                        Color(0xFF06B6D4),
                        Color(0xFF3B82F6)
                      ]),
                ),
                child: const Icon(Icons.bar_chart,
                    color: Colors.white, size: 24),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الإحصائيات والتحليلات',
                      style: TextStyles.bold20
                          .copyWith(color: Colors.white)),
                  Text('تابع أداء طلابك وتحليلات شاملة',
                      style: TextStyles.regular13
                          .copyWith(color: Colors.white70)),
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
              const Icon(Icons.cloud_off,
                  size: 48, color: Colors.grey),
              SizedBox(height: 12.h),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyles.regular14),
              SizedBox(height: 16.h),
              ElevatedButton(
                  onPressed: _fetchReport,
                  child: const Text('إعادة المحاولة')),
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
        TeacherAnalyticsStats(summary: _summary),
        SizedBox(height: 20.h),
        TeacherAnalyticsCharts(
          enrollmentTrend: _enrollmentTrend,
          scoreDist: _scoreDist,
          topStudents: _topStudents,
          coursePerformance: _coursePerformance,
          summary: _summary,
        ),
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
            color: isDark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _period,
              dropdownColor: isDark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1A1A2E),
              ),
              items: _periods
                  .map((p) => DropdownMenuItem(
                      value: p.$1, child: Text(p.$2)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _period = v ?? 'month'),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        IconButton(
          onPressed: _fetchReport,
          icon: const Icon(Icons.refresh),
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? const Color(0xFF1E293B)
                : Colors.white,
            foregroundColor: isDark
                ? const Color(0xFFF1F5F9)
                : null,
            side: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE5E7EB)),
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 18),
          label: Text('تصدير',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark
                ? const Color(0xFFF1F5F9)
                : null,
            side: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE5E7EB)),
          ),
        ),
      ],
    );
  }
}
