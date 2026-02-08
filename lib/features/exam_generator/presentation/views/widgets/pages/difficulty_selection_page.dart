import 'package:flutter/material.dart';
import '../../widgets/page_header.dart';
import '../../widgets/difficulty_card.dart';

class DifficultySelectionPage extends StatelessWidget {
  final String? selectedDifficulty;
  final Function(String) onDifficultySelected;

  const DifficultySelectionPage({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const PageHeader(
            title: 'اختر الصعوبة',
            stepInfo: 'الخطوة 4 من 4',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: const Text(
                'اختر مستوى الصعوبية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  DifficultyCard(
                    title: 'سهل',
                    description: 'مناسب للمبتدئين والمراجعة السريعة',
                    emoji: '😊',
                    color: const Color(0xFF4CAF50),
                    isSelected: selectedDifficulty == 'سهل',
                    onTap: () => onDifficultySelected('سهل'),
                  ),
                  DifficultyCard(
                    title: 'متوسط',
                    description: 'مستوى الامتحانات المدرسية',
                    emoji: '🤔',
                    color: const Color(0xFFFF9800),
                    isSelected: selectedDifficulty == 'متوسط',
                    onTap: () => onDifficultySelected('متوسط'),
                  ),
                  DifficultyCard(
                    title: 'صعب',
                    description: 'مستوى الامتحانات النهائية المتقدمة',
                    emoji: '😰',
                    color: const Color(0xFFF44336),
                    isSelected: selectedDifficulty == 'صعب',
                    onTap: () => onDifficultySelected('صعب'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
