import 'package:flutter/material.dart';
import 'package:qemma/features/dashboard/presentation/views/assignments_view.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/achievement_banner.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/assignments_section.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/custom_drawer.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/dashboard_header.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/my_courses_section.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/student_statistics_list.dart';

import '../../../../core/widgets/bottom_navigation_bar.dart';
import '../../../home/presentation/views/widgets/gradient_fab.dart';

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
            AchievementBanner(
              rank: 12,
              totalPoints: 1547,
              weeks: 5,
            ),
            MyCoursesSection(),
            AssignmentsSection()
          ],
        ),
      ),
      bottomNavigationBar: ButtonNavigationBar(selectedIndex: 1),
      floatingActionButton: GradientFab(),
    );
  }
}

