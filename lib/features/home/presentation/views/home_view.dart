import 'package:flutter/material.dart';
import 'package:qemma/features/all_books_screen/presentation/views/all_books_view.dart';
import 'package:qemma/features/all_courses_screen/presentation/views/all_courses_view.dart';
import 'package:qemma/features/exam_generator/presentation/views/exam_generation_screen.dart';
import 'package:qemma/features/home/presentation/views/widgets/featured_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),

                const Text(
                  'اختر رحلتك التعليمية',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'منصة ذكية بتوفرلك كل اللي محتاجه علشان تتفوق',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                FeatureCard(
                  title: 'الكورسات التعليمية',
                  description:
                      'دروس متكاملة وشاملة من أفضل المدرسين من كل المراحل',
                  icon: Icons.school,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  features: [
                    'دروسات ملعة مجانا',
                    'شرح تفصيلي',
                    'تمرينة للتقدم',
                  ],
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CoursesScreen()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                FeatureCard(
                  title: 'كتب المدرسين',
                  description: 'ملخصات ومذكرات من أفضل مدرسي الأدبية للمواد',
                  icon: Icons.menu_book,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  features: ['ملخصات منهجية', 'مذكرات PDF', 'مراجعات نهائية'],
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BooksScreen()),
                    );
                  },
                ),

                const SizedBox(height: 16),
                FeatureCard(
                  title: 'الاختبارات والتمرينات',
                  description:
                      'اختبارات تفاعلية على جميع نماذج الاختبارات الأدبية المختلفة',
                  icon: Icons.edit_document,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  features: ['اختبارات متنوعة', 'نماذج امتحانات', 'تصحيح فوري'],
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamSelectionFlow(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
