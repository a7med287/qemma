import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../features/student/presentation/views/student_dashboard_view.dart';
import '../../features/explore/screens/courses_page.dart';
import '../../features/explore/screens/teachers_books_page.dart';
import '../../features/explore/screens/exams_page_out.dart';
import '../../core/utils/app_colors.dart';

class MainView extends StatefulWidget {
  static const routeName = kStudentHomeRoute;
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const StudentDashboardView(),
    const CoursesPage(),
    const TeachersBooksPage(),
    const ExamsPageOut(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'لوحة التحكم',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school),
                label: 'الكورسات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'الكتب',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.quiz_outlined),
                activeIcon: Icon(Icons.quiz),
                label: 'الاختبارات',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
