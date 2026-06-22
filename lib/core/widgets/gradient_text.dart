import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Paints [text] using [AppColors.primaryGradient] instead of a flat color.
/// Used to highlight the brand name "قِمّة" wherever it appears in headings.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = AppColors.primaryGradient,
  });

  final String text;
  final TextStyle style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}
