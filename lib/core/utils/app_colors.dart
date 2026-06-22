import 'package:flutter/material.dart';

/// Central color palette for the whole app.
///
/// Colors were sampled directly from the Qema (قِمَة) reference designs so the
/// Flutter app matches the web look 1:1 in both Light and Dark mode.
abstract class AppColors {
  // ---------------------------------------------------------------------
  // Brand / gradient colors (shared between Light & Dark)
  // ---------------------------------------------------------------------
  /// Indigo/blue - start of the brand gradient.
  static const Color gradientStart = Color(0xFF3959EB);

  /// Purple - middle stop of the brand gradient.
  static const Color gradientMid = Color(0xFF8438E3);

  /// Magenta/pink - end of the brand gradient.
  static const Color gradientEnd = Color(0xFFCB2A8B);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  /// Used as the "main" brand color wherever a single, flat color is needed
  /// (e.g. active dots indicator, icons, links).
  static const Color primaryColor = gradientStart;
  static const Color secondaryColor = gradientEnd;

  // ---------------------------------------------------------------------
  // Feature/accent colors (icons on cards, tags, badges...)
  // ---------------------------------------------------------------------
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentGreen = Color(0xFF22C55E);

  // ---------------------------------------------------------------------
  // Light theme
  // ---------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF7F8FE);
  static const List<Color> lightBackgroundGradient = [
    Color(0xFFD9E4FF),
    Color(0xFFE7DFFD),
    Color(0xFFFFFFFF),
  ];
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE9EBF7);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightSkipText = Color(0xFF575D5E);

  // ---------------------------------------------------------------------
  // Dark theme
  // ---------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF0A0E1F);
  static const List<Color> darkBackgroundGradient = [
    Color(0xFF1B1740),
    Color(0xFF120E2E),
    Color(0xFF0A0A1A),
  ];
  static const Color darkSurface = Color(0xFF0F1326);
  static const Color darkCard = Color(0xFF131831);
  static const Color darkBorder = Color(0xFF242A47);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkSkipText = Color(0xFFB7BCC6);

  static const Color dotInactiveOpacity = Color(0x80000000);
}
