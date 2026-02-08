import 'package:flutter/material.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/custom_drawer.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/dashboard_header.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/my_courses_section.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/student_statistics_list.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            DashBoardHeader(),
            HorizontalStatisticsList(),
            MyCoursesSection(),
          ],
        ),
      ),
    );
  }
}

