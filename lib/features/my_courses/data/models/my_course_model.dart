import 'package:flutter/material.dart';
class Course {
  final String id;
  final String title;
  final String instructor;
  final int completedLessons;
  final int totalLessons;
  final double rating;
  final double progress;
  final CourseGradient gradient;

  Course({
    required this.id,
    required this.title,
    required this.instructor,
    required this.completedLessons,
    required this.totalLessons,
    required this.rating,
    required this.progress,
    required this.gradient,
  });

  String get lessonsText => '$completedLessons/$totalLessons دروس';
  String get progressText => '${progress.toInt()}%';
}

class CourseGradient {
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  CourseGradient({
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  static CourseGradient pink = CourseGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF8FB3)],
  );

  static CourseGradient green = CourseGradient(
    colors: [Color(0xFF00B894), Color(0xFF26D0A3)],
  );

  static CourseGradient purple = CourseGradient(
    colors: [Color(0xFF7B68EE), Color(0xFF9B8CFF)],
  );

  static CourseGradient blue = CourseGradient(
    colors: [Color(0xFF3498DB), Color(0xFF5DADE2)],
  );

  static CourseGradient orange = CourseGradient(
    colors: [Color(0xFFFF9500), Color(0xFFFFAB40)],
  );

  static CourseGradient red = CourseGradient(
    colors: [Color(0xFFE74C3C), Color(0xFFEC7063)],
  );
}