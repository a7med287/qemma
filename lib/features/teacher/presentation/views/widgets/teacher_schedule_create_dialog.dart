import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_text_styles.dart';

class TeacherScheduleCreateDialog extends StatelessWidget {
  const TeacherScheduleCreateDialog({
    super.key,
    required this.formKey,
    required this.titleCtrl,
    required this.meetingLinkCtrl,
    required this.maxStudentsCtrl,
    required this.descCtrl,
    required this.selectedCourse,
    required this.selectedType,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.courses,
    required this.submitting,
    required this.editingId,
    required this.onCourseChanged,
    required this.onTypeChanged,
    required this.onDatePicked,
    required this.onStartTimePicked,
    required this.onEndTimePicked,
    required this.onSubmit,
    required this.onCancel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController meetingLinkCtrl;
  final TextEditingController maxStudentsCtrl;
  final TextEditingController descCtrl;
  final String selectedCourse;
  final String selectedType;
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<Map<String, dynamic>> courses;
  final bool submitting;
  final String? editingId;
  final ValueChanged<String> onCourseChanged;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onDatePicked;
  final VoidCallback onStartTimePicked;
  final VoidCallback onEndTimePicked;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  String _timeStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final fieldBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final fieldText = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
    final fieldLabel = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Dialog(
      insetPadding: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(editingId != null ? 'تعديل حصة' : 'إضافة حصة جديدة',
                      style: TextStyles.semiBold16.copyWith(color: fieldText)),
                  SizedBox(height: 4.h),
                  Text('قم بجدولة حصة جديدة لطلابك',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        color: fieldLabel,
                      )),
                  SizedBox(height: 16.h),

                  _buildTextField(
                    controller: titleCtrl,
                    label: 'عنوان الحصة *',
                    hint: 'مثال: مراجعة الوحدة الأولى',
                    icon: Icons.class_,
                    iconColor: const Color(0xFF2563EB),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                    isDark: isDark,
                    fieldText: fieldText,
                    fieldLabel: fieldLabel,
                    fieldBorder: fieldBorder,
                  ),
                  SizedBox(height: 12.h),

                  _buildCourseDropdown(isDark, fieldBorder, fieldLabel, fieldText, cardBg),
                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      Expanded(child: _buildDateField(isDark, fieldBorder, fieldLabel, fieldText)),
                      SizedBox(width: 12.w),
                      Expanded(child: _buildTypeDropdown(isDark, fieldBorder, fieldLabel, fieldText, cardBg)),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      Expanded(child: _buildTimeField('وقت البداية *', startTime, onStartTimePicked, isDark, fieldBorder, fieldLabel, fieldText)),
                      SizedBox(width: 12.w),
                      Expanded(child: _buildTimeField('وقت النهاية *', endTime, onEndTimePicked, isDark, fieldBorder, fieldLabel, fieldText)),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  if (selectedType == 'online') ...[
                    _buildTextField(
                      controller: meetingLinkCtrl,
                      label: 'رابط الحصة (Zoom, Google Meet...)',
                      hint: 'https://zoom.us/j/...',
                      icon: Icons.link,
                      iconColor: const Color(0xFF8B5CF6),
                      isDark: isDark,
                      fieldText: fieldText,
                      fieldLabel: fieldLabel,
                      fieldBorder: fieldBorder,
                    ),
                    SizedBox(height: 12.h),
                  ],

                  _buildTextField(
                    controller: maxStudentsCtrl,
                    label: 'الحد الأقصى للطلاب (اختياري)',
                    hint: 'مثال: 30',
                    icon: Icons.people,
                    iconColor: const Color(0xFF10B981),
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    fieldText: fieldText,
                    fieldLabel: fieldLabel,
                    fieldBorder: fieldBorder,
                  ),
                  SizedBox(height: 12.h),

                  _buildDescriptionField(isDark, fieldBorder, fieldLabel, fieldText),
                  SizedBox(height: 16.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onCancel,
                        child: Text(
                          editingId != null ? 'إلغاء التعديل' : 'إلغاء',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            color: fieldLabel,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8.r),
                            onTap: submitting ? null : onSubmit,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.w, vertical: 12.h),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (submitting)
                                    SizedBox(
                                      width: 16.w,
                                      height: 16.w,
                                      child: const CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  else
                                    const Icon(Icons.save,
                                        color: Colors.white, size: 18),
                                  SizedBox(width: 8.w),
                                  Text(
                                    submitting
                                        ? 'جارٍ الحفظ...'
                                        : editingId != null
                                            ? 'حفظ التعديلات'
                                            : 'حفظ الحصة',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required bool isDark,
    required Color fieldText,
    required Color fieldLabel,
    required Color fieldBorder,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(
          fontFamily: 'Cairo', fontSize: 14.sp, color: fieldText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: fieldLabel,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12.sp,
          color: fieldLabel.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(icon, size: 20, color: iconColor),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: fieldBorder),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }

  Widget _buildCourseDropdown(bool isDark, Color fieldBorder, Color fieldLabel, Color fieldText, Color cardBg) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fieldBorder),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCourse.isNotEmpty ? selectedCourse : null,
          isExpanded: true,
          hint: Row(
            children: [
              const Icon(Icons.people, size: 20, color: Color(0xFF7C3AED)),
              SizedBox(width: 8.w),
              Text('اختر الكورس',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    color: fieldLabel.withValues(alpha: 0.5),
                  )),
            ],
          ),
          dropdownColor: cardBg,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.sp,
            color: fieldText,
          ),
          items: [
            DropdownMenuItem(
                value: '',
                child: Text('بدون كورس محدد',
                    style: TextStyle(color: fieldLabel))),
            ...courses.map((c) {
              final id = (c['id'] ?? c['_id'] ?? '') as String;
              final title = (c['title'] ?? '') as String;
              return DropdownMenuItem(value: id, child: Text(title));
            }),
          ],
          onChanged: (v) => onCourseChanged(v ?? ''),
        ),
      ),
    );
  }

  Widget _buildDateField(bool isDark, Color fieldBorder, Color fieldLabel, Color fieldText) {
    return InkWell(
      onTap: onDatePicked,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: fieldBorder),
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Color(0xFFDB2777)),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('التاريخ *',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.sp,
                      color: fieldLabel,
                    )),
                Text(_dateStr(selectedDate),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: fieldText,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown(bool isDark, Color fieldBorder, Color fieldLabel, Color fieldText, Color cardBg) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fieldBorder),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          isExpanded: true,
          dropdownColor: cardBg,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.sp,
            color: fieldText,
          ),
          items: const [
            DropdownMenuItem(value: 'online', child: Text('حصة أونلاين')),
            DropdownMenuItem(value: 'offline', child: Text('حصة حضورية')),
          ],
          onChanged: (v) => onTypeChanged(v ?? 'online'),
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay time, VoidCallback onTap,
      bool isDark, Color fieldBorder, Color fieldLabel, Color fieldText) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: fieldBorder),
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 20, color: Color(0xFFF59E0B)),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.sp,
                      color: fieldLabel,
                    )),
                Text(_timeStr(time),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: fieldText,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(bool isDark, Color fieldBorder, Color fieldLabel, Color fieldText) {
    return TextFormField(
      controller: descCtrl,
      maxLines: 4,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: fieldText),
      decoration: InputDecoration(
        labelText: 'وصف الحصة (اختياري)',
        hintText: 'أضف تفاصيل إضافية عن الحصة...',
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: fieldLabel,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12.sp,
          color: fieldLabel.withValues(alpha: 0.5),
        ),
        alignLabelWithHint: true,
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: fieldBorder),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }
}
