import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';

class GradientText extends StatelessWidget {
  const GradientText({
    super.key, required this.text, required this.textSize,
  });

  final String text;
  final double textSize;
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.secondaryColor,
          ],
        ).createShader(bounds);
      },
      child:  Text(
        text,
        style: TextStyle(
          fontSize: textSize,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
