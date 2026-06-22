// lib/features/auth/views/login_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qemma/features/auth/presentation/views/widgets/auth_styles.dart';
import '../../../../core/widgets/app_background.dart';
import '../cubits/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  static const routeName = '/login';

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _showPassword = false;
  bool _loading = false;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    String? emailErr;
    String? passErr;

    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      emailErr = 'البريد الإلكتروني مطلوب';
    } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      emailErr = 'البريد الإلكتروني غير صالح';
    }

    if (_passwordCtrl.text.isEmpty) {
      passErr = 'كلمة المرور مطلوبة';
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });

    return emailErr == null && passErr == null;
  }

  Future<void> _handleLogin() async {
    if (!_validate()) return;

    setState(() => _loading = true);

    try {
      final user = await context.read<AuthCubit>().login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        user.dashboardRoute,
      );
    } catch (e) {
      // Error handled by BlocListener/AuthCubit
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _navigateToRegister() {
    Navigator.pushReplacementNamed(
      context,
      '/register',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 20.h,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                MediaQuery.of(context).size.height - 40.h,
              ),
              child: IntrinsicHeight(
                child: _buildLocalForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Align(
        //   alignment: AlignmentDirectional.topStart,
        //   child: TextButton.icon(
        //     onPressed: () =>
        //         Navigator.pushReplacementNamed(context, '/'),
        //     icon: Icon(
        //       Icons.arrow_back_rounded,
        //       color: AuthColors.textSecondary(context),
        //       size: 18,
        //     ),
        //     label: Text(
        //       'العودة للرئيسية',
        //       style: TextStyle(
        //         color: AuthColors.textSecondary(context),
        //         fontFamily: 'Cairo',
        //       ),
        //     ),
        //   ),
        // ),
        SizedBox(height: 120.h),

        const BrandTitle(),

        SizedBox(height: 12.h),

        Text(
          'تسجيل الدخول',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AuthColors.textPrimary(context),
          ),
        ),

        SizedBox(height: 6.h),

        Text(
          'أدخل بياناتك للدخول إلى حسابك',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AuthColors.textSecondary(context),
          ),
        ),

        SizedBox(height: 32.h),

        AuthTextField(
          label: 'البريد الإلكتروني',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          prefixIcon: Icon(
            Icons.email_outlined,
            color: AuthColors.textSecondary(context),
          ),
        ),

        SizedBox(height: 16.h),

        AuthTextField(
          label: 'كلمة المرور',
          controller: _passwordCtrl,
          obscureText: !_showPassword,
          errorText: _passwordError,
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: AuthColors.textSecondary(context),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
            icon: Icon(
              _showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AuthColors.textSecondary(context),
            ),
          ),
        ),

        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/forgot-password'),
            child: const Text(
              'نسيت كلمة المرور؟',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AuthColors.gradientStart,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        SizedBox(height: 8.h),

        GradientButton(
          text: 'تسجيل الدخول',
          onPressed: _handleLogin,
          isLoading: _loading,
        ),

        SizedBox(height: 24.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ليس لديك حساب؟  ',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AuthColors.textSecondary(context),
                fontSize: 13,
              ),
            ),
            GestureDetector(
              onTap: _navigateToRegister,
              child: const Text(
                'سجل الآن',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AuthColors.gradientStart,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}