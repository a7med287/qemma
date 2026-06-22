import 'package:flutter/material.dart';

class ExploreColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color accent = Color(0xFFDB2777);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const List<Color> mainGradient = [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)];
  static const List<Color> blueGradient = [Color(0xFF2563EB), Color(0xFF1D4ED8)];
  static const List<Color> purpleGradient = [Color(0xFF7C3AED), Color(0xFF6D28D9)];
  static const List<Color> pinkGradient = [Color(0xFFDB2777), Color(0xFFBE185D)];
  static const List<Color> greenGradient = [Color(0xFF059669), Color(0xFF047857)];
  static const List<Color> orangeGradient = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const List<Color> cyanGradient = [Color(0xFF0891B2), Color(0xFF0E7490)];

  static Map<String, SubjectStyle> subjectColors = {
    'الرياضيات': SubjectStyle(color: 0xFF2563EB, gradient: blueGradient),
    'الفيزياء': SubjectStyle(color: 0xFF059669, gradient: greenGradient),
    'الكيمياء': SubjectStyle(color: 0xFFDB2777, gradient: pinkGradient),
    'الأحياء': SubjectStyle(color: 0xFF059669, gradient: greenGradient),
    'اللغة العربية': SubjectStyle(color: 0xFFF59E0B, gradient: orangeGradient),
    'اللغة الإنجليزية': SubjectStyle(color: 0xFF2563EB, gradient: blueGradient),
    'التاريخ': SubjectStyle(color: 0xFF7C3AED, gradient: purpleGradient),
    'الجغرافيا': SubjectStyle(color: 0xFF0891B2, gradient: cyanGradient),
    'الفلسفة': SubjectStyle(color: 0xFF7C3AED, gradient: purpleGradient),
  };
}

class SubjectStyle {
  final int color;
  final List<Color> gradient;
  const SubjectStyle({required this.color, required this.gradient});
}
