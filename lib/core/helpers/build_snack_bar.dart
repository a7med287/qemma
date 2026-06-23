import 'package:flutter/material.dart';
import '../../core/utils/app_colors.dart';

void buildSnackBar(BuildContext context, String message,
    {bool isError = false, bool showCloseButton = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: isError ? Colors.redAccent : AppColors.primaryColor,
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
      action: showCloseButton
          ? SnackBarAction(
              label: 'إغلاق',
              textColor: Colors.white,
              onPressed: () {
                messenger.hideCurrentSnackBar();
              },
            )
          : null,
    ),
  );
}
