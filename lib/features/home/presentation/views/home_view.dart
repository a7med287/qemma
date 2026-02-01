import 'package:flutter/material.dart';
import 'package:qemma/features/home/presentation/views/widgets/custom_drawer.dart';
import 'package:qemma/features/home/presentation/views/widgets/home_header.dart';
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

          ],
        ),
      ),
    );
  }
}
