import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/repositories/teacher_repository.dart';
import 'dart:typed_data';

class TeacherEditBookView extends StatefulWidget {
  static const routeName = '/teacher/books/edit';

  final Map<String, dynamic> book;

  const TeacherEditBookView({super.key, required this.book});

  @override
  State<TeacherEditBookView> createState() => _TeacherEditBookViewState();
}

class _TeacherEditBookViewState extends State<TeacherEditBookView> {
  bool _submitting = false;
  String? _teacherSubject;
  String? _formError;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _grade;
  late double _price;
  late bool _isFree;
  late bool _isPublished;
  String? _coverBase64;

  // Cached decoded bytes to avoid repeated decode & crashes

  Uint8List? _coverBytes;

  final _grades = ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'];

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _titleCtrl = TextEditingController(text: book['title'] ?? '');
    _descCtrl = TextEditingController(text: book['description'] ?? '');
    _grade = book['grade'] ?? '';
    final p = (book['price'] ?? 0) is int ? (book['price'] as int).toDouble() : (book['price'] ?? 0.0).toDouble();
    _price = p > 0 ? p : 0;
    _isFree = p == 0;
    _isPublished = book['isPublished'] ?? false;
    _coverBase64 = book['coverImage'];

    // Decode existing cover safely
    if (_coverBase64 != null && _coverBase64!.isNotEmpty) {
      _decodeCover(_coverBase64!);
    }

