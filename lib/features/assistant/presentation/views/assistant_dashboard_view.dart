import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/assistant_models.dart';
import '../../data/repositories/assistant_repository.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/views/login_view.dart';
import 'assistant_chat_view.dart';
import 'assistant_grade_exams_view.dart';
import 'assistant_notifications_view.dart';
import 'assistant_profile_view.dart';
import 'assistant_student_detail_view.dart';

class AssistantDashboardView extends StatefulWidget {
  static const routeName = '/assistant-teacher/dashboard';
  const AssistantDashboardView({super.key});

  @override
  State<AssistantDashboardView> createState() => _AssistantDashboardViewState();
}

class _AssistantDashboardViewState extends State<AssistantDashboardView> {
  AssistantDashboardData? _data;
  bool _loading = true;
  String? _error;

  AssistantRepository get _repo => context.read<AssistantRepository>();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.getDashboard();
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'فشل تحميل لوحة التحكم'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
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
    return _AssistantDashboardContent(data: _data!, onRefresh: _loadDashboard);
  }
}

class _AssistantDashboardContent extends StatefulWidget {
  final AssistantDashboardData data;
  final VoidCallback onRefresh;
  const _AssistantDashboardContent({required this.data, required this.onRefresh});

  @override
  State<_AssistantDashboardContent> createState() => _AssistantDashboardContentState();
}

class _AssistantDashboardContentState extends State<_AssistantDashboardContent> {
  String _searchQuery = '';
  String _filterCourse = 'all';
  EnrichedStudentsResponse? _enriched;
  bool _studentsLoading = false;
  String? _studentsError;
  int _selectedTab = 0;

  AssistantRepository get _repo => context.read<AssistantRepository>();

  Future<void> _loadStudents() async {
    setState(() { _studentsLoading = true; _studentsError = null; });
    try {
      final data = await _repo.getStudentsEnriched();
      if (mounted) setState(() { _enriched = data; _studentsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _studentsError = 'فشل تحميل الطلاب'; _studentsLoading = false; });
    }
  }

