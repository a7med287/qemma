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
  Map<String, ChildPerformance> _performances = {};
  bool _loading = true;
  String? _error;
  String _reportType = 'overall';
  String? _selectedChildId;
  String _timeRange = 'month';

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
      final perfMap = <String, ChildPerformance>{};
      await Future.wait(children.map((child) async {
        try {
          perfMap[child.id] = await repo.getChildPerformance(child.id);
        } catch (_) {}
      }));
      if (mounted) setState(() { _children = children; _performances = perfMap; });
    } catch (e) {
      if (mounted) setState(() => _error = 'فشل تحميل التقارير');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ChildSummary> get _filtered =>
      _selectedChildId != null
          ? _children.where((c) => c.id == _selectedChildId).toList()
          : _children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ParentGradientHeader(
            leading: const ParentBackButton(),
            title: 'التقارير والإحصائيات',
            subtitle: 'تقارير شاملة عن أداء الأبناء',
            trailing: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('تصدير PDF', style: TextStyle(fontFamily: 'Cairo')),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: .2),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ),
          Expanded(
            child: ParentAsyncBody(
              loading: _loading,
              error: _error,
              onRetry: _load,
              builder: () => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilters(),
                    SizedBox(height: 16.h),
                    _buildStatsGrid(),
                    SizedBox(height: 16.h),
                    _buildChildrenComparison(),
                    SizedBox(height: 16.h),
                    _buildSubjectPerformance(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _dropdown(
              value: _reportType,
              items: const [
                DropdownMenuItem(value: 'overall', child: Text('شامل', style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'academic', child: Text('أكاديمي', style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'attendance', child: Text('الحضور', style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'comparison', child: Text('مقارنة', style: TextStyle(fontFamily: 'Cairo'))),
              ],
              onChanged: (v) => setState(() => _reportType = v ?? 'overall'),
            )),
            SizedBox(width: 12.w),
            Expanded(child: _dropdown(
              value: _selectedChildId ?? 'all',
              items: [
                const DropdownMenuItem(value: 'all', child: Text('الكل', style: TextStyle(fontFamily: 'Cairo'))),
                ..._children.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontFamily: 'Cairo')))),
              ],
              onChanged: (v) => setState(() => _selectedChildId = v == 'all' ? null : v),
            )),
          ],
        ),
        SizedBox(height: 12.h),
        _dropdown(
          value: _timeRange,
          items: const [
            DropdownMenuItem(value: 'week', child: Text('هذا الأسبوع', style: TextStyle(fontFamily: 'Cairo'))),
            DropdownMenuItem(value: 'month', child: Text('هذا الشهر', style: TextStyle(fontFamily: 'Cairo'))),
            DropdownMenuItem(value: 'semester', child: Text('الفصل الدراسي', style: TextStyle(fontFamily: 'Cairo'))),
            DropdownMenuItem(value: 'year', child: Text('السنة الدراسية', style: TextStyle(fontFamily: 'Cairo'))),
          ],
          onChanged: (v) => setState(() => _timeRange = v ?? 'month'),
        ),
      ],
    );
  }

  Widget _dropdown({
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

  Widget _buildStatsGrid() {
    final filtered = _filtered;
    final totalCourses = filtered.fold(0, (s, c) => s + c.totalCourses);
    final avgGrade = filtered.isEmpty ? 0.0 : filtered.fold(0.0, (s, c) => s + c.averageGrade) / filtered.length;
    final avgAtt = filtered.isEmpty ? 0.0 : filtered.fold(0.0, (s, c) => s + c.attendanceRate) / filtered.length;
    final totalAssign = filtered.fold(0, (s, c) {
      final perf = _performances[c.id];
      return s + (perf?.completedAssignments ?? 0);
    });

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard(
              icon: Icons.school, color: const Color(0xFF7C3AED),
              value: '$totalCourses', label: 'إجمالي الكورسات',
            )),
            SizedBox(width: 12.w),
            Expanded(child: _statCard(
              icon: Icons.assessment, color: const Color(0xFF2563EB),
              value: '${avgGrade.round()}%', label: 'متوسط الدرجات',
            )),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _statCard(
              icon: Icons.trending_up, color: const Color(0xFF059669),
              value: '${avgAtt.round()}%', label: 'متوسط الحضور',
            )),
            SizedBox(width: 12.w),
            Expanded(child: _statCard(
              icon: Icons.assignment, color: const Color(0xFFF59E0B),
              value: '$totalAssign', label: 'واجبات مكتملة',
            )),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.borderColor.withValues(alpha: .5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32.sp, color: color),
          SizedBox(height: 8.h),
          Text(value, style: TextStyles.bold23.copyWith(color: context.textPrimary)),
          SizedBox(height: 2.h),
          Text(label, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildChildrenComparison() {
    final filtered = _filtered;
    if (filtered.isEmpty) return const SizedBox.shrink();

    final avatars = <Color>[
      const Color(0xFF2563EB), const Color(0xFF7C3AED),
      const Color(0xFF059669), const Color(0xFFF59E0B), const Color(0xFFDC2626),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Row(
              children: [
                Icon(Icons.compare_arrows, color: const Color(0xFF2563EB), size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  filtered.length == 1
                      ? 'تقارير ${filtered.first.name}'
                      : 'مقارنة بين الأبناء',
                  style: TextStyles.semiBold16.copyWith(color: context.textPrimary),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
            child: Table(
              columnWidths: const <int, TableColumnWidth>{
                0: FixedColumnWidth(130),
                1: FixedColumnWidth(120),
                2: FixedColumnWidth(70),
                3: FixedColumnWidth(90),
                4: FixedColumnWidth(75),
                5: FixedColumnWidth(50),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  children: [
                    _headerCell('الطالب'),
                    _headerCell('المتوسط'),
                    _headerCell('الحضور'),
                    _headerCell('الواجبات'),
                    _headerCell('الترتيب'),
                    _headerCell('الاتجاه'),
                  ],
                ),
                ...filtered.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final child = entry.value;
                  final perf = _performances[child.id];
                  final avgGrade = child.averageGrade;
                  final att = child.attendanceRate;
                  final completed = perf?.completedAssignments ?? 0;
                  final total = perf?.totalAssignments ?? 0;
                  final rank = perf?.classRank;
                  final trendUp = perf == null || (completed >= total * 0.7 || avgGrade >= 75);

                  return TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16.r,
                              backgroundColor: avatars[idx % avatars.length],
                              child: Text(
                                child.name.isNotEmpty ? child.name.characters.first : '?',
                                style: TextStyle(
                                  fontFamily: 'Cairo', fontWeight: FontWeight.w900,
                                  fontSize: 12.sp, color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(child.name,
                                style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${avgGrade.round()}%',
                              style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                            ),
                            SizedBox(height: 4.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3.r),
                              child: LinearProgressIndicator(
                                value: (avgGrade / 100).clamp(0.0, 1.0),
                                minHeight: 6.h,
                                backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                color: avgGrade >= 80 ? const Color(0xFF059669) : const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                        child: Text('${att.round()}%',
                          style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                        child: Text(
                          perf != null ? '$completed/$total' : '-',
                          style: TextStyles.regular14.copyWith(color: context.textSecondary),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                        child: rank != null
                            ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: rank == 1
                                      ? const Color(0xFFFEF3C7)
                                      : (context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emoji_events, size: 14.sp,
                                      color: rank == 1 ? const Color(0xFFF59E0B) : const Color(0xFF6B7280),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text('#$rank',
                                      style: TextStyle(
                                        fontFamily: 'Cairo', fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: rank == 1 ? const Color(0xFFF59E0B) : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Text('-', style: TextStyles.regular14.copyWith(color: context.textSecondary)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                        child: Icon(
                          trendUp ? Icons.trending_up : Icons.trending_down,
                          color: trendUp ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          size: 20.sp,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      child: Text(text,
        style: TextStyles.semiBold13.copyWith(color: context.textPrimary),
      ),
    );
  }

  Widget _buildSubjectPerformance() {
    final filtered = _filtered;
    if (filtered.isEmpty) return const SizedBox.shrink();

    final allSubjects = <String>{};
    final subjectGrades = <String, Map<String, double?>>{};
    for (final child in filtered) {
      final perf = _performances[child.id];
      if (perf != null) {
        for (final s in perf.subjects) {
          allSubjects.add(s.subject);
          subjectGrades.putIfAbsent(s.subject, () => {});
          subjectGrades[s.subject]![child.id] = s.grade;
        }
      }
    }

    if (allSubjects.isEmpty) return const SizedBox.shrink();

    final subjectList = allSubjects.toList();
    final colCount = filtered.length + 1;
    final colWidths = <int, TableColumnWidth>{
      0: FixedColumnWidth(100),
    };
    for (var i = 1; i < colCount; i++) {
      colWidths[i] = const FixedColumnWidth(80);
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Row(
              children: [
                Icon(Icons.assessment, color: const Color(0xFF7C3AED), size: 20.sp),
                SizedBox(width: 8.w),
                Text('الأداء حسب المادة',
                  style: TextStyles.semiBold16.copyWith(color: context.textPrimary),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
            child: Table(
              columnWidths: colWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  children: [
                    _headerCell('المادة'),
                    ...filtered.map((child) => _headerCell(child.name)),
                  ],
                ),
                ...subjectList.map((subject) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                        child: Text(subject,
                          style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                        ),
                      ),
                      ...filtered.map((child) {
                        final grade = subjectGrades[subject]?[child.id];
                        final color = grade != null
                            ? (grade >= 80 ? const Color(0xFF059669) : const Color(0xFFF59E0B))
                            : const Color(0xFF94A3B8);
                        final bg = grade != null
                            ? (grade >= 80 ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB))
                            : const Color(0xFFF3F4F6);
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text(
                              grade != null ? '${grade.round()}%' : '-',
                              style: TextStyle(
                                fontFamily: 'Cairo', fontSize: 11.sp,
                                fontWeight: FontWeight.w700, color: color,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
