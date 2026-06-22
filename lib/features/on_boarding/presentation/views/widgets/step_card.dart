import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../../../core/widgets/gradient_border_card.dart';
import 'on_boarding_models.dart';

class StepCard extends StatelessWidget {
  const StepCard({super.key, required this.step});

  final OnBoardingStepModel step;

  @override
  Widget build(BuildContext context) {
    return GradientBorderCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              "${step.number}",
              style: TextStyles.bold18.copyWith(
                color: Colors.white,
                fontSize: 15.sp,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            step.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.semiBold14.copyWith(
              color: context.textPrimary,
              fontSize: 12.5.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            step.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.regular13.copyWith(
              color: context.textSecondary,
              fontSize: 10.5.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}