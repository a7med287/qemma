import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../../../core/widgets/gradient_border_card.dart';
import 'on_boarding_models.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({super.key, required this.feature});

  final OnBoardingFeatureModel feature;

  @override
  Widget build(BuildContext context) {
    return GradientBorderCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(feature.icon, color: feature.color, size: 18.sp),
          ),
          SizedBox(height: 10.h),
          // مثال داخل FeatureCard.dart
          Text(
            feature.title,
            maxLines: 1, // منع النص من التعدد إذا كان طويلاً جداً
            overflow: TextOverflow.ellipsis, // وضع نقاط عند القص
            style: TextStyles.semiBold14.copyWith(
              color: context.textPrimary,
              fontSize: 14.sp, // تأكد دائماً من استخدام .sp
            ),
          ),
          SizedBox(height: 4.h),
          // مثال داخل FeatureCard.dart
          Text(
            feature.description,
            maxLines: 3, // منع النص من التعدد إذا كان طويلاً جداً
            overflow: TextOverflow.ellipsis, // وضع نقاط عند القص
            style: TextStyles.semiBold14.copyWith(
              color: context.textPrimary,
              fontSize: 12.sp, // تأكد دائماً من استخدام .sp
            ),
          ),
        ],
      ),
    );
  }
}