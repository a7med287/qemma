import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';

class TeacherUploadLessonView extends StatefulWidget {
  static const routeName = '/teacher/upload-lesson';
  const TeacherUploadLessonView({super.key});

  @override
  State<TeacherUploadLessonView> createState() => _TeacherUploadLessonViewState();
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

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes Bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
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
        courseId: _courseId,
        title: _titleCtrl.text,
        content: _contentCtrl.text,
        summary: _summaryCtrl.text,
        order: int.tryParse(_orderCtrl.text) ?? 1,
        isPublished: _isPublished,
        videoPath: _videoFile?.path,
        pdfPath: _pdfFile?.path,
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

  void _showToast(String message, {bool error = false}) {
    buildSnackBar(context, message, isError: error);
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
              _buildForm(context),
              SizedBox(height: 20.h),
              _buildTips(context),
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
          label: const Text('العودة للوحة التحكم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
          style: TextButton.styleFrom(foregroundColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF374151)),
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

  Widget _buildForm(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('معلومات الدرس',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          SizedBox(height: 16.h),

          _buildCourseSelector(context),
          SizedBox(height: 16.h),
          _buildField(label: 'عنوان الدرس', controller: _titleCtrl, required: true, hint: 'مثال: المعادلات من الدرجة الأولى'),
          SizedBox(height: 12.h),
          _buildField(label: 'ملخص الدرس', controller: _summaryCtrl, multiline: true, maxLines: 2, hint: 'ملخص مختصر عن محتوى الدرس...'),
          SizedBox(height: 12.h),
          _buildField(label: 'محتوى الدرس (اختياري)', controller: _contentCtrl, multiline: true, maxLines: 4, hint: 'اكتب شرح تفصيلي أو ملاحظات عن الدرس...'),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildField(label: 'ترتيب الدرس', controller: _orderCtrl, keyboardType: TextInputType.number),
              ),
              SizedBox(width: 12.w),
              Expanded(child: _buildPublishToggle()),
            ],
          ),
          SizedBox(height: 20.h),

