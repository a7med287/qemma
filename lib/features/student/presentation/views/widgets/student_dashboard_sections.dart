import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../data/mock/student_mock_data.dart';
import '../../../data/models/student_models.dart';
import '../../../data/repositories/student_repository.dart';
import '../../routes/student_routes.dart';
import '../../widgets/student_shared_widgets.dart';

class StudentDashboardSections extends StatelessWidget {
  const StudentDashboardSections({
    super.key,
    required this.data,
    required this.onToggleTask,
  });

  final StudentDashboardData data;
  final void Function(String id) onToggleTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ContestCard(),
        if (data.alerts.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildAlerts(context),
        ],
        SizedBox(height: 16.h),
        _buildCoursesSection(context),
        SizedBox(height: 16.h),
        _buildBooksSection(context),
        SizedBox(height: 16.h),
        _buildTasksSection(context),
        SizedBox(height: 16.h),
        _buildChartSection(context),
        SizedBox(height: 16.h),
        _buildPerformanceAnalysis(context),
        SizedBox(height: 16.h),
        _buildLiveSessions(context),
        SizedBox(height: 16.h),
        _buildRecentExams(context),
        SizedBox(height: 80.h),
      ],
    );
  }

  Widget _buildAlerts(BuildContext context) {
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

  Widget _buildCoursesSection(BuildContext context) {
    return StudentGlassCard(
      title: '📚 كورساتي',
      icon: '🎓',
      actionLabel: 'عرض الكل',
      onAction: () => Navigator.pushNamed(context, StudentRoutes.courses),
      child: data.enrolledCourses.isEmpty
          ? Center(
              child: Text('لم يتم التسجيل في أي كورس بعد',
                  style: TextStyles.regular14.copyWith(color: context.textSecondary)))
          : Column(
              children: data.enrolledCourses.map((c) {
                final color =
                    StudentMockData.studentColors[data.enrolledCourses.indexOf(c) % 4];
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
                                    Text(c.title,
                                        style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Text(c.teacher,
                                        style: TextStyles.regular13.copyWith(color: context.textSecondary)),
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
                                        Text('${c.completedLessons}/${c.totalLessons} درس',
                                            style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text('${c.progress}%',
                                  style: TextStyles.semiBold14.copyWith(color: color)),
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
                              Text(book.title,
                                  style: TextStyles.semiBold14.copyWith(color: Colors.white)),
                              Text(book.subtitle,
                                  style: TextStyles.regular13.copyWith(color: Colors.white70)),
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
                        Text(book.teacher,
                            style: TextStyles.regular13.copyWith(color: context.textPrimary)),
                        Row(
                          children: [
                            Chip(
                                label: Text('${book.chapters} فصل'),
                                visualDensity: VisualDensity.compact),
                            SizedBox(width: 4.w),
                            Chip(
                                label: Text('${book.pages} صفحة'),
                                visualDensity: VisualDensity.compact),
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

  Widget _buildTasksSection(BuildContext context) {
    return StudentGlassCard(
      title: '📝 المهام القادمة',
      icon: '✅',
      actionLabel: 'عرض الكل',
      onAction: () => Navigator.pushNamed(context, StudentRoutes.tasks),
      child: Column(
        children: data.tasks.take(5).map((t) {
          return CheckboxListTile(
            value: t.completed,
            onChanged: (_) => onToggleTask(t.id),
            title: Text(
              t.title,
              style: TextStyles.semiBold14.copyWith(
                color: context.textPrimary,
                decoration: t.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text('📅 ${t.dueDate} • ${t.courseName}',
                style: TextStyles.regular13.copyWith(color: const Color(0xFFF59E0B))),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
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
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28.w)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                    data.chart.grades.length, (i) => FlSpot(i.toDouble(), data.chart.grades[i])),
                isCurved: true,
                color: const Color(0xFF2563EB),
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData:
                    BarAreaData(show: true, color: const Color(0xFF2563EB).withValues(alpha: .1)),
              ),
              LineChartBarData(
                spots: List.generate(data.chart.studyHours.length,
                    (i) => FlSpot(i.toDouble(), data.chart.studyHours[i])),
                isCurved: true,
                color: const Color(0xFF059669),
                barWidth: 2,
                dotData: const FlDotData(show: true),
                belowBarData:
                    BarAreaData(show: true, color: const Color(0xFF059669).withValues(alpha: .1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceAnalysis(BuildContext context) {
    return StudentGlassCard(
      title: 'تحليل الأداء',
      icon: '🧠',
      child: Column(
        children: [
          _performanceSection(
              context, '💪 نقاط القوة', data.strengths, const Color(0xFF059669)),
          SizedBox(height: 16.h),
          _performanceSection(
              context, '🎯 يحتاج تحسين', data.weaknesses, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _performanceSection(
      BuildContext context, String title, List<PerformanceItem> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyles.semiBold16.copyWith(color: color)),
        SizedBox(height: 8.h),
        ...items.map((item) => Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xFF334155)
                    : color.withValues(alpha: .08),
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
                          Text(item.subject,
                              style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                          if (item.topic.isNotEmpty)
                            Text(item.topic,
                                style:
                                    TextStyles.regular13.copyWith(color: context.textSecondary)),
                        ],
                      ),
                      Text('${item.score}%', style: TextStyles.bold18.copyWith(color: color)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  LinearProgressIndicator(
                      value: item.score / 100,
                      color: color,
                      backgroundColor: color.withValues(alpha: .2)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildLiveSessions(BuildContext context) {
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
            decoration:
                BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12.r)),
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

  Widget _buildRecentExams(BuildContext context) {
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
                color: context.isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.quiz, color: Colors.white, size: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title,
                            style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                        Text(e.courseTitle,
                            style:
                                TextStyles.regular13.copyWith(color: context.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text('${e.score.round()}%',
                        style: TextStyles.semiBold14.copyWith(color: color)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ContestCard extends StatefulWidget {
  const _ContestCard();

  @override
  State<_ContestCard> createState() => _ContestCardState();
}

class _ContestCardState extends State<_ContestCard> {
  ContestDashboardData? _contestData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<StudentRepository>().getContestDashboard();
      if (mounted) setState(() { _contestData = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _contestData?.stats;
    return StudentGlassCard(
      title: '🏆 المسابقات الذهبية',
      icon: '🥇',
      actionLabel: 'لوحة المسابقات',
      onAction: () => Navigator.pushNamed(context, StudentRoutes.contests),
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
                        Text('تابع تقدمك في المسابقات الذهبية',
                            style: TextStyles.bold18.copyWith(color: Colors.white)),
                        Text('الصف الثالث الثانوي • جميع الشعب',
                            style: TextStyles.regular13.copyWith(color: Colors.white70)),
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
                    .map((s) => Chip(
                        label: Text(s),
                        backgroundColor: Colors.white24,
                        labelStyle: const TextStyle(color: Colors.white)))
                    .toList(),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _contestStat(
                    _loading ? '...' : '${stats?.totalContests ?? 0}',
                    'مسابقات',
                  ),
                  _contestStat(
                    _loading ? '...' : '${_contestData?.currentRating ?? 0}',
                    'التقييم',
                  ),
                  _contestStat(
                    _loading ? '...' : '#${stats?.bestRank ?? 0}',
                    'أفضل ترتيب',
                  ),
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
}
