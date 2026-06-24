import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth_styles.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../data/models/auth_models.dart';

Widget roleCard({
  required UserRole role,
  required UserRole selectedRole,
  required String label,
  required IconData icon,
  required ValueChanged<UserRole> onChanged,
  required BuildContext context,
}) {
  final selected = selectedRole == role;
  final color = roleColor(role);
  return GestureDetector(
    onTap: () => onChanged(role),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: .12) : AuthColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? color : AuthColors.border(context),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 8.w),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
            fontWeight: FontWeight.w700, color: selected ? color : AuthColors.textSecondary(context))),
      ]),
    ),
  );
}

Color roleColor(UserRole role) => switch (role) {
  UserRole.student          => AuthColors.studentColor,
  UserRole.teacher          => AuthColors.teacherColor,
  UserRole.assistantTeacher => AuthColors.assistantColor,
  UserRole.parent           => AuthColors.parentColor,
};

Widget emailField({
  required TextEditingController controller,
  required String? errorText,
  required ValueChanged<String> onChanged,
  required BuildContext context,
}) {
  final prefix = controller.text.trim();
  return TextField(
    controller: controller,
    textDirection: TextDirection.ltr,
    keyboardType: TextInputType.emailAddress,
    onChanged: (v) {
      final cleaned = v.replaceAll(RegExp(r'@.*'), '');
      if (cleaned != v) {
        controller.value = controller.value.copyWith(text: cleaned);
      }
      onChanged(cleaned);
    },
    style: TextStyle(color: AuthColors.textPrimary(context), fontFamily: 'Cairo', fontSize: 15),
    decoration: InputDecoration(
      labelText: 'البريد الإلكتروني',
      hintText: 'اسمك',
      errorText: errorText,
      helperText: prefix.isNotEmpty
          ? 'سيكون بريدك: $prefix@qemma.com'
          : 'يجب أن ينتهي بـ @qemma.com',
      labelStyle: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo'),
      hintStyle: TextStyle(color: AuthColors.textHint(context), fontFamily: 'Cairo'),
      helperStyle: TextStyle(color: AuthColors.textHint(context), fontFamily: 'Cairo', fontSize: 11),
      errorStyle: const TextStyle(color: AuthColors.error, fontFamily: 'Cairo', fontSize: 11),
      prefixIcon: Icon(Icons.alternate_email_rounded, color: AuthColors.textSecondary(context)),
      suffixIcon: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AuthColors.surfaceLight(context),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('@qemma.com',
            style: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo',
                fontSize: 12, fontWeight: FontWeight.w700)),
      ),
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
    ),
  );
}

Widget dropdownField<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  String? error,
  required BuildContext context,
}) {
  return DropdownButtonFormField<T>(
    initialValue: value,
    items: items,
    onChanged: onChanged,
    dropdownColor: AuthColors.surface(context),
    style: TextStyle(color: AuthColors.textPrimary(context), fontFamily: 'Cairo', fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      errorText: error,
      labelStyle: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo'),
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
    ),
  );
}

Widget personCard({
  required String name,
  required String username,
  required String label,
  required Color color,
  required IconData icon,
  required BuildContext context,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: .5), width: 1.5),
    ),
    child: Row(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      SizedBox(width: 12.w),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: TextStyle(fontFamily: 'Cairo', fontSize: 15,
            fontWeight: FontWeight.w700, color: AuthColors.textPrimary(context))),
        Text('@$username', style: TextStyle(fontFamily: 'Cairo', fontSize: 12,
            color: AuthColors.textSecondary(context))),
        SizedBox(height: 4.h),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
              fontWeight: FontWeight.w700, color: color)),
        ),
      ])),
      Icon(Icons.check_circle_rounded, color: AuthColors.success, size: 24),
    ]),
  );
}

Widget miniButton({
  required String label,
  required VoidCallback onPressed,
  required bool loading,
  required Color color,
  required BuildContext context,
}) {
  return SizedBox(
    height: 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: loading
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(label, style: const TextStyle(fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget infoBox(String text, {required BuildContext context}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AuthColors.gradientStart.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AuthColors.gradientStart.withValues(alpha: .25)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline_rounded, color: AuthColors.gradientStart, size: 16),
      SizedBox(width: 8.w),
      Expanded(
        child: Text(text, style: const TextStyle(color: AuthColors.gradientStart,
            fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}

class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final quarters = [
      (-0.5, const Color(0xFFEA4335)),
      (0.5,  const Color(0xFF4285F4)),
      (1.5,  const Color(0xFFFBBC05)),
      (2.5,  const Color(0xFF34A853)),
    ];
    for (final (start, color) in quarters) {
      paint.color = color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: r),
          start * 3.14159, 3.14159, true, paint);
    }
    paint.color = Colors.white;
    canvas.drawCircle(center, r * 0.5, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

Widget googleIcon() {
  return SizedBox(
    width: 20,
    height: 20,
    child: CustomPaint(painter: GoogleIconPainter()),
  );
}

const subjects = [
  'اللغة العربية', 'اللغة الإنجليزية', 'الفيزياء', 'الكيمياء',
  'الأحياء', 'الرياضيات', 'الجغرافيا', 'التاريخ', 'الإحصاء',
];