          Text('الملفات',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          SizedBox(height: 12.h),

          _buildVideoUpload(context),
          SizedBox(height: 12.h),
          _buildPdfUpload(context),

          if (_loading) ...[
            SizedBox(height: 20.h),
            _buildProgressBar(),
          ],

          SizedBox(height: 24.h),
          Row(
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
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
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
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSelector(BuildContext context) {
    final isDark = context.isDark;
    if (_coursesLoading) {
      return Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            SizedBox(width: 20.w, height: 20.w, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12.w),
            Text('جاري تحميل الكورسات...',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
          ],
        ),
      );
    }
    if (_coursesError != null) {
      return Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 8.w),
            Expanded(child: Text(_coursesError!, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: const Color(0xFFDC2626)))),
            TextButton(onPressed: _fetchCourses, child: const Text('إعادة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11))),
          ],
        ),
      );
    }
    if (_courses.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Color(0xFFF59E0B), size: 18),
            SizedBox(width: 8.w),
            Expanded(
              child: Text('لا توجد كورسات بعد. أنشئ كورساً أولاً ثم ارفع الدروس.',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: const Color(0xFFB45309))),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/teacher/courses/create'),
              child: const Text('إنشاء كورس', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _courseId.isNotEmpty && _courses.any((c) => c.id == _courseId) ? _courseId : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'اختر الكورس *',
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
      items: _courses.map((course) {
        final subtitle = [course.category, course.level]
            .whereType<String>()
            .join(' - ');
        final label = subtitle.isNotEmpty
            ? '${course.title} ($subtitle)'
            : course.title;

        return DropdownMenuItem<String>(
          value: course.id,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 12.sp,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _courseId = v ?? ''),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool multiline = false,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
    String? hint,
  }) {
    final isDark = context.isDark;
    return TextField(
      controller: controller,
      maxLines: multiline ? maxLines : 1,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
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

  Widget _buildPublishToggle() {
    final isDark = context.isDark;
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('نشر الدرس فوراً',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11.sp,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          ),
          Switch.adaptive(
            value: _isPublished,
            onChanged: (v) => setState(() => _isPublished = v),
            activeTrackColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoUpload(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border.all(
          color: _videoFile != null ? const Color(0xFF8B5CF6) : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8.r),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      child: _videoFile == null ? _buildUploadPlaceholder(
        icon: Icons.video_library,
        title: 'رفع فيديو الدرس',
        subtitle: 'الحد الأقصى: 500 ميجابايت — MP4, AVI, MOV, WMV',
        buttonLabel: 'اختيار فيديو',
        buttonColor: const Color(0xFF8B5CF6),
        onPick: _pickVideo,
      ) : _buildFileCard(
        icon: Icons.video_library,
        iconColor: const Color(0xFF8B5CF6),
        name: _videoFile!.name,
        size: _videoFile!.size,
        onRemove: () => setState(() => _videoFile = null),
      ),
    );
  }

  Widget _buildPdfUpload(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border.all(
          color: _pdfFile != null ? const Color(0xFFDC2626) : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8.r),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      child: _pdfFile == null ? _buildUploadPlaceholder(
        icon: Icons.picture_as_pdf,
        title: 'رفع ملف PDF (اختياري)',
        subtitle: 'ملاحظات، تمارين، أو مواد إضافية (الحد الأقصى: 50 ميجابايت)',
        buttonLabel: 'اختيار PDF',
        buttonColor: const Color(0xFFDC2626),
        onPick: _pickPdf,
      ) : _buildFileCard(
        icon: Icons.picture_as_pdf,
        iconColor: const Color(0xFFDC2626),
        name: _pdfFile!.name,
        size: _pdfFile!.size,
        onRemove: () => setState(() => _pdfFile = null),
      ),
    );
  }

  Widget _buildUploadPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color buttonColor,
    required VoidCallback onPick,
  }) {
    final isDark = context.isDark;
    return Column(
      children: [
        Icon(icon, size: 48.sp, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
        SizedBox(height: 8.h),
        Text(title,
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13.sp,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
        SizedBox(height: 4.h),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
        SizedBox(height: 12.h),
        ElevatedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.cloud_upload, size: 18),
          label: Text(buttonLabel, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard({
    required IconData icon,
    required Color iconColor,
    required String name,
    required int size,
    required VoidCallback onRemove,
  }) {
    final isDark = context.isDark;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                  Text(_formatSize(size),
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
                ],
              ),
            ),
            if (!_loading)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18, color: Color(0xFFEF4444)),
              ),
          ],
        ),
      ],
    );
  }

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
    final result = await FilePicker.platform.pickFiles(allowedExtensions: ['pdf']);
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

  Widget _buildProgressBar() {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_uploadProgress < 100 ? 'جاري الرفع...' : 'تم الرفع ✅',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
            Text('${_uploadProgress.round()}%',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: _uploadProgress / 100,
            minHeight: 8.h,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
        ),
      ],
    );
  }

  Widget _buildTips(BuildContext context) {
    final isDark = context.isDark;
    final tips = [
      'استخدم عناوين واضحة ووصفية للدروس',
      'تأكد من جودة الفيديو والصوت قبل الرفع',
      'أضف ملف PDF للملاحظات والتمارين',
      'رتّب الدروس بشكل منطقي ومتسلسل',
      'اكتب ملخصاً مختصراً ليستفيد منه الطالب',
    ];
    final formats = ['MP4', 'AVI', 'MOV', 'WMV'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نصائح لرفع الدروس',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          SizedBox(height: 12.h),
          ...tips.map((tip) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: const Color(0xFF059669), size: 16),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(tip,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                ),
              ],
            ),
          )),
          SizedBox(height: 12.h),
          Text('صيغ الملفات المدعومة:',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              ...formats.map((f) => Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(f,
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 10.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
              )),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text('PDF',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 10.sp,
                        color: Color(0xFFDC2626))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
