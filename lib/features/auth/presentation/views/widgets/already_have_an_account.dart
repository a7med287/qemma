import 'package:flutter/material.dart';
import 'package:qemma/core/utils/styles.dart';

import '../../../../../core/utils/app_colors.dart';

class AlreadyHaveAnAccount extends StatelessWidget {
  const AlreadyHaveAnAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "تمتلك حساب بالفعل؟ ",
          style: Styles.textStyleSemiBold16.copyWith(color: Color(0xff616A6B)),
        ),
        InkWell(
          onTap: () {

          },
          child: Text(
            " تسجيل دخول",
            style: Styles.textStyleSemiBold16.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
