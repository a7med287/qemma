import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'teacher_theme_helpers.dart';

String _pad(int n) => n.toString().padLeft(2, '0');

class LiveClassSetupForm extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String selectedCourse;
  final int maxCapacity;
  final String scheduledTime;
  final List<Map<String, dynamic>> courses;
  final bool loadingCourses;
  final bool loading;
  final VoidCallback onCreateRoom;
  final ValueChanged<String> onCourseChanged;
  final ValueChanged<int> onCapacityChanged;
  final ValueChanged<String> onDateTimeChanged;
  final bool isDark;

  const LiveClassSetupForm({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.selectedCourse,
    required this.maxCapacity,
    required this.scheduledTime,
    required this.courses,
    required this.loadingCourses,
    required this.loading,
    required this.onCreateRoom,
    required this.onCourseChanged,
    required this.onCapacityChanged,
    required this.onDateTimeChanged,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('أنشئ حصة أونلاين مباشرة لطلابك',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13.sp,
              color: fieldLabelColor(context),
            )),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardBgColor(context),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: fieldBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleField(context),
              SizedBox(height: 12.h),
              _buildCourseDropdown(context),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: [
                  SizedBox(
                    width: 0.4.sw,
                    child: _buildDateTimeField(context),
                  ),
                  SizedBox(
                    width: 0.4.sw,
                    child: _buildCapacityField(context),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildDescriptionField(context),
              SizedBox(height: 16.h),
              _buildCreateButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return TextField(
      controller: titleCtrl,
      style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14.sp,
          color: fieldTextColor(context)),
      decoration: InputDecoration(
        labelText: 'عنوان الحصة *',
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: fieldLabelColor(context),
        ),
        hintText: 'مثال: مراجعة الوحدة الأولى',
        prefixIcon:
            const Icon(Icons.video_call, color: Color(0xFF7C3AED)),
        filled: true,
        fillColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: fieldBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: fieldBorderColor(context)),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    return TextField(
      controller: descCtrl,
      maxLines: 3,
      style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14.sp,
          color: fieldTextColor(context)),
      decoration: InputDecoration(
        labelText: 'الوصف (اختياري)',
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: fieldLabelColor(context),
        ),
        hintText: 'أضف تفاصيل عن الحصة...',
        filled: true,
        fillColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: fieldBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: fieldBorderColor(context)),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }

  Widget _buildCourseDropdown(BuildContext context) {
    if (loadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fieldBorderColor(context)),
        color: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCourse.isNotEmpty ? selectedCourse : null,
          isExpanded: true,
          hint: Row(
            children: [
              const Icon(Icons.school,
                  size: 20, color: Color(0xFF7C3AED)),
              SizedBox(width: 8.w),
              Text('اختر الكورس',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    color: fieldLabelColor(context),
                  )),
            ],
          ),
          dropdownColor: cardBgColor(context),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.sp,
            color: fieldTextColor(context),
          ),
          items: [
            DropdownMenuItem(
                value: '',
                child: Text('بدون كورس محدد',
                    style: TextStyle(color: fieldLabelColor(context)))),
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

  Widget _buildDateTimeField(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate:
              DateTime.tryParse(scheduledTime) ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time == null) return;
        final formatted =
            '${date.year}-${_pad(date.month)}-${_pad(date.day)}T${_pad(time.hour)}:${_pad(time.minute)}';
        onDateTimeChanged(formatted);
      },
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: fieldBorderColor(context)),
          color: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF9FAFB),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الوقت المحدد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10.sp,
                  color: fieldLabelColor(context),
                )),
            Text(scheduledTime.replaceAll('T', ' '),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: fieldTextColor(context),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityField(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fieldBorderColor(context)),
        color: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF9FAFB),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, size: 20, color: Color(0xFF10B981)),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعة القصوى',
                border: InputBorder.none,
              ),
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  color: fieldTextColor(context)),
              onChanged: (v) =>
                  onCapacityChanged(int.tryParse(v) ?? 100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: loading ? null : onCreateRoom,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('إنشاء الحصة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
