import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/parent_models.dart';
import '../../data/repositories/parent_repository.dart';
import '../widgets/parent_async_body.dart';
import '../widgets/parent_shared_widgets.dart';

class ReportsView extends StatefulWidget {
  static const routeName = '/parent/reports';
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  List<ChildSummary> _children = [];
  List<ChildPerformance> _performances = [];
  bool _loading = true;
  String? _error;
  String _reportType = 'overall';
  String? _selectedChildId;
  String _timeRange = 'semester';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = context.read<ParentRepository>();
      final children = await repo.getChildren();
      final performances = <ChildPerformance>[];
      for (final child in children) {
        try {
          final perf = await repo.getChildPerformance(child.id);
          performances.add(perf);
        } catch (_) {}
      }
      setState(() {
        _children = children;
        _performances = performances;
      });
    } catch (e) {
      setState(() => _error = 'فشل تحميل التقارير');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 16.h, bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text('التقارير', style: TextStyles.bold20.copyWith(color: context.textPrimary)),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Expanded(child: _buildDropdown(
                  value: _reportType,
                  items: const [
                    DropdownMenuItem(value: 'overall', child: Text('تقرير شامل', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'academic', child: Text('أكاديمي', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'attendance', child: Text('حضور', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'comparison', child: Text('مقارنة', style: TextStyle(fontFamily: 'Cairo'))),
                  ],
                  onChanged: (v) => setState(() => _reportType = v ?? 'overall'),
                )),
                SizedBox(width: 8.w),
                Expanded(child: _buildDropdown(
                  value: _selectedChildId ?? 'all',
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('جميع الأبناء', style: TextStyle(fontFamily: 'Cairo'))),
                    ..._children.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontFamily: 'Cairo')))),
                  ],
                  onChanged: (v) => setState(() => _selectedChildId = v == 'all' ? null : v),
                )),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
            child: _buildDropdown(
              value: _timeRange,
              items: const [
                DropdownMenuItem(value: 'week', child: Text('أسبوع', style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'month', child: Text('شهر', style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'semester', child: Text('فصل دراسي', style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'year', child: Text('سنة', style: TextStyle(fontFamily: 'Cairo'))),
              ],
              onChanged: (v) => setState(() => _timeRange = v ?? 'semester'),
            ),
          ),
          SizedBox(height: 16.h),
          _buildReportContent(),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: context.cardColor,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: context.textPrimary),
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    return ParentAsyncBody(
      loading: _loading,
      error: _error,
      onRetry: _load,
      builder: () {
        final filtered = _selectedChildId != null
            ? _performances.where((p) => p.childId == _selectedChildId).toList()
            : _performances;

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(40.r),
              child: Column(
                children: [
                  Icon(Icons.assessment_outlined, size: 64.sp, color: context.textSecondary.withValues(alpha: .5)),
                  SizedBox(height: 16.h),
                  Text('لا توجد بيانات تقارير', style: TextStyles.semiBold16.copyWith(color: context.textSecondary)),
                ],
              ),
            ),
          );
        }

        final totalAvg = filtered.fold(0.0, (s, p) => s + p.averageGrade) / filtered.length;
        final totalAtt = filtered.fold(0.0, (s, p) => s + p.attendanceRate) / filtered.length;
        final totalComp = filtered.fold(0, (s, p) => s + p.completedAssignments);
        final totalAssign = filtered.fold(0, (s, p) => s + p.totalAssignments);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Expanded(child: ParentStatCard(label: 'الكورسات', value: '${_children.fold(0, (s, c) => s + c.totalCourses)}', icon: Icons.menu_book, color: const Color(0xFF7C3AED))),
                  Expanded(child: ParentStatCard(label: 'متوسط الدرجات', value: '${totalAvg.toStringAsFixed(1)}%', icon: Icons.grade, color: parentGradeColor(totalAvg))),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Expanded(child: ParentStatCard(label: 'متوسط الحضور', value: '${totalAtt.toStringAsFixed(0)}%', icon: Icons.check_circle, color: const Color(0xFF2563EB))),
                  Expanded(child: ParentStatCard(label: 'الواجبات المنجزة', value: '$totalComp/$totalAssign', icon: Icons.assignment_turned_in, color: const Color(0xFF059669))),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text('مقارنة الأبناء', style: TextStyles.bold18.copyWith(color: context.textPrimary)),
            ),
            SizedBox(height: 8.h),
            ...filtered.map((p) => _buildChildComparison(context, p)),
            SizedBox(height: 16.h),
            _buildSubjectComparison(context, filtered),
            SizedBox(height: 16.h),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('تصدير PDF', style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChildComparison(BuildContext context, ChildPerformance perf) {
    final avgColor = parentGradeColor(perf.averageGrade);
    final attColor = parentGradeColor(perf.attendanceRate);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.borderColor.withValues(alpha: .5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(perf.childName, style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                const Spacer(),
                if (perf.classRank != null)
                  Text('الترتيب: #${perf.classRank}', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
              ],
            ),
            SizedBox(height: 8.h),
            _progressRow('المعدل', perf.averageGrade, avgColor),
            SizedBox(height: 4.h),
            _progressRow('الحضور', perf.attendanceRate, attColor),
            SizedBox(height: 4.h),
            Row(
              children: [
                Text('الواجبات: ${perf.completedAssignments}/${perf.totalAssignments}', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                const Spacer(),
                Icon(
                  perf.completedAssignments >= perf.totalAssignments * 0.7
                      ? Icons.trending_up : Icons.trending_down,
                  color: perf.completedAssignments >= perf.totalAssignments * 0.7
                      ? const Color(0xFF059669) : const Color(0xFFEF4444),
                  size: 18.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressRow(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
            const Spacer(),
            Text('${value.toStringAsFixed(1)}%', style: TextStyles.semiBold13.copyWith(color: color)),
          ],
        ),
        SizedBox(height: 2.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            color: color,
            minHeight: 6.h,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectComparison(BuildContext context, List<ChildPerformance> performances) {
    final allSubjects = <String>{};
    final subjectGrades = <String, List<double>>{};
    for (final p in performances) {
      for (final s in p.subjects) {
        allSubjects.add(s.subject);
        subjectGrades.putIfAbsent(s.subject, () => []).add(s.grade);
      }
    }

    if (allSubjects.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ParentGlassCard(
        title: 'أداء المواد',
        icon: Icons.analytics,
        child: Column(
          children: allSubjects.map((subject) {
            final grades = subjectGrades[subject] ?? [];
            final avg = grades.isEmpty ? 0.0 : grades.fold(0.0, (s, g) => s + g) / grades.length;
            final color = parentGradeColor(avg);
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(subject, style: TextStyles.semiBold14.copyWith(color: context.textPrimary))),
                      Text('${avg.toStringAsFixed(1)}%', style: TextStyles.semiBold13.copyWith(color: color)),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: (avg / 100).clamp(0.0, 1.0),
                      backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      color: color,
                      minHeight: 4.h,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
