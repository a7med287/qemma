import 'package:flutter/material.dart';
import '../../widgets/page_header.dart';
import '../../widgets/selection_card.dart';

class ChapterSelectionPage extends StatelessWidget {
  final String? selectedChapter;
  final Function(String) onChapterSelected;

  const ChapterSelectionPage({
    super.key,
    required this.selectedChapter,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final chapters = [
      {'title': 'الميكانيكا', 'icon': Icons.settings},
      {'title': 'الكهربية', 'icon': Icons.electrical_services},
      {'title': 'المغناطيسية', 'icon': Icons.hub},
      {'title': 'الضوء', 'icon': Icons.lightbulb},
      {'title': 'الصوت', 'icon': Icons.volume_up},
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
          const PageHeader(title: 'اختر الفصل', stepInfo: 'الخطوة 3 من 4'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: const Text(
                'اختر الفصل',
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
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  return SelectionCard(
                    title: chapter['title'] as String,
                    icon: chapter['icon'] as IconData,
                    isSelected: selectedChapter == chapter['title'],
                    onTap: () =>
                        onChapterSelected(chapter['title'] as String),
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
