import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'teacher_theme_helpers.dart';

class TeacherAnalyticsStats extends StatelessWidget {
  const TeacherAnalyticsStats({
    super.key,
    required this.summary,
  });

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cards = [
      _StatData('إجمالي الطلاب', '${summary['totalStudents'] ?? '—'}', Icons.people, const Color(0xFF2563EB), summary['passRate'] != null && summary['passRate'] >= 70),
      _StatData('الاختبارات المنشورة', '${summary['totalExams'] ?? '—'}', Icons.assignment, const Color(0xFF7C3AED), true),
      _StatData('معدل النجاح', summary['passRate'] != null ? '${summary['passRate']}%' : '—', Icons.check_circle, const Color(0xFF059669), (summary['passRate'] ?? 0) >= 70),
      _StatData('متوسط الدرجات', '${summary['avgScore'] ?? '—'}', Icons.school, const Color(0xFFF59E0B), (summary['avgScore'] ?? 0) >= 70),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 1.4, crossAxisSpacing: 12.w, mainAxisSpacing: 12.h,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          ),
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36.w, height: 36.w,
                    decoration: BoxDecoration(
                      color: isDark ? c.color.withValues(alpha: .2) : c.color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(c.icon, color: c.color, size: 18.sp),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: c.trendUp ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      c.trendUp ? Icons.trending_up : Icons.trending_down,
                      size: 14.sp,
                      color: c.trendUp ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(c.value,
                  style: TextStyle(
                    fontSize: 20.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
                  )),
              SizedBox(height: 2.h),
              Text(c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp, fontWeight: FontWeight.w600, fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool trendUp;
  const _StatData(this.title, this.value, this.icon, this.color, this.trendUp);
}
