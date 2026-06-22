import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Small quality-of-life extensions used all over the UI layer.
extension BuildContextX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Theme-aware text colors, since [AppColors] keeps light/dark separate.
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

  Color get cardColor => isDark ? AppColors.darkCard : AppColors.lightCard;

  Color get borderColor =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;

  List<Color> get backgroundGradient =>
      isDark ? AppColors.darkBackgroundGradient : AppColors.lightBackgroundGradient;
}
