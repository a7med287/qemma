import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../data/models/teacher_models.dart';
import 'teacher_theme_helpers.dart';

class TeacherCourseCard extends StatelessWidget {
  const TeacherCourseCard({
    super.key,
    required this.course,
    required this.onEdit,
    required this.onTogglePublish,
    required this.onDelete,
  });

  final TeacherCourse course;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublish;
  final VoidCallback onDelete;

  Widget _buildThumbnailImage(String thumbnail) {
    if (thumbnail.startsWith('data:image')) {
      try {
        final base64Str = thumbnail.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
        );
      } catch (_) {
        return _thumbnailPlaceholder();
      }
    }
    return Image.network(
      thumbnail,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 32.sp, color: const Color(0xFF475569)),
          Text('بدون صورة',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.r)),
      child: Text(label,
          style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (course.thumbnail != null && course.thumbnail!.isNotEmpty)
                  Positioned.fill(
                    child: _buildThumbnailImage(course.thumbnail!),
                  )
                else
                  _thumbnailPlaceholder(),
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: [
                      if (course.category != null)
                        _badge(course.category!, const Color(0xFF2563EB)),
                      if (course.level != null)
                        _badge(course.level!, const Color(0xFF7C3AED)),
                      _badge(course.isPublished ? 'منشور' : 'مسودة',
                          course.isPublished ? const Color(0xFF059669) : const Color(0xFFF59E0B)),
                    ],
                  ),
                ),
                Positioned(
                  left: 6.w,
                  top: 6.h,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'toggle') onTogglePublish();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Row(
                        children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('تعديل', style: TextStyle(fontFamily: 'Cairo'))],
                      )),
                      PopupMenuItem(value: 'toggle', child: Row(
                        children: [
                          Icon(course.isPublished ? Icons.visibility_off : Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text(course.isPublished ? 'إخفاء' : 'نشر', style: const TextStyle(fontFamily: 'Cairo')),
                        ],
                      )),
                      const PopupMenuItem(value: 'delete', child: Row(
                        children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8),
                          Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.red))],
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 11.sp,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      _miniStat(context, Icons.people, '${course.stats?.enrollments ?? 0}', 'طالب'),
                      _miniStat(context, Icons.video_library, '${course.stats?.lessons ?? 0}', 'درس'),
                      _miniStat(context, Icons.attach_money, '${course.price}', 'ج.م'),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 26.h,
                    child: TextButton(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('تعديل الكورس',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 10.sp,
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF374151))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, IconData icon, String value, String label) {
    final isDark = context.isDark;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10.sp, fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          Text(label,
              style: TextStyle(fontSize: 8.sp, fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class TeacherCourseDeleteDialog extends StatelessWidget {
  const TeacherCourseDeleteDialog({
    super.key,
    required this.course,
    required this.isDark,
  });

  final TeacherCourse course;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
          Text('تأكيد حذف الكورس',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد أنك تريد حذف الكورس التالي؟',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14.sp,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                  if (course.description != null && course.description!.isNotEmpty)
                    Text(course.description!,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3A1))),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8.r)),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Color(0xFFDC2626), size: 16),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text('⚠️ هذا الإجراء لا يمكن التراجع عنه',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: const Color(0xFFDC2626))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('إلغاء',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          child: const Text('نعم، احذف الكورس',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class TeacherCourseEmptyState extends StatelessWidget {
  const TeacherCourseEmptyState({
    super.key,
    required this.isSearching,
  });

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64.sp,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
            SizedBox(height: 16.h),
            Text(isSearching ? 'لا توجد نتائج للبحث' : 'لا توجد كورسات بعد',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 16.sp,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
            SizedBox(height: 8.h),
            Text(isSearching ? 'جرّب كلمة بحث مختلفة' : 'ابدأ بإنشاء كورسك الأول الآن',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}
