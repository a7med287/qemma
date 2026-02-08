import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qemma/core/utils/app_images.dart';
import 'package:qemma/core/utils/styles.dart';

class CustomSocialButton extends StatelessWidget {
  const CustomSocialButton({super.key, this.onPressed});

  final void Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            SvgPicture.asset(Assets.googleIcon),
            Spacer(),
            Text(
              "تسجيل بواسطة جوجل",
              style: Styles.textStyleSemiBold16.copyWith(
                color: Color(0xff0C0D0D),
              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
