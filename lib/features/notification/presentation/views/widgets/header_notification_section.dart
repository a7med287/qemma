import 'package:flutter/material.dart';
import 'package:qemma/core/widgets/back_icon_widget.dart';

import '../../../../../core/utils/app_colors.dart';

class HeaderNotificationSection extends StatelessWidget {
  const HeaderNotificationSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            AppColors.accentColor,
            AppColors.secondaryColor,
            AppColors.primaryColor,
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0,top: 24),
        child: Row(
          children: [
            BackIconWidget(),
            SizedBox(width: 15),

            Icon(Icons.notifications, color: Colors.yellow, size: 24),
            SizedBox(width: 8),
            Icon(Icons.bolt, color: Colors.yellow, size: 24),
            SizedBox(width: 8),
            const Text(
              'تنبيهات عاجلة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

        ),
      ),
    );
  }
}
