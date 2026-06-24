import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../../auth/presentation/views/login_view.dart';
import '../../../data/models/teacher_models.dart';
import '../teacher_notifications_view.dart';
import '../teacher_profile_view.dart';

class TeacherDashboardHeader extends StatelessWidget {
  const TeacherDashboardHeader({super.key, required this.data});

  final TeacherDashboardData data;

  @override
  Widget build(BuildContext context) {
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
                        if (value == 'profile') {
                          Navigator.pushNamed(context, TeacherProfileView.routeName);
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
}
