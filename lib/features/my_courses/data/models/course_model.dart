
import 'package:flutter/cupertino.dart';

class CourseModel {
  final String title;
  final String instructor;
  final double progress;
  final int completedLessons;
  final int totalLessons;
  final double rating;
  final Color color;
  final IconData icon;

  CourseModel({
    required this.title,
    required this.instructor,
    required this.progress,
    required this.completedLessons,
    required this.totalLessons,
    required this.rating,
    required this.color,
    required this.icon,
  });
}