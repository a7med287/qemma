import 'package:flutter/material.dart';
import 'features_on_boarding_page.dart';
import 'steps_on_boarding_page.dart';
import 'welcome_on_boarding_page.dart';

class OnBoardingPageView extends StatelessWidget {
  const OnBoardingPageView({super.key, required this.pageController});

  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: pageController,
      children: const [
        WelcomeOnBoardingPage(),
        FeaturesOnBoardingPage(),
        StepsOnBoardingPage(),
      ],
    );
  }
}
