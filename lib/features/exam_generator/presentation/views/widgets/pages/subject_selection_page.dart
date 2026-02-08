import 'package:flutter/material.dart';
import '../../widgets/page_header.dart';
import '../../widgets/selection_card.dart';

class SubjectSelectionPage extends StatelessWidget {
  final String? selectedSubject;
  final Function(String) onSubjectSelected;

  const SubjectSelectionPage({
    Key? key,
    required this.selectedSubject,
    required this.onSubjectSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subjects = [
      {'title': 'الرياضيات', 'icon': Icons.calculate},
      {'title': 'الفيزياء', 'icon': Icons.science},
      {'title': 'الكيمياء', 'icon': Icons.science},
      {'title': 'الأحياء', 'icon': Icons.biotech},
      {'title': 'اللغة العربية', 'icon': Icons.menu_book},
      {'title': 'اللغة الإنجليزية', 'icon': Icons.translate},
      {'title': 'التاريخ', 'icon': Icons.history_edu},
      {'title': 'الجغرافيا', 'icon': Icons.public},
    ];

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
          const PageHeader(title: 'اختر المادة', stepInfo: 'الخطوة 2 من 4'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: const Text(
                'اختر المادة',
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
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];

                  return SelectionCard(
                    title: subject['title'] as String,
                    icon: subject['icon'] as IconData,
                    isSelected: selectedSubject == subject['title'],
                    onTap: () =>
                        onSubjectSelected(subject['title'] as String),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
