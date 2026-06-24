import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../data/models/student_models.dart';
import '../../widgets/student_shared_widgets.dart';

class StudentDashboardHeader extends StatelessWidget {
  const StudentDashboardHeader({
    super.key,
    required this.data,
    this.onMenuTap,
    this.onNotificationTap,
  });

  final StudentDashboardData data;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
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
                onPressed: onMenuTap ?? () {},
                icon: const Icon(Icons.menu, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white12),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: onNotificationTap ?? () {},
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
                          child: Text(stat.change,
                              style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.bold)),
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

  static IconData _kpiIcon(String type) {
    return switch (type) {
      'avgGrade' => Icons.star,
      'homework' => Icons.check_circle,
      'attendance' => Icons.school,
      'studyTime' => Icons.access_time,
      _ => Icons.analytics,
    };
  }
}
