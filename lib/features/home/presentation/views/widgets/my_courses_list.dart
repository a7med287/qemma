import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../my_courses/data/models/course_model.dart';
import '../../../../my_courses/presentation/views/widgets/course_progress_card.dart';

class MyCoursesHorizontalList extends StatefulWidget {
  const MyCoursesHorizontalList({super.key});

  @override
  State<MyCoursesHorizontalList> createState() =>
      _MyCoursesHorizontalListState();
}

class _MyCoursesHorizontalListState extends State<MyCoursesHorizontalList> {
  final List<CourseModel> courses = [
    CourseModel(
      title: 'الرياضيات - التفاضل و التكامل',
      instructor: 'أحمد أحمد',
      progress: 0.75,
      completedLessons: 18,
      totalLessons: 24,
      rating: 4.8,
      color: Colors.blue,
      icon: Icons.school_rounded
    ),
    CourseModel(
      title: 'الفيزياء - الميكانيكا التقليدية',
      instructor: 'سارة محمود',
      progress: 0.60,
      completedLessons: 12,
      totalLessons: 20,
      rating: 4.7,
      color: Colors.purple,
      icon:Icons.school_rounded
    ),
    CourseModel(
      title: 'الكيمياء العضوية',
      instructor: 'أحمد منصور',
      progress: 0.45,
      completedLessons: 9,
      totalLessons: 18,
      rating: 4.9,
      color: Colors.teal,
      icon: Icons.school_rounded,
    ),
    CourseModel(
      title: 'اللغة الإنجليزية - المستوى المتقدم',
      instructor: 'نورا علي',
      progress: 0.30,
      completedLessons: 9,
      totalLessons: 30,
      rating: 4.6,
      color: Colors.pink,
      icon: Icons.school_rounded,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          return CourseProgressCard(courseModel: courses[index]);
        },
      ),
    );
  }
}
