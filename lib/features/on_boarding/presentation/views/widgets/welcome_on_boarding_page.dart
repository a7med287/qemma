import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../../../core/widgets/gradient_text.dart';

/// First onboarding page — the hero/welcome message:
/// "تعلّم بذكاء... وحقق أعلى نتيجة مع قِمّة"
class WelcomeOnBoardingPage extends StatelessWidget {
  const WelcomeOnBoardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyles.bold25.copyWith(color: context.textPrimary);

    // LayoutBuilder + ConstrainedBox(minHeight) lets the content stay
    // vertically centered on normal/tall phone screens (the common case),
    // but still scroll instead of overflowing on short screens or in
    // landscape, where small phones don't have enough height for the
    // Spacers + blob + headline + paragraph all at once.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 16.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32.h,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decorative gradient blob behind the headline, echoing the
                // soft colorful background from the web hero section.
                _HeroBlob(),
                SizedBox(height: 40.h),
                Text(
                  "تعلّم بذكاء...",
                  textAlign: TextAlign.center,
                  style: titleStyle,
                ),
                SizedBox(height: 6.h),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text("وحقق أعلى نتيجة مع ", style: titleStyle),
                    GradientText("قِمّة", style: titleStyle),
                  ],
                ),
                SizedBox(height: 20.h),
                Text(
                  "منصة تعليمية ذكية لطلاب الثانوية العامة تجمع بين الشرح العميق، "
                      "التدريب الحقيقي، والمتابعة المستمرة لحد يوم النتيجة.",
                  textAlign: TextAlign.center,
                  style: TextStyles.regular14.copyWith(
                    color: context.textSecondary,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroBlob extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140.w,
      height: 140.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140.w,
            height: 140.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  context.isDark
                      ? const Color(0xFF8438E3).withValues(alpha: .35)
                      : const Color(0xFF8438E3).withValues(alpha: .15),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          Icon(
            Icons.auto_awesome_rounded,
            size: 56.sp,
            color: context.isDark ? Colors.white : const Color(0xFF3959EB),
          ),
        ],
      ),
    );
  }
}