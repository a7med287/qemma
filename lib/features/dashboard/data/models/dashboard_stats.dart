import 'package:flutter/material.dart';

class DashboardStats {
  final double comprehensionRate;
  final double commitmentRate;
  final double attendanceRate;
  final int studyHours;
  final int rank;
  final int totalPoints;
  final int weeks;

  DashboardStats({
    required this.comprehensionRate,
    required this.commitmentRate,
    required this.attendanceRate,
    required this.studyHours,
    required this.rank,
    required this.totalPoints,
    required this.weeks,
  });
}

class SubjectProgress {
  final String name;
  final String chapter;
  final double progress;
  final double score;
  final int totalScore;
  final Color color;
  final bool needsImprovement;

  SubjectProgress({
    required this.name,
    required this.chapter,
    required this.progress,
    required this.score,
    required this.totalScore,
    required this.color,
    this.needsImprovement = false,
  });
}

class TaskItem {
  final String title;
  final String subtitle;
  final String? dueDate;
  final Color color;
  final IconData icon;
  final bool isUrgent;

  TaskItem({
    required this.title,
    required this.subtitle,
    this.dueDate,
    required this.color,
    required this.icon,
    this.isUrgent = false,
  });
}
