import 'package:flutter/material.dart';
import 'package:qemma/features/my_courses/presentation/views/my_courses_screen.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/styles.dart';
import '../../../../../core/widgets/custom_elevation_button.dart';
import 'my_courses_list.dart';

class MyCoursesSection extends StatelessWidget {
  const MyCoursesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(" كورساتي ", style: Styles.textStyleBold20),
                CustomElevationButton(
                  text: "عرض الكل",
                  color: AppColors.primaryColor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyCoursesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            MyCoursesHorizontalList(),
          ],
        ),
      ),
    );
  }
}
