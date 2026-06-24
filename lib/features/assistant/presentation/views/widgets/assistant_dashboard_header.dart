import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../../auth/presentation/views/login_view.dart';
import '../assistant_notifications_view.dart';
import '../assistant_profile_view.dart';

class AssistantDashboardHeader extends StatelessWidget {
  const AssistantDashboardHeader({
    super.key,
    required this.teacherName,
    required this.unreadCount,
  });

  final String teacherName;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final initial = teacherName.isNotEmpty ? teacherName[0] : 'م';
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
                      Text('مرحباً، ${teacherName.isNotEmpty ? teacherName : 'المدرس المساعد'}',
                          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                      SizedBox(height: 4.h),
                      _chip('مدرس مساعد'),
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
                        if (unreadCount > 0)
                          Positioned(
                            right: 0, top: 0,
                            child: Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                              constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h),
                              child: Text('$unreadCount',
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

  Widget _chip(String label) {
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
}
