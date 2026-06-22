import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';

class TeacherEditCourseView extends StatefulWidget {
  static const routeName = '/teacher/courses/edit';
  final TeacherCourse course;
  const TeacherEditCourseView({super.key, required this.course});

  @override
  State<TeacherEditCourseView> createState() => _TeacherEditCourseViewState();
}

class _TeacherEditCourseViewState extends State<TeacherEditCourseView> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;

  late String _category;
  late String _level;
  late bool _published;
  PlatformFile? _thumbnail;
  String? _previewUrl;
  bool _loading = false;

  final _categories = ['رياضيات', 'علوم', 'فيزياء', 'كيمياء', 'أحياء',
    'لغة عربية', 'لغة إنجليزية', 'لغة فرنسية', 'تاريخ', 'جغرافيا'];
  final _levels = ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي',
    'الصف الأول الإعدادي', 'الصف الثاني الإعدادي', 'الصف الثالث الإعدادي',
    'مبتدئ', 'متوسط', 'متقدم'];

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _titleCtrl = TextEditingController(text: c.title);
    _descCtrl = TextEditingController(text: c.description ?? '');
    _priceCtrl = TextEditingController(text: c.price.toString());
    _durationCtrl = TextEditingController(text: c.duration?.toString() ?? '');
    _category = c.category ?? '';
    _level = c.level ?? '';
    _published = c.isPublished;
    _previewUrl = c.thumbnail;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showToast('عنوان الكورس مطلوب', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<TeacherRepository>().updateCourse(
        widget.course.id,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        category: _category,
        level: _level,
        price: int.tryParse(_priceCtrl.text) ?? 0,
        duration: int.tryParse(_durationCtrl.text),
        isPublished: _published,
        thumbnailFile: _thumbnail,
        removeThumbnail: _previewUrl == null && _thumbnail == null,
      );
      if (!mounted) return;
      _showToast('تم تحديث الكورس بنجاح ✅');
      Navigator.pop(context, true);
    } on Failure catch (e) {
      setState(() => _loading = false);
      _showToast(e.message, error: true);
    } catch (_) {
      setState(() => _loading = false);
      _showToast('فشل تحديث الكورس', error: true);
    }
  }

  void _showToast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('تعديل الكورس', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildField(label: 'عنوان الكورس', controller: _titleCtrl, required: true),
            SizedBox(height: 16.h),
            _buildField(label: 'وصف الكورس', controller: _descCtrl, multiline: true),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _buildDropdown(label: 'التصنيف', value: _category, items: _categories, onChanged: (v) => setState(() => _category = v))),
                SizedBox(width: 12.w),
                Expanded(child: _buildDropdown(label: 'المستوى', value: _level, items: _levels, onChanged: (v) => setState(() => _level = v))),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _buildField(label: 'السعر (جنيه)', controller: _priceCtrl, keyboardType: TextInputType.number)),
                SizedBox(width: 12.w),
                Expanded(child: _buildField(label: 'المدة (بالأسابيع)', controller: _durationCtrl, keyboardType: TextInputType.number)),
              ],
            ),
            SizedBox(height: 16.h),
            _buildImagePicker(),
            SizedBox(height: 16.h),
            _buildPublishToggle(),
            SizedBox(height: 32.h),
            SizedBox(
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 20),
                label: Text(_loading ? 'جاري الحفظ...' : 'حفظ التعديلات',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, bool multiline = false, bool required = false, TextInputType? keyboardType}) {
    final isDark = context.isDark;
    return TextField(
      controller: controller,
      maxLines: multiline ? 3 : 1,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      ),
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required ValueChanged<String> onChanged}) {
    final isDark = context.isDark;
    final selectedValue = value.isNotEmpty && items.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      value: selectedValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      ),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
      items: items.toSet().map((item) => DropdownMenuItem<String>(
        value: item,
        child: Text(item, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp)),
      )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }

  Widget _buildImagePicker() {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('صورة الكورس',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13.sp,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 2),
            borderRadius: BorderRadius.circular(8.r),
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          ),
          child: Column(
            children: [
              if (_previewUrl != null)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: _thumbnail != null
                          ? Image.file(File(_thumbnail!.path!), height: 120.h, width: double.infinity, fit: BoxFit.cover)
                          : Image.network(_previewUrl!, height: 120.h, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                    Positioned(
                      top: -4, right: -4,
                      child: GestureDetector(
                        onTap: () => setState(() { _previewUrl = null; _thumbnail = null; }),
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: Icon(Icons.close, color: Colors.white, size: 14.sp),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Icon(Icons.image, size: 40.sp, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
              SizedBox(height: 8.h),
              TextButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    if (file.size > 5 * 1024 * 1024) {
                      _showToast('الحجم الأقصى 5 ميجابايت', error: true);
                      return;
                    }
                    setState(() { _thumbnail = file; _previewUrl = file.path; });
                  }
                },
                icon: const Icon(Icons.image, size: 16),
                label: Text(_previewUrl != null ? 'تغيير الصورة' : 'اختر صورة',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPublishToggle() {
    final isDark = context.isDark;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(_published ? Icons.check_circle : Icons.warning,
              color: _published ? const Color(0xFF059669) : const Color(0xFFF59E0B), size: 20),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_published ? 'الكورس منشور ومرئي للطلاب' : 'الكورس غير منشور (مسودة)',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                Text(_published ? 'يمكن للطلاب رؤيته والتسجيل فيه' : 'لن يظهر للطلاب حتى تقوم بنشره',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Switch.adaptive(
            value: _published,
            onChanged: (v) => setState(() => _published = v),
            activeTrackColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }
}
