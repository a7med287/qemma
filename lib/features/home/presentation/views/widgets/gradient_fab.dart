import 'package:flutter/material.dart';
import 'package:qemma/features/ai_qemma_chat/presentation/views/chat_view.dart';

import '../../../../../core/utils/app_colors.dart';

class GradientFab extends StatelessWidget {
  const GradientFab({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AiQemmaChatView()),
        );
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor],
          ),
        ),
        child: Icon(Icons.smart_toy_outlined, size: 28, color: Colors.white),
      ),
    );
  }
}
