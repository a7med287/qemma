import 'package:flutter/material.dart';

import '../../../../../core/widgets/custom_elevation_button.dart';
import '../../../data/models/alert_notification_model.dart';

class BuildNotificationItem extends StatelessWidget {
  const BuildNotificationItem({super.key, required this.notification});

  final AlertNotificationModel notification;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: notification.gradientColors,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: notification.color,
              shape: BoxShape.circle,
            ),
            child: Icon(notification.icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 5),
                Text(
                  notification.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          CustomElevationButton(
            onPressed:() {

            } ,
            text: notification.buttonText,
            color: notification.color,
          ),
        ],
      ),
    );
  }
}
