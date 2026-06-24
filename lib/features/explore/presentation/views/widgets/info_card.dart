import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final List<Widget> children;
  final double titleFontSize;
  final FontWeight titleFontWeight;

  const InfoCard({super.key,
    required this.isDark,
    required this.title,
    required this.children,
    this.titleFontSize = 18,
    this.titleFontWeight = FontWeight.w900,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: titleFontSize, fontWeight: titleFontWeight, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
