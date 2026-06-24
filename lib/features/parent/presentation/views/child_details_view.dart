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
  List<ChildTask> _assignments = [];
  List<ChildExamResult> _examResults = [];
  List<Map<String, dynamic>> _pendingExams = [];
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
        repo.getChildPendingExams(widget.childId),
        repo.getChildExamResults(widget.childId),
      ]);
      if (mounted) {
        setState(() {
          _detail = results[0] as ChildDetail;
          _courses = results[1] as List<ChildCourse>;
          _assignments = results[2] as List<ChildTask>;
          _pendingExams = results[3] as List<Map<String, dynamic>>;
          _examResults = results[4] as List<ChildExamResult>;
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
                          SizedBox(width: 12.w),
                          Container(width: 1, height: 40.h, color: context.borderColor),
                          SizedBox(width: 12.w),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Column(
                              children: [
                                Text('${_detail!.averageGrade.round()}%',
                                  style: TextStyles.bold23.copyWith(color: const Color(0xFF2563EB)),
                                ),
                                Text('المتوسط',
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
        final teacherName = c.teacherName != null && c.teacherName!.isNotEmpty ? c.teacherName : null;
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
                  if (teacherName != null)
                    Text(teacherName,
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
    if (_assignments.isEmpty) {
      return _empty('لا توجد واجبات', Icons.assignment);
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      itemCount: _assignments.length,
      itemBuilder: (_, i) {
        final a = _assignments[i];
        final isCompleted = a.status == 'completed';
        final statusColor = isCompleted ? const Color(0xFF059669) : const Color(0xFFF59E0B);
        final statusBg = isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.borderColor.withValues(alpha: .3), width: .5,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            title: Row(
              children: [
                Expanded(
                  child: Text(a.title,
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
                  '${a.courseTitle ?? ''}${a.dueDate != null ? ' • التسليم: ${a.dueDate!.day}/${a.dueDate!.month}/${a.dueDate!.year}' : ''}',
                  style: TextStyles.regular13.copyWith(color: context.textSecondary),
                ),
                if (a.score != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text('الدرجة: ${a.score!.round()}${a.maxScore != null ? '/${a.maxScore!.round()}' : ''}',
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
    final completedExams = _examResults.map((e) {
      final pct = e.percentage ?? (e.maxScore > 0 ? (e.score / e.maxScore) * 100 : 0);
      return _ExamItem(
        id: e.id,
        title: e.title,
        course: e.courseTitle ?? '',
        date: e.submittedAt != null
            ? '${e.submittedAt!.day}/${e.submittedAt!.month}/${e.submittedAt!.year}'
            : '',
        time: '',
        grade: pct,
        status: 'completed',
      );
    }).toList();

    final upcomingFromTasks = _pendingExams.map((e) {
      final rawDate = e['availableFrom'] as String? ?? e['dueDate'] as String?;
      String date = '';
      String time = '';
      if (rawDate != null) {
        final dt = DateTime.tryParse(rawDate);
        if (dt != null) {
          date = _formatDate(rawDate);
          time = e['availableFrom'] != null ? _formatTime(rawDate) : '';
        }
      }
      return _ExamItem(
        id: e['_id'] ?? e['id'] ?? '',
        title: e['title'] ?? '',
        course: e['courseName'] ?? e['courseTitle'] ?? '',
        date: date,
        time: time,
        grade: 0,
        status: 'upcoming',
      );
    }).toList();

    final allExams = [...completedExams, ...upcomingFromTasks];

    if (allExams.isEmpty) {
      return _empty('لا توجد اختبارات', Icons.bar_chart);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      itemCount: allExams.length,
      itemBuilder: (_, i) {
        final exam = allExams[i];
        final isLast = i == allExams.length - 1;
        final isCompleted = exam.status == 'completed';
        final statusFg = isCompleted ? const Color(0xFF059669) : const Color(0xFF2563EB);
        final statusBg = isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF);
        return Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: context.borderColor.withValues(alpha: .3), width: .5,
                    ),
                  ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            title: Row(
              children: [
                Expanded(
                  child: Text(exam.title,
                    style: TextStyles.semiBold16.copyWith(color: context.textPrimary),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(isCompleted ? 'مكتمل' : 'قادم',
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 11.sp,
                      fontWeight: FontWeight.w700, color: statusFg,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${exam.course}${exam.date.isNotEmpty ? ' • ${exam.date}' : ''}${exam.time.isNotEmpty ? ' • ${exam.time}' : ''}',
                  style: TextStyles.regular13.copyWith(color: context.textSecondary),
                ),
                if (exam.grade > 0)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Row(
                      children: [
                        Text('الدرجة: ${exam.grade.round()}%',
                          style: TextStyles.semiBold14.copyWith(color: const Color(0xFF059669)),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          exam.grade >= 80 ? Icons.trending_up : Icons.trending_down,
                          size: 18.sp,
                          color: exam.grade >= 80 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ],
                    ),
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
    final notifs = _detail?.notifications ?? [];
    if (notifs.isEmpty) {
      return _empty('لا يوجد نشاط حديث', Icons.calendar_today);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      itemCount: notifs.length > 10 ? 10 : notifs.length,
      itemBuilder: (_, i) {
        final n = notifs[i];
        final type = n['type'] as String? ?? '';
        final icon = type == 'exam'
            ? Icons.check_circle
            : type == 'assignment'
                ? Icons.warning_amber_rounded
                : Icons.check_circle;
        final iconColor = type == 'exam'
            ? const Color(0xFF059669)
            : type == 'assignment'
                ? const Color(0xFFF59E0B)
                : const Color(0xFF2563EB);
        final text = n['title'] as String? ?? n['body'] as String? ?? '';
        final time = n['createdAt'] as String? ?? n['time'] as String? ?? 'منذ قليل';
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.borderColor.withValues(alpha: .3), width: .5,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            leading: Icon(icon, color: iconColor, size: 22.sp),
            title: Text(text,
              style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
            ),
            subtitle: Text(time,
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

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ExamItem {
  final String id;
  final String title;
  final String course;
  final String date;
  final String time;
  final double grade;
  final String status;
  const _ExamItem({
    required this.id, required this.title, required this.course,
    required this.date, required this.time, required this.grade, required this.status,
  });
}

