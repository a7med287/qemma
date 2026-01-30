import 'package:flutter/material.dart';
import 'package:qemma/core/widgets/custom_button.dart';
import 'package:qemma/core/widgets/custom_text_form_field.dart';
import 'package:qemma/core/widgets/gradient_text.dart';
import 'package:qemma/features/auth/presentation/views/widgets/already_have_an_account.dart';
import 'package:qemma/features/auth/presentation/views/widgets/custom_social_button.dart';
import 'package:qemma/features/auth/presentation/views/widgets/or_divider.dart';
import 'package:qemma/features/auth/presentation/views/widgets/role_selector.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  String selectedRole = 'parent';

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
                      GradientText(text: "قِمَّة", textSize: 40,),
                      SizedBox(height: 16,),
                      Row(
                        children: [
                          RoleSelector(
                            title: 'ولي أمر',
                            icon: Icons.people,
                            isSelected: selectedRole == 'parent',
                            onTap: () =>
                                setState(() => selectedRole = 'parent'),
                          ),
                          const SizedBox(width: 12),
                          RoleSelector(
                            title: 'مدرس',
                            icon: Icons.person,
                            isSelected: selectedRole == 'teacher',
                            onTap: () =>
                                setState(() => selectedRole = 'teacher'),
                          ),
                          const SizedBox(width: 12),
                          RoleSelector(
                            title: 'طالب',
                            icon: Icons.school,
                            isSelected: selectedRole == 'student',
                            onTap: () =>
                                setState(() => selectedRole = 'student'),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 32 : 24),

                      const CustomTextFormField(
                        textInputType: TextInputType.name,
                        labelText: 'الاسم الكامل',
                        iconData: Icons.person,
                      ),
                      const SizedBox(height: 14),

                      const CustomTextFormField(
                        textInputType: TextInputType.emailAddress,
                        labelText: 'البريد الإلكتروني',
                        iconData: Icons.email,
                      ),
                      const SizedBox(height: 14),

                      const CustomTextFormField(
                        textInputType: TextInputType.name,
                        labelText: 'رقم الهاتف',
                        iconData: Icons.phone,
                      ),
                      const SizedBox(height: 14),

                      const CustomTextFormField(
                        textInputType: TextInputType.name,
                        labelText: 'كلمة المرور',
                        iconData: Icons.lock,
                      ),
                      const SizedBox(height: 14),

                      const CustomTextFormField(
                        textInputType: TextInputType.name,
                        labelText: 'تأكيد كلمة المرور',
                        iconData: Icons.lock_outline_rounded,
                      ),

                      SizedBox(height: isTablet ? 36 : 24),

                      CustomButton(text: 'إنشاء حساب', onTap: () {}),
                      const SizedBox(height: 24),
                      AlreadyHaveAnAccount(),
                      const SizedBox(height: 24),
                      OrDivider() ,
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
