import 'package:flutter/material.dart';
import 'package:qemma/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:qemma/features/home/presentation/views/home_view.dart';

import '../utils/app_colors.dart';

class ButtonNavigationBar extends StatelessWidget {
  final int selectedIndex;
  const ButtonNavigationBar({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,

      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: Colors.grey,
      currentIndex: selectedIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardView()),
            );
            break;
        }
      },
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسيه"),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: "لوحة التحكم",
        ),
      ],
    );
  }
}
