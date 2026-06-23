import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import 'teacher_books_view.dart';
import 'teacher_create_course_view.dart';
import 'teacher_my_courses_view.dart';
import 'teacher_send_notification_view.dart';
import 'teacher_upload_lesson_view.dart';
import 'teacher_analytics_view.dart';
import 'teacher_assignments_view.dart';
import 'teacher_chat_management_view.dart';
import 'teacher_create_exam_view.dart';
import 'teacher_grade_exams_view.dart';
import 'teacher_schedule_view.dart';
import 'teacher_live_class_view.dart';
import 'teacher_notifications_view.dart';

class TeacherDashboardView extends StatefulWidget {
  static const routeName = '/teacher/dashboard';
  const TeacherDashboardView({super.key});

  @override
  State<TeacherDashboardView> createState() => _TeacherDashboardViewState();
}

class _TeacherDashboardViewState extends State<TeacherDashboardView> {
  TeacherDashboardData? _data;
  bool _loading = true;
  String? _error;

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
      final data = await context.read<TeacherRepository>().getDashboard();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 48.sp, color: Colors.grey),
                SizedBox(height: 12.h),
                Text(_error!, textAlign: TextAlign.center, style: TextStyles.regular14),
                SizedBox(height: 16.h),
                ElevatedButton(onPressed: _loadDashboard, child: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      );
    }
    return _TeacherDashboardContent(data: _data!, onRefresh: _loadDashboard);
  }
}

class _TeacherDashboardContent extends StatefulWidget {
  final TeacherDashboardData data;
  final VoidCallback onRefresh;
  const _TeacherDashboardContent({required this.data, required this.onRefresh});

  @override
  State<_TeacherDashboardContent> createState() => _TeacherDashboardContentState();
}