    _loadTeacherSubject();
  }

  void _decodeCover(String base64Str) {
    try {
      final data = base64Str.contains(',') ? base64Str.split(',').last : base64Str;
      _coverBytes = base64Decode(data);
    } catch (_) {
      _coverBytes = null;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherSubject() async {
    try {
      final repo = context.read<TeacherRepository>();
      final res = await repo.getTeacherProfile();
      final teacher = res['teacher'] as Map?;
      final specialties = teacher?['specialties'] as List?;
      if (specialties != null && specialties.isNotEmpty) {
        _teacherSubject = specialties[0].toString();
      } else {
        _teacherSubject = teacher?['expertise'] as String?;
      }
    } catch (_) {}
  }

  String? _validate() {
    if (_titleCtrl.text.trim().isEmpty) return 'عنوان الكتاب مطلوب';
    if (_grade.isEmpty) return 'الصف الدراسي مطلوب';
    if (!_isFree && (_price <= 0)) return 'يجب أن يكون السعر رقماً موجباً';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) { setState(() => _formError = err); return; }
    setState(() => _submitting = true);
    try {
      await context.read<TeacherRepository>().updateBook(widget.book['id'],
        title: _titleCtrl.text, grade: _grade, description: _descCtrl.text,
        price: _isFree ? 0 : _price, isPublished: _isPublished,
        coverBase64: _coverBase64,
      );
      if (!mounted) return;
      buildSnackBar(context, 'تم تحديث الكتاب بنجاح');
      Navigator.pop(context, true);
    } on Failure catch (e) {
      _showToast(e.message, error: true);
      setState(() => _submitting = false);
    } catch (_) {
      _showToast('فشل تحديث الكتاب', error: true);
      setState(() => _submitting = false);
    }
  }

  void _showToast(String msg, {bool error = false}) {
    buildSnackBar(context, msg, isError: error);
  }

  Future<void> _pickCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      if (file.bytes == null) {
        _showToast('تعذر قراءة الصورة، حاول مرة أخرى', error: true);
        return;
      }

      if (file.bytes!.length > 2 * 1024 * 1024) {
        _showToast('حجم الصورة يجب أن يكون أقل من 2MB', error: true);
        return;
      }

      final ext = (file.extension ?? 'png').toLowerCase();
      final base64Str = 'data:image/$ext;base64,${base64Encode(file.bytes!)}';

      setState(() {
        _coverBase64 = base64Str;
        _coverBytes = file.bytes;
      });
    } catch (e) {
      _showToast('حدث خطأ أثناء اختيار الصورة', error: true);
    }
  }

  Widget _buildCoverPreview() {
    if (_coverBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Stack(
          children: [
            Image.memory(
              _coverBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 120.h,
              errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
            ),
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: () => setState(() {
                  _coverBase64 = null;
                  _coverBytes = null;
                }),
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(color: Color(0xB0000000), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
      ),
      child: const Center(child: Icon(Icons.menu_book, size: 48, color: Colors.white38)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isDark),
              SizedBox(height: 20.h),
              _buildForm(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white),
        ),
        SizedBox(width: 8.w),
        Container(
          width: 44.w, height: 44.w,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)]),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: const Icon(Icons.edit, color: Colors.white, size: 22),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تعديل الكتاب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 18.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
            Text(widget.book['title'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2563EB).withValues(alpha: .1) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: isDark ? const Color(0xFF2563EB).withValues(alpha: .3) : const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.school, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المادة الدراسية (من حسابك)', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF))),
                  Text(_teacherSubject ?? 'غير محدد', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1D4ED8))),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        DropdownButtonFormField<String>(
          initialValue: _grade.isNotEmpty ? _grade : null,
          decoration: _inputDec('الصف الدراسي *', isDark),
          items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp)))).toList(),
          onChanged: (v) { if (v != null) setState(() => _grade = v); },
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
        ),
        SizedBox(height: 14.h),

        TextField(
          controller: _titleCtrl, textDirection: TextDirection.rtl,
          decoration: _inputDec('عنوان الكتاب *', isDark),
          style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
        ),
        SizedBox(height: 14.h),

        TextField(
          controller: _descCtrl, textDirection: TextDirection.rtl, maxLines: 3,
          decoration: _inputDec('الوصف (اختياري)', isDark),
          style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
        ),
        SizedBox(height: 14.h),

        Text('تسعير الكتاب *', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(child: _toggleBtn('مجاني', _isFree, const Color(0xFF16A34A), isDark)),
            SizedBox(width: 8.w),
            Expanded(child: _toggleBtn('مدفوع', !_isFree, const Color(0xFFB45309), isDark)),
          ],
        ),
        SizedBox(height: 10.h),

        if (!_isFree)
          TextField(
            textDirection: TextDirection.ltr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDec('السعر *', isDark, suffix: 'ج.م'),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
            onChanged: (v) {
              if (v.isEmpty) { _price = 0; return; }
              final p = double.tryParse(v);
              if (p != null) _price = p;
            },
          )
        else
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16A34A).withValues(alpha: .1) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: isDark ? const Color(0xFF16A34A).withValues(alpha: .3) : const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, size: 16, color: Color(0xFF16A34A)),
                SizedBox(width: 6.w),
                Text('سيكون الكتاب مجاناً للطلاب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11.sp, color: const Color(0xFF16A34A))),
              ],
            ),
          ),
        SizedBox(height: 14.h),

        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF6366F1).withValues(alpha: .08) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isPublished ? '📢 منشور ومرئي للطلاب' : '📝 مسودة (غير منشور)',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                    Text(_isPublished ? 'الكتاب سيظهر للطلاب فور الحفظ' : 'لن يظهر للطلاب حتى تقوم بنشره',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isPublished = !_isPublished),
                child: Container(
                  width: 44, height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _isPublished ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: _isPublished ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.all(2.r),
                      width: 20, height: 20,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        OutlinedButton.icon(
          onPressed: _pickCover,
          icon: const Icon(Icons.cloud_upload, size: 18),
          label: Text(_coverBase64 != null ? 'تغيير صورة الغلاف' : 'رفع صورة الغلاف (اختياري)',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11.sp)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            padding: EdgeInsets.symmetric(vertical: 10.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
        Text('الحد الأقصى للحجم: 2MB — JPG, PNG, WEBP',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3A8))),

        if (_coverBytes != null) ...[
          SizedBox(height: 8.h),
          _buildCoverPreview(),
        ],

        if (_formError != null) ...[
          SizedBox(height: 10.h),
          Text(_formError!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
        ],

        SizedBox(height: 20.h),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.r)),
            gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)]),
          ),
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: _submitting
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 8.w),
              const Text('جاري الحفظ...', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
            ])
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.save, size: 18, color: Colors.white),
              SizedBox(width: 8.w),
              const Text('حفظ التعديلات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
            ]),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDec(String label, bool isDark, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      suffixText: suffix,
      suffixStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
    );
  }

  Widget _toggleBtn(String label, bool selected, Color color, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFree = label == 'مجاني';
          if (_isFree) _price = 0;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? color.withValues(alpha: .15) : color.withValues(alpha: .08))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(label == 'مجاني' ? Icons.card_giftcard : Icons.attach_money, size: 16, color: selected ? color : (isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
            SizedBox(width: 4.w),
            Text(label, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp, color: selected ? color : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))),
          ],
        ),
      ),
    );
  }
}