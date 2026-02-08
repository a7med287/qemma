import 'package:flutter/material.dart';
import 'package:qemma/core/widgets/back_icon_widget.dart';
import 'package:qemma/features/my_courses/presentation/views/widgets/filter_chip_item.dart';
import 'package:qemma/features/my_courses/presentation/views/widgets/my_course_card.dart';

import '../../../../core/widgets/bottom_navigation_bar.dart';
import '../../../home/presentation/views/widgets/gradient_fab.dart';
import '../../data/models/my_course_model.dart';


class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  String _selectedFilter = 'الكل (6)';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'الكل (6)',
    'قيد التقدم',
    'مكتملة',
    'لم تبدأ',
  ];

  final List<Course> _courses = [
    Course(
      id: '1',
      title: 'الرياضيات - التفاضل والتكامل',
      instructor: 'محمد أحمد',
      completedLessons: 18,
      totalLessons: 24,
      rating: 4.8,
      progress: 75,
      gradient: CourseGradient.blue,
    ),
    Course(
      id: '2',
      title: 'الفيزياء - الميكانيكا الكلاسيكية',
      instructor: 'سارة محمود',
      completedLessons: 12,
      totalLessons: 20,
      rating: 4.7,
      progress: 60,
      gradient: CourseGradient.purple,
    ),
    Course(
      id: '3',
      title: 'الكيمياء العضوية',
      instructor: 'أحمد حسن',
      completedLessons: 8,
      totalLessons: 18,
      rating: 4.9,
      progress: 45,
      gradient: CourseGradient.green,
    ),
    Course(
      id: '4',
      title: 'اللغة الإنجليزية - المستوى المتقدم',
      instructor: 'نورا علي',
      completedLessons: 9,
      totalLessons: 30,
      rating: 4.6,
      progress: 30,
      gradient: CourseGradient.pink,
    ),
    Course(
      id: '5',
      title: 'البرمجة بلغة Python',
      instructor: 'خالد يوسف',
      completedLessons: 15,
      totalLessons: 25,
      rating: 4.9,
      progress: 60,
      gradient: CourseGradient.orange,
    ),
    Course(
      id: '6',
      title: 'الأحياء - الخلية والوراثة',
      instructor: 'مريم سعيد',
      completedLessons: 10,
      totalLessons: 22,
      rating: 4.7,
      progress: 45,
      gradient: CourseGradient.red,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar:  ButtonNavigationBar(selectedIndex: 2),
      floatingActionButton: GradientFab(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5F72FF), Color(0xFF4E5FE8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildFilters(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildCourseList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Top Bar
          Row(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  const Text(
                    'كورساتي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث عن كورس...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                icon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChipItem(
              label: filter,
              isSelected: _selectedFilter == filter,
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCourseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MyCourseCard(
            course: _courses[index],
            onTap: () {
              // Navigate to course details
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}