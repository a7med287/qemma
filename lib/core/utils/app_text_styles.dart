import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized text styles.
///
/// All sizes go through `.sp` (flutter_screenutil) so type scales correctly
/// across phones, tablets and desktop/web without any extra work at the
/// call-site. Colors are intentionally NOT baked in here (besides a sane
/// default) — widgets should grab the correct light/dark color from
/// [AppColors] or `Theme.of(context)` and apply it with `.copyWith(color: ..)`.
abstract class TextStyles {
  static TextStyle _base(double size, FontWeight weight) {
    return GoogleFonts.cairo(
      fontSize: size.sp,
      fontWeight: weight,
      height: 1.4,
    );
  }

  static TextStyle get bold28 => _base(28, FontWeight.bold);
  static TextStyle get bold25 => _base(25, FontWeight.bold);
  static TextStyle get bold23 => _base(23, FontWeight.bold);
  static TextStyle get bold20 => _base(20, FontWeight.bold);
  static TextStyle get bold18 => _base(18, FontWeight.bold);

  static TextStyle get semiBold18 => _base(18, FontWeight.w600);
  static TextStyle get semiBold16 => _base(16, FontWeight.w600);
  static TextStyle get semiBold14 => _base(14, FontWeight.w600);
  static TextStyle get semiBold13 => _base(13, FontWeight.w600);

  static TextStyle get medium15 => _base(15, FontWeight.w500);
  static TextStyle get medium13 => _base(13, FontWeight.w500);

  static TextStyle get regular14 => _base(14, FontWeight.normal);
  static TextStyle get regular13 => _base(13, FontWeight.normal);
}
