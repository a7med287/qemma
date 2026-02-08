import 'package:flutter/material.dart';
import 'package:qemma/core/utils/app_colors.dart';
import 'package:qemma/core/utils/styles.dart';
import 'package:qemma/core/widgets/custom_elevation_button.dart';
import 'package:qemma/features/home/presentation/views/widgets/custom_drawer.dart';
import 'package:qemma/features/home/presentation/views/widgets/home_header.dart';
import 'package:qemma/features/home/presentation/views/widgets/my_courses_list.dart';
import 'package:qemma/features/home/presentation/views/widgets/my_courses_section.dart';
import 'package:qemma/features/home/presentation/views/widgets/student_statistics_list.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            HomeHeader(),
            HorizontalStatisticsList(),
            MyCoursesSection(),
          ],
        ),
      ),
    );
  }
}

