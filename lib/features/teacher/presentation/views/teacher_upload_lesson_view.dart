import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import 'widgets/teacher_upload_lesson_form.dart';
import 'widgets/teacher_upload_lesson_file_picker.dart';

class TeacherUploadLessonView extends StatefulWidget {
  static const routeName = '/teacher/upload-lesson';
  const TeacherUploadLessonView({super.key});

  @override
  State<TeacherUploadLessonView> createState() =>
      _TeacherUploadLessonViewState();
}

class _TeacherUploadLessonViewState extends State<TeacherUploadLessonView> {
  List<TeacherCourse> _courses = [];
  bool _coursesLoading = true;
  String? _coursesError;

  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '1');

  String _courseId = '';
  bool _isPublished = true;

  PlatformFile? _videoFile;
  PlatformFile? _pdfFile;

  bool _loading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _contentCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() { _coursesLoading = true; _coursesError = null; });
    try {
      final courses = await context.read<TeacherRepository>().getMyCourses();
      if (!mounted) return;
      setState(() { _courses = courses; _coursesLoading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _coursesError = e.message; _coursesLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _coursesError = 'فشل تحميل الكورسات'; _coursesLoading = false; });
    }
  }

  bool _validate() {
    if (_courseId.isEmpty) { _showToast('يرجى اختيار الكورس', error: true); return false; }
    if (_titleCtrl.text.trim().isEmpty) { _showToast('عنوان الدرس مطلوب', error: true); return false; }
    if (_videoFile == null && _pdfFile == null) { _showToast('يرجى رفع فيديو أو ملف PDF على الأقل', error: true); return false; }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() { _loading = true; _uploadProgress = 0; });
    try {
      await context.read<TeacherRepository>().createLesson(
        courseId: _courseId, title: _titleCtrl.text, content: _contentCtrl.text,
        summary: _summaryCtrl.text, order: int.tryParse(_orderCtrl.text) ?? 1,
        isPublished: _isPublished, videoPath: _videoFile?.path, pdfPath: _pdfFile?.path,
      );
      if (!mounted) return;
      setState(() => _uploadProgress = 100);
      _showToast('تم رفع الدرس بنجاح! 🎉');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } on Failure catch (e) {
      setState(() { _loading = false; _uploadProgress = 0; });
      _showToast(e.message, error: true);
    } catch (_) {
      setState(() { _loading = false; _uploadProgress = 0; });
      _showToast('فشل رفع الدرس', error: true);
    }
  }

  void _showToast(String message, {bool error = false}) =>
      buildSnackBar(context, message, isError: error);

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 500 * 1024 * 1024) {
        _showToast('حجم الفيديو يجب أن يكون أقل من 500 ميجابايت', error: true);
        return;
      }
      setState(() => _videoFile = file);
      _showToast('تم اختيار الفيديو ✅');
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 50 * 1024 * 1024) {
        _showToast('حجم ملف PDF يجب أن يكون أقل من 50 ميجابايت', error: true);
        return;
      }
      setState(() => _pdfFile = file);
      _showToast('تم اختيار ملف PDF ✅');
    }
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
              _buildHeader(context),
              SizedBox(height: 20.h),
              TeacherUploadLessonForm(
                courses: _courses, coursesLoading: _coursesLoading,
                coursesError: _coursesError, courseId: _courseId,
                titleController: _titleCtrl, summaryController: _summaryCtrl,
                contentController: _contentCtrl, orderController: _orderCtrl,
                isPublished: _isPublished,
                onCourseChanged: (v) => setState(() => _courseId = v),
                onPublishedChanged: (v) => setState(() => _isPublished = v),
                onRefreshCourses: _fetchCourses,
              ),
              SizedBox(height: 20.h),
              TeacherUploadLessonFilePicker(
                videoFile: _videoFile, pdfFile: _pdfFile,
                loading: _loading, uploadProgress: _uploadProgress,
                onPickVideo: _pickVideo, onPickPdf: _pickPdf,
                onRemoveVideo: () => setState(() => _videoFile = null),
                onRemovePdf: () => setState(() => _pdfFile = null),
              ),
              SizedBox(height: 24.h),
              _buildActions(isDark),
              SizedBox(height: 20.h),
              const TeacherUploadLessonTips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('العودة للوحة التحكم',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
          style: TextButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF374151)),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Container(
              width: 46.w, height: 46.w,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Icon(Icons.cloud_upload, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('رفع درس جديد',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 20.sp,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                Text('أضف محتوى تعليمي جديد لطلابك',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF374151),
              side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB)),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: (_loading || _coursesLoading || _courses.isEmpty) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white,
              disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
            ),
            child: _loading
                ? Text('جاري الرفع... ${_uploadProgress.round()}%',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 13))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, size: 20),
                      SizedBox(width: 8),
                      Text('رفع الدرس', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 13)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
