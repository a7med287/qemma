import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/helpers/build_snack_bar.dart';
import '../../../data/models/teacher_models.dart';
import '../../../data/repositories/teacher_repository.dart';

class CourseLessonsDialog extends StatefulWidget {
  const CourseLessonsDialog({
    super.key,
    required this.course,
    required this.repository,
    required this.isDark,
    required this.onLessonChanged,
  });

  final TeacherCourse course;
  final TeacherRepository repository;
  final bool isDark;
  final VoidCallback onLessonChanged;

  @override
  State<CourseLessonsDialog> createState() => _CourseLessonsDialogState();
}

class _CourseLessonsDialogState extends State<CourseLessonsDialog> {
  List<Lesson> _lessons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lessons = await widget.repository.getLessons(widget.course.id);
      if (!mounted) return;
      setState(() { _lessons = lessons; _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'فشل تحميل الدروس'; _loading = false; });
    }
  }

  Future<void> _handleDelete(Lesson lesson) async {
    try {
      await widget.repository.deleteLesson(lesson.id);
      if (!mounted) return;
      setState(() => _lessons.removeWhere((l) => l.id == lesson.id));
      widget.onLessonChanged();
    } on Failure catch (e) {
      if (!mounted) return;
      buildSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      buildSnackBar(context, 'فشل حذف الدرس', isError: true);
    }
  }

  void _showDeleteConfirm(Lesson lesson) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => _LessonDeleteDialog(
        lesson: lesson,
        isDark: widget.isDark,
        onConfirm: () => _handleDelete(lesson),
      ),
    );
  }

  void _showEditDialog(Lesson lesson) async {
    await showDialog(
      context: context,
      builder: (ctx) => _LessonEditDialog(
        lesson: lesson,
        repository: widget.repository,
        isDark: widget.isDark,
        onSaved: () {
          _fetchLessons();
          widget.onLessonChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w, height: 40.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const Icon(Icons.menu_book, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('دروس الكورس',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900,
                              fontSize: 16.sp,
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                      Text('${widget.course.title} — ${_lessons.length} درس',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          // Body
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()))
                : _error != null
                    ? Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off, size: 40.sp, color: Colors.grey),
                            SizedBox(height: 8.h),
                            Text(_error!, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
                            SizedBox(height: 12.h),
                            ElevatedButton(onPressed: _fetchLessons,
                                child: const Text('إعادة المحاولة',
                                    style: TextStyle(fontFamily: 'Cairo'))),
                          ],
                        ),
                      )
                    : _lessons.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(32.r),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.menu_book, size: 56.sp,
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                                SizedBox(height: 12.h),
                                Text('لا توجد دروس بعد',
                                    style: TextStyle(fontFamily: 'Cairo',
                                        fontWeight: FontWeight.w700, fontSize: 15.sp,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                                SizedBox(height: 6.h),
                                Text('أضف دروساً جديدة لهذا الكورس',
                                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp,
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.all(12.r),
                            itemCount: _lessons.length,
                            separatorBuilder: (_, __) => SizedBox(height: 8.h),
                            itemBuilder: (_, i) {
                              final lesson = _lessons[i];
                              return Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28.w, height: 28.w,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text('${i + 1}',
                                            style: TextStyle(fontFamily: 'Cairo',
                                                fontWeight: FontWeight.w900, fontSize: 11.sp,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(lesson.title,
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontFamily: 'Cairo',
                                                  fontWeight: FontWeight.w700, fontSize: 13.sp,
                                                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                                          SizedBox(height: 2.h),
                                          Row(
                                            children: [
                                              if (lesson.videoUrl != null)
                                                _mediaChip(Icons.video_library, 'فيديو'),
                                              if (lesson.videoUrl != null && lesson.pdfUrl != null)
                                                SizedBox(width: 4.w),
                                              if (lesson.pdfUrl != null)
                                                _mediaChip(Icons.picture_as_pdf, 'PDF'),
                                              if (lesson.videoUrl != null || lesson.pdfUrl != null)
                                                SizedBox(width: 4.w),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 6.w, vertical: 1.h),
                                                decoration: BoxDecoration(
                                                  color: lesson.isPublished
                                                      ? (isDark
                                                          ? const Color(0xFF059669).withValues(alpha: .2)
                                                          : const Color(0xFFF0FDF4))
                                                      : (isDark
                                                          ? const Color(0xFFF59E0B).withValues(alpha: .2)
                                                          : const Color(0xFFFFFBEB)),
                                                  borderRadius: BorderRadius.circular(4.r),
                                                ),
                                                child: Text(
                                                  lesson.isPublished ? 'منشور' : 'مسودة',
                                                  style: TextStyle(fontFamily: 'Cairo',
                                                      fontWeight: FontWeight.w700, fontSize: 9.sp,
                                                      color: lesson.isPublished
                                                          ? const Color(0xFF059669)
                                                          : const Color(0xFFB45309)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _showEditDialog(lesson),
                                      icon: const Icon(Icons.edit, size: 18),
                                      color: const Color(0xFF8B5CF6),
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: .1),
                                        minimumSize: Size(28.w, 28.w),
                                        padding: EdgeInsets.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    IconButton(
                                      onPressed: () => _showDeleteConfirm(lesson),
                                      icon: const Icon(Icons.delete, size: 18),
                                      color: const Color(0xFFDC2626),
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFFDC2626).withValues(alpha: .1),
                                        minimumSize: Size(28.w, 28.w),
                                        padding: EdgeInsets.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          // Footer
          if (_lessons.isNotEmpty && _error == null)
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
              ),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'add_lesson'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة درس جديد',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    side: BorderSide(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mediaChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.sp,
              color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
          SizedBox(width: 2.w),
          Text(label,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp,
                  color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

// ── Lesson Delete Dialog ─────────────────────────────────────────────────────

class _LessonDeleteDialog extends StatefulWidget {
  const _LessonDeleteDialog({
    required this.lesson,
    required this.isDark,
    required this.onConfirm,
  });

  final Lesson lesson;
  final bool isDark;
  final Future<void> Function() onConfirm;

  @override
  State<_LessonDeleteDialog> createState() => _LessonDeleteDialogState();
}

class _LessonDeleteDialogState extends State<_LessonDeleteDialog> {
  bool _submitting = false;

  Future<void> _handleConfirm() async {
    setState(() => _submitting = true);
    try {
      await widget.onConfirm();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Row(
        children: [
          Container(
            width: 36.w, height: 36.w,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: const Icon(Icons.warning, color: Color(0xFFDC2626), size: 20),
          ),
          SizedBox(width: 12.w),
          Text('تأكيد حذف الدرس',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('هل أنت متأكد أنك تريد حذف هذا الدرس؟',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Text(widget.lesson.title,
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14.sp,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text('إلغاء',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          child: _submitting
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 8.w),
                    const Text('جاري الحذف...',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                  ],
                )
              : const Text('نعم، احذف الدرس',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ── Lesson Edit Dialog ──────────────────────────────────────────────────────

class _LessonEditDialog extends StatefulWidget {
  const _LessonEditDialog({
    required this.lesson,
    required this.repository,
    required this.isDark,
    required this.onSaved,
  });

  final Lesson lesson;
  final TeacherRepository repository;
  final bool isDark;
  final VoidCallback onSaved;

  @override
  State<_LessonEditDialog> createState() => _LessonEditDialogState();
}

class _LessonEditDialogState extends State<_LessonEditDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _summaryCtrl;
  bool _isPublished = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    _titleCtrl = TextEditingController(text: l.title);
    _contentCtrl = TextEditingController(text: l.content ?? '');
    _summaryCtrl = TextEditingController(text: l.summary ?? '');
    _isPublished = l.isPublished;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      buildSnackBar(context, 'عنوان الدرس مطلوب', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.repository.updateLesson(widget.lesson.id,
        title: _titleCtrl.text,
        content: _contentCtrl.text,
        summary: _summaryCtrl.text,
        isPublished: _isPublished,
      );
      if (!mounted) return;
      buildSnackBar(context, 'تم تحديث الدرس بنجاح ✅');
      widget.onSaved();
      Navigator.pop(context);
    } on Failure catch (e) {
      setState(() => _loading = false);
      buildSnackBar(context, e.message, isError: true);
    } catch (_) {
      setState(() => _loading = false);
      buildSnackBar(context, 'فشل تحديث الدرس', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Row(
        children: [
          Container(
            width: 36.w, height: 36.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: const Icon(Icons.edit, color: Colors.white, size: 18),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تعديل الدرس',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                Text(widget.lesson.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
              decoration: _inputDec('عنوان الدرس *', isDark),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _summaryCtrl,
              maxLines: 2,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
              decoration: _inputDec('ملخص الدرس', isDark),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
              decoration: _inputDec('محتوى الدرس', isDark),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Text('نشر الدرس',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13.sp,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                  const Spacer(),
                  Switch.adaptive(
                    value: _isPublished,
                    onChanged: (v) => setState(() => _isPublished = v),
                    activeTrackColor: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('إلغاء',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _save,
          icon: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save, size: 18),
          label: Text(_loading ? 'جاري الحفظ...' : 'حفظ التعديلات',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDec(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
    );
  }
}
