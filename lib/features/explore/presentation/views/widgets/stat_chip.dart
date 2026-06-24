import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;
  const StatChip({super.key, required this.icon, this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? Colors.white),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, fontFamily: 'Cairo', color: Colors.white)),
      ],
    );
  }
}
