import 'package:flutter/material.dart';
import 'package:qemma/features/ai_qemma_chat/presentation/views/chat_view.dart';
import 'package:qemma/features/home/presentation/views/home_view.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_images.dart';
import '../../../../my_courses/presentation/views/my_courses_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF5F5FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage(Assets.testProfileImage),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'أحمد رزق فتحى',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ahmed@student.com',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  const Divider(),

                  _buildMenuItem(
                    icon: Icons.home,
                    iconColor: AppColors.primaryColor,
                    title: 'الرئيسية',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(),
                        ),
                      );

                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.school,
                    iconColor: Colors.purple,
                    title: 'كورساتي',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyCoursesScreen(),
                        ),
                      );

                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.quiz,
                    iconColor: Colors.teal,
                    title: 'الاختبارات',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.video_library,
                    iconColor: Colors.red,
                    title: 'الحصص المباشرة',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.question_answer,
                    iconColor: Colors.orange,
                    title: 'المساعد الذكي',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AiQemmaChatView(),
                        ),
                      );

                    },
                  ),
                  const Divider(),

                  _buildMenuItem(
                    icon: Icons.person,
                    iconColor: Colors.deepPurple,
                    title: 'الملف الشخصي',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    iconColor: Colors.grey,
                    title: 'الإعدادات',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  _buildMenuItem(
                    icon: Icons.logout,
                    iconColor: Colors.red,
                    title: 'تسجيل الخروج',
                    titleColor: Colors.red,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: titleColor ?? Colors.black87,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
