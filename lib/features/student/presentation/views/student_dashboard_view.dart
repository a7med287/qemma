import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../auth/presentation/views/login_view.dart';
import '../../data/mock/student_mock_data.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../routes/student_routes.dart';
import '../widgets/student_async_body.dart';
import '../widgets/student_shared_widgets.dart';

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
  DateTime _currentDate = DateTime.now();
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
    final student = data.student;
    final unread = data.notifications.where((n) => n.unread).length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      drawer: _buildDrawer(context, data),
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.smart_toy, color: Colors.white, size: 28),
              if (unread > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$unread', style: TextStyles.semiBold13.copyWith(color: Colors.white, fontSize: 10.sp)),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, data)),
              SliverPadding(
                padding: EdgeInsets.all(16.r),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildContestCard(context),
                    if (data.alerts.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      _buildAlerts(context, data),
                    ],
                    SizedBox(height: 16.h),
                    _buildCoursesSection(context, data),
                    SizedBox(height: 16.h),
                    _buildBooksSection(context),
                    SizedBox(height: 16.h),
                    _buildTasksSection(context, data),
                    SizedBox(height: 16.h),
                    _buildChartSection(context, data),
                    SizedBox(height: 16.h),
                    _buildPerformanceAnalysis(context, data),
                    SizedBox(height: 16.h),
                    _buildLiveSessions(context, data),
                    SizedBox(height: 16.h),
                    _buildRecentExams(context, data),
                    SizedBox(height: 16.h),
                    // _buildNotificationsPreview(context, data),
                    SizedBox(height: 80.h),
                  ]),
                ),
              ),
            ],
          ),
          if (_assistantOpen) _buildAssistant(context, student.firstName),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, StudentDashboardData data) {
    final student = data.student;
    return StudentGradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 36.r,
                    backgroundColor: Colors.white,
                    child: Text(
                      studentInitials(student.name),
                      style: TextStyles.bold20.copyWith(color: AppColors.gradientMid),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '${student.overallProgress}%',
                          style: TextStyles.semiBold13.copyWith(color: AppColors.gradientMid),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحباً، ${student.firstName} 👋', style: TextStyles.bold20.copyWith(color: Colors.white)),
                    Text(student.gradeLevel, style: TextStyles.regular14.copyWith(color: Colors.white70)),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: data.badges
                          .map((b) => Chip(
                        label: Text(b.label, style: TextStyle(fontSize: 10.sp, color: Colors.white)),
                        backgroundColor: Colors.white24,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white12),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, StudentRoutes.notifications),
                icon: Badge(
                  label: Text('${data.notifications.where((n) => n.unread).length}'),
                  isLabelVisible: data.notifications.any((n) => n.unread),
                  child: const Icon(Icons.notifications, color: Colors.white),
                ),
                style: IconButton.styleFrom(backgroundColor: Colors.white12),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8.h,
            crossAxisSpacing: 8.w,
            childAspectRatio: 1.6,
            children: data.kpis.map((stat) {
              return Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(_kpiIcon(stat.type), color: Colors.white, size: 20.sp),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(stat.change, style: TextStyle(fontSize: 10.sp, color: const Color(0xFF059669), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(stat.value, style: TextStyles.bold20.copyWith(color: Colors.white)),
                    Text(stat.label, style: TextStyles.regular13.copyWith(color: Colors.white70)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _kpiIcon(String type) {
    return switch (type) {
      'avgGrade' => Icons.star,
      'homework' => Icons.check_circle,
      'attendance' => Icons.school,
      'studyTime' => Icons.access_time,
      _ => Icons.analytics,
    };
  }

  Widget _buildContestCard(BuildContext context) {
    return StudentGlassCard(
      title: '🏆 المسابقات الذهبية',
      icon: '🥇',
      actionLabel: 'لوحة المسابقات',
      onAction: () => Navigator.pushNamed(context, StudentRoutes.contestDashboard),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, StudentRoutes.contestDashboard),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.white, size: 32.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تابع تقدمك في المسابقات الذهبية', style: TextStyles.bold18.copyWith(color: Colors.white)),
                        Text('الصف الثالث الثانوي • جميع الشعب', style: TextStyles.regular13.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_back, color: Colors.white),
                ],
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                children: ['علمي رياضة', 'علمي علوم', 'أدبي']
                    .map((s) => Chip(label: Text(s), backgroundColor: Colors.white24, labelStyle: const TextStyle(color: Colors.white)))
                    .toList(),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _contestStat('5', 'مسابقات'),
                  _contestStat('1547', 'التقييم'),
                  _contestStat('#12', 'أفضل ترتيب'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contestStat(String value, String label) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyles.bold18.copyWith(color: Colors.white)),
            Text(label, style: TextStyles.regular13.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerts(BuildContext context, StudentDashboardData data) {
    return StudentGlassCard(
      title: '⚡ تنبيهات عاجلة',
      icon: '🔔',
      child: Column(
        children: data.alerts.map((a) {
          final color = switch (a.type) {
            'exam' => const Color(0xFFEF4444),
            'assignment' => const Color(0xFFF59E0B),
            _ => AppColors.gradientMid,
          };
          final route = switch (a.type) {
            'exam' => StudentRoutes.exams,
            'assignment' => StudentRoutes.submitAssignment,
            _ => StudentRoutes.liveClass,
          };
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF334155) : color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8.r),
              border: Border(right: BorderSide(color: color, width: 4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8.r)),
                  child: Icon(
                    a.type == 'exam' ? Icons.warning : Icons.assignment_late,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                      Text(a.message, style: TextStyles.regular13.copyWith(color: color)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, route),
                  style: TextButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                  child: Text(a.actionLabel),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCoursesSection(BuildContext context, StudentDashboardData data) {
    return StudentGlassCard(
      title: '📚 كورساتي',
      icon: '🎓',
      actionLabel: 'عرض الكل',
      onAction: () => Navigator.pushNamed(context, StudentRoutes.courses),
      child: data.enrolledCourses.isEmpty
          ? Center(child: Text('لم يتم التسجيل في أي كورس بعد', style: TextStyles.regular14.copyWith(color: context.textSecondary)))
          : Column(
        children: data.enrolledCourses.map((c) {
          final color = StudentMockData.studentColors[data.enrolledCourses.indexOf(c) % 4];
          return InkWell(
            onTap: () => StudentRoutes.pushCourse(context, c.id),
            child: Container(
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(8.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(height: 4.h, color: color),
                  Padding(
                    padding: EdgeInsets.all(12.r),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withValues(alpha: .15),
                          child: Icon(Icons.school, color: color, size: 20.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.title, style: TextStyles.semiBold14.copyWith(color: context.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(c.teacher, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                              SizedBox(height: 8.h),
                              LinearProgressIndicator(
                                value: c.progress / 100,
                                backgroundColor: context.borderColor,
                                color: color,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${c.rating} ⭐', style: TextStyles.regular13),
                                  Text('${c.completedLessons}/${c.totalLessons} درس', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text('${c.progress}%', style: TextStyles.semiBold14.copyWith(color: color)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBooksSection(BuildContext context) {
    return StudentGlassCard(
      title: '📖 الكتب الدراسية',
      icon: '📚',
      actionLabel: 'عرض الكل',
      onAction: () => Navigator.pushNamed(context, StudentRoutes.books),
      child: Column(
        children: StudentMockData.books.take(4).map((StudyBook book) {
          return InkWell(
            onTap: () => StudentRoutes.pushBook(context, book.id),
            child: Container(
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(8.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: book.gradient),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_stories, color: Colors.white),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book.title, style: TextStyles.semiBold14.copyWith(color: Colors.white)),
                              Text(book.subtitle, style: TextStyles.regular13.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.r),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(book.teacher, style: TextStyles.regular13.copyWith(color: context.textPrimary)),
                        Row(
                          children: [
                            Chip(label: Text('${book.chapters} فصل'), visualDensity: VisualDensity.compact),
                            SizedBox(width: 4.w),
                            Chip(label: Text('${book.pages} صفحة'), visualDensity: VisualDensity.compact),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context, StudentDashboardData data) {
    return StudentGlassCard(
      title: '📝 المهام القادمة',
      icon: '✅',
      actionLabel: 'عرض الكل',
      onAction: () => Navigator.pushNamed(context, StudentRoutes.tasks),
      child: Column(
        children: data.tasks.take(5).map((t) {
          return CheckboxListTile(
            value: t.completed,
            onChanged: (_) => _toggleTask(t.id),
            title: Text(
              t.title,
              style: TextStyles.semiBold14.copyWith(
                color: context.textPrimary,
                decoration: t.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text('📅 ${t.dueDate} • ${t.courseName}', style: TextStyles.regular13.copyWith(color: const Color(0xFFF59E0B))),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, StudentDashboardData data) {
    return StudentGlassCard(
      title: '📈 تقدم الأداء',
      icon: '📊',
      child: SizedBox(
        height: 220.h,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Text(
                    data.chart.labels[v.toInt()],
                    style: TextStyle(fontSize: 10.sp, color: context.textSecondary),
                  ),
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28.w)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(data.chart.grades.length, (i) => FlSpot(i.toDouble(), data.chart.grades[i])),
                isCurved: true,
                color: const Color(0xFF2563EB),
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: const Color(0xFF2563EB).withValues(alpha: .1)),
              ),
              LineChartBarData(
                spots: List.generate(data.chart.studyHours.length, (i) => FlSpot(i.toDouble(), data.chart.studyHours[i])),
                isCurved: true,
                color: const Color(0xFF059669),
                barWidth: 2,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: const Color(0xFF059669).withValues(alpha: .1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceAnalysis(BuildContext context, StudentDashboardData data) {
    return StudentGlassCard(
      title: 'تحليل الأداء',
      icon: '🧠',
      child: Column(
        children: [
          _performanceSection(context, '💪 نقاط القوة', data.strengths, const Color(0xFF059669)),
          SizedBox(height: 16.h),
          _performanceSection(context, '🎯 يحتاج تحسين', data.weaknesses, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _performanceSection(BuildContext context, String title, List<PerformanceItem> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyles.semiBold16.copyWith(color: color)),
        SizedBox(height: 8.h),
        ...items.map((item) => Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF334155) : color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border(right: BorderSide(color: color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.subject, style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                      if (item.topic.isNotEmpty) Text(item.topic, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                    ],
                  ),
                  Text('${item.score}%', style: TextStyles.bold18.copyWith(color: color)),
                ],
              ),
              SizedBox(height: 8.h),
              LinearProgressIndicator(value: item.score / 100, color: color, backgroundColor: color.withValues(alpha: .2)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildLiveSessions(BuildContext context, StudentDashboardData data) {
    return StudentGlassCard(
      title: '🎥 الحصص المباشرة',
      icon: '📺',
      actionLabel: 'الجدول',
      onAction: () => Navigator.pushNamed(context, StudentRoutes.liveClass),
      child: Column(
        children: data.liveSessions.map((s) {
          final gradient = LinearGradient(
            colors: StudentMockData.studentColors.take(3).toList(),
          );
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12.r)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.isLive)
                  Chip(
                    label: const Text('مباشر', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.white24,
                    visualDensity: VisualDensity.compact,
                  ),
                Text(s.title, style: TextStyles.semiBold16.copyWith(color: Colors.white)),
                Text(s.teacher, style: TextStyles.regular14.copyWith(color: Colors.white70)),
                Text(s.time, style: TextStyles.regular13.copyWith(color: Colors.white70)),
                SizedBox(height: 8.h),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, StudentRoutes.liveClass),
                  icon: const Icon(Icons.play_circle),
                  label: const Text('🚀 انضم الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: context.textPrimary,
                    minimumSize: Size(double.infinity, 40.h),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, StudentDashboardData data) {
    final year = _currentDate.year;
    final month = _currentDate.month;
    final firstDay = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();

    bool hasEvent(int d) {
      final dateStr = '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      return data.calendarEvents.any((e) => e.date == dateStr);
    }

    bool isToday(int d) => d == today.day && month == today.month && year == today.year;

    return StudentGlassCard(
      title: ' التقويم',
      icon: '🗓️',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _currentDate = DateTime(year, month + 1)),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${arabicMonths[month - 1]} $year', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
              IconButton(
                onPressed: () => setState(() => _currentDate = DateTime(year, month - 1)),

                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: arabicDays
                .map((d) => Expanded(child: Center(child: Text(d, style: TextStyles.regular13.copyWith(color: context.textSecondary)))))
                .toList(),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: firstDay + daysInMonth,
            itemBuilder: (_, i) {
              if (i < firstDay) return const SizedBox();
              final d = i - firstDay + 1;
              return Container(
                margin: EdgeInsets.all(2.r),
                decoration: BoxDecoration(
                  gradient: isToday(d) ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$d',
                      style: TextStyles.semiBold13.copyWith(
                        color: isToday(d) ? Colors.white : context.textPrimary,
                      ),
                    ),
                    if (hasEvent(d))
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isToday(d) ? Colors.white : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, StudentDashboardData data) {
    final student = data.student;
    final actions = [
      (Icons.person, 'الملف الشخصي', StudentRoutes.profile, AppColors.gradientMid),
      (Icons.play_circle, 'ابدأ التمرين', StudentRoutes.exams, StudentMockData.studentColors[0]),
      (Icons.cloud_upload, 'سلّم الواجب', StudentRoutes.submitAssignment, StudentMockData.studentColors[1]),
      (Icons.videocam, 'انضم للحصة', StudentRoutes.liveClass, StudentMockData.studentColors[3]),
      (Icons.chat, 'اسأل المساعد', '', StudentMockData.studentColors[2]),
      (Icons.menu_book, 'مكتبة المواد', StudentRoutes.courses, StudentMockData.studentColors[5]),
      (Icons.assessment, 'تقرير الأداء', StudentRoutes.performance, const Color(0xFFEF4444)),
      (Icons.emoji_events, 'المسابقات الذهبية', StudentRoutes.contestDashboard, const Color(0xFFF59E0B)),
      (Icons.auto_stories, 'الكتب الدراسية', StudentRoutes.books, StudentMockData.studentColors[4]),
    ];

    return Drawer(
      backgroundColor: context.isDark ? AppColors.darkBackground : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, StudentRoutes.profile);
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28.r,
                      backgroundColor: Colors.white,
                      child: Text(
                        studentInitials(student.name),
                        style: TextStyles.bold18.copyWith(color: AppColors.gradientMid),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: TextStyles.semiBold16.copyWith(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(student.gradeLevel, style: TextStyles.regular13.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: Colors.white70),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                children: [



                  ...actions.map((a) => ListTile(
                    leading: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: a.$4.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(a.$1, color: a.$4, size: 20.sp),
                    ),
                    title: Text(a.$2, style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                    onTap: () {
                      Navigator.pop(context);
                      if (a.$3.isEmpty) {
                        setState(() => _assistantOpen = true);
                      } else {
                        Navigator.pushNamed(context, a.$3);
                      }
                    },
                  )),
                  Divider(height: 1, color: context.borderColor),
                  ListTile(
                    leading: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.exit_to_app, color: Colors.red, size: 20.sp),
                    ),
                    title: Text('تسجيل الخروج', style: TextStyles.semiBold14.copyWith(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<AuthCubit>().logout();
                      Navigator.pushNamedAndRemoveUntil(context, LoginView.routeName, (_) => false);
                    },
                  ),
                  SizedBox(height: 4.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: _buildCalendar(context, data),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExams(BuildContext context, StudentDashboardData data) {
    return StudentGlassCard(
      title: '📊 نتائج الاختبارات',
      icon: '🎯',
      actionLabel: 'جميع النتائج',
      onAction: () => Navigator.pushNamed(context, StudentRoutes.exams),
      child: Column(
        children: data.recentExams.map((e) {
          final color = studentGradeColor(e.score);
          return InkWell(
            onTap: () => Navigator.pushNamed(context, StudentRoutes.exams),
            child: Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.quiz, color: Colors.white, size: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title, style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                        Text(e.courseTitle, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text('${e.score.round()}%', style: TextStyles.semiBold14.copyWith(color: color)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAssistant(BuildContext context, String firstName) {
    return Positioned(
      left: 16.w,
      bottom: 100.h,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: 320.w,
          height: 400.h,
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy, color: Colors.white),
                    SizedBox(width: 8.w),
                    Text('المساعد الذكي', style: TextStyles.semiBold16.copyWith(color: Colors.white)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _assistantOpen = false),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: context.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text('مرحباً $firstName! 👋 كيف يمكنني مساعدتك؟'),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12.r),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'اكتب سؤالك...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}