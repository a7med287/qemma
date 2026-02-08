import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_images.dart';
import '../../../../../core/utils/styles.dart';

AppBar buildChatAppBar() {
  return AppBar(
    shape: Border(bottom: BorderSide(color: Colors.grey)),
    title: Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Image.asset(Assets.robotIcon, height: 36),
        title: Text(
          "مساعد قمة الذكي",
          style: Styles.textStyleBold20.copyWith(color: AppColors.primaryColor),
        ),
      ),
    ),
  );
}
