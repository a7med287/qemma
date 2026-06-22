import 'package:flutter/material.dart';
import '../explore_colors.dart';

class Book {
  final String id;
  final String title;
  final String subject;
  final String description;
  final double price;
  final double oldPrice;
  final int pages;
  final int downloads;
  final double rating;
  final Color color;
  final List<Color> gradient;
  final String? coverImage;
  final String grade;
  final String? createdAt;
  final List<String> tags;
  final BookTeacher teacher;

  Book({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.price,
    required this.oldPrice,
    required this.pages,
    required this.downloads,
    required this.rating,
    required this.color,
    required this.gradient,
    this.coverImage,
    required this.grade,
    this.createdAt,
    required this.tags,
    required this.teacher,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] as String? ?? '';
    final style = ExploreColors.subjectColors[subject] ?? SubjectStyle(color: 0xFF2563EB, gradient: ExploreColors.blueGradient);
    return Book(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      subject: subject,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      oldPrice: 0,
      pages: 0,
      downloads: json['purchases'] ?? 0,
      rating: 0,
      color: Color(style.color),
      gradient: style.gradient,
      coverImage: json['coverImage'] as String?,
      grade: json['grade'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      tags: [],
      teacher: BookTeacher(
        id: json['teacherId']?.toString() ?? '',
        name: json['teacherName'] as String? ?? 'مدرس',
        avatar: json['teacherAvatar'] as String?,
        rating: 0,
      ),
    );
  }
}

class BookTeacher {
  final String id;
  final String name;
  final String? avatar;
  final double rating;

  BookTeacher({
    required this.id,
    required this.name,
    this.avatar,
    required this.rating,
  });
}
