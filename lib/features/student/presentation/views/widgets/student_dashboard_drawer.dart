import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../../auth/presentation/views/login_view.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../data/mock/student_mock_data.dart';
import '../../../data/models/student_models.dart';
import '../../routes/student_routes.dart';
import '../../widgets/student_shared_widgets.dart';
import 'student_dashboard_calendar.dart';

class StudentDashboardDrawer extends StatelessWidget {
  const StudentDashboardDrawer({
    super.key,
    required this.data,
    this.onAssistantTap,
  });

  final StudentDashboardData data;
  final VoidCallback? onAssistantTap;

  @override
  Widget build(BuildContext context) {
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
                            onAssistantTap?.call();
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
                    child: StudentDashboardCalendar(data: data),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
