import 'package:flutter/material.dart';
import '../explore_colors.dart';

class Course {
  final String id;
  final String title;
  final String subject;
  final String description;
  final double price;
  final double oldPrice;
  final String duration;
  final int lessonsCount;
  final int studentsCount;
  final double rating;
  final String level;
  final Color color;
  final List<Color> gradient;
  final List<String> tags;
  final double completionRate;
  final CourseTeacher teacher;

  Course({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.price,
    required this.oldPrice,
    required this.duration,
    required this.lessonsCount,
    required this.studentsCount,
    required this.rating,
    required this.level,
    required this.color,
    required this.gradient,
    required this.tags,
    required this.completionRate,
    required this.teacher,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String? ?? '';
    final style = ExploreColors.subjectColors[category] ?? SubjectStyle(color: 0xFF2563EB, gradient: ExploreColors.blueGradient);
    final teacherData = json['teacher'];
    return Course(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      subject: category,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      oldPrice: 0,
      duration: json['duration'] != null ? '${json['duration']} ساعة' : '',
      lessonsCount: json['stats']?['lessons'] ?? 0,
      studentsCount: json['stats']?['enrollments'] ?? 0,
      rating: 0,
      level: json['level'] as String? ?? '',
      color: Color(style.color),
      gradient: style.gradient,
      tags: [],
      completionRate: 0,
      teacher: teacherData != null
          ? CourseTeacher(
              id: teacherData['id'].toString(),
              userId: teacherData['userId']?.toString() ?? '',
              name: teacherData['user']?['name'] as String? ?? teacherData['name'] as String? ?? 'مدرس',
              rating: 0,
              students: 0,
              avatar: teacherData['user']?['avatar'] as String? ?? teacherData['avatar'] as String?,
            )
          : CourseTeacher(id: '', userId: '', name: 'مدرس', rating: 0, students: 0),
    );
  }
}

class CourseTeacher {
  final String id;
  final String userId;
  final String name;
  final double rating;
  final int students;
  final String? avatar;

  CourseTeacher({
    required this.id,
    required this.userId,
    required this.name,
    required this.rating,
    required this.students,
    this.avatar,
  });
}
