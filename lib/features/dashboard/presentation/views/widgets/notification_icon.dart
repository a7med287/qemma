import 'package:flutter/material.dart';

import '../../../../notification/presentation/views/notification_view.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotificationView()),
          );
        },
        child: CircleAvatar(
          backgroundColor: Colors.white10,
          child: Badge(
            smallSize: 10,
            backgroundColor: Colors.redAccent,
            label: Text("3"),
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Icon(
                Icons.notifications,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
