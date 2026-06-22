// lib/features/auth/widgets/auth_styles.dart
// Shared design tokens for all auth screens — now Light & Dark aware,
// matching the rest of the app (see core/helpers/build_context_extensions.dart
// and core/utils/app_colors.dart). Brand/gradient/semantic colors stay
// constant across themes by design; surfaces & text colors follow the
// current ThemeMode (driven by ThemeCubit).

import 'package:flutter/material.dart';

import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_colors.dart';

abstract class AuthColors {
  // ── Brand colors — identical in Light & Dark ────────────────────────
  static const gradientStart = Color(0xFF3959EB);
  static const gradientMid   = Color(0xFF8438E3);
  static const gradientEnd   = Color(0xFFCB2A8B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientMid, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Focus ring — always brand purple, regardless of theme.
  static const borderFocus = Color(0xFF7C3AED);

  // Semantic state colors — same in both themes (sufficient contrast on
  // both light & dark surfaces since they're only ever used at full
  // saturation on icons/text, or at low alpha for tinted backgrounds).
  static const success = Color(0xFF059669);
  static const error   = Color(0xFFEF4444);
  static const info    = Color(0xFF2563EB);

  // Role accent colors — same in both themes.
  static const studentColor   = Color(0xFF2563EB);
  static const teacherColor   = Color(0xFF7C3AED);
  static const assistantColor = Color(0xFF059669);
  static const parentColor    = Color(0xFFDB2777);

  // ── Theme-aware tokens — call with the current BuildContext ─────────
  // (mirror context.textPrimary / textSecondary / cardColor / borderColor,
  // exactly like the onboarding screens use them.)

  static Color textPrimary(BuildContext context) => context.textPrimary;

  static Color textSecondary(BuildContext context) => context.textSecondary;

  /// A touch more muted than [textSecondary] — for hints/placeholders.
  static Color textHint(BuildContext context) =>
      context.textSecondary.withValues(alpha: .65);

  /// Card / input-field background.
  static Color surface(BuildContext context) => context.cardColor;

  /// Slightly distinct from [surface] — used for small nested chips
  /// (e.g. the "@qemma.com" suffix badge inside the email field).
  static Color surfaceLight(BuildContext context) => Color.alphaBlend(
    context.textPrimary.withValues(alpha: .06),
    context.cardColor,
  );

  static Color border(BuildContext context) => context.borderColor;

  static Color background(BuildContext context) =>
      context.isDark ? AppColors.darkBackground : AppColors.lightBackground;
}

// Gradient brand title "قِمّة" — always rendered with the brand gradient,
// so it looks identical in Light & Dark.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => AuthColors.primaryGradient.createShader(bounds),
      child: const Text(
        'قِمّة',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Shared gradient button — white text on the brand gradient, unaffected by
// theme (the background itself supplies the contrast).
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.gradient  = AuthColors.primaryGradient,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AuthColors.gradientMid.withValues(alpha: .35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Outlined secondary button — now theme-aware (surface/border/text follow
// Light & Dark).
class OutlinedAuthButton extends StatelessWidget {
  const OutlinedAuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  final String text;
  final VoidCallback onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AuthColors.border(context), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AuthColors.surface(context),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 10)],
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AuthColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Theme-aware text field — surface/border/text/hint all follow Light & Dark;
// focus ring and error colors stay brand-constant.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText  = false,
    this.errorText,
    this.hint,
    this.helperText,
    this.onChanged,
    this.textDirection,
    this.maxLength,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final String? hint;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final TextDirection? textDirection;
  final int? maxLength;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textDirection: textDirection,
      maxLength: maxLength,
      enabled: enabled,
      onChanged: onChanged,
      style: TextStyle(
        color: AuthColors.textPrimary(context),
        fontFamily: 'Cairo',
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        counterText: '',
        labelStyle: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo'),
        hintStyle: TextStyle(color: AuthColors.textHint(context), fontFamily: 'Cairo'),
        helperStyle: TextStyle(color: AuthColors.textHint(context), fontFamily: 'Cairo', fontSize: 11),
        errorStyle: const TextStyle(color: AuthColors.error, fontFamily: 'Cairo', fontSize: 11),
        filled: true,
        fillColor: AuthColors.surface(context),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AuthColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthColors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AuthColors.border(context).withValues(alpha: .5)),
        ),
      ),
    );
  }
}

// Info / error alert banner — colors are theme-invariant semantic accents,
// so no changes needed beyond keeping context available.
class AuthAlert extends StatelessWidget {
  const AuthAlert({
    super.key,
    required this.message,
    this.type = AlertType.info,
  });

  final String message;
  final AlertType type;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (type) {
      AlertType.info    => (AuthColors.info,    Icons.info_outline_rounded),
      AlertType.success => (AuthColors.success, Icons.check_circle_outline_rounded),
      AlertType.error   => (AuthColors.error,   Icons.error_outline_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum AlertType { info, success, error }