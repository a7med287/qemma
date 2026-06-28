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

class PerformanceReportView extends StatefulWidget {
  const PerformanceReportView({super.key});

  @override
  State<PerformanceReportView> createState() => _PerformanceReportViewState();
}

class _PerformanceReportViewState extends State<PerformanceReportView> {
  PerformanceReportData? _data;
  bool _loading = true;
  String? _error;

  AiAnalysis? _aiAnalysis;
  bool _aiLoading = false;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await context.read<StudentRepository>().getPerformance();
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    }
  }

  Future<void> _analyzeWithAI() async {
    setState(() { _aiLoading = true; _aiError = null; _aiAnalysis = null; });
    try {
      final result = await context.read<StudentRepository>().analyzePerformance();
      if (!mounted) return;
      setState(() { _aiAnalysis = result; _aiLoading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _aiError = e.message; _aiLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _aiError = e.toString(); _aiLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 56, height: 56, child: CircularProgressIndicator(strokeWidth: 4, color: const Color(0xFF7C3AED))),
              SizedBox(height: 16.h),
              Text('جاري تحميل التقرير...', style: TextStyles.regular14.copyWith(color: context.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('تعذر تحميل التقرير', style: TextStyles.semiBold18.copyWith(color: context.textPrimary)),
                SizedBox(height: 8.h),
                Text(_error!, style: TextStyles.regular14.copyWith(color: context.textSecondary), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    if (_data == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: ListView(
        children: [
          _buildHeader(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRankingCard(),
                SizedBox(height: 16.h),
                _buildCourseProgressCard(),
                SizedBox(height: 16.h),
                _buildGradesComparisonCard(),
                SizedBox(height: 16.h),
                _buildSubjectsPerformance(),
                if (_data!.strengths.isNotEmpty || _data!.weaknesses.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  _buildStrengthsWeaknesses(),
                ],
                SizedBox(height: 16.h),
                _buildWeeklyProgress(),
                SizedBox(height: 24.h),
                _buildAiSection(),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final statsConfig = <String, IconData>{
      'avgGrade': Icons.star_rounded,
      'homework': Icons.check_circle_rounded,
      'attendance': Icons.school_rounded,
      'studyTime': Icons.access_time_rounded,
    };
    final statsColors = <String, Color>{
      'avgGrade': const Color(0xFFF59E0B),
      'homework': const Color(0xFF059669),
      'attendance': const Color(0xFF2563EB),
      'studyTime': const Color(0xFF7C3AED),
    };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(top: 48.h, bottom: 24.h),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                StudentBackButton(onPressed: () => Navigator.pop(context)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 تقرير الأداء', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo')),
                      Text(
                        '${_data!.studentName}${_data!.studentLevel.isNotEmpty ? ' • ${_data!.studentLevel}' : ''}',
                        style: TextStyle(fontSize: 13.sp, color: Colors.white.withValues(alpha: 0.9), fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _aiLoading ? null : _analyzeWithAI,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_aiLoading)
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        else
                          Icon(Icons.auto_awesome_rounded, size: 16.sp, color: Colors.white),
                        SizedBox(width: 6.w),
                        Text('تحليل بالذكاء الاصطناعي',
                            style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _data!.kpis.map((k) {
                final icon = statsConfig[k.type] ?? Icons.star_rounded;
                final color = statsColors[k.type] ?? const Color(0xFF64748B);
                return Container(
                  width: (MediaQuery.of(context).size.width - 48.w) / 2,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(icon, size: 22.sp, color: Colors.white),
                          if (k.change.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up_rounded, size: 12.sp, color: const Color(0xFF059669)),
                                  SizedBox(width: 2.w),
                                  Text(k.change,
                                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF059669), fontFamily: 'Cairo')),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(k.value,
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo')),
                      Text(k.label,
                          style: TextStyle(fontSize: 12.sp, color: Colors.white.withValues(alpha: 0.9), fontFamily: 'Cairo')),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ranking Card ─────────────────────────────────────────────────
  Widget _buildRankingCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 22.sp, color: const Color(0xFFF59E0B)),
              SizedBox(width: 8.w),
              Text('الترتيب والتصنيف',
                  style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
            ],
          ),
          SizedBox(height: 20.h),
          Container(
            width: 100.w, height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
              boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Center(
              child: Text('#${_data!.classRank}',
                  style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo')),
            ),
          ),
          SizedBox(height: 8.h),
          Text('من أصل ${_data!.totalStudents} طالب',
              style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
          if (_data!.rankImproved)
            Container(
              margin: EdgeInsets.only(top: 4.h),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_rounded, size: 14.sp, color: const Color(0xFF059669)),
                  SizedBox(width: 4.w),
                  Text('تقدم مستواك',
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF059669), fontFamily: 'Cairo')),
                ],
              ),
            ),
          SizedBox(height: 16.h),
          _rankInfoRow('النسبة المئوية', 'أفضل ${100 - (_data!.percentile)}%', const Color(0xFF2563EB)),
          if (_data!.maxScore > 0)
            _rankInfoRow('أعلى درجة', '${_data!.maxScore}%', const Color(0xFF059669)),
          if (_data!.minScore < 100)
            _rankInfoRow('أدنى درجة', '${_data!.minScore}%', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _rankInfoRow(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(value,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: color, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  // ── Course Progress Card ─────────────────────────────────────────
  Widget _buildCourseProgressCard() {
    final progress = _data!.courseProgress;
    final completed = progress['completed'] ?? 0;
    final inProgress = progress['inProgress'] ?? 0;
    final notStarted = progress['notStarted'] ?? 0;
    final total = progress['total'] ?? 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📚 تقدم الكورسات', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 16.h),
          SizedBox(
            height: 220.h,
            child: total > 0
                ? PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(value: completed.toDouble(), color: const Color(0xFF059669), radius: 50.r, title: '', showTitle: false),
                        PieChartSectionData(value: inProgress.toDouble(), color: const Color(0xFFF59E0B), radius: 50.r, title: '', showTitle: false),
                        PieChartSectionData(value: notStarted.toDouble(), color: const Color(0xFF94A3B8), radius: 50.r, title: '', showTitle: false),
                      ],
                      centerSpaceRadius: 40.r,
                      sectionsSpace: 2,
                    ),
                  )
                : Center(child: Text('لا توجد كورسات مسجلة',
                    style: TextStyles.regular14.copyWith(color: context.textSecondary))),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _progressStat('${completed}', 'مكتمل', const Color(0xFF059669)),
              _progressStat('${inProgress}', 'قيد التقدم', const Color(0xFFF59E0B)),
              _progressStat('${notStarted}', 'لم يبدأ', const Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: color, fontFamily: 'Cairo')),
        Text(label,
            style: TextStyle(fontSize: 11.sp, color: context.textSecondary, fontFamily: 'Cairo')),
      ],
    );
  }

  // ── Grades Comparison Card ───────────────────────────────────────
  Widget _buildGradesComparisonCard() {
    final subjects = _data!.subjects;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📈 مقارنة الدرجات', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 16.h),
          SizedBox(
            height: 220.h,
            child: subjects.isNotEmpty
                ? BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barGroups: List.generate(subjects.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: subjects[i].grade.toDouble(),
                              color: const Color(0xFF2563EB).withValues(alpha: 0.8),
                              width: 8.w,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: subjects[i].classAvg.toDouble(),
                              color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
                              width: 8.w,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= subjects.length) return const SizedBox.shrink();
                              return Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Text(subjects[i].name.length > 4 ? '${subjects[i].name.substring(0, 4)}..' : subjects[i].name,
                                    style: TextStyle(fontSize: 9.sp, color: context.textSecondary, fontFamily: 'Cairo')),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  )
                : Center(child: Text('لا توجد نتائج امتحانات بعد',
                    style: TextStyles.regular14.copyWith(color: context.textSecondary))),
          ),
        ],
      ),
    );
  }

  // ── Subjects Performance ─────────────────────────────────────────
  Widget _buildSubjectsPerformance() {
    final subjects = _data!.subjects;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📚 أداء المواد', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 16.h),
          if (subjects.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text('لا توجد بيانات أداء للمواد بعد. قم بحل الاختبارات لترى تحليلك.',
                    style: TextStyles.regular14.copyWith(color: context.textSecondary), textAlign: TextAlign.center),
              ),
            )
          else
            ...subjects.map((s) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: context.isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border(top: BorderSide(color: s.color, width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.name, style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                            Row(
                              children: [
                                Text('${s.grade}%',
                                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: s.color, fontFamily: 'Cairo')),
                                SizedBox(width: 8.w),
                                if (s.trendValue.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: s.trend == 'up' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          s.trend == 'up' ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                          size: 12.sp,
                                          color: s.trend == 'up' ? const Color(0xFF059669) : const Color(0xFFEF4444),
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(s.trendValue,
                                            style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700,
                                                color: s.trend == 'up' ? const Color(0xFF059669) : const Color(0xFFEF4444),
                                                fontFamily: 'Cairo')),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: LinearProgressIndicator(
                            value: s.grade / 100,
                            minHeight: 6,
                            backgroundColor: context.isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(s.color),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text('متوسط الفصل: ${s.classAvg}% • ${s.examsCount} اختبار',
                            style: TextStyle(fontSize: 11.sp, color: context.textSecondary, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // ── Strengths & Weaknesses ───────────────────────────────────────
  Widget _buildStrengthsWeaknesses() {
    return Column(
      children: [
        if (_data!.strengths.isNotEmpty)
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💪 نقاط القوة', style: TextStyles.semiBold16.copyWith(color: const Color(0xFF059669))),
                SizedBox(height: 12.h),
                ..._data!.strengths.map((s) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _progressItem(s.subject, s.score, const Color(0xFF059669)),
                    )),
              ],
            ),
          ),
        SizedBox(height: 12.h),
        if (_data!.weaknesses.isNotEmpty)
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️ نقاط الضعف', style: TextStyles.semiBold16.copyWith(color: const Color(0xFFEF4444))),
                SizedBox(height: 12.h),
                ..._data!.weaknesses.map((s) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _progressItem(s.subject, s.score, const Color(0xFFEF4444)),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _progressItem(String subject, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(subject, style: TextStyles.semiBold13.copyWith(color: context.textPrimary)),
            Row(
              children: [
                Text('$score%',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: color, fontFamily: 'Cairo')),
              ],
            ),
          ],
        ),
        SizedBox(height: 4.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 6,
            backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ── Weekly Progress ──────────────────────────────────────────────
  Widget _buildWeeklyProgress() {
    final labels = _data!.weeklyLabels;
    final grades = _data!.studentGrades;
    final avg = _data!.classAverage;
    final hasData = grades.any((g) => g > 0);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 تطور الأداء عبر الوقت', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 16.h),
          SizedBox(
            height: 240.h,
            child: hasData
                ? LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(labels.length, (i) => FlSpot(i.toDouble(), grades[i])),
                          color: const Color(0xFF2563EB),
                          barWidth: 2.5,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4, color: const Color(0xFF2563EB), strokeWidth: 0,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          ),
                        ),
                        LineChartBarData(
                          spots: List.generate(labels.length, (i) => FlSpot(i.toDouble(), avg[i])),
                          color: const Color(0xFF94A3B8),
                          barWidth: 1.5,
                          isCurved: true,
                          dashArray: [5, 5],
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}',
                                  style: TextStyle(fontSize: 10.sp, color: context.textSecondary, fontFamily: 'Cairo'));
                            })),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                                return Text(labels[i],
                                    style: TextStyle(fontSize: 9.sp, color: context.textSecondary, fontFamily: 'Cairo'));
                              }),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 100,
                    ),
                  )
                : Center(child: Text('لا توجد بيانات أداء كافية بعد',
                    style: TextStyles.regular14.copyWith(color: context.textSecondary))),
          ),
        ],
      ),
    );
  }

  // ── AI Analysis Section ──────────────────────────────────────────
  Widget _buildAiSection() {
    if (_aiError != null) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(_aiError!, style: const TextStyle(color: Color(0xFFEF4444), fontFamily: 'Cairo', fontSize: 13)),
      );
    }

    if (_aiAnalysis == null) return const SizedBox.shrink();

    final ai = _aiAnalysis!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 22.sp, color: const Color(0xFF7C3AED)),
            SizedBox(width: 8.w),
            Text('تحليل الأداء بالذكاء الاصطناعي',
                style: TextStyles.semiBold18.copyWith(color: context.textPrimary)),
          ],
        ),
        SizedBox(height: 16.h),
        if (ai.overallAssessment != null) ...[
          _aiCard(
            icon: Icons.insights_rounded, iconColor: const Color(0xFF7C3AED),
            title: 'التقييم العام',
            child: Text(ai.overallAssessment!,
                style: TextStyle(fontSize: 13.sp, color: context.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), fontFamily: 'Cairo', height: 1.8)),
          ),
          SizedBox(height: 12.h),
        ],
        if (ai.strengths.isNotEmpty)
          _aiCard(
            icon: Icons.stars_rounded, iconColor: const Color(0xFF059669),
            title: 'نقاط القوة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ai.strengths.map((s) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8.w),
                    Expanded(child: Text(s,
                        style: TextStyle(fontSize: 13.sp, color: context.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), fontFamily: 'Cairo'))),
                  ],
                ),
              )).toList(),
            ),
          ),
        SizedBox(height: 12.h),
        if (ai.weaknesses.isNotEmpty)
          _aiCard(
            icon: Icons.warning_amber_rounded, iconColor: const Color(0xFFDC2626),
            title: 'نقاط الضعف',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ai.weaknesses.map((s) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('❌', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8.w),
                    Expanded(child: Text(s,
                        style: TextStyle(fontSize: 13.sp, color: context.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), fontFamily: 'Cairo'))),
                  ],
                ),
              )).toList(),
            ),
          ),
        SizedBox(height: 12.h),
        if (ai.weakLessons.isNotEmpty)
          _aiCard(
            icon: Icons.psychology_rounded, iconColor: const Color(0xFF7C3AED),
            title: 'الدروس التي تحتاج مراجعة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ai.weakLessons.map((l) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8.w),
                    Expanded(child: Text(l,
                        style: TextStyle(fontSize: 13.sp, color: context.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), fontFamily: 'Cairo'))),
                  ],
                ),
              )).toList(),
            ),
          ),
        SizedBox(height: 12.h),
        if (ai.topicsToStudy.isNotEmpty)
          _aiCard(
            icon: Icons.auto_graph_rounded, iconColor: const Color(0xFF2563EB),
            title: 'المواضيع المقترحة للمذاكرة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ai.topicsToStudy.map((t) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8.w),
                    Expanded(child: Text(t,
                        style: TextStyle(fontSize: 13.sp, color: context.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), fontFamily: 'Cairo'))),
                  ],
                ),
              )).toList(),
            ),
          ),
        SizedBox(height: 12.h),
        if (ai.advice != null)
          _aiCard(
            icon: Icons.format_quote_rounded, iconColor: const Color(0xFFF59E0B),
            title: 'نصيحة',
            child: Text('"${ai.advice!}"',
                style: TextStyle(fontSize: 13.sp, fontStyle: FontStyle.italic,
                    color: context.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), fontFamily: 'Cairo', height: 1.8)),
          ),
        SizedBox(height: 12.h),
        if (ai.improvements.isNotEmpty)
          _aiCard(
            icon: Icons.tips_and_updates_rounded, iconColor: const Color(0xFF059669),
            title: 'مقترحات للتحسين',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ai.improvements.map((imp) => Container(
                margin: EdgeInsets.only(bottom: 6.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8.w),
                    Expanded(child: Text(imp,
                        style: TextStyle(fontSize: 13.sp, color: context.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), fontFamily: 'Cairo'))),
                  ],
                ),
              )).toList(),
            ),
          ),
        SizedBox(height: 12.h),
        if (ai.studyPlan != null)
          _aiCard(
            icon: Icons.lightbulb_rounded, iconColor: const Color(0xFFF59E0B),
            title: 'خطة الدراسة المقترحة',
            child: Text(ai.studyPlan!,
                style: TextStyle(fontSize: 13.sp, color: context.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), fontFamily: 'Cairo', height: 1.8)),
          ),
        SizedBox(height: 12.h),
        if (ai.motivationalMessage != null)
          _aiCard(
            icon: Icons.speed_rounded, iconColor: const Color(0xFF7C3AED),
            title: 'رسالة تحفيزية',
            textAlignCenter: true,
            child: Text(ai.motivationalMessage!,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED), fontFamily: 'Cairo', height: 1.8)),
          ),
      ],
    );
  }

  Widget _aiCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
    bool textAlignCenter = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: textAlignCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: textAlignCenter ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 22.sp, color: iconColor),
              SizedBox(width: 8.w),
              Text(title, style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  // ── Card helper ──────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}
