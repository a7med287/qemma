import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

InputDecoration teacherInputDecoration(String label,
    {String? hint, bool required = false, required bool isDark}) {
  final borderColor =
      isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  final labelColor =
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  return InputDecoration(
    labelText: required ? '$label *' : label,
    hintText: hint,
    hintStyle: TextStyle(
      fontFamily: 'Cairo',
      color: labelColor.withValues(alpha: 0.5),
      fontSize: 13.sp,
    ),
    labelStyle: TextStyle(
      fontFamily: 'Cairo',
      color: labelColor,
      fontSize: 14.sp,
    ),
    filled: true,
    fillColor:
    isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
    ),
    contentPadding:
    EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
  );
}
