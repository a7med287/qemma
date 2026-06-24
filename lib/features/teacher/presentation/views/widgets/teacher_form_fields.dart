import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import 'teacher_theme_helpers.dart';
import 'teacher_input_decoration.dart';

class TeacherTextField extends StatelessWidget {
  const TeacherTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.required = false,
    this.enabled = true,
    this.isDark,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final bool required;
  final bool enabled;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? context.isDark;
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14.sp,
        color: enabled
            ? fieldTextColor(context)
            : fieldTextColor(context).withValues(alpha: 0.5),
      ),
      decoration: teacherInputDecoration(label, hint: hint, required: required, isDark: dark),
      textInputAction:
      maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
    );
  }
}

class TeacherNumberField extends StatefulWidget {
  const TeacherNumberField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.isDark,
  });

  final int value;
  final String label;
  final ValueChanged<int> onChanged;
  final bool? isDark;

  @override
  State<TeacherNumberField> createState() => _TeacherNumberFieldState();
}

class _TeacherNumberFieldState extends State<TeacherNumberField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(TeacherNumberField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark ?? context.isDark;
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14.sp,
        color: fieldTextColor(context),
      ),
      decoration: teacherInputDecoration(widget.label, isDark: dark),
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null) widget.onChanged(parsed);
      },
    );
  }
}

class TeacherDateTimeField extends StatelessWidget {
  const TeacherDateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.controller,
    required this.onChanged,
    this.isDark,
  });

  final String label;
  final String value;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? context.isDark;
    return TextField(
      controller: controller,
      decoration: teacherInputDecoration(label, isDark: dark),
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14.sp,
        color: fieldTextColor(context),
      ),
      readOnly: true,
      onTap: () async {
        if (!context.mounted) return;
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate:
          DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (!context.mounted || date == null) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (!context.mounted || time == null) return;
        final dt = DateTime(date.year, date.month, date.day,
            time.hour, time.minute);
        final formatted = dt.toIso8601String().substring(0, 16);
        controller.text = formatted;
        onChanged(formatted);
      },
    );
  }
}

class TeacherSwitchRow extends StatelessWidget {
  const TeacherSwitchRow({
    super.key,
    required this.value,
    required this.label,
    this.subtitle,
    required this.onChanged,
    this.activeColor = const Color(0xFF2563EB),
    this.isDark,
  });

  final bool value;
  final String label;
  final String? subtitle;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? context.isDark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                      color: dark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1F2937),
                    )),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
                        color: fieldLabelColor(context),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherDropdown extends StatelessWidget {
  const TeacherDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isDark,
  });

  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String> onChanged;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? context.isDark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fieldBorderColor(context)),
        color:
        dark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor:
          dark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: fieldTextColor(context),
          ),
          items: items,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class TeacherCard extends StatelessWidget {
  const TeacherCard({
    super.key,
    required this.children,
    this.isDark,
  });

  final List<Widget> children;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? context.isDark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

Widget teacherChip(String label, Color color, bool isDark) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Text(label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
          color: color,
        )),
  );
}