  List<AssistantStudent> get _filteredStudents {
    final students = _enriched?.students ?? [];
    var list = students;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) =>
          s.name.toLowerCase().contains(q) ||
          (s.username?.toLowerCase().contains(q) ?? false) ||
          (s.email?.toLowerCase().contains(q) ?? false)).toList();
    }
    if (_filterCourse != 'all') {
      list = list.where((s) =>
          s.enrollments.any((e) => e.courseId == _filterCourse)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(context, data),
          _buildTabs(isDark),
          Expanded(
            child: _selectedTab == 0
                ? _buildHomeTab(context, data, isDark)
                : _buildStudentsTab(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AssistantDashboardData data) {
    final initial = data.teacherName.isNotEmpty ? data.teacherName[0] : 'م';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF047857), Color(0xFF065F46)],
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
                  radius: 28.r,
                  backgroundColor: Colors.white,
                  child: Text(initial,
                      style: TextStyle(
                        color: const Color(0xFF059669),
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      )),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مرحباً، ${data.teacherName.isNotEmpty ? data.teacherName : 'المدرس المساعد'}',
                          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                      SizedBox(height: 4.h),
                      _buildHeaderChip('مدرس مساعد'),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pushNamed(context, AssistantNotificationsView.routeName),
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          style: IconButton.styleFrom(backgroundColor: Colors.white12),
                        ),
                        if (data.unreadCount > 0)
                          Positioned(
                            right: 0, top: 0,
                            child: Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                              constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h),
                              child: Text('${data.unreadCount}',
                                  style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 4.w),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white12),
                      onSelected: (value) {
                        if (value == 'profile') {
                          Navigator.pushNamed(context, AssistantProfileView.routeName);
                        } else if (value == 'logout') {
                          context.read<AuthCubit>().logout();
                          Navigator.pushNamedAndRemoveUntil(context, LoginView.routeName, (_) => false);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'profile', child: Row(
                          children: [Icon(Icons.person, size: 20), SizedBox(width: 8), Text('الملف الشخصي')],
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

  Widget _buildHeaderChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(label,
          style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        children: [
          Expanded(child: _tabButton('الرئيسية', _selectedTab == 0, isDark, () => setState(() => _selectedTab = 0))),
          Expanded(child: _tabButton('الطلاب', _selectedTab == 1, isDark, () {
            setState(() => _selectedTab = 1);
            _loadStudents();
          })),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF059669) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold,
              color: active ? const Color(0xFF059669) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
            )),
      ),
    );
  }

  // ── Home Tab ────────────────────────────────────────────────────
  Widget _buildHomeTab(BuildContext context, AssistantDashboardData data, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(context, data, isDark),
          SizedBox(height: 20.h),
          _buildQuickActionsTitle(context, isDark),
          SizedBox(height: 12.h),
          _buildQuickActionsGrid(context),
          SizedBox(height: 20.h),
          if (data.recentAttempts.isNotEmpty) ...[
            Text('محاولات بانتظار التصحيح',
                style: TextStyles.semiBold16.copyWith(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E))),
            SizedBox(height: 10.h),
            ...data.recentAttempts.take(5).map((a) => _buildAttemptItem(a, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AssistantDashboardData data, bool isDark) {
    final stats = [
      _StatItem(title: 'الطلاب', value: '${data.studentsCount}', icon: Icons.people, color: const Color(0xFF2563EB), bgColor: const Color(0xFFEFF6FF)),
      _StatItem(title: 'محادثات نشطة', value: '${data.activeChats}', icon: Icons.chat_bubble_outline, color: const Color(0xFF059669), bgColor: const Color(0xFFECFDF5)),
      _StatItem(title: 'تصحيح مقالات', value: '${data.pendingGrading}', icon: Icons.assignment_turned_in, color: const Color(0xFFF59E0B), bgColor: const Color(0xFFFFFBEB)),
      _StatItem(title: 'إشعارات جديدة', value: '${data.unreadCount}', icon: Icons.notifications, color: const Color(0xFFDB2777), bgColor: const Color(0xFFFDF2F8)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 12.w, mainAxisSpacing: 12.h,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _buildStatCard(context, stats[i], isDark),
    );
  }

  Widget _buildStatCard(BuildContext context, _StatItem stat, bool isDark) {
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36.w, height: 36.w,
              decoration: BoxDecoration(color: stat.bgColor, borderRadius: BorderRadius.circular(8.r)),
              child: Icon(stat.icon, color: stat.color, size: 20.sp),
            ),
            Text(stat.value,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E))),
            Text(stat.title,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsTitle(BuildContext context, bool isDark) {
    return Text('إجراءات سريعة',
        style: TextStyles.bold18.copyWith(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E)));
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      _QuickAction(title: 'الطلاب', desc: 'عرض الطلاب المسجلين', icon: Icons.people, color: const Color(0xFF2563EB),
          onTap: () { _loadStudents(); setState(() => _selectedTab = 1); }),
      _QuickAction(title: 'المحادثات', desc: 'تواصل مع الطلاب والمدرس', icon: Icons.chat_bubble_outline, color: const Color(0xFF059669),
          onTap: () => Navigator.pushNamed(context, AssistantChatView.routeName)),
      _QuickAction(title: 'تصحيح الاختبارات', desc: 'تصحيح مقالات الطلاب', icon: Icons.assignment_turned_in, color: const Color(0xFFF59E0B),
          onTap: () => Navigator.pushNamed(context, AssistantGradeExamsView.routeName)),
      _QuickAction(title: 'الإشعارات', desc: 'عرض الإشعارات', icon: Icons.notifications, color: const Color(0xFFDB2777),
          onTap: () => Navigator.pushNamed(context, AssistantNotificationsView.routeName)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 10.w, mainAxisSpacing: 10.h,
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
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                Container(
                  width: 44.w, height: 44.w,
                  decoration: BoxDecoration(color: action.color.withValues(alpha: .15), borderRadius: BorderRadius.circular(10.r)),
                  child: Icon(action.icon, color: action.color, size: 22.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(action.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E))),
                      Text(action.desc,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500, fontFamily: 'Cairo',
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, size: 20, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttemptItem(Map<String, dynamic> attempt, bool isDark) {
    final student = attempt['student'] as Map? ?? {};
    final studentName = (student['name'] ?? (student['user'] as Map?)?['name'] ?? 'طالب') as String;
    final examTitle = (attempt['exam'] as Map?)?['title'] ?? 'اختبار';
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF59E0B),
            child: Text(studentName.isNotEmpty ? studentName[0] : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, fontFamily: 'Cairo',
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                Text(examTitle,
                    style: TextStyle(fontSize: 11.sp, fontFamily: 'Cairo',
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: .15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text('بانتظار التصحيح',
                style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: const Color(0xFFF59E0B))),
          ),
        ],
      ),
    );
  }

  // ── Students Tab ────────────────────────────────────────────────
  Widget _buildStudentsTab(BuildContext context, bool isDark) {
    if (_studentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_studentsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            SizedBox(height: 12.h),
            Text(_studentsError!, style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
            SizedBox(height: 12.h),
            ElevatedButton(onPressed: _loadStudents, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final enriched = _enriched;
    if (enriched == null) {
      return const SizedBox.shrink();
    }

    // No linked teacher
    if (enriched.linkedTeacher == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🔗', style: TextStyle(fontSize: 48.sp)),
              SizedBox(height: 12.h),
              Text('غير مرتبط بمدرس رئيسي',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18.sp, fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
              SizedBox(height: 8.h),
              Text('يجب أن يكون حسابك مرتبطاً بمدرس رئيسي لعرض طلابه.\nتواصل مع المدرس ليقوم بالربط من خلال رمز التحقق.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linked Teacher Banner ──
          _buildLinkedTeacherBanner(enriched.linkedTeacher!, isDark),

          // ── Stats Row ──
          _buildStudentsStats(enriched.stats, isDark),
          SizedBox(height: 16.h),

          // ── Search & Filter ──
          _buildSearchAndFilter(isDark),

          // ── Students List ──
          _buildStudentsCards(isDark),
        ],
      ),
    );
  }

  Widget _buildLinkedTeacherBanner(LinkedTeacher teacher, bool isDark) {
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0x266366F1), const Color(0x1A7C3AED)]
              : [const Color(0x266366F1), const Color(0x1A7C3AED)],
        ),
        border: Border.all(
          color: isDark ? const Color(0x4D6366F1) : const Color(0x336366F1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundImage: teacher.avatar != null ? NetworkImage(teacher.avatar!) : null,
            child: Text(teacher.name.isNotEmpty ? teacher.name[0] : 'م',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المدرس الرئيسي المرتبط',
                    style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: textSecondary)),
                Text(teacher.name,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp, fontFamily: 'Cairo', color: textPrimary)),
                if (teacher.username != null)
                  Text('@${teacher.username}',
                      style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: const Color(0xFF6366F1))),
              ],
            ),
          ),
          if (teacher.specialties.isNotEmpty)
            ...teacher.specialties.take(2).map((s) => Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x336366F1) : const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(s,
                    style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: const Color(0xFF6366F1))),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildStudentsStats(StudentsStats stats, bool isDark) {
    final items = [
      _StatItem2(label: 'إجمالي الطلاب', value: '${stats.totalStudents}', emoji: '👥', color: const Color(0xFF6366F1)),
      _StatItem2(label: 'الكورسات', value: '${stats.totalCourses}', emoji: '📚', color: const Color(0xFF2563EB)),
      _StatItem2(label: 'إجمالي التسجيلات', value: '${stats.totalEnrollments}', emoji: '📝', color: const Color(0xFF059669)),
      _StatItem2(label: 'كورسات منشورة', value: '${stats.publishedCourses}', emoji: '✅', color: const Color(0xFFF59E0B)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 8.w, mainAxisSpacing: 8.h,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildStatCard2(items[i], isDark),
    );
  }

  Widget _buildStatCard2(_StatItem2 item, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 12, offset: const Offset(0, 2))]
            : [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      padding: EdgeInsets.all(8.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.emoji, style: TextStyle(fontSize: 20.sp)),
          SizedBox(height: 4.h),
          Text(item.value,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: item.color)),
          Text(item.label,
              textAlign: TextAlign.center,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8.sp, fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isDark) {
    return Column(
      children: [
        // Search field
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937)),
          decoration: InputDecoration(
            hintText: 'ابحث باسم الطالب أو البريد أو المستخدم...',
            hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)).withValues(alpha: .5)),
            prefixIcon: Icon(Icons.search, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          ),
        ),
        SizedBox(height: 8.h),
        // Course filter dropdown
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filterCourse,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937)),
              onChanged: (v) => setState(() => _filterCourse = v ?? 'all'),
              items: [
                DropdownMenuItem(value: 'all', child: Text('كل الكورسات',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))),
                ...(_enriched?.courses ?? []).map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.title, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsCards(bool isDark) {
    final students = _filteredStudents;
    if (students.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 32.h),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 56, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              SizedBox(height: 12.h),
              Text('لا يوجد طلاب مطابقون للبحث',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14.sp,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 12.h),
      itemCount: students.length,
      itemBuilder: (_, i) {
        final student = students[i];
        return _buildStudentCard(student, i, isDark);
      },
    );
  }

  Widget _buildStudentCard(AssistantStudent student, int index, bool isDark) {
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final hslHue = (index * 47) % 360;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => _showStudentDetail(student),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Avatar + name + arrow
              Row(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: HSLColor.fromAHSL(1, hslHue.toDouble(), 0.7, 0.55).toColor(),
                    child: Text(student.name.isNotEmpty ? student.name[0] : 'ط',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(student.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp, fontFamily: 'Cairo', color: textPrimary)),
                            ),
                            if (student.username != null) ...[
                              SizedBox(width: 4.w),
                              Text('@${student.username}',
                                  style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: const Color(0xFF6366F1))),
                            ],
                          ],
                        ),
                        if (student.email != null)
                          Text(student.email!,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.sp, fontFamily: 'Cairo', color: textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: const Color(0xFF6366F1)),
                ],
              ),
              SizedBox(height: 8.h),
              // Chips row
              Wrap(
                spacing: 6.w,
                runSpacing: 4.h,
                children: [
                  if (student.gradeLevel != null && student.gradeLevel!.isNotEmpty)
                    _chip(student.gradeLevel!, const Color(0xFF059669),
                        isDark ? const Color(0x33059669) : const Color(0xFFD1FAE5)),
                  _chip('${student.enrollments.length} كورس', const Color(0xFF2563EB),
                      isDark ? const Color(0x332563EB) : const Color(0xFFDBEAFE)),
                ],
              ),
              SizedBox(height: 10.h),
              // Stats row: avg progress + avg score + exams
              Row(
                children: [
                  // Average Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تقدم متوسط',
                            style: TextStyle(fontSize: 9.sp, fontFamily: 'Cairo', color: textSecondary)),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3.r),
                                child: LinearProgressIndicator(
                                  value: student.avgProgress / 100,
                                  minHeight: 6.h,
                                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation(
                                    student.avgProgress >= 75
                                        ? const Color(0xFF059669)
                                        : student.avgProgress >= 40
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text('${student.avgProgress.round()}%',
                                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Average Score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('متوسط الدرجات',
                          style: TextStyle(fontSize: 9.sp, fontFamily: 'Cairo', color: textSecondary)),
                      SizedBox(height: 4.h),
                      _buildScoreBadge(student.avgScore),
                    ],
                  ),
                  SizedBox(width: 16.w),
                  // Exam Attempts
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اختبارات',
                          style: TextStyle(fontSize: 9.sp, fontFamily: 'Cairo', color: textSecondary)),
                      SizedBox(height: 4.h),
                      Text('${student.examAttempts}',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: textPrimary)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: textColor)),
    );
  }

  Widget _buildScoreBadge(double? score) {
    if (score == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text('لا يوجد',
            style: TextStyle(fontSize: 9.sp, fontFamily: 'Cairo', color: const Color(0xFF94A3B8))),
      );
    }
    final color = score >= 75
        ? const Color(0xFF059669)
        : score >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    final bg = score >= 75
        ? const Color(0xFFD1FAE5)
        : score >= 50
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFFEE2E2);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text('${score.round()}%',
          style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: color)),
    );
  }

  void _showStudentDetail(AssistantStudent student) {
    Navigator.pushNamed(
      context,
      AssistantStudentDetailView.routeName,
      arguments: student.id,
    );
  }
}

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

class _StatItem2 {
  final String label;
  final String value;
  final String emoji;
  final Color color;
  const _StatItem2({required this.label, required this.value, required this.emoji, required this.color});
}
