import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/views/login_view.dart';
import '../../data/models/parent_models.dart';
import '../../data/repositories/parent_repository.dart';
import '../routes/parent_routes.dart';
import '../widgets/parent_async_body.dart';
import '../widgets/parent_shared_widgets.dart';

class ParentDashboardView extends StatefulWidget {
  static const routeName = ParentRoutes.dashboard;
  const ParentDashboardView({super.key});

  @override
  State<ParentDashboardView> createState() => _ParentDashboardViewState();
}

class _ParentDashboardViewState extends State<ParentDashboardView> {
  ParentDashboardData? _data;
  bool _loading = true;
  String? _error;
  bool _showAddChild = false;

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
      final repo = context.read<ParentRepository>();
      final children = await repo.getChildren();
      int activeCourses = 0;
      int pendingAssignments = 0;
      int alerts = 0;
      final activities = <RecentActivity>[];
      final events = <UpcomingEvent>[];

      for (final child in children) {
        activeCourses += child.totalCourses;
        pendingAssignments += child.pendingAssignments;
        alerts += child.alerts;

        // Extract recent activities from notifications (frontend pattern)
        final notifs = child.notifications.take(3);
        int notifId = 0;
        for (final n in notifs) {
          final type = n['type'] ?? '';
          final title = n['title'] ?? n['message'] ?? '';
          final time = n['createdAt'] ?? n['timestamp'];
          activities.add(
            RecentActivity(
              id: '${child.id}_notif_$notifId',
              type: type == 'exam'
                  ? 'success'
                  : type == 'assignment'
                  ? 'warning'
                  : 'info',
              childName: child.name.split(' ').firstOrNull ?? child.name,
              text: title is String ? title : '',
              timestamp: time != null
                  ? DateTime.tryParse(time.toString()) ?? DateTime.now()
                  : DateTime.now(),
            ),
          );
          notifId++;
        }

        // Extract upcoming events from tasks (frontend pattern)
        final incompleteTasks = child.tasks
            .where((t) => t.status != 'completed')
            .take(3);
        for (final t in incompleteTasks) {
          final isExam =
              t.status == 'upcoming' ||
              (t.title.toLowerCase().contains('اختبار') ||
                  t.title.toLowerCase().contains('امتحان'));
          events.add(
            UpcomingEvent(
              id: t.id,
              childName: child.name.split(' ').firstOrNull ?? child.name,
              type: isExam ? 'exam' : 'assignment',
              title: t.title,
              date: t.dueDate ?? DateTime.now(),
              time: null,
            ),
          );
        }
      }

      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _data = ParentDashboardData(
          children: children,
          totalChildren: children.length,
          activeCourses: activeCourses,
          pendingAssignments: pendingAssignments,
          alerts: alerts,
          recentActivities: activities.take(5).toList(),
          upcomingEvents: events.take(5).toList(),
        );
      });
    } catch (e) {
      setState(() => _error = 'فشل تحميل البيانات');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22.r,
                        backgroundColor: Colors.white.withValues(alpha: .2),
                        child: Text(
                          (user?.name ?? '?')[0],
                          style: TextStyles.bold18.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحباً، ${user?.name ?? ''}',
                              style: TextStyles.semiBold16.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'ولي أمر',
                              style: TextStyles.regular13.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          ParentRoutes.notifications,
                        ),
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (v) {
                          if (v == 'profile') {
                            Navigator.pushNamed(context, ParentRoutes.profile);
                          } else if (v == 'logout') {
                            context.read<AuthCubit>().logout();
                            Navigator.pushNamedAndRemoveUntil(context, LoginView.routeName, (_) => false);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'الملف الشخصي',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.exit_to_app,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'تسجيل الخروج',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
          Expanded(
            child: ParentAsyncBody(
              loading: _loading,
              error: _error,
              onRetry: _load,
              builder: () => _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Expanded(
                  child: ParentStatCard(
                    label: 'الأبناء',
                    value: '${data.totalChildren}',
                    icon: Icons.people,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ParentStatCard(
                    label: 'الكورسات النشطة',
                    value: '${data.activeCourses}',
                    icon: Icons.menu_book,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Expanded(
                  child: ParentStatCard(
                    label: 'الواجبات المعلقة',
                    value: '${data.pendingAssignments}',
                    icon: Icons.assignment,
                    color: const Color(0xFFD97706),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ParentStatCard(
                    label: 'التنبيهات',
                    value: '${data.alerts}',
                    icon: Icons.warning_amber,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          if (data.children.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'نظرة عامة على الأبناء',
              Icons.family_restroom,
              showViewAll: true,
            ),
            ...data.children.map((child) => _buildChildCard(context, child)),
            if (_showAddChild) _buildAddChildModal(context),
          ] else ...[
            Center(
              child: Padding(
                padding: EdgeInsets.all(40.r),
                child: Column(
                  children: [
                    Icon(
                      Icons.family_restroom,
                      size: 80.sp,
                      color: context.textSecondary.withValues(alpha: .3),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'لا يوجد أبناء مسجلين',
                      style: TextStyles.semiBold16.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'أضف ابنك/ابنتك باستخدام اسم المستخدم الخاص بهم',
                      style: TextStyles.regular13.copyWith(
                        color: context.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.h),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showAddChild = true),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'إضافة طالب',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientMid,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                    if (_showAddChild) _buildAddChildModal(context),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 12.h),
          _buildQuickActions(context),
          SizedBox(height: 12.h),
          _buildUpcomingEvents(context, data),
          SizedBox(height: 12.h),
          _buildRecentActivities(context, data),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData? icon, {
    bool showViewAll = false,
    VoidCallback? onAdd,
    bool showAdd = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20.sp, color: context.textPrimary),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyles.bold18.copyWith(color: context.textPrimary),
            ),
          ),
          if (showAdd)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'إضافة طالب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (showViewAll)
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, ParentRoutes.children),
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildSummary child) {
    final avgColor = parentGradeColor(child.averageGrade);
    final progressColor = parentGradeColor(child.overallProgress);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/parent/child/${child.id}'),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: context.borderColor.withValues(alpha: .5),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: AppColors.gradientMid.withValues(
                      alpha: .12,
                    ),
                    child: Text(
                      child.name.isNotEmpty ? child.name[0] : '?',
                      style: TextStyles.bold18.copyWith(
                        color: AppColors.gradientMid,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: TextStyles.semiBold16.copyWith(
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          child.gradeLevel,
                          style: TextStyles.regular13.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (child.behaviorAlert != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '⚠️ ${child.behaviorAlert!}',
                        style: TextStyles.semiBold13.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _miniStat(
                    'المعدل',
                    '${child.averageGrade.toStringAsFixed(1)}%',
                    avgColor,
                    trailing: Icon(
                      child.averageGrade >= 80
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 16.sp,
                      color: child.averageGrade >= 80
                          ? const Color(0xFF059669)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  _miniStat(
                    'الحضور',
                    '${child.attendanceRate.toStringAsFixed(0)}%',
                    const Color(0xFF2563EB),
                  ),
                  _miniStat(
                    'الكورسات',
                    '${child.totalCourses}',
                    const Color(0xFF7C3AED),
                  ),
                  _miniStat(
                    'الواجبات',
                    '${child.pendingAssignments}',
                    child.pendingAssignments > 0
                        ? const Color(0xFFD97706)
                        : context.textPrimary,
                  ),
                ],
              ),
              if (child.overallProgress > 0) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      'التقدم الكلي',
                      style: TextStyles.regular13.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${child.overallProgress.toStringAsFixed(0)}%',
                      style: TextStyles.semiBold13.copyWith(
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: child.overallProgress / 100,
                    backgroundColor: context.isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    color: progressColor,
                    minHeight: 6.h,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(
    String label,
    String value,
    Color color, {
    Widget? trailing,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyles.regular13.copyWith(color: context.textSecondary),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Text(value, style: TextStyles.semiBold14.copyWith(color: color)),
              if (trailing != null) ...[SizedBox(width: 2.w), trailing],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(
    BuildContext context,
    ParentDashboardData data,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
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
            Text(
              'النشاط الأخير',
              style: TextStyles.bold18.copyWith(color: context.textPrimary),
            ),
            SizedBox(height: 12.h),
            if (data.recentActivities.isEmpty)
              _buildEmptyPlaceholder(
                context,
                Icons.history,
                'لا توجد أنشطة حديثة',
                'ستظهر أنشطة أبنائك هنا',
              )
            else
              ...data.recentActivities
                  .take(5)
                  .map((a) => _buildActivityItem(context, a)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, RecentActivity activity) {
    IconData icon;
    Color iconColor;
    switch (activity.type) {
      case 'success':
      case 'exam':
        icon = Icons.check_circle;
        iconColor = const Color(0xFF059669);
      case 'warning':
      case 'assignment':
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFD97706);
      case 'error':
        icon = Icons.cancel;
        iconColor = const Color(0xFFEF4444);
      default:
        icon = Icons.event_available;
        iconColor = const Color(0xFF2563EB);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${activity.childName}: ',
                        style: TextStyles.semiBold14.copyWith(
                          color: context.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: activity.text,
                        style: TextStyles.regular14.copyWith(
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatTimestamp(activity.timestamp),
                  style: TextStyles.regular13.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents(BuildContext context, ParentDashboardData data) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.borderColor.withValues(alpha: .5)),
        ),

        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'الأحداث القادمة',
                style: TextStyles.bold18.copyWith(color: context.textPrimary),
              ),
              SizedBox(height: 12.h),
              if (data.upcomingEvents.isEmpty)
                _buildEmptyPlaceholder(
                  context,
                  Icons.calendar_today,
                  'لا توجد أحداث قادمة',
                  'ستظهر اختبارات وواجبات أبنائك هنا',
                )
              else
                ...data.upcomingEvents
                    .take(5)
                    .map((e) => _buildEventItem(context, e)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, UpcomingEvent event) {
    final isExam = event.type == 'exam';
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: context.borderColor.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  event.childName,
                  style: TextStyles.semiBold13.copyWith(color: Colors.white),
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isExam
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  isExam ? 'اختبار' : 'مهمة',
                  style: TextStyles.semiBold13.copyWith(
                    color: isExam
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            event.title,
            style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 12.sp,
                color: context.textSecondary,
              ),
              SizedBox(width: 4.w),
              Text(
                _formatDate(event.date),
                style: TextStyles.regular13.copyWith(
                  color: context.textSecondary,
                ),
              ),
              if (event.time != null && event.time!.isNotEmpty) ...[
                SizedBox(width: 12.w),
                Icon(
                  Icons.access_time,
                  size: 12.sp,
                  color: context.textSecondary,
                ),
                SizedBox(width: 4.w),
                Text(
                  event.time!,
                  style: TextStyles.regular13.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
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
            Text(
              'إجراءات سريعة',
              style: TextStyles.bold18.copyWith(color: context.textPrimary),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _quickActionButton(
                    context,
                    icon: Icons.people,
                    label: 'الأبناء',
                    onTap: () =>
                        Navigator.pushNamed(context, ParentRoutes.children),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _quickActionButton(
                    context,
                    icon: Icons.assessment,
                    label: 'التقارير',
                    onTap: () =>
                        Navigator.pushNamed(context, ParentRoutes.reports),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _quickActionButton(
                    context,
                    icon: Icons.person_add,
                    label: 'إضافة طالب',
                    accent: true,
                    onTap: () => setState(() => _showAddChild = true),
                  ),
                ),
              ],
            ),
            if (_showAddChild) ...[
              SizedBox(height: 12.h),
              _buildAddChildModal(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: accent ? const Color(0xFFDB2777) : context.borderColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: accent ? const Color(0xFFDB2777) : context.textPrimary,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyles.semiBold13.copyWith(
                color: accent ? const Color(0xFFDB2777) : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40.sp,
            color: context.textSecondary.withValues(alpha: .3),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyles.semiBold14.copyWith(color: context.textSecondary),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyles.regular13.copyWith(
              color: context.textSecondary.withValues(alpha: .7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'منذ لحظات';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildAddChildModal(BuildContext context) {
    final usernameCtrl = TextEditingController();
    bool lookupLoading = false;
    bool codeSent = false;
    bool verifyLoading = false;
    bool linkLoading = false;
    Map<String, dynamic>? foundStudent;
    String? error;
    final codeCtrl = TextEditingController();
    final repo = context.read<ParentRepository>();
    final authService = context.read<AuthService>();
    final user = context.read<AuthCubit>().currentUser;
    final parentEmail = user?.email ?? '';

    return StatefulBuilder(
      builder: (context, setLocal) => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDB2777), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'إضافة طالب جديد',
                    style: TextStyles.bold18.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _showAddChild = false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (!codeSent) ...[
              // Step 1: Lookup
              Text(
                'الخطوة 1: ابحث عن الطالب بالاسم المميز',
                style: TextStyles.semiBold14.copyWith(
                  color: context.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: usernameCtrl,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: 'مثال: std_BraveWolf42',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: context.isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      enabled: !lookupLoading && foundStudent == null,
                    ),
                  ),
                  if (foundStudent == null) ...[
                    SizedBox(width: 8.w),
                    ElevatedButton(
                      onPressed: lookupLoading
                          ? null
                          : () async {
                              if (usernameCtrl.text.trim().isEmpty) return;
                              setLocal(() {
                                lookupLoading = true;
                                error = null;
                                foundStudent = null;
                              });
                              try {
                                final info = await authService.lookupStudent(
                                  usernameCtrl.text.trim(),
                                );
                                setLocal(() => foundStudent = info);
                              } catch (e) {
                                setLocal(
                                  () => error =
                                      'لم يتم العثور على طالب بهذا الاسم',
                                );
                              } finally {
                                setLocal(() => lookupLoading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: lookupLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'بحث',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
              // Student info card
              if (foundStudent != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F8),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFDB2777)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFFDF2F8),
                        child: const Icon(
                          Icons.school,
                          color: Color(0xFFDB2777),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              foundStudent!['name'] ?? '',
                              style: TextStyles.semiBold16.copyWith(
                                color: context.textPrimary,
                              ),
                            ),
                            Text(
                              '@${foundStudent!['username'] ?? ''}',
                              style: TextStyles.regular13.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: Color(0xFF059669)),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                // Step 2: Send code
                Text(
                  'الخطوة 2: أرسل كود التحقق للطالب',
                  style: TextStyles.semiBold14.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'سيصل للطالب ${foundStudent!['name'] ?? ''} كود مكون من 6 أرقام عبر الإشعارات.',
                          style: TextStyles.regular13.copyWith(
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: verifyLoading
                        ? null
                        : () async {
                            setLocal(() {
                              verifyLoading = true;
                              error = null;
                            });
                            try {
                              await authService.sendCodeToStudent(
                                studentUsername: usernameCtrl.text.trim(),
                                parentEmail: parentEmail,
                              );
                              setLocal(() => codeSent = true);
                              buildSnackBar(context, 'تم إرسال الكود للطالب ⚡');
                            } catch (e) {
                              setLocal(() => error = 'فشل إرسال الكود');
                            } finally {
                              setLocal(() => verifyLoading = false);
                            }
                          },
                    icon: verifyLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: const Text(
                      'إرسال الكود للطالب ⚡',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Step 3: Verify code & link
              Text(
                'الخطوة 3: أدخل الكود الذي أرسله لك الطالب',
                style: TextStyles.semiBold14.copyWith(
                  color: context.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '✅ تم إرسال الكود للطالب ${foundStudent?['name'] ?? ''}. اطلب منه الكود ثم أدخله هنا.',
                        style: TextStyles.regular13.copyWith(
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  letterSpacing: 8,
                  fontSize: 24.sp,
                  fontFamily: 'Cairo',
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  filled: true,
                  fillColor: context.isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  counterText: '',
                ),
                onChanged: (v) {
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits != v) {
                    codeCtrl.value = codeCtrl.value.copyWith(
                      text: digits,
                      selection: TextSelection.collapsed(offset: digits.length),
                    );
                  }
                },
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (verifyLoading ||
                          linkLoading ||
                          codeCtrl.text.length != 6)
                      ? null
                      : () async {
                          setLocal(() {
                            verifyLoading = true;
                            error = null;
                          });
                          try {
                            await authService.verifyParentCode(
                              studentUsername: usernameCtrl.text.trim(),
                              code: codeCtrl.text.trim(),
                            );
                            setLocal(() {
                              linkLoading = true;
                            });
                            await repo.linkChild(usernameCtrl.text.trim());
                            buildSnackBar(context, '✅ تم ربط الطالب بنجاح 🎉');
                            setState(() => _showAddChild = false);
                            _load();
                          } catch (e) {
                            setLocal(
                              () => error = 'الكود غير صحيح أو انتهت صلاحيته',
                            );
                          } finally {
                            setLocal(() {
                              verifyLoading = false;
                              linkLoading = false;
                            });
                          }
                        },
                  icon: (verifyLoading || linkLoading)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle, size: 18),
                  label: Text(
                    (verifyLoading || linkLoading)
                        ? 'جاري الربط...'
                        : 'تحقق وربط الطالب ✅',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: const Color(
                      0xFF059669,
                    ).withValues(alpha: .5),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: TextButton(
                  onPressed: () {
                    setLocal(() {
                      codeSent = false;
                      codeCtrl.clear();
                    });
                  },
                  child: Text(
                    'إعادة إرسال الكود',
                    style: TextStyles.semiBold14.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
            if (error != null) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
