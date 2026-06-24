import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';

class TeacherCreateCourseBasicInfo extends StatelessWidget {
  const TeacherCreateCourseBasicInfo({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.prereqCtrl,
    required this.titleError,
    required this.descError,
    required this.selectedLevel,
    required this.levelError,
    required this.levels,
    required this.prerequisites,
    required this.thumbnail,
    required this.subject,
    required this.onLevelChanged,
    required this.onAddPrerequisite,
    required this.onRemovePrerequisite,
    required this.onPickThumbnail,
    required this.onRemoveThumbnail,
    required this.onFieldChanged,
  });

  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController prereqCtrl;
  final String? titleError;
  final String? descError;
  final String selectedLevel;
  final String? levelError;
  final List<String> levels;
  final List<String> prerequisites;
  final PlatformFile? thumbnail;
  final String subject;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onAddPrerequisite;
  final ValueChanged<int> onRemovePrerequisite;
  final VoidCallback onPickThumbnail;
  final VoidCallback onRemoveThumbnail;
  final void Function(String) onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      children: [
        _buildCard(context, isDark, [
          _sectionTitle('المعلومات الأساسية', isDark),
          SizedBox(height: 4.h),
          _buildLabel('عنوان الكورس', required: true, isDark: isDark),
          _buildInput(
            controller: titleCtrl,
            fieldKey: 'title',
            placeholder: 'مثال: دورة الفيزياء الشاملة',
            error: titleError,
            onChanged: (v) => onFieldChanged('title'),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildLabel('وصف الكورس', required: true, isDark: isDark),
          _buildInput(
            controller: descCtrl,
            fieldKey: 'description',
            placeholder: 'اكتب وصفاً تفصيلياً للكورس...',
            multiline: true,
            error: descError,
            onChanged: (v) => onFieldChanged('description'),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildLabel('التصنيف (مادتك الدراسية)', isDark: isDark),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📚', style: TextStyle(fontSize: 16.sp)),
                SizedBox(width: 8.w),
                Text(subject.isNotEmpty ? subject : 'لم يتم تحديد المادة',
                    style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
              ],
            ),
          ),
          if (subject.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text('⚠️ لم يتم تحديد مادتك الدراسية في ملفك الشخصي',
                  style: TextStyle(color: const Color(0xFFEF4444), fontSize: 12.sp, fontFamily: 'Cairo')),
            ),
          SizedBox(height: 16.h),
          _buildLabel('المستوى', required: true, isDark: isDark),
          _buildDropdown(levels, selectedLevel, onLevelChanged, levelError, isDark),
          SizedBox(height: 16.h),
          _buildLabel('المتطلبات السابقة (اختياري)', isDark: isDark),
          _buildPrerequisiteInput(isDark),
          SizedBox(height: 12.h),
          _buildPrerequisiteChips(isDark),
        ]),
        SizedBox(height: 16.h),
        _buildCard(context, isDark, [
          _sectionTitle('صورة الكورس', isDark),
          SizedBox(height: 16.h),
          _buildThumbnailSection(isDark),
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

  Widget _buildDropdown(List<String> items, String selected, ValueChanged<String> onChanged, String? error, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: error != null ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
          width: error != null ? 2 : 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected.isNotEmpty ? selected : null,
          hint: Text('اختر المستوى',
              style: TextStyle(fontSize: 14.sp, fontFamily: 'Cairo', color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(fontSize: 14.sp, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }

  Widget _buildPrerequisiteInput(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: prereqCtrl,
            textDirection: TextDirection.rtl,
            onSubmitted: (_) => onAddPrerequisite(),
            style: TextStyle(
              fontSize: 14.sp, fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: 'أضف متطلب...',
              hintTextDirection: TextDirection.rtl,
              hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Material(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(8.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: onAddPrerequisite,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Text('إضافة',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 13.sp)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrerequisiteChips(bool isDark) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: List.generate(prerequisites.length, (i) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(prerequisites[i],
                  style: TextStyle(fontSize: 12.sp, fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
              SizedBox(width: 4.w),
              GestureDetector(
                onTap: () => onRemovePrerequisite(i),
                child: Icon(Icons.close, size: 16.sp, color: const Color(0xFFF87171)),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildThumbnailSection(bool isDark) {
    if (thumbnail != null && thumbnail!.bytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.memory(
              thumbnail!.bytes!,
              width: double.infinity,
              height: 180.h,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8.h,
            right: 8.w,
            child: GestureDetector(
              onTap: onRemoveThumbnail,
              child: Container(
                width: 28.w,
                height: 28.w,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: Icon(Icons.close, color: Colors.white, size: 16.sp),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        GestureDetector(
          onTap: onPickThumbnail,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 32.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text('🖼️', style: TextStyle(fontSize: 40.sp)),
                SizedBox(height: 8.h),
                Text('اضغط لرفع صورة',
                    style: TextStyle(fontSize: 13.sp, fontFamily: 'Cairo',
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPickThumbnail,
            icon: const Text('📤', style: TextStyle(fontSize: 16)),
            label: Text('اختر صورة',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13.sp,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF374151))),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text('الحد الأقصى: 5 ميجابايت — JPG, PNG, WEBP',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo',
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
      ],
    );
  }
}
