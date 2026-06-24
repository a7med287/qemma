import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../data/models/assistant_models.dart';

class DashboardHomeTab extends StatelessWidget {
  final AssistantDashboardData data;
  final bool isDark;
  final VoidCallback onQuickActionStudents;
  final VoidCallback onQuickActionChat;
  final VoidCallback onQuickActionGrade;
  final VoidCallback onQuickActionNotifications;

  const DashboardHomeTab({
    super.key,
    required this.data,
    required this.isDark,
    required this.onQuickActionStudents,
    required this.onQuickActionChat,
    required this.onQuickActionGrade,
    required this.onQuickActionNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatsRow(data: data, isDark: isDark),
          SizedBox(height: 20.h),
          _QuickActionsGrid(
            isDark: isDark,
            onStudents: onQuickActionStudents,
            onChat: onQuickActionChat,
            onGrade: onQuickActionGrade,
            onNotifications: onQuickActionNotifications,
          ),
          SizedBox(height: 20.h),
          if (data.recentAttempts.isNotEmpty) ...[
            Text('محاولات بانتظار التصحيح',
                style: TextStyles.semiBold16.copyWith(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E))),
            SizedBox(height: 10.h),
            ...data.recentAttempts.take(5).map((a) => _AttemptItem(attempt: a, isDark: isDark)),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AssistantDashboardData data;
  final bool isDark;
  const _StatsRow({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(title: 'الطلاب', value: '${data.studentsCount}', icon: Icons.people, color: const Color(0xFF2563EB), bgColor: const Color(0xFFEFF6FF)),
      _StatData(title: 'محادثات نشطة', value: '${data.activeChats}', icon: Icons.chat_bubble_outline, color: const Color(0xFF059669), bgColor: const Color(0xFFECFDF5)),
      _StatData(title: 'تصحيح مقالات', value: '${data.pendingGrading}', icon: Icons.assignment_turned_in, color: const Color(0xFFF59E0B), bgColor: const Color(0xFFFFFBEB)),
      _StatData(title: 'إشعارات جديدة', value: '${data.unreadCount}', icon: Icons.notifications, color: const Color(0xFFDB2777), bgColor: const Color(0xFFFDF2F8)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 12.w, mainAxisSpacing: 12.h,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _StatCard(stat: stats[i], isDark: isDark),
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _StatData({required this.title, required this.value, required this.icon, required this.color, required this.bgColor});
}

class _StatCard extends StatelessWidget {
  final _StatData stat;
  final bool isDark;
  const _StatCard({required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
}

class _QuickActionsGrid extends StatelessWidget {
  final bool isDark;
  final VoidCallback onStudents;
  final VoidCallback onChat;
  final VoidCallback onGrade;
  final VoidCallback onNotifications;

  const _QuickActionsGrid({
    required this.isDark,
    required this.onStudents,
    required this.onChat,
    required this.onGrade,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickActionData(title: 'الطلاب', desc: 'عرض الطلاب المسجلين', icon: Icons.people, color: const Color(0xFF2563EB), onTap: onStudents),
      _QuickActionData(title: 'المحادثات', desc: 'تواصل مع الطلاب والمدرس', icon: Icons.chat_bubble_outline, color: const Color(0xFF059669), onTap: onChat),
      _QuickActionData(title: 'تصحيح الاختبارات', desc: 'تصحيح مقالات الطلاب', icon: Icons.assignment_turned_in, color: const Color(0xFFF59E0B), onTap: onGrade),
      _QuickActionData(title: 'الإشعارات', desc: 'عرض الإشعارات', icon: Icons.notifications, color: const Color(0xFFDB2777), onTap: onNotifications),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('إجراءات سريعة',
            style: TextStyles.bold18.copyWith(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E))),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 10.w, mainAxisSpacing: 10.h,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _QuickActionCard(action: items[i], isDark: isDark),
        ),
      ],
    );
  }
}

class _QuickActionData {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _QuickActionData({required this.title, required this.desc, required this.icon, required this.color, this.onTap});
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData action;
  final bool isDark;
  const _QuickActionCard({required this.action, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
}

class _AttemptItem extends StatelessWidget {
  final Map<String, dynamic> attempt;
  final bool isDark;
  const _AttemptItem({required this.attempt, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
}

class DashboardStudentsTab extends StatelessWidget {
  final bool isDark;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final EnrichedStudentsResponse? enriched;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String filterCourse;
  final ValueChanged<String> onFilterChanged;
  final List<Course> courses;
  final List<AssistantStudent> filteredStudents;
  final void Function(AssistantStudent student) onStudentTap;

  const DashboardStudentsTab({
    super.key,
    required this.isDark,
    required this.loading,
    this.error,
    required this.onRetry,
    this.enriched,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.filterCourse,
    required this.onFilterChanged,
    required this.courses,
    required this.filteredStudents,
    required this.onStudentTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            SizedBox(height: 12.h),
            Text(error!, style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
            SizedBox(height: 12.h),
            ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    if (enriched == null) {
      return const SizedBox.shrink();
    }

    if (enriched!.linkedTeacher == null) {
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
          _LinkedTeacherBanner(teacher: enriched!.linkedTeacher!, isDark: isDark),
          _StudentsStatsGrid(stats: enriched!.stats, isDark: isDark),
          SizedBox(height: 16.h),
          _SearchAndFilter(
            isDark: isDark,
            searchQuery: searchQuery,
            onSearchChanged: onSearchChanged,
            filterCourse: filterCourse,
            onFilterChanged: onFilterChanged,
            courses: courses,
          ),
          _StudentsList(
            isDark: isDark,
            students: filteredStudents,
            onStudentTap: onStudentTap,
          ),
        ],
      ),
    );
  }
}

class _LinkedTeacherBanner extends StatelessWidget {
  final LinkedTeacher teacher;
  final bool isDark;
  const _LinkedTeacherBanner({required this.teacher, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
}

class _StudentsStatsGrid extends StatelessWidget {
  final StudentsStats stats;
  final bool isDark;
  const _StudentsStatsGrid({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StudentsStatData(label: 'إجمالي الطلاب', value: '${stats.totalStudents}', emoji: '👥', color: const Color(0xFF6366F1)),
      _StudentsStatData(label: 'الكورسات', value: '${stats.totalCourses}', emoji: '📚', color: const Color(0xFF2563EB)),
      _StudentsStatData(label: 'إجمالي التسجيلات', value: '${stats.totalEnrollments}', emoji: '📝', color: const Color(0xFF059669)),
      _StudentsStatData(label: 'كورسات منشورة', value: '${stats.publishedCourses}', emoji: '✅', color: const Color(0xFFF59E0B)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 8.w, mainAxisSpacing: 8.h,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _StudentsStatCard(item: items[i], isDark: isDark),
    );
  }
}

class _StudentsStatData {
  final String label;
  final String value;
  final String emoji;
  final Color color;
  const _StudentsStatData({required this.label, required this.value, required this.emoji, required this.color});
}

class _StudentsStatCard extends StatelessWidget {
  final _StudentsStatData item;
  final bool isDark;
  const _StudentsStatCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
}

class _SearchAndFilter extends StatelessWidget {
  final bool isDark;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String filterCourse;
  final ValueChanged<String> onFilterChanged;
  final List<Course> courses;

  const _SearchAndFilter({
    required this.isDark,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.filterCourse,
    required this.onFilterChanged,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: onSearchChanged,
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
              value: filterCourse,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937)),
              onChanged: (v) => onFilterChanged(v ?? 'all'),
              items: [
                DropdownMenuItem(value: 'all', child: Text('كل الكورسات',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))),
                ...courses.map((c) => DropdownMenuItem(
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
}

class _StudentsList extends StatelessWidget {
  final bool isDark;
  final List<AssistantStudent> students;
  final void Function(AssistantStudent student) onStudentTap;

  const _StudentsList({
    required this.isDark,
    required this.students,
    required this.onStudentTap,
  });

  @override
  Widget build(BuildContext context) {
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
      itemBuilder: (_, i) => _StudentCard(
        student: students[i],
        index: i,
        isDark: isDark,
        onTap: () => onStudentTap(students[i]),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final AssistantStudent student;
  final int index;
  final bool isDark;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.index,
    required this.isDark,
    required this.onTap,
  });

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

  Widget _scoreBadge(double? score) {
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

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('متوسط الدرجات',
                          style: TextStyle(fontSize: 9.sp, fontFamily: 'Cairo', color: textSecondary)),
                      SizedBox(height: 4.h),
                      _scoreBadge(student.avgScore),
                    ],
                  ),
                  SizedBox(width: 16.w),
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
}
