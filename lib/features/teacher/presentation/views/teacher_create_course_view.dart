import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../../../core/helpers/build_snack_bar.dart';

class TeacherCreateCourseView extends StatefulWidget {
  static const routeName = '/teacher/courses/create';
  const TeacherCreateCourseView({super.key});

  @override
  State<TeacherCreateCourseView> createState() => _TeacherCreateCourseViewState();
}

class _TeacherCreateCourseViewState extends State<TeacherCreateCourseView> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _maxStudentsCtrl = TextEditingController();
  final _prereqCtrl = TextEditingController();

  String _selectedLevel = '';
  String _startDate = '';
  String _endDate = '';
  bool _isPublished = false;
  final List<String> _prerequisites = [];
  PlatformFile? _thumbnail;
  bool _loading = false;

  String? _titleError;
  String? _descError;
  String? _levelError;
  String? _priceError;
  String? _durationError;
  String? _startDateError;


  final _levels = [
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
  ];

  String get _teacherSubject {
    final user = context.read<AuthCubit>().currentUser;
    return user?.subject ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _maxStudentsCtrl.dispose();
    _prereqCtrl.dispose();
    super.dispose();
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'title': _titleError = null; break;
        case 'description': _descError = null; break;
        case 'level': _levelError = null; break;
        case 'price': _priceError = null; break;
        case 'duration': _durationError = null; break;
        case 'startDate': _startDateError = null; break;
      }
    });
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _titleError = _titleCtrl.text.trim().isEmpty ? 'عنوان الكورس مطلوب' : null;
      if (_titleError != null) valid = false;
      _descError = _descCtrl.text.trim().isEmpty ? 'وصف الكورس مطلوب' : null;
      if (_descError != null) valid = false;
      _levelError = _selectedLevel.isEmpty ? 'المستوى مطلوب' : null;
      if (_levelError != null) valid = false;

      _priceError = _priceCtrl.text.trim().isEmpty ? 'السعر مطلوب' : null;
      if (_priceError == null) {
        final price = double.tryParse(_priceCtrl.text.trim());
        if (price == null) {
          _priceError = 'السعر يجب أن يكون رقماً';
        } else if (price <= 0) {
          _priceError = 'السعر يجب أن يكون أكبر من صفر';
        }
      }
      if (_priceError != null) valid = false;

      _durationError = _durationCtrl.text.trim().isEmpty ? 'المدة مطلوبة' : null;
      if (_durationError == null) {
        final duration = int.tryParse(_durationCtrl.text.trim());
        if (duration == null) {
          _durationError = 'المدة يجب أن تكون رقماً';
        } else if (duration <= 0) {
          _durationError = 'المدة يجب أن تكون أكبر من صفر';
        }
      }
      if (_durationError != null) valid = false;

      _startDateError = _startDate.isEmpty ? 'تاريخ البداية مطلوب' : null;
      if (_startDateError == null &&
          _endDate.isNotEmpty &&
          _endDate.compareTo(_startDate) < 0) {
        _startDateError = 'تاريخ البداية يجب أن يكون قبل تاريخ النهاية';
      }
      if (_startDateError != null) valid = false;

      // Optional max students: if provided, must be a positive integer.
      if (_maxStudentsCtrl.text.trim().isNotEmpty) {
        final maxStudents = int.tryParse(_maxStudentsCtrl.text.trim());
        if (maxStudents == null || maxStudents <= 0) {
          valid = false;
        }
      }
    });
    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      _showSnackbar('يرجى ملء جميع الحقول المطلوبة', false);
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<TeacherRepository>().createCourse(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        category: _teacherSubject,
        level: _selectedLevel,
        price: double.parse(_priceCtrl.text),
        duration: int.parse(_durationCtrl.text),
        maxStudents: _maxStudentsCtrl.text.isNotEmpty ? int.tryParse(_maxStudentsCtrl.text) : null,
        startDate: _startDate,
        endDate: _endDate.isNotEmpty ? _endDate : null,
        prerequisites: _prerequisites,
        thumbnailFile: _thumbnail,
        isPublished: _isPublished,
      );
      if (!mounted) return;
      _showSnackbar('تم إنشاء الكورس بنجاح! 🎉', true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } on Failure catch (e) {
      _showSnackbar(e.message, false);
    } catch (e) {
      _showSnackbar('حدث خطأ أثناء إنشاء الكورس', false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackbar(String message, bool success) {
    buildSnackBar(context, message, isError: !success);
  }

  Future<void> _pickThumbnail() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        // We fetch the raw bytes instead of relying on a file-system path.
        // On Android, images picked from cloud sources (Google Photos, etc.)
        // return a content:// URI that File() cannot open directly, which
        // crashes the app when rendering with Image.file(). Using bytes with
        // Image.memory() avoids that entirely and works consistently across
        // Android versions and storage providers.
        withData: true,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          _showSnackbar('حجم الصورة يجب أن يكون أقل من 5 ميجابايت', false);
          return;
        }
        if (file.bytes == null) {
          _showSnackbar('تعذر قراءة الصورة، حاول صورة أخرى', false);
          return;
        }
        setState(() => _thumbnail = file);
      }
    } catch (e) {
      _showSnackbar('حدث خطأ أثناء اختيار الصورة', false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        if (isStart) {
          _startDate = formatted;
          _startDateError = null;
        } else {
          _endDate = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final subject = _teacherSubject;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  _buildMainForm(context, subject),
                  SizedBox(height: 16.h),
                  _buildSidebar(context, subject),
                  SizedBox(height: 16.h),
                  _buildSubmitButton(context),
                  SizedBox(height: 8.h),
                  _buildCancelButton(context),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 24.h),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white12),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إنشاء كورس جديد',
                      style: TextStyle(
                        color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                      )),
                  Text('أضف كورساً جديداً لطلابك',
                      style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 13.sp, fontFamily: 'Cairo')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Text(title,
          style: TextStyle(
            fontSize: 18.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
            color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          )),
    );
  }

  Widget _buildCard(Widget child) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      padding: EdgeInsets.all(20.r),
      child: child,
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text('$text${required ? ' *' : ''}',
          style: TextStyle(
            fontSize: 13.sp, fontWeight: FontWeight.w600, fontFamily: 'Cairo',
            color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF374151),
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
  }) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: (v) {
            onChanged?.call(v);
            // Explicit field key instead of inferring from the controller
            // reference, so newly added fields can't silently fail to clear
            // their error.
            if (fieldKey.isNotEmpty) _clearError(fieldKey);
          },
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
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB), width: 1,
              ),
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

  Widget _buildMainForm(BuildContext context, String subject) {
    return Column(
      children: [
        _buildCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('المعلومات الأساسية'),
              SizedBox(height: 4.h),
              _buildLabel('عنوان الكورس', required: true),
              _buildInput(controller: _titleCtrl, fieldKey: 'title', placeholder: 'مثال: دورة الفيزياء الشاملة', error: _titleError),
              SizedBox(height: 16.h),
              _buildLabel('وصف الكورس', required: true),
              _buildInput(controller: _descCtrl, fieldKey: 'description', placeholder: 'اكتب وصفاً تفصيلياً للكورس...', multiline: true, error: _descError),
              SizedBox(height: 16.h),
              _buildLabel('التصنيف (مادتك الدراسية)'),
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
              _buildLabel('المستوى', required: true),
              _buildDropdown(_levels, _selectedLevel, (v) {
                setState(() {
                  _selectedLevel = v;
                  _levelError = null;
                });
              }, _levelError),
              SizedBox(height: 16.h),
              _buildLabel('المتطلبات السابقة (اختياري)'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _prereqCtrl,
                      textDirection: TextDirection.rtl,
                      onSubmitted: (_) => _addPrerequisite(),
                      style: TextStyle(
                        fontSize: 14.sp, fontFamily: 'Cairo',
                        color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'أضف متطلب...',
                        hintTextDirection: TextDirection.rtl,
                        hintStyle: TextStyle(color: context.isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: context.isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
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
                      onTap: _addPrerequisite,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        child: Text('إضافة',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 13.sp)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: List.generate(_prerequisites.length, (i) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: context.isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_prerequisites[i],
                            style: TextStyle(fontSize: 12.sp, fontFamily: 'Cairo',
                                color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                        SizedBox(width: 4.w),
                        GestureDetector(
                          onTap: () => setState(() => _prerequisites.removeAt(i)),
                          child: Icon(Icons.close, size: 16.sp, color: const Color(0xFFF87171)),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        _buildCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('تفاصيل الكورس'),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('السعر (جنيه)', required: true),
                        _buildInput(controller: _priceCtrl, fieldKey: 'price', placeholder: 'مثال: 500', keyboardType: TextInputType.number, error: _priceError),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('المدة (بالأسابيع)', required: true),
                        _buildInput(controller: _durationCtrl, fieldKey: 'duration', placeholder: 'مثال: 8', keyboardType: TextInputType.number, error: _durationError),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('الحد الأقصى للطلاب (اختياري)'),
                        _buildInput(controller: _maxStudentsCtrl, fieldKey: 'maxStudents', placeholder: 'مثال: 30', keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('تاريخ البداية', required: true),
                        _buildDateField(isStart: true, error: _startDateError),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildLabel('تاريخ النهاية (اختياري)'),
              _buildDateField(isStart: false),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        _buildCard(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نشر الكورس',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                            color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                    SizedBox(height: 4.h),
                    Text(_isPublished ? 'الكورس سيكون مرئياً للطلاب فور الإنشاء' : 'الكورس سيُحفظ كمسودة غير منشورة',
                        style: TextStyle(fontSize: 12.sp, fontFamily: 'Cairo',
                            color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
                activeTrackColor: const Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(List<String> items, String selected, ValueChanged<String> onChanged, String? error) {
    final isDark = context.isDark;
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
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildDateField({required bool isStart, String? error}) {
    final isDark = context.isDark;
    final value = isStart ? _startDate : _endDate;
    return InkWell(
      onTap: () => _pickDate(isStart: isStart),
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

  Widget _buildSidebar(BuildContext context, String subject) {
    return Column(
      children: [
        _buildCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('صورة الكورس',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                      color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
              SizedBox(height: 16.h),
              if (_thumbnail != null && _thumbnail!.bytes != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      // Image.memory instead of Image.file: file_picker now
                      // returns raw bytes (withData: true), which avoids the
                      // crash that happened when Android handed back a
                      // content:// URI that File() couldn't open.
                      child: Image.memory(
                        _thumbnail!.bytes!,
                        width: double.infinity,
                        height: 180.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: GestureDetector(
                        onTap: () => setState(() => _thumbnail = null),
                        child: Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: Icon(Icons.close, color: Colors.white, size: 16.sp),
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: _pickThumbnail,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    decoration: BoxDecoration(
                      color: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: context.isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('🖼️', style: TextStyle(fontSize: 40.sp)),
                        SizedBox(height: 8.h),
                        Text('اضغط لرفع صورة',
                            style: TextStyle(fontSize: 13.sp, fontFamily: 'Cairo',
                                color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickThumbnail,
                  icon: const Text('📤', style: TextStyle(fontSize: 16)),
                  label: Text('اختر صورة',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13.sp,
                          color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF374151))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text('الحد الأقصى: 5 ميجابايت — JPG, PNG, WEBP',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo',
                      color: context.isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        _buildCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ملخص الكورس',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                      color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
              SizedBox(height: 16.h),
              _summaryRow('العنوان', _titleCtrl.text.isNotEmpty ? _titleCtrl.text : '—'),
              _summaryRow('التصنيف', subject.isNotEmpty ? subject : '—'),
              _summaryRow('المستوى', _selectedLevel.isNotEmpty ? _selectedLevel : '—'),
              _summaryRow('السعر', _priceCtrl.text.isNotEmpty ? '${_priceCtrl.text} جنيه' : '—'),
              _summaryRow('المدة', _durationCtrl.text.isNotEmpty ? '${_durationCtrl.text} أسابيع' : '—'),
              _summaryRow('تاريخ البداية', _startDate.isNotEmpty ? _startDate : '—'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    final isDark = context.isDark;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:',
              style: TextStyle(fontSize: 12.sp, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }

  void _addPrerequisite() {
    final text = _prereqCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _prerequisites.add(text);
        _prereqCtrl.clear();
      });
    }
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: _loading ? null : _submit,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: _loading
                  ? const LinearGradient(colors: [Color(0xFF475569), Color(0xFF475569)])
                  : const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
              boxShadow: _loading
                  ? null
                  : [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: .4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: _loading
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 8.w),
                  Text('⏳ جاري الإنشاء...',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                ],
              )
                  : Text('✨ إنشاء الكورس',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _loading ? null : () => Navigator.maybePop(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(vertical: 12.h),
        ),
        child: Text('إلغاء',
            style: TextStyle(fontSize: 14.sp, fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
      ),
    );
  }


}