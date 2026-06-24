import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/parent_models.dart';
import '../../data/repositories/parent_repository.dart';
import '../widgets/parent_async_body.dart';
import '../widgets/parent_shared_widgets.dart';

class ChildDetailsView extends StatefulWidget {
  final String childId;
  const ChildDetailsView({super.key, required this.childId});

  @override
  State<ChildDetailsView> createState() => _ChildDetailsViewState();
}

class _ChildDetailsViewState extends State<ChildDetailsView>
    with SingleTickerProviderStateMixin {
  ChildDetail? _detail;
  bool _loading = true;
  String? _error;
  late final TabController _tabCtrl;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() => _tab = _tabCtrl.index);
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = context.read<ParentRepository>();
      final detail = await repo.getChildDashboard(widget.childId);
      setState(() => _detail = detail);
    } catch (e) {
      setState(() => _error = 'فشل تحميل بيانات الطالب');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const ParentBackButton(),
                      const Spacer(),
                    ],
                  ),
                  if (_detail != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28.r,
                          backgroundColor: Colors.white.withValues(alpha: .2),
                          child: Text(
                            _detail!.name.isNotEmpty ? _detail!.name[0] : '?',
                            style: TextStyles.bold20.copyWith(color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_detail!.name, style: TextStyles.bold20.copyWith(color: Colors.white)),
                              Text(_detail!.gradeLevel, style: TextStyles.regular13.copyWith(color: Colors.white70)),
                              if (_detail!.email != null || _detail!.phone != null)
                                Text('${_detail!.email ?? ''}  ${_detail!.phone ?? ''}',
                                    style: TextStyles.regular13.copyWith(color: Colors.white60)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text('${_detail!.averageGrade.toStringAsFixed(1)}%', style: TextStyles.bold18.copyWith(color: Colors.white)),
                            Text('المعدل', style: TextStyles.regular13.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
          Material(
            color: context.cardColor,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.gradientMid,
              unselectedLabelColor: context.textSecondary,
              indicatorColor: AppColors.gradientMid,
              tabs: const [
                Tab(text: 'الكورسات'),
                Tab(text: 'الواجبات'),
                Tab(text: 'الامتحانات'),
                Tab(text: 'النشاطات'),
              ],
            ),
          ),
          Expanded(
            child: ParentAsyncBody(
              loading: _loading,
              error: _error,
              onRetry: _load,
              builder: () {
                final detail = _detail;
                if (detail == null) return const SizedBox.shrink();
                switch (_tab) {
                  case 0: return _buildCourses(detail);
                  case 1: return _buildAssignments(detail);
                  case 2: return _buildExams(detail);
                  case 3: return _buildActivities(detail);
                  default: return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourses(ChildDetail detail) {
    if (detail.courses.isEmpty) {
      return _empty('لا توجد كورسات مسجلة', Icons.menu_book);
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: detail.courses.length,
      itemBuilder: (_, i) {
        final c = detail.courses[i];
        final gradeColor = parentGradeColor(c.grade);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/parent/child/${widget.childId}/course/${c.id}'),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: context.borderColor.withValues(alpha: .5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(c.title, style: TextStyles.semiBold16.copyWith(color: context.textPrimary))),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text('${c.grade.toStringAsFixed(1)}%', style: TextStyles.semiBold13.copyWith(color: gradeColor)),
                      ),
                    ],
                  ),
                  if (c.teacherName != null) ...[
                    SizedBox(height: 4.h),
                    Text('مدرس: ${c.teacherName}', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                  ],
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      _courseStat('التقدم', '${c.progress.toStringAsFixed(0)}%'),
                      _courseStat('الحصص', '${c.attendedSessions}/${c.totalSessions}'),
                      _courseStat('الواجبات', '${c.pendingAssignments} معلقة'),
                    ],
                  ),
                  if (c.progress > 0) ...[
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: c.progress / 100,
                        backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        color: gradeColor,
                        minHeight: 4.h,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _courseStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyles.semiBold13.copyWith(color: context.textPrimary)),
          Text(label, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAssignments(ChildDetail detail) {
    if (detail.tasks.isEmpty) {
      return _empty('لا توجد واجبات', Icons.assignment);
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: detail.tasks.length,
      itemBuilder: (_, i) {
        final t = detail.tasks[i];
        final statusColor = parentStatusColor(t.status);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: context.borderColor.withValues(alpha: .5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title, style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                      if (t.courseTitle != null)
                        Text(t.courseTitle!, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                      if (t.dueDate != null)
                        Text('تاريخ الاستحقاق: ${t.dueDate!.day}/${t.dueDate!.month}/${t.dueDate!.year}',
                            style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                    ],
                  ),
                ),
                if (t.score != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: parentGradeColor(t.score!).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text('${t.score!.toStringAsFixed(0)}/${t.maxScore?.toStringAsFixed(0) ?? '100'}',
                        style: TextStyles.semiBold13.copyWith(color: parentGradeColor(t.score!))),
                  ),
                if (statusColor != null) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(parentStatusLabel(t.status),
                        style: TextStyles.semiBold13.copyWith(color: statusColor)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExams(ChildDetail detail) {
    if (detail.examResults.isEmpty) {
      return _empty('لا توجد نتائج امتحانات', Icons.quiz);
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: detail.examResults.length,
      itemBuilder: (_, i) {
        final e = detail.examResults[i];
        final percent = e.maxScore > 0 ? (e.score / e.maxScore) * 100 : 0.0;
        final gradeColor = parentGradeColor(percent);
        final hasTrend = e.previousScore != null;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: context.borderColor.withValues(alpha: .5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title, style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                      if (e.courseTitle != null)
                        Text(e.courseTitle!, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text('${e.score.toStringAsFixed(0)}/${e.maxScore.toStringAsFixed(0)}',
                      style: TextStyles.semiBold13.copyWith(color: gradeColor)),
                ),
                if (hasTrend) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    e.score >= (e.previousScore ?? 0) ? Icons.trending_up : Icons.trending_down,
                    color: e.score >= (e.previousScore ?? 0) ? const Color(0xFF059669) : const Color(0xFFEF4444),
                    size: 18.sp,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivities(ChildDetail detail) {
    return _empty('النشاطات قريباً', Icons.history);
  }

  Widget _empty(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.sp, color: context.textSecondary.withValues(alpha: .5)),
          SizedBox(height: 16.h),
          Text(text, style: TextStyles.semiBold16.copyWith(color: context.textSecondary)),
        ],
      ),
    );
  }
}