class _TeacherDashboardContentState extends State<_TeacherDashboardContent> {
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(context, data),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(16.r),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildContestCard(context),
                      if (data.subjects.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        _buildSubjectsCard(context, data),
                      ],
                      SizedBox(height: 16.h),
                      _buildStatsRow(context, data),
                      SizedBox(height: 24.h),
                      _buildQuickActionsTitle(context),
                      SizedBox(height: 12.h),
                      _buildQuickActionsGrid(context),
                      SizedBox(height: 24.h),
                      _buildBottomRow(context, data),
                      SizedBox(height: 24.h),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TeacherDashboardData data) {
    final initial = data.teacherName.isNotEmpty ? data.teacherName[0] : 'م';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor: Colors.white,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: const Color(0xFF7C3AED),
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً، ${data.teacherName.isNotEmpty ? data.teacherName : 'المدرس'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 4.h,
                        children: [
                          _buildHeaderChip('مدرس'),
                          if (data.subjects.isNotEmpty)
                            _buildHeaderChip('${data.subjects.length} مادة', icon: Icons.school),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pushNamed(context, TeacherNotificationsView.routeName),
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          style: IconButton.styleFrom(backgroundColor: Colors.white12),
                        ),
                        if (data.unreadCount > 0)
                          Positioned(
                            right: 0.w,
                            top: 0.h,
                            child: Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h),
                              child: Text(
                                '${data.unreadCount}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 4.w),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white12),
                      onSelected: (value) {
                        if (value == 'logout') {
                          // handle logout
                        } else if (value == 'settings') {
                          // navigate to settings
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'settings', child: Row(
                          children: [Icon(Icons.settings, size: 20), SizedBox(width: 8), Text('الإعدادات')],
                        )),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'logout', child: Row(
                          children: [Icon(Icons.exit_to_app, size: 20, color: Colors.red), SizedBox(width: 8), Text('تسجيل الخروج', style: TextStyle(color: Colors.red))],
                        )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderChip(String label, {IconData? icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: icon != null ? Colors.white.withValues(alpha: .3) : Colors.white.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 14.sp),
            SizedBox(width: 4.w),
          ],
          Text(label, style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildContestCard(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 6.h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: .3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🏆 إدارة المسابقات الذهبية',
                              style: TextStyles.bold18.copyWith(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                          SizedBox(height: 4.h),
                          Text('أضف أسئلة للمسابقات المخصصة لك وتابع مسابقاتك السابقة',
                              style: TextStyles.regular13.copyWith(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            children: [
                              _contestChip('الصف الثالث الثانوي', const Color(0xFFF59E0B), isDark),
                              _contestChip('علمي رياضة', const Color(0xFFD97706), isDark),
                              _contestChip('علمي علوم', const Color(0xFFD97706), isDark),
                              _contestChip('أدبي', const Color(0xFFD97706), isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () =>
                        {},
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.white, size: 18),
                              SizedBox(width: 8.w),
                              Text('إدارة المسابقات',
                                  style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contestChip(String label, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: .2) : color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(label,
          style: TextStyle(
            color: color,
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            fontFamily: 'Cairo',
          )),
    );
  }

  Widget _buildSubjectsCard(BuildContext context, TeacherDashboardData data) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 22),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المواد الدراسية',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.semiBold16.copyWith(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                      Text('المواد المخصصة لك',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.regular13.copyWith(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ],
                  ),
                ),
                // TextButton(
                //   style: TextButton.styleFrom(
                //     padding: EdgeInsets.symmetric(horizontal: 6.w),
                //     minimumSize: Size.zero,
                //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                //   ),
                //   onPressed: () {},
                //   child: Text('عرض الكل', style: TextStyles.semiBold13.copyWith(color: context.textSecondary)),
                // ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF7C3AED).withValues(alpha: .1) : const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: isDark ? const Color(0xFF7C3AED).withValues(alpha: .3) : const Color(0xFFE9D5FF)),
              ),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: data.subjects.map((subject) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
                    ),
                    child: Text(subject,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        )),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, TeacherDashboardData data) {
    final stats = [
      _StatItem(
        title: 'إجمالي الطلاب',
        value: '${data.totalStudents}',
        icon: Icons.people,
        color: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
      ),
      _StatItem(
        title: 'الكورسات النشطة',
        value: '${data.activeCourses}',
        icon: Icons.menu_book,
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
      ),
      _StatItem(
        title: 'الحصص هذا الأسبوع',
        value: '${data.upcomingSchedules.length}',
        icon: Icons.videocam,
        color: const Color(0xFFDB2777),
        bgColor: const Color(0xFFFDF2F8),
      ),
      _StatItem(
        title: 'معدل النجاح',
        value: data.passRate != null ? '${data.passRate!.round()}%' : '0%',
        icon: Icons.trending_up,
        color: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        // Slightly taller cards so icon + value + title never overflow,
        // even with long localized numbers/titles.
        childAspectRatio: 1.45,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _buildStatCard(context, stats[i]),
    );
  }

  Widget _buildStatCard(BuildContext context, _StatItem stat) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // spaceBetween distributes the fixed cell height instead of
          // letting content grow past it (which is what caused the
          // RenderFlex overflow before).
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: stat.bgColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(stat.icon, color: stat.color, size: 20.sp),
            ),
            Text(stat.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
                )),
            Text(stat.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsTitle(BuildContext context) {
    return Text('إجراءات سريعة',
        style: TextStyles.bold18.copyWith(color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E)));
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      _QuickAction(title: 'إدارة المسابقات الذهبية', desc: 'أضف أسئلة للمسابقات الذهبية - الصف الثالث', icon: Icons.emoji_events, color: const Color(0xFFF59E0B)),
      _QuickAction(title: 'مكتبة الكتب', desc: 'إدارة ورفع الكتب الدراسية', icon: Icons.menu_book, color: const Color(0xFF8B5CF6), onTap: () => Navigator.pushNamed(context, TeacherBooksView.routeName)),
      _QuickAction(title: 'إرسال إشعار', desc: 'أرسل إشعارات للطلاب', icon: Icons.campaign, color: const Color(0xFFEF4444), onTap: () => Navigator.pushNamed(context, TeacherSendNotificationView.routeName)),
      _QuickAction(title: 'إنشاء كورس جديد', desc: 'أضف كورس جديد لطلابك', icon: Icons.add, color: const Color(0xFF2563EB), onTap: () => Navigator.pushNamed(context, TeacherCreateCourseView.routeName)),
      _QuickAction(title: 'بدء حصة مباشرة', desc: 'ابدأ حصة أونلاين الآن', icon: Icons.videocam, color: const Color(0xFF7C3AED), onTap: () => Navigator.pushNamed(context, TeacherLiveClassView.routeName)),
      _QuickAction(title: 'إضافة اختبار', desc: 'أنشئ اختبار جديد', icon: Icons.assignment, color: const Color(0xFFDB2777), onTap: () => Navigator.pushNamed(context, TeacherCreateExamView.routeName)),
      _QuickAction(title: 'عرض التقارير', desc: 'تابع أداء الطلاب', icon: Icons.bar_chart, color: const Color(0xFF059669), onTap: () => Navigator.pushNamed(context, TeacherAnalyticsView.routeName)),
      _QuickAction(title: 'كورساتي', desc: 'عرض وإدارة كورساتك', icon: Icons.menu_book, color: const Color(0xFF06B6D4), onTap: () => Navigator.pushNamed(context, TeacherMyCoursesView.routeName)),
      _QuickAction(title: 'تصحيح الاختبارات', desc: 'راجع وصحح اختبارات الطلاب', icon: Icons.assignment_turned_in, color: const Color(0xFF10B981), onTap: () => Navigator.pushNamed(context, TeacherGradeExamsView.routeName)),
      _QuickAction(title: 'إدارة الواجبات', desc: 'أنشئ واجبات وتابع تسليم الطلاب', icon: Icons.assignment, color: const Color(0xFF0891B2), onTap: () => Navigator.pushNamed(context, TeacherAssignmentsView.routeName)),
      _QuickAction(title: 'إدارة المحادثات', desc: 'تواصل مع طلابك والمدرس المساعد', icon: Icons.chat_bubble_outline, color: const Color(0xFF2563EB), onTap: () => Navigator.pushNamed(context, TeacherChatManagementView.routeName)),
      _QuickAction(title: 'رفع درس', desc: 'أضف محتوى تعليمي جديد', icon: Icons.add_circle_outline, color: const Color(0xFFF59E0B), onTap: () => Navigator.pushNamed(context, TeacherUploadLessonView.routeName)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) => _buildQuickActionCard(context, actions[i]),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, _QuickAction action) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: action.onTap,
          child: Padding(
            padding: EdgeInsets.all(10.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(action.icon, color: action.color, size: 20.sp),
                ),
                SizedBox(height: 6.h),
                Text(action.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
                    )),
                SizedBox(height: 2.h),
                Text(action.desc,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRow(BuildContext context, TeacherDashboardData data) {
    return Column(
      children: [
        Row(
          children: [
            // Expanded(child: _buildRecentActivity(context)),
            // SizedBox(width: 16.w),
            Expanded(child: _SchedulePanel(initialSchedules: data.upcomingSchedules)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('النشاط الأخير',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.semiBold16.copyWith(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E))),
            SizedBox(height: 24.h),
            Center(
              child: Column(
                children: [
                  Icon(Icons.school, size: 48.sp, color: isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
                  SizedBox(height: 8.h),
                  Text('لا يوجد نشاط حالياً',
                      textAlign: TextAlign.center,
                      style: TextStyles.regular14.copyWith(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                  Text('ابدأ بإنشاء كورس أو حصة جديدة',
                      textAlign: TextAlign.center,
                      style: TextStyles.regular13.copyWith(color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Schedule Panel (refreshes independently from the dashboard) ────────────
class _SchedulePanel extends StatefulWidget {
  final List<ScheduleItem> initialSchedules;
  const _SchedulePanel({required this.initialSchedules});

  @override
  State<_SchedulePanel> createState() => _SchedulePanelState();
}

class _SchedulePanelState extends State<_SchedulePanel> {
  late List<ScheduleItem> _schedules;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _schedules = widget.initialSchedules;
  }

  Future<void> _refreshSchedules() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<TeacherRepository>();
      final dashboard = await repo.getDashboard();
      if (mounted) {
        setState(() => _schedules = dashboard.upcomingSchedules);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openSchedule() async {
    await Navigator.pushNamed(context, TeacherScheduleView.routeName);
    if (mounted) await _refreshSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('الجدول الزمني',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.semiBold16.copyWith(
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E))),
                ),
                if (_loading)
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _openSchedule,
                    child: Text('إضافة حصة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                            color: const Color(0xFF2563EB))),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            if (_loading && _schedules.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (_schedules.isEmpty)
              Center(
                child: Column(
                  children: [
                    SizedBox(height: 24.h),
                    Icon(Icons.calendar_today,
                        size: 48.sp,
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
                    SizedBox(height: 8.h),
                    Text('لا توجد حصص مجدولة هذا الأسبوع',
                        textAlign: TextAlign.center,
                        style: TextStyles.regular13.copyWith(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                    SizedBox(height: 8.h),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _openSchedule,
                      child: Text('إضافة حصة',
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                              color: const Color(0xFF2563EB))),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _schedules
                    .take(5)
                    .map((s) => _SchedulePanelItem(item: s))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Schedule Panel Item (extracted to keep build clean) ────────────────────
class _SchedulePanelItem extends StatelessWidget {
  final ScheduleItem item;
  const _SchedulePanelItem({required this.item});

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final d = DateTime.parse(dateStr);
      const months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
      ];
      const days = [
        'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت',
      ];
      return '${days[d.weekday % 7]}، ${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isOnline = item.type == 'online';

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              isOnline ? Icons.videocam : Icons.class_,
              size: 16.sp,
              color: isOnline ? const Color(0xFF2563EB) : const Color(0xFF059669),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                    )),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 10.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(_formatDate(item.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 9.sp,
                              fontFamily: 'Cairo',
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.access_time,
                        size: 10.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    SizedBox(width: 4.w),
                    Text(item.startTime,
                        style: TextStyle(
                            fontSize: 9.sp,
                            fontFamily: 'Cairo',
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(isOnline ? 'أونلاين' : 'حضوري',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                  color: isOnline ? const Color(0xFF2563EB) : const Color(0xFF059669),
                )),
          ),
        ],
      ),
    );
  }
}

// ── Legacy helpers ─────────────────────────────────────────────────────────
class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _StatItem({required this.title, required this.value, required this.icon, required this.color, required this.bgColor});
}

class _QuickAction {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _QuickAction({required this.title, required this.desc, required this.icon, required this.color, this.onTap});
}