import 'package:flutter/material.dart';

class HeaderStat extends StatelessWidget {
  final IconData icon;
  final String text;
  const HeaderStat({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white)),
      ],
    );
  }
}
