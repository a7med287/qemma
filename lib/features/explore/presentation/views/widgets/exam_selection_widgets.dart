import 'package:flutter/material.dart';
import '../../../explore_colors.dart';

class SelectionList extends StatelessWidget {
  final bool isDark;
  final List<String> items;
  final String? selectedItem;
  final IconData icon;
  final ValueChanged<String> onSelect;

  const SelectionList({super.key, required this.isDark, required this.items, this.selectedItem, required this.icon, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر الصف الدراسي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
        const SizedBox(height: 16),
        ...items.map((item) {
          final isSelected = selectedItem == item;
          return GestureDetector(
            onTap: () => onSelect(item),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? (isDark ? const Color(0x1ADB2777) : const Color(0x1AFDF2F8)) : (isDark ? const Color(0xFF0F172A) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? ExploreColors.accent : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: ExploreColors.pinkGradient), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(item, style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class SelectionGrid extends StatelessWidget {
  final bool isDark;
  final List<String> items;
  final String? selectedItem;
  final IconData icon;
  final ValueChanged<String> onSelect;

  const SelectionGrid({super.key, required this.isDark, required this.items, this.selectedItem, required this.icon, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر المادة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
        const SizedBox(height: 16),
        ...items.map((item) {
          final isSelected = selectedItem == item;
          return GestureDetector(
            onTap: () => onSelect(item),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? (isDark ? const Color(0x1ADB2777) : const Color(0x1AFDF2F8)) : (isDark ? const Color(0xFF0F172A) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? ExploreColors.accent : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: ExploreColors.pinkGradient), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(item, style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const SummaryItem({super.key, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
      ],
    );
  }
}

class ExamInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const ExamInfoRow({super.key, required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
      ],
    );
  }
}
