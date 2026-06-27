import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';

class TeacherCreateCourseSyllabus extends StatelessWidget {
  const TeacherCreateCourseSyllabus({
    super.key,
    required this.priceCtrl,
    required this.durationCtrl,
    required this.maxStudentsCtrl,
    required this.priceError,
    required this.durationError,
    required this.startDate,
    required this.endDate,
    required this.startDateError,
    required this.isPublished,
    required this.onStartDatePicked,
    required this.onEndDatePicked,
    required this.onPublishedChanged,
    required this.onFieldChanged,
  });

  final TextEditingController priceCtrl;
  final TextEditingController durationCtrl;
  final TextEditingController maxStudentsCtrl;
  final String? priceError;
  final String? durationError;
  final String startDate;
  final String endDate;
  final String? startDateError;
  final bool isPublished;
  final VoidCallback onStartDatePicked;
  final VoidCallback onEndDatePicked;
  final ValueChanged<bool> onPublishedChanged;
  final void Function(String) onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      children: [
        _buildCard(context, isDark, [
          _sectionTitle('تفاصيل الكورس', isDark),
          _buildLabel('السعر (جنيه)', required: true, isDark: isDark),
          _buildInput(
            controller: priceCtrl,
            fieldKey: 'price',
            placeholder: 'مثال: 500',
            keyboardType: TextInputType.number,
            error: priceError,
            onChanged: (v) => onFieldChanged('price'),
            isDark: isDark,
          ),
          // 20% platform fee alert
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: priceCtrl,
            builder: (_, val, __) {
              final p = double.tryParse(val.text);
              if (p == null || p <= 0) return const SizedBox.shrink();
              final net = (p * 0.8).toStringAsFixed(2);
              return Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2563EB).withValues(alpha: .1) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFF2563EB)),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF)),
                      children: [
                        TextSpan(text: 'تنبيه: ', style: TextStyle(fontWeight: FontWeight.w900)),
                        TextSpan(text: 'المنصة تأخذ 20% من كل اشتراك. ستحصل على '),
                        TextSpan(text: '$net جنيه', style: TextStyle(fontWeight: FontWeight.w900)),
                        TextSpan(text: ' لكل طالب.'),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16.h),
          _buildLabel('المدة (بالأسابيع)', required: true, isDark: isDark),
          _buildInput(
            controller: durationCtrl,
            fieldKey: 'duration',
            placeholder: 'مثال: 8',
            keyboardType: TextInputType.number,
            error: durationError,
            onChanged: (v) => onFieldChanged('duration'),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildLabel('الحد الأقصى للطلاب (اختياري)', isDark: isDark),
          _buildInput(
            controller: maxStudentsCtrl,
            fieldKey: 'maxStudents',
            placeholder: 'مثال: 30',
            keyboardType: TextInputType.number,
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildLabel('تاريخ البداية', required: true, isDark: isDark),
          _buildDateField(startDate, startDateError, onStartDatePicked, isDark),
          SizedBox(height: 16.h),
          _buildLabel('تاريخ النهاية (اختياري)', isDark: isDark),
          _buildDateField(endDate, null, onEndDatePicked, isDark),
        ]),
        SizedBox(height: 16.h),
        _buildCard(context, isDark, [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نشر الكورس',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                    SizedBox(height: 4.h),
                    Text(isPublished ? 'الكورس سيكون مرئياً للطلاب فور الإنشاء' : 'الكورس سيُحفظ كمسودة غير منشورة',
                        style: TextStyle(fontSize: 12.sp, fontFamily: 'Cairo',
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isPublished,
                onChanged: onPublishedChanged,
                activeTrackColor: const Color(0xFF2563EB),
              ),
            ],
          ),
        ]),
      ],
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Text(title,
          style: TextStyle(
            fontSize: 18.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          )),
    );
  }

  Widget _buildLabel(String text, {bool required = false, required bool isDark}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text('$text${required ? ' *' : ''}',
          style: TextStyle(
            fontSize: 13.sp, fontWeight: FontWeight.w600, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF374151),
          )),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String fieldKey,
    String? placeholder,
    String? error,
    bool multiline = false,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: (v) => onChanged?.call(v),
          maxLines: multiline ? 4 : 1,
          keyboardType: keyboardType,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 14.sp, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintTextDirection: TextDirection.rtl,
            hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: error != null ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
                width: error != null ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(error,
                style: TextStyle(color: const Color(0xFFEF4444), fontSize: 12.sp, fontFamily: 'Cairo')),
          ),
      ],
    );
  }

  Widget _buildDateField(String value, String? error, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: error != null ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
            width: error != null ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value.isNotEmpty ? value : 'اختر تاريخ',
                style: TextStyle(
                  fontSize: 14.sp, fontFamily: 'Cairo',
                  color: value.isNotEmpty
                      ? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
                )),
            Icon(Icons.calendar_today, size: 18.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
