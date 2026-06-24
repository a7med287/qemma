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

class CourseDetailsView extends StatefulWidget {
  final String childId;
  final String courseId;
  const CourseDetailsView({super.key, required this.childId, required this.courseId});

  @override
  State<CourseDetailsView> createState() => _CourseDetailsViewState();
}

class _CourseDetailsViewState extends State<CourseDetailsView>
    with SingleTickerProviderStateMixin {
  CourseDetail? _detail;
  bool _loading = true;
  String? _error;
  late final TabController _tabCtrl;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
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
      final detail = await context.read<ParentRepository>().getChildCourseDetails(widget.childId, widget.courseId);
      setState(() => _detail = detail);
    } catch (e) {
      setState(() => _error = 'فشل تحميل بيانات الكورس');
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
                    Text(_detail!.title, style: TextStyles.bold20.copyWith(color: Colors.white)),
                    if (_detail!.teacherName != null)
                      Text('مدرس: ${_detail!.teacherName}', style: TextStyles.regular13.copyWith(color: Colors.white70)),
                    SizedBox(height: 8.h),
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
              isScrollable: true,
              tabs: const [
                Tab(text: 'الواجبات'),
                Tab(text: 'الحصص'),
                Tab(text: 'الامتحانات'),
                Tab(text: 'سجل الدرجات'),
                Tab(text: 'سجل الحضور'),
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

                if (_tab == 0) return _statsRow(detail);
                if (_loading) return const SizedBox.shrink();

                switch (_tab) {
                  case 0: return _buildAssignments(detail);
                  case 1: return _buildSessions(detail);
                  case 2: return _buildExams(detail);
                  case 3: return _buildGradeRecords(detail);
                  case 4: return _buildAttendanceRecords(detail);
                  default: return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(CourseDetail detail) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
          child: Row(
            children: [
              Expanded(child: ParentStatCard(label: 'المعدل', value: '${detail.averageGrade.toStringAsFixed(1)}%', icon: Icons.grade, color: parentGradeColor(detail.averageGrade))),
              Expanded(child: ParentStatCard(label: 'الحضور', value: '${detail.attendanceRate.toStringAsFixed(0)}%', icon: Icons.check_circle, color: const Color(0xFF2563EB))),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            children: [
              Expanded(child: ParentStatCard(label: 'الحصص', value: '${detail.attendedSessions}/${detail.totalSessions}', icon: Icons.videocam, color: const Color(0xFF7C3AED))),
              Expanded(child: ParentStatCard(label: 'الواجبات المعلقة', value: '${detail.pendingAssignments}', icon: Icons.assignment, color: const Color(0xFFD97706))),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        if (_buildTabContent(detail) case final w?) w,
      ],
    );
  }

  Widget? _buildTabContent(CourseDetail detail) {
    switch (_tab) {
      case 0: return _buildAssignments(detail);
      case 1: return _buildSessions(detail);
      case 2: return _buildExams(detail);
      case 3: return _buildGradeRecords(detail);
      case 4: return _buildAttendanceRecords(detail);
      default: return null;
    }
  }

  Widget _buildAssignments(CourseDetail detail) {
    final items = detail.assignments;
    if (items.isEmpty) return _empty('لا توجد واجبات');
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final a = items[i];
        final statusColor = parentStatusColor(a.status);
        return _listTile(
          title: a.title,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (a.score != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: parentGradeColor(a.score!).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text('${a.score!.toStringAsFixed(0)}/${a.maxScore?.toStringAsFixed(0) ?? '100'}',
                      style: TextStyles.semiBold13.copyWith(color: parentGradeColor(a.score!))),
                ),
              if (statusColor != null) ...[
                SizedBox(width: 8.w),
                _statusChip(a.status, statusColor),
              ],
            ],
          ),
          subtitle: a.dueDate != null ? 'تاريخ الاستحقاق: ${a.dueDate!.day}/${a.dueDate!.month}/${a.dueDate!.year}' : null,
        );
      },
    );
  }

  Widget _buildSessions(CourseDetail detail) {
    final items = detail.sessions;
    if (items.isEmpty) return _empty('لا توجد حصص');
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final s = items[i];
        return _listTile(
          title: s.title,
          subtitle: '${s.date.day}/${s.date.month}/${s.date.year}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.isLive)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text('مباشر', style: TextStyles.semiBold13.copyWith(color: const Color(0xFFEF4444))),
                ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (s.attended ? const Color(0xFF059669) : const Color(0xFFEF4444)).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(s.attended ? 'حضر' : 'غائب',
                    style: TextStyles.semiBold13.copyWith(color: s.attended ? const Color(0xFF059669) : const Color(0xFFEF4444))),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExams(CourseDetail detail) {
    final items = detail.exams;
    if (items.isEmpty) return _empty('لا توجد امتحانات');
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final e = items[i];
        final statusColor = parentStatusColor(e.status);
        return _listTile(
          title: e.title,
          subtitle: e.date != null ? '${e.date!.day}/${e.date!.month}/${e.date!.year}' : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (e.score != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: parentGradeColor(e.score!).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text('${e.score!.toStringAsFixed(0)}/${e.maxScore?.toStringAsFixed(0) ?? '100'}',
                      style: TextStyles.semiBold13.copyWith(color: parentGradeColor(e.score!))),
                ),
              if (statusColor != null) ...[
                SizedBox(width: 8.w),
                _statusChip(e.status, statusColor),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeRecords(CourseDetail detail) {
    final items = detail.gradeRecords;
    if (items.isEmpty) return _empty('لا توجد درجات مسجلة');
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final g = items[i];
        final color = parentGradeColor(g.percentage);
        return _listTile(
          title: g.examTitle,
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text('${g.score.toStringAsFixed(0)}/${g.maxScore.toStringAsFixed(0)} (${g.grade})',
                style: TextStyles.semiBold13.copyWith(color: color)),
          ),
          subtitle: '${g.percentage.toStringAsFixed(1)}%',
        );
      },
    );
  }

  Widget _buildAttendanceRecords(CourseDetail detail) {
    final items = detail.attendanceRecords;
    if (items.isEmpty) return _empty('لا توجد سجلات حضور');
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final a = items[i];
        return _listTile(
          title: a.sessionTitle,
          subtitle: '${a.date.day}/${a.date.month}/${a.date.year}',
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: (a.present ? const Color(0xFF059669) : const Color(0xFFEF4444)).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(a.present ? 'حاضر' : 'غائب',
                style: TextStyles.semiBold13.copyWith(color: a.present ? const Color(0xFF059669) : const Color(0xFFEF4444))),
          ),
        );
      },
    );
  }

  Widget _listTile({
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
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
                  Text(title, style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(subtitle, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(parentStatusLabel(status), style: TextStyles.semiBold13.copyWith(color: color)),
    );
  }

  Widget _empty(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64.sp, color: context.textSecondary.withValues(alpha: .5)),
          SizedBox(height: 16.h),
          Text(text, style: TextStyles.semiBold16.copyWith(color: context.textSecondary)),
        ],
      ),
    );
  }
}
