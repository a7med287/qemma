import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_images.dart';
import '../../../../../core/utils/styles.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({super.key, required this.onSend});
  final void Function(String) onSend;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        cursorColor: AppColors.primaryColor,
        decoration: InputDecoration(
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 8),
                child: InkWell(
                  onTap: () {
                    if (controller.text.trim().isEmpty) return;
                    widget.onSend(controller.text.trim());
                    controller.clear();
                  },
                  child: Image.asset(Assets.sendIcon),
                ),
              ),
              InkWell(onTap: () {}, child: Image.asset(Assets.microphoneIcon)),

            ],
          ),
          contentPadding: EdgeInsetsGeometry.all(16),
          hintText: "اكتب سؤالك ",
          hintStyle: Styles.textStyleBold13.copyWith(color: Color(0xffA1A1A1)),
          fillColor: Colors.white,
          filled: true,
          border: buildOutlineInputBorder(borderColor: Colors.white),
          enabledBorder: buildOutlineInputBorder(borderColor: Colors.white),
          focusedBorder: buildOutlineInputBorder(
            borderColor: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}

OutlineInputBorder buildOutlineInputBorder({required Color borderColor}) {
  return OutlineInputBorder(
    borderSide: BorderSide(color: borderColor),
    borderRadius: BorderRadius.circular(30),
  );
}
