import 'package:flutter/material.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'كورساتي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          _buildIconButton(Icons.book),
                          const SizedBox(width: 10),
                          _buildIconButton(Icons.school),
                        ],
                      ),
                    ],
                  ),
                ),

                // Section Header with Show All button
                const SizedBox(height: 20),
                CourseSectionHeader(
                  title: 'دوراتي التدريبية',
                  onShowAllPressed: () {
                    // Handle show all
                  },
                ),

                const SizedBox(height: 20),

                // Horizontal Course List
                const Expanded(
                  child: CoursesList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(10),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class CourseSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onShowAllPressed;

  const CourseSectionHeader({
    Key? key,
    required this.title,
    required this.onShowAllPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onShowAllPressed,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'عرض الكل',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CoursesList extends StatelessWidget {
  const CoursesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final courses = [
      CourseModel(
        title: 'الرياضيات ، التفاضل و التكامل',
        instructor: 'أ. محمد أحمد',
        progress: 0.75,
        currentLesson: 18,
        totalLessons: 24,
        rating: 4.8,
        color: const Color(0xFF667eea),
        icon: Icons.functions,
      ),
      CourseModel(
        title: 'الكيمياء العضوية',
        instructor: 'أ. أحمد سمير',
        progress: 0.45,
        currentLesson: 8,
        totalLessons: 18,
        rating: 4.9,
        color: const Color(0xFF00d2ff),
        icon: Icons.science,
      ),
      CourseModel(
        title: 'اللغة الإنجليزية - المستوى المتقدم',
        instructor: 'أ. نورا علي',
        progress: 0.30,
        currentLesson: 9,
        totalLessons: 30,
        rating: 4.6,
        color: const Color(0xFFf5576c),
        icon: Icons.language,
      ),
      CourseModel(
        title: 'الفيزياء - الميكانيكا الكلاسيكية',
        instructor: 'أ. سارة محمود',
        progress: 0.60,
        currentLesson: 12,
        totalLessons: 20,
        rating: 4.7,
        color: const Color(0xFFfa709a),
        icon: Icons.play_circle_outline,
      ),
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(left: 20),
          child: CourseCard(course: courses[index]),
        );
      },
    );
  }
}

class CourseCard extends StatelessWidget {
  final CourseModel course;

  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          height: 210,
          child: Column(
            children: [
              // Top colored border
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      course.color,
                      course.color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),

              SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with title and icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2d3748),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  course.instructor,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  course.color,
                                  course.color.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              course.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Progress section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'التقدم',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF718096),
                                ),
                              ),
                              Text(
                                '${(course.progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2d3748),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: course.progress,
                              backgroundColor: const Color(0xFFe2e8f0),
                              valueColor: AlwaysStoppedAnimation<Color>(course.color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Footer with lessons and rating
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFe2e8f0),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${course.currentLesson}/${course.totalLessons} درس',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF718096),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  course.rating.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2d3748),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFfbbf24),
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
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
}

class CourseModel {
  final String title;
  final String instructor;
  final double progress;
  final int currentLesson;
  final int totalLessons;
  final double rating;
  final Color color;
  final IconData icon;

  CourseModel({
    required this.title,
    required this.instructor,
    required this.progress,
    required this.currentLesson,
    required this.totalLessons,
    required this.rating,
    required this.color,
    required this.icon,
  });
}