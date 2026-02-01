import 'package:flutter/cupertino.dart';

class AlertNotificationModel {
  final String title;
  final String subtitle;
  final String buttonText;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  AlertNotificationModel({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.icon,
    required this.color,
    required this.gradientColors,
  });
}