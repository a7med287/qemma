import 'package:flutter/material.dart';

class Assignment {
  final String id;
  final String title;
  final String subject;
  final String dueDate;
  final AssignmentType type;
  final AssignmentStatus status;
  final bool isCompleted;

  Assignment({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.type,
    required this.status,
    this.isCompleted = false,
  });

  Assignment copyWith({
    String? id,
    String? title,
    String? subject,
    String? dueDate,
    AssignmentType? type,
    AssignmentStatus? status,
    bool? isCompleted,
  }) {
    return Assignment(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

enum AssignmentType {
  homework,
  essay,
  exam,
  report,
  video,
}

enum AssignmentStatus {
  pending,
  urgent,
  completed,
  overdue,
}

extension AssignmentTypeExtension on AssignmentType {
  String get label {
    switch (this) {
      case AssignmentType.homework:
        return 'واجب';
      case AssignmentType.essay:
        return 'مقالة';
      case AssignmentType.exam:
        return 'اختبار';
      case AssignmentType.report:
        return 'تقرير';
      case AssignmentType.video:
        return 'فيديو';
    }
  }

  Color get color {
    switch (this) {
      case AssignmentType.homework:
        return const Color(0xFF0984E3);
      case AssignmentType.essay:
        return const Color(0xFFE91E63);
      case AssignmentType.exam:
        return const Color(0xFFFF9500);
      case AssignmentType.report:
        return const Color(0xFF00B894);
      case AssignmentType.video:
        return const Color(0xFFFF6B6B);
    }
  }

  IconData get icon {
    switch (this) {
      case AssignmentType.homework:
        return Icons.assignment;
      case AssignmentType.essay:
        return Icons.description;
      case AssignmentType.exam:
        return Icons.quiz;
      case AssignmentType.report:
        return Icons.assessment;
      case AssignmentType.video:
        return Icons.play_circle;
    }
  }
}