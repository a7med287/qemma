import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/repositories/teacher_repository.dart';
import 'widgets/teacher_create_course_basic_info.dart';
import 'widgets/teacher_create_course_media.dart';
import 'widgets/teacher_create_course_syllabus.dart';

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

  final _levels = ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'];

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
        if (price == null || price <= 0) _priceError = 'السعر يجب أن يكون رقماً موجباً';
      }
      if (_priceError != null) valid = false;
      _durationError = _durationCtrl.text.trim().isEmpty ? 'المدة مطلوبة' : null;
      if (_durationError == null) {
        final duration = int.tryParse(_durationCtrl.text.trim());
        if (duration == null || duration <= 0) _durationError = 'المدة يجب أن تكون رقماً موجباً';
      }
      if (_durationError != null) valid = false;
      _startDateError = _startDate.isEmpty ? 'تاريخ البداية مطلوب' : null;
      if (_startDateError == null && _endDate.isNotEmpty && _endDate.compareTo(_startDate) < 0) {
        _startDateError = 'تاريخ البداية يجب أن يكون قبل تاريخ النهاية';
      }
      if (_startDateError != null) valid = false;
      if (_maxStudentsCtrl.text.trim().isNotEmpty) {
        final ms = int.tryParse(_maxStudentsCtrl.text.trim());
        if (ms == null || ms <= 0) valid = false;
      }
    });
    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      buildSnackBar(context, 'يرجى ملء جميع الحقول المطلوبة', isError: true);
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
      buildSnackBar(context, 'تم إنشاء الكورس بنجاح! 🎉');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } on Failure catch (e) {
      buildSnackBar(context, e.message, isError: true);
    } catch (_) {
      buildSnackBar(context, 'حدث خطأ أثناء إنشاء الكورس', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true, allowMultiple: false);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          buildSnackBar(context, 'حجم الصورة يجب أن يكون أقل من 5 ميجابايت', isError: true);
          return;
        }
        if (file.bytes == null) {
          buildSnackBar(context, 'تعذر قراءة الصورة، حاول صورة أخرى', isError: true);
          return;
        }
        setState(() => _thumbnail = file);
      }
    } catch (_) {
      buildSnackBar(context, 'حدث خطأ أثناء اختيار الصورة', isError: true);
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
        final f = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        if (isStart) { _startDate = f; _startDateError = null; }
        else { _endDate = f; }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final subject = _teacherSubject;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
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
                            style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                        Text('أضف كورساً جديداً لطلابك',
                            style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 13.sp, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  TeacherCreateCourseBasicInfo(
                    titleCtrl: _titleCtrl,
                    descCtrl: _descCtrl,
                    prereqCtrl: _prereqCtrl,
                    titleError: _titleError,
                    descError: _descError,
                    selectedLevel: _selectedLevel,
                    levelError: _levelError,
                    levels: _levels,
                    prerequisites: _prerequisites,
                    thumbnail: _thumbnail,
                    subject: subject,
                    onLevelChanged: (v) => setState(() { _selectedLevel = v; _levelError = null; }),
                    onAddPrerequisite: _addPrerequisite,
                    onRemovePrerequisite: (i) => setState(() => _prerequisites.removeAt(i)),
                    onPickThumbnail: _pickThumbnail,
                    onRemoveThumbnail: () => setState(() => _thumbnail = null),
                    onFieldChanged: _clearError,
                  ),
                  SizedBox(height: 16.h),
                  TeacherCreateCourseSyllabus(
                    priceCtrl: _priceCtrl,
                    durationCtrl: _durationCtrl,
                    maxStudentsCtrl: _maxStudentsCtrl,
                    priceError: _priceError,
                    durationError: _durationError,
                    startDate: _startDate,
                    endDate: _endDate,
                    startDateError: _startDateError,
                    isPublished: _isPublished,
                    onStartDatePicked: () => _pickDate(isStart: true),
                    onEndDatePicked: () => _pickDate(isStart: false),
                    onPublishedChanged: (v) => setState(() => _isPublished = v),
                    onFieldChanged: _clearError,
                  ),
                  SizedBox(height: 16.h),
                  TeacherCreateCourseMedia(
                    titleCtrl: _titleCtrl,
                    subject: subject,
                    selectedLevel: _selectedLevel,
                    priceCtrl: _priceCtrl,
                    durationCtrl: _durationCtrl,
                    startDate: _startDate,
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
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
                            boxShadow: _loading ? null : [BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: .4),
                                blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Center(
                            child: _loading
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 18, height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
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
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.maybePop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text('إلغاء',
                          style: TextStyle(fontSize: 14.sp, fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
