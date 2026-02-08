import 'package:flutter/material.dart';
import 'package:qemma/core/widgets/custom_button.dart';
import 'package:qemma/core/widgets/custom_text_form_field.dart';
import 'package:qemma/core/widgets/gradient_text.dart';
import 'package:qemma/features/auth/presentation/views/widgets/custom_social_button.dart';
import 'package:qemma/features/auth/presentation/views/widgets/dont_have_an_account.dart';
import 'package:qemma/features/auth/presentation/views/widgets/or_divider.dart';
import 'package:qemma/features/home/presentation/views/home_view.dart';

import '../../../dashboard/presentation/views/dashboard_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Container(
                width: isTablet ? 620 : double.infinity,
                padding: EdgeInsets.all(isTablet ? 32 : 20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GradientText(text: "قِمَّة", textSize: 40),

                      SizedBox(height: isTablet ? 32 : 24),

                      const CustomTextFormField(
                        textInputType: TextInputType.emailAddress,
                        labelText: 'البريد الإلكتروني',
                        iconData: Icons.email,
                      ),
                      const SizedBox(height: 14),

                      const CustomTextFormField(
                        textInputType: TextInputType.name,
                        labelText: 'كلمة المرور',
                        iconData: Icons.lock,
                      ),

                      SizedBox(height: isTablet ? 36 : 24),

                      CustomButton(
                        text: 'تسجيل الدخول',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      DontHaveAnAccountWidget(),
                      const SizedBox(height: 24),
                      OrDivider(),
                      const SizedBox(height: 16),
                      CustomSocialButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
