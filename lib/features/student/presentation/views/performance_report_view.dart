import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../widgets/student_async_body.dart';
import '../widgets/student_shared_widgets.dart';

class PerformanceReportView extends StatefulWidget {
  const PerformanceReportView({super.key});

  @override
  State<PerformanceReportView> createState() => _PerformanceReportViewState();
}

class _PerformanceReportViewState extends State<PerformanceReportView> {
  PerformanceReportData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<StudentRepository>().getPerformance();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  @override
  Widget build(BuildContext context) {
    return StudentPageShell(
      title: '📊 تقرير الأداء',
      headerChild: Text(_data?.studentLevel ?? '', style: TextStyles.regular14.copyWith(color: Colors.white70)),
      body: StudentAsyncBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: _data == null
            ? const SizedBox.shrink()
            : ListView(
                padding: EdgeInsets.all(16.r),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: _data!.kpis
                        .map((k) => StudentGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(k.value, style: TextStyles.bold20.copyWith(color: context.textPrimary)),
                                  Text(k.label, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                                  Text(k.change, style: TextStyles.regular13.copyWith(color: Colors.green)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 16.h),
                  StudentGlassCard(
                    title: '🏅 الترتيب',
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32.r,
                          backgroundColor: Colors.amber.shade100,
                          child: Text('#${_data!.classRank}', style: TextStyles.bold20.copyWith(color: Colors.amber.shade800)),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الترتيب ${_data!.classRank} من ${_data!.totalStudents}', style: TextStyles.semiBold16),
                              Text('أفضل ${_data!.percentile}% من الفصل', style: TextStyles.regular14.copyWith(color: context.textSecondary)),
                              if (_data!.rankImproved) Text('📈 تحسّن ترتيبك!', style: TextStyles.regular13.copyWith(color: Colors.green)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (_data!.weeklyLabels.isNotEmpty)
                    StudentGlassCard(
                      title: '📈 التقدم الأسبوعي',
                      child: SizedBox(
                        height: 200.h,
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(_data!.weeklyLabels.length, (i) => FlSpot(i.toDouble(), _data!.studentGrades[i])),
                                color: const Color(0xFF2563EB),
                                isCurved: true,
                              ),
                              LineChartBarData(
                                spots: List.generate(_data!.weeklyLabels.length, (i) => FlSpot(i.toDouble(), _data!.classAverage[i])),
                                color: const Color(0xFF94A3B8),
                                isCurved: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 16.h),
                  StudentGlassCard(
                    title: '📚 أداء المواد',
                    child: Column(
                      children: _data!.subjects.map((s) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(s.name, style: TextStyles.semiBold14),
                                    Text('${s.grade}% (متوسط الفصل ${s.classAvg}%)', style: TextStyles.regular13.copyWith(color: s.color)),
                                  ],
                                ),
                                LinearProgressIndicator(value: s.grade / 100, color: s.color),
                              ],
                            ),
                          )).toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
