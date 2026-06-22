import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qemma/features/auth/presentation/views/login_view.dart';
import '../../../../../constants.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/services/shared_preferences_singleton.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_button.dart';
import 'on_boarding_page_view.dart';

class OnBoardingViewBody extends StatefulWidget {
  const OnBoardingViewBody({super.key});

  @override
  State<OnBoardingViewBody> createState() => _OnBoardingViewBodyState();
}

class _OnBoardingViewBodyState extends State<OnBoardingViewBody> {
  late PageController pageController;

  static const int _lastPageIndex = 2;
  var currentPage = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    pageController.addListener(() {
      final page = pageController.page?.round() ?? 0;
      if (page != currentPage) setState(() => currentPage = page);
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _finishOnBoarding() {
    Prefs.setBool(kIsOnBoardingSeen, true);
    Navigator.pushReplacementNamed(context, LoginView.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == _lastPageIndex;

    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: Visibility(
              visible: !isLastPage,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Padding(
                padding: EdgeInsets.only(top: 4.h, left: 8.w, right: 8.w),
                child: CustomTextButton(onPressed: _finishOnBoarding, text: "تخطّ"),
              ),
            ),
          ),
          Expanded(child: OnBoardingPageView(pageController: pageController)),
          DotsIndicator(
            dotsCount: 3,
            position: currentPage,
            decorator: DotsDecorator(
              activeColor: AppColors.primaryColor,
              color: context.textSecondary.withValues(alpha: .4),
              size: Size(8.w, 8.w),
              activeSize: Size(22.w, 8.w),
              spacing: EdgeInsets.symmetric(horizontal: 3.w),
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
              shape: const CircleBorder(),
            ),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding.w),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isLastPage
                  ? CustomButton(
                      key: const ValueKey("get_started"),
                      onPressed: _finishOnBoarding,
                      text: "ابدأ رحلتك التعليمية",
                    )
                  : SizedBox(
                      key: const ValueKey("next"),
                      width: double.infinity,
                      height: 52.h,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        onPressed: () => pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        ),
                        child: Text("التالي", style: TextStyle(color: context.textPrimary)),
                      ),
                    ),
            ),
          ),
          SizedBox(height: isLastPage ? 24.h : 32.h),
        ],
      ),
    );
  }
}
