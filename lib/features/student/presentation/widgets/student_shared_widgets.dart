import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class StudentGlassCard extends StatelessWidget {
  const StudentGlassCard({
    super.key,
    this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
    required this.child,
  });

  final String? title;
  final String? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor),
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4.h,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  Row(
                    children: [
                      if (icon != null) ...[
                        Text(icon!, style: TextStyle(fontSize: 20.sp)),
                        SizedBox(width: 8.w),
                      ],
                      Expanded(
                        child: Text(
                          title!,
                          style: TextStyles.bold18.copyWith(color: context.textPrimary),
                        ),
                      ),
                      if (actionLabel != null && onAction != null)
                        TextButton.icon(
                          onPressed: onAction,
                          icon: Icon(Icons.arrow_back, size: 16.sp, color: context.textSecondary),
                          label: Text(
                            actionLabel!,
                            style: TextStyles.semiBold13.copyWith(color: context.textSecondary),
                          ),
                        ),
                    ],
                  ),
                  Divider(color: context.borderColor, height: 24.h),
                ],
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudentGradientHeader extends StatelessWidget {
  const StudentGradientHeader({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      padding: padding ?? EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      child: SafeArea(
        bottom: false,
        child: child,
      ),
    );
  }
}

class StudentBackButton extends StatelessWidget {
  const StudentBackButton({super.key, this.onPressed, this.color = Colors.white});

  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: Icon(Icons.arrow_back, color: color),
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: .15),
      ),
    );
  }
}

class StudentPageShell extends StatelessWidget {
  const StudentPageShell({
    super.key,
    required this.title,
    required this.body,
    this.headerChild,
    this.gradient = AppColors.primaryGradient,
    this.onBack,
  });

  final String title;
  final Widget body;
  final Widget? headerChild;
  final Gradient gradient;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: gradient),
            padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 20.h),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StudentBackButton(onPressed: onBack),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyles.bold20.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (headerChild != null) ...[
                    SizedBox(height: 16.h),
                    headerChild!,
                  ],
                ],
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

Color studentGradeColor(double grade) {
  if (grade >= 90) return const Color(0xFF059669);
  if (grade >= 80) return const Color(0xFF2563EB);
  if (grade >= 70) return const Color(0xFF7C3AED);
  if (grade >= 60) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

String studentInitials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
  if (parts.isNotEmpty) return parts[0][0];
  return 'U';
}

const arabicMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

const arabicDays = ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];
