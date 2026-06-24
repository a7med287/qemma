import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../data/models/teacher_models.dart';

class TeacherDashboardStats extends StatelessWidget {
  const TeacherDashboardStats({super.key, required this.data});

  final TeacherDashboardData data;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final items = [
      _StatItem(title: 'إجمالي الطلاب', value: '${data.totalStudents}', icon: Icons.people, color: const Color(0xFF2563EB)),
      _StatItem(title: 'الكورسات النشطة', value: '${data.activeCourses}', icon: Icons.menu_book, color: const Color(0xFF7C3AED)),
      _StatItem(title: 'الحصص هذا الأسبوع', value: '${data.upcomingSchedules.length}', icon: Icons.videocam, color: const Color(0xFFDB2777)),
      _StatItem(title: 'معدل النجاح', value: data.passRate != null ? '${data.passRate!.round()}%' : '0%', icon: Icons.trending_up, color: const Color(0xFF059669)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.45,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildStatCard(context, items[i], isDark),
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
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: stat.color.withValues(alpha: .1),
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
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({required this.title, required this.value, required this.icon, required this.color});
}
