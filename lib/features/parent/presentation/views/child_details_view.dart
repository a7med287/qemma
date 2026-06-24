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
  List<ChildCourse> _courses = [];
  List<ChildTask> _tasks = [];
  List<ChildExamResult> _examResults = [];
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
      final results = await Future.wait([
        repo.getChildDashboard(widget.childId),
        repo.getChildCourses(widget.childId),
        repo.getChildTasks(widget.childId),
        repo.getChildExamResults(widget.childId),
      ]);
      if (mounted) {
        setState(() {
          _detail = results[0] as ChildDetail;
          _courses = results[1] as List<ChildCourse>;
          _tasks = results[2] as List<ChildTask>;
          _examResults = results[3] as List<ChildExamResult>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'فشل تحميل بيانات الطالب');
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
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                    child: Row(
                      children: [
                        const ParentBackButton(),
                        SizedBox(width: 12.w),
                        Text('تفاصيل الطالب',
                          style: TextStyles.bold20.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (_detail != null) ...[
                    SizedBox(height: 12.h),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36.r,
                            backgroundColor: const Color(0xFF2563EB),
                            child: Text(
                              _detail!.name.isNotEmpty ? _detail!.name.characters.first : '?',
                              style: TextStyle(
                                fontFamily: 'Cairo', fontWeight: FontWeight.w900,
                                fontSize: 24.sp, color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_detail!.name,
                                  style: TextStyles.bold18.copyWith(
                                    color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(_detail!.gradeLevel.isNotEmpty ? _detail!.gradeLevel : 'غير محدد',
                                  style: TextStyles.regular13.copyWith(color: const Color(0xFF64748B)),
                                ),
                                if (_detail!.email != null || _detail!.phone != null) ...[
                                  SizedBox(height: 6.h),
                                  Wrap(
                                    spacing: 6.w,
                                    runSpacing: 4.h,
                                    children: [
                                      if (_detail!.email != null)
                                        _infoChip(Icons.person, _detail!.email!),
                                      if (_detail!.phone != null)
                                        _infoChip(Icons.phone, _detail!.phone!),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // SizedBox(width: 8.w),
                          // Column(
                          //   children: [
                          //     Text('${_detail!.averageGrade.round()}%',
                          //       style: TextStyles.bold23.copyWith(color: const Color(0xFF2563EB)),
                          //     ),
                          //     Text('المتوسط',
                          //       style: TextStyle(
                          //         fontFamily: 'Cairo', fontSize: 10.sp,
                          //         color: context.textSecondary,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          SizedBox(width: 12.w),
                          Container(width: 1, height: 40.h, color: context.borderColor),
                          SizedBox(width: 12.w),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Column(
                              children: [
                                Text('${_detail!.attendanceRate.round()}%',
                                  style: TextStyles.bold23.copyWith(color: const Color(0xFF059669)),
                                ),
                                Text('الحضور',
                                  style: TextStyle(
                                    fontFamily: 'Cairo', fontSize: 10.sp,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
              labelStyle: TextStyles.semiBold13,
              tabs: const [
                Tab(icon: Icon(Icons.school, size: 18), text: 'الكورسات'),
                Tab(icon: Icon(Icons.assignment, size: 18), text: 'الواجبات'),
                Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'الاختبارات'),
                Tab(icon: Icon(Icons.calendar_today, size: 18), text: 'النشاط'),
              ],
            ),
          ),
          Expanded(
            child: ParentAsyncBody(
              loading: _loading,
              error: _error,
              onRetry: _load,
              builder: () {
                if (_tab == 0) return _buildCourses();
                if (_tab == 1) return _buildAssignments();
                if (_tab == 2) return _buildExams();
                return _buildActivities();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF334155) : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Courses Tab ──

  Widget _buildCourses() {
    if (_courses.isEmpty) {
      return _empty('لا توجد كورسات مسجلة', Icons.menu_book);
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      itemCount: _courses.length,
      itemBuilder: (_, i) {
        final c = _courses[i];
        final gradeColor = parentGradeColor(c.grade);
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context, '/parent/child/${widget.childId}/course/${c.id}'),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(16.r),
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
                      Expanded(
                        child: Text(c.title,
                          style: TextStyles.semiBold16.copyWith(color: context.textPrimary),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(c.grade > 0 ? '${c.grade.round()}%' : '-',
                          style: TextStyles.semiBold13.copyWith(color: gradeColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(c.teacherName ?? 'غير محدد',
                    style: TextStyles.regular13.copyWith(color: context.textSecondary),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الدرجة: ${c.grade > 0 ? '${c.grade.round()}%' : '-'}',
                        style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                      ),
                      Text('التقدم: ${c.progress.round()}%',
                        style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: (c.progress / 100).clamp(0.0, 1.0),
                      minHeight: 8.h,
                      backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      color: c.progress >= 80 ? const Color(0xFF059669) : const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Assignments Tab ──

  Widget _buildAssignments() {
    if (_tasks.isEmpty) {
      return _empty('لا توجد واجبات', Icons.assignment);
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      itemCount: _tasks.length,
      itemBuilder: (_, i) {
        final t = _tasks[i];
        final isCompleted = t.status == 'completed';
        final statusColor = isCompleted ? const Color(0xFF059669) : const Color(0xFFF59E0B);
        final statusBg = isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
        return Container(
          margin: EdgeInsets.only(bottom: 4.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.borderColor.withValues(alpha: .3), width: .5,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            title: Row(
              children: [
                Expanded(
                  child: Text(t.title,
                    style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(isCompleted ? 'مكتمل' : 'معلق',
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 11.sp,
                      fontWeight: FontWeight.w700, color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.courseTitle ?? ''}${t.dueDate != null ? ' • التسليم: ${t.dueDate!.day}/${t.dueDate!.month}/${t.dueDate!.year}' : ''}',
                  style: TextStyles.regular13.copyWith(color: context.textSecondary),
                ),
                if (t.score != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text('الدرجة: ${t.score!.round()}${t.maxScore != null ? '/${t.maxScore!.round()}' : ''}',
                      style: TextStyles.semiBold14.copyWith(color: const Color(0xFF059669)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Exams Tab ──

  Widget _buildExams() {
    final sorted = _examResults.where((e) => e.maxScore > 0).toList();
    if (sorted.isEmpty && _examResults.isEmpty) {
      return _empty('لا توجد اختبارات', Icons.bar_chart);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      itemCount: _examResults.length,
      itemBuilder: (_, i) {
        final e = _examResults[i];
        final percent = e.maxScore > 0 ? (e.score / e.maxScore) * 100 : 0.0;
        final hasPrevious = e.previousScore != null;
        return Container(
          margin: EdgeInsets.only(bottom: 4.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.borderColor.withValues(alpha: .3), width: .5,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            title: Row(
              children: [
                Expanded(
                  child: Text(e.title,
                    style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: e.passed ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(e.passed ? 'مكتمل' : 'قادم',
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: e.passed ? const Color(0xFF059669) : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (e.courseTitle != null)
                  Text(e.courseTitle!,
                    style: TextStyles.regular13.copyWith(color: context.textSecondary),
                  ),
                if (percent > 0)
                  Row(
                    children: [
                      Text('الدرجة: ${percent.round()}%',
                        style: TextStyles.semiBold14.copyWith(color: const Color(0xFF059669)),
                      ),
                      if (hasPrevious) ...[
                        SizedBox(width: 6.w),
                        Icon(
                          e.score >= (e.previousScore ?? 0) ? Icons.trending_up : Icons.trending_down,
                          size: 18.sp,
                          color: e.score >= (e.previousScore ?? 0)
                              ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Activities Tab ──

  Widget _buildActivities() {
    // Derive activities from exam results (matching frontend pattern)
    final activities = <_ActivityItem>[];
    for (final e in _examResults) {
      activities.add(_ActivityItem(
        type: 'success',
        text: e.passed ? 'اجتاز اختبار ${e.title}' : 'لم يجتاز اختبار ${e.title}',
        time: 'منذ فترة',
      ));
    }
    for (final t in _tasks.where((t) => t.status == 'completed')) {
      activities.add(_ActivityItem(
        type: 'warning',
        text: 'أتم ${t.title}',
        time: t.dueDate != null ? '${t.dueDate!.day}/${t.dueDate!.month}/${t.dueDate!.year}' : 'منذ فترة',
      ));
    }

    if (activities.isEmpty) {
      return _empty('لا يوجد نشاط حديث', Icons.calendar_today);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      itemCount: activities.length,
      itemBuilder: (_, i) {
        final a = activities[i];
        IconData icon;
        Color iconColor;
        switch (a.type) {
          case 'success':
            icon = Icons.check_circle; iconColor = const Color(0xFF059669);
          case 'warning':
            icon = Icons.warning_amber_rounded; iconColor = const Color(0xFFF59E0B);
          case 'error':
            icon = Icons.cancel; iconColor = const Color(0xFFDC2626);
          default:
            icon = Icons.check_circle; iconColor = const Color(0xFF2563EB);
        }
        return Container(
          margin: EdgeInsets.only(bottom: 4.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.borderColor.withValues(alpha: .3), width: .5,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            leading: Icon(icon, color: iconColor, size: 22.sp),
            title: Text(a.text,
              style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
            ),
            subtitle: Text(a.time,
              style: TextStyles.regular13.copyWith(color: context.textSecondary),
            ),
          ),
        );
      },
    );
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

class _ActivityItem {
  final String type;
  final String text;
  final String time;
  const _ActivityItem({required this.type, required this.text, required this.time});
}
