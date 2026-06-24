import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../../auth/presentation/views/login_view.dart';
import '../../routes/parent_routes.dart';

class ParentDashboardHeader extends StatelessWidget {
  const ParentDashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: Colors.white.withValues(alpha: .2),
                  child: Text(
                    (user?.name ?? '?')[0],
                    style: TextStyles.bold18.copyWith(color: Colors.white),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً، ${user?.name ?? ''}',
                        style: TextStyles.semiBold16.copyWith(color: Colors.white),
                      ),
                      Text(
                        'ولي أمر',
                        style: TextStyles.regular13.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, ParentRoutes.notifications),
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (v) {
                    if (v == 'profile') {
                      Navigator.pushNamed(context, ParentRoutes.profile);
                    } else if (v == 'logout') {
                      context.read<AuthCubit>().logout();
                      Navigator.pushNamedAndRemoveUntil(
                          context, LoginView.routeName, (_) => false);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 20),
                          SizedBox(width: 8),
                          Text('الملف الشخصي', style: TextStyle(fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('تسجيل الخروج',
                              style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}
