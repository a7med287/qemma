import 'package:flutter/material.dart';
import '../../../../core/widgets/app_background.dart';
import 'widgets/on_boarding_view_body.dart';

class OnBoardingView extends StatelessWidget {
  const OnBoardingView({super.key});

  static const String routeName = "OnBoardingView";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: const AppBackground(child: OnBoardingViewBody()),
    );
  }
}
