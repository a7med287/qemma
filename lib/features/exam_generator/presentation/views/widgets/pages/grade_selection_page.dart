import 'package:flutter/material.dart';
import '../../widgets/page_header.dart';
import '../../widgets/selection_card.dart';

class GradeSelectionPage extends StatelessWidget {
  final String? selectedGrade;
  final Function(String) onGradeSelected;

  const GradeSelectionPage({
    super.key,
    required this.selectedGrade,
    required this.onGradeSelected,
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
            title: 'اختر الصف',
            stepInfo: 'الخطوة 1 من 4',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: const Text(
                'اختر الصف الدراسي',
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
                  SelectionCard(
                    title: 'الصف الأول الثانوي',
                    icon: Icons.school,
                    isSelected: selectedGrade == 'الصف الأول الثانوي',
                    onTap: () => onGradeSelected('الصف الأول الثانوي'),
                  ),
                  SelectionCard(
                    title: 'الصف الثاني الثانوي',
                    icon: Icons.school,
                    isSelected: selectedGrade == 'الصف الثاني الثانوي',
                    onTap: () => onGradeSelected('الصف الثاني الثانوي'),
                  ),
                  SelectionCard(
                    title: 'الصف الثالث الثانوي',
                    icon: Icons.school,
                    isSelected: selectedGrade == 'الصف الثالث الثانوي',
                    onTap: () => onGradeSelected('الصف الثالث الثانوي'),
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