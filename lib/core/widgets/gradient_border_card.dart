import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../helpers/build_context_extensions.dart';
import '../utils/app_colors.dart';

/// A surface card with a thin gradient line on its top edge — the signature
/// "feature card" look used across the Qema designs (see the 6 feature
/// cards and the 4 step cards).
class GradientBorderCard extends StatelessWidget {
  const GradientBorderCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius.r);
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: radius,
        border: Border.all(color: context.borderColor),
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 3.h, decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
          Padding(
            padding: padding ?? EdgeInsets.all(16.r),
            child: child,
          ),
        ],
      ),
    );
  }
}
