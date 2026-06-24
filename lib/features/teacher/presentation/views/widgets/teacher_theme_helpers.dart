import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
export '../../../../../core/helpers/build_context_extensions.dart';

Color fieldBorderColor(BuildContext context) =>
    context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

Color fieldTextColor(BuildContext context) =>
    context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);

Color fieldLabelColor(BuildContext context) =>
    context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

Color cardBgColor(BuildContext context) =>
    context.isDark ? const Color(0xFF1E293B) : Colors.white;

Color bgColor(BuildContext context) =>
    context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);

InputDecoration inpDecoration(BuildContext context, String label, {bool required = false}) {
  final isDark = context.isDark;
  return InputDecoration(
    labelText: required ? '$label *' : label,
    labelStyle: TextStyle(
        fontFamily: 'Cairo', fontSize: 14.sp, color: fieldLabelColor(context)),
    filled: true,
    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: fieldBorderColor(context))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: fieldBorderColor(context))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide:
        const BorderSide(color: Color(0xFF8B5CF6), width: 2)),
    contentPadding:
    EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
  );
}
