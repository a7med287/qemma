import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/models/parent_models.dart';
import '../../data/repositories/parent_repository.dart';
import '../routes/parent_routes.dart';
import '../widgets/parent_async_body.dart';
import '../widgets/parent_shared_widgets.dart';
import 'widgets/parent_dashboard_header.dart';
import 'widgets/parent_dashboard_children.dart';
import 'widgets/parent_dashboard_sections.dart';
import 'widgets/parent_add_child_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
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

        final notifs = child.notifications.take(3);
        for (final n in notifs) {
          final type = n['type'] ?? '';
          final title = n['title'] ?? n['message'] ?? '';
          final time = n['createdAt'] ?? n['timestamp'];
          activities.add(
            RecentActivity(
              id: n['_id']?.toString() ?? n['id']?.toString() ?? '${child.id}_notif_${activities.length}',
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
        }

        final incompleteTasks =
            child.tasks.where((t) => !t.completed).take(3);
        for (final t in incompleteTasks) {
          final taskType = t.type == 'exam' ? 'exam' : 'assignment';
          events.add(
            UpcomingEvent(
              id: t.id,
              childName: child.name.split(' ').firstOrNull ?? child.name,
              type: taskType,
              title: t.title,
              date: t.dueDate ?? DateTime.now(),
              time: t.dueLabel,
            ),
          );
        }
      }

      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!mounted) return;
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
      final msg = e is ServerFailure ? e.message : 'فشل تحميل البيانات';
      if (mounted) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ParentDashboardHeader(),
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
          ParentDashboardChildren(
            children: data.children,
            onAddChild: _showAddChildDialog,
          ),
          SizedBox(height: 12.h),
          QuickActionsSection(onAddChild: _showAddChildDialog),
          SizedBox(height: 12.h),
          UpcomingEventsSection(events: data.upcomingEvents),
          SizedBox(height: 12.h),
          RecentActivitiesSection(activities: data.recentActivities),
        ],
      ),
    );
  }

  Future<void> _showAddChildDialog() async {
    final repo = context.read<ParentRepository>();
    final authService = context.read<AuthService>();
    final user = context.read<AuthCubit>().currentUser;
    final parentEmail = user?.email ?? '';

    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ParentAddChildDialog(
        repo: repo,
        authService: authService,
        parentEmail: parentEmail,
      ),
    );

    if (added == true) _load();
  }
}
