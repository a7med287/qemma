import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../routes/student_routes.dart';
import '../widgets/student_async_body.dart';
import 'widgets/student_dashboard_header.dart';
import 'widgets/student_dashboard_sections.dart';
import 'widgets/student_dashboard_drawer.dart';
import 'widgets/student_dashboard_assistant.dart';

class StudentDashboardView extends StatefulWidget {
  static const routeName = StudentRoutes.dashboard;
  const StudentDashboardView({super.key});

  @override
  State<StudentDashboardView> createState() => _StudentDashboardViewState();
}

class _StudentDashboardViewState extends State<StudentDashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StudentDashboardData? _data;
  bool _loading = true;
  String? _error;
  bool _assistantOpen = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<StudentRepository>().getDashboard();
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل تحميل لوحة التحكم';
        _loading = false;
      });
    }
  }

  void _toggleTask(String id) {
    if (_data == null) return;
    setState(() {
      _data = StudentDashboardData(
        student: _data!.student,
        kpis: _data!.kpis,
        badges: _data!.badges,
        enrolledCourses: _data!.enrolledCourses,
        recentExams: _data!.recentExams,
        liveSessions: _data!.liveSessions,
        alerts: _data!.alerts,
        tasks: _data!.tasks
            .map((t) => t.id == id
                ? StudentTask(
                    id: t.id,
                    title: t.title,
                    courseName: t.courseName,
                    courseId: t.courseId,
                    dueDate: t.dueDate,
                    completed: !t.completed,
                    type: t.type,
                  )
                : t)
            .toList(),
        notifications: _data!.notifications,
        chart: _data!.chart,
        calendarEvents: _data!.calendarEvents,
        strengths: _data!.strengths,
        weaknesses: _data!.weaknesses,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StudentAsyncBody(
      loading: _loading,
      error: _error,
      onRetry: _loadDashboard,
      child: _data == null ? const SizedBox.shrink() : _buildContent(context, _data!),
    );
  }

  Widget _buildContent(BuildContext context, StudentDashboardData data) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      drawer: StudentDashboardDrawer(
        data: data,
        onAssistantTap: () => setState(() => _assistantOpen = true),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => setState(() => _assistantOpen = !_assistantOpen),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 64.w,
          height: 64.w,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientMid.withValues(alpha: .4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.smart_toy, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: StudentDashboardHeader(
                  data: data,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onNotificationTap: () =>
                      Navigator.pushNamed(context, StudentRoutes.notifications),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.all(16.r),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    StudentDashboardSections(
                      data: data,
                      onToggleTask: _toggleTask,
                    ),
                  ]),
                ),
              ),
            ],
          ),
          if (_assistantOpen)
            StudentDashboardAssistant(
              firstName: data.student.firstName,
              onClose: () => setState(() => _assistantOpen = false),
            ),
        ],
      ),
    );
  }
}
