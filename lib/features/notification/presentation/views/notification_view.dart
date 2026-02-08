import 'package:flutter/material.dart';
import 'package:qemma/core/utils/app_colors.dart';
import 'package:qemma/features/notification/presentation/views/widgets/build_notification_item.dart';
import 'package:qemma/features/notification/presentation/views/widgets/header_notification_section.dart';

import '../../data/models/alert_notification_model.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  final List<AlertNotificationModel> notifications = [
    AlertNotificationModel(
      title: 'انتبه! لا يُنسى امتحان الرياضيات!',
      subtitle: 'يبدأ بعد 45 دقيقة!',
      buttonText: 'قم الآن',
      icon: Icons.warning_rounded,
      color: const Color(0xFFf44336),
      gradientColors: const [Color(0xFFffebee), Color(0xFFffcdd2)],
    ),
    AlertNotificationModel(
      title: 'واجب الفيزياء',
      subtitle: 'متأخر بيومين!',
      buttonText: 'سجل الآن',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFFff9800),
      gradientColors: const [Color(0xFFfff8e1), Color(0xFFffe082)],
    ),
    AlertNotificationModel(
      title: 'حصة الكيمياء المبتشرة',
      subtitle: 'تبدأ الآن - 45 طالب منضم',
      buttonText: 'انضم',
      icon: Icons.videocam_rounded,
      color: const Color(0xFF9c27b0),
      gradientColors: const [Color(0xFFf3e5f5), Color(0xFFe1bee7)],
    ),
    AlertNotificationModel(
      title: 'تحديث مهم',
      subtitle: 'إصدار جديد متاح',
      buttonText: 'تحديث',
      icon: Icons.system_update_rounded,
      color: const Color(0xFF4CAF50),
      gradientColors: const [Color(0xFFe8f5e9), Color(0xFFc8e6c9)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderNotificationSection(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: BuildNotificationItem(
                    notification: notifications[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
