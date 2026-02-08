import 'package:flutter/material.dart';
import 'package:qemma/core/utils/styles.dart';
import 'package:qemma/features/auth/presentation/views/register_view.dart';

import '../../../../../core/utils/app_colors.dart';

class DontHaveAnAccountWidget extends StatelessWidget {
  const DontHaveAnAccountWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "لا تمتلك حساب؟  ",
          style: Styles.textStyleSemiBold16.copyWith(color: Color(0xff616A6B)),
        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegisterView()),
            );
          },
          child: Text(
            "قم بإنشاء حساب",
            style: Styles.textStyleSemiBold16.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
