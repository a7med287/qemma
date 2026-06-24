import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class ParentGlassCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;

  const ParentGlassCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.accentColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.gradientMid;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor.withValues(alpha: .5)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: .6)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
          ),
          if (title != null || actionLabel != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 0),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18.sp, color: accent),
                    SizedBox(width: 8.w),
                  ],
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyles.semiBold16.copyWith(color: context.textPrimary),
                      ),
                    ),
                  if (actionLabel != null)
                    TextButton(
                      onPressed: onAction,
                      child: Text(
                        actionLabel!,
                        style: TextStyles.semiBold13.copyWith(color: accent),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: padding ?? EdgeInsets.all(16.r),
            child: child,
          ),
        ],
      ),
    );
  }
}

class ParentStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const ParentStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.borderColor.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyles.bold20.copyWith(color: context.textPrimary),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyles.regular13.copyWith(color: context.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ParentGradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final double height;

  const ParentGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: استخدمنا `constraints` بـ minHeight بدل `height` الثابتة، علشان
    // الـ Container يكبر تلقائيًا لو المحتوى (leading/trailing/title/subtitle)
    // احتاج مساحة أكبر من القيمة المحددة، بدل ما يحصل RenderFlex overflow.
    return Container(
      constraints: BoxConstraints(minHeight: height.h),
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          // FIX: mainAxisSize.min + شيل الـ Spacer() الخارجي، علشان الـ Column
          // ياخد بالظبط المساحة اللي محتاجها بدون أي افتراض بارتفاع غير محدود.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leading != null) leading!,
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyles.bold20.copyWith(color: Colors.white),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4.h),
              Text(
                subtitle!,
                style: TextStyles.regular13.copyWith(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ParentBackButton extends StatelessWidget {
  const ParentBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }
}

class ParentPageShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? trailing;
  final double headerHeight;

  const ParentPageShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.trailing,
    this.headerHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ParentGradientHeader(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            height: headerHeight,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 16.h, bottom: 24.h),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

Color parentGradeColor(double value) {
  if (value >= 90) return const Color(0xFF059669);
  if (value >= 75) return const Color(0xFF2563EB);
  if (value >= 60) return const Color(0xFFD97706);
  return const Color(0xFFEF4444);
}

Color? parentStatusColor(String status) {
  switch (status) {
    case 'completed':
    case 'submitted':
    case 'passed':
      return const Color(0xFF059669);
    case 'pending':
    case 'upcoming':
      return const Color(0xFFD97706);
    case 'missed':
    case 'failed':
      return const Color(0xFFEF4444);
    case 'graded':
      return const Color(0xFF2563EB);
    default:
      return null;
  }
}

String parentStatusLabel(String status) {
  switch (status) {
    case 'completed':
      return 'مكتمل';
    case 'submitted':
      return 'تم التسليم';
    case 'passed':
      return 'ناجح';
    case 'pending':
      return 'معلق';
    case 'upcoming':
      return 'قادم';
    case 'missed':
      return 'فات';
    case 'failed':
      return 'راسب';
    case 'graded':
      return 'مصحح';
    default:
      return status;
  }
}