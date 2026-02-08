import 'package:flutter/material.dart';
import 'package:qemma/core/utils/styles.dart';

class FiltersBooksSection extends StatelessWidget {
  const FiltersBooksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'ابحث عن كتاب أو مدرس...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomDropdown(
                  items: [
                    'علمى رياضه',
                    'علمى علوم',
                    'ادبي',
                  ],
                  hint: "اختر الشعبه",
                  onSelected: (value) {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomDropdown(
                  items: [
                    'اللغة العربية',
                    'الفيزياء',
                    'الكيمياء',
                    'الرياضيات',
                  ],
                  hint: "اختر الماده",
                  onSelected: (value) {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomDropdown extends StatelessWidget {
  final List<String> items;
  final String hint;
  final Function(String?) onSelected;
  final TextEditingController? controller;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.hint,
    required this.onSelected,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownMenu<String>(
            controller: controller,
            width: constraints.maxWidth,
            menuHeight: 300,
            hintText: hint,

            inputDecorationTheme: InputDecorationTheme(
              hintStyle: Styles.textStyleRegular14,
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),

            menuStyle: MenuStyle(
              backgroundColor: WidgetStateProperty.all(Colors.white),
              elevation: WidgetStateProperty.all(15),
              shadowColor: WidgetStateProperty.all(
                Colors.black.withValues(alpha: 0.2),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
              ),

              maximumSize: WidgetStateProperty.all(const Size.fromHeight(400)),
            ),
            dropdownMenuEntries: items.map((String item) {
              return DropdownMenuEntry<String>(
                value: item,
                label: item,

                style: MenuItemButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  foregroundColor: Colors.black87,
                ),
              );
            }).toList(),
            onSelected: onSelected,
          ),
        );
      },
    );
  }
}
