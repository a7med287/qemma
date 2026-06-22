import 'package:flutter/material.dart';
import '../helpers/build_context_extensions.dart';
import '../utils/app_text_styles.dart';

class CustomTextButton extends StatelessWidget {
  const CustomTextButton({super.key, required this.onPressed, required this.text});

  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyles.regular13.copyWith(color: context.textSecondary),
      ),
    );
  }
}
