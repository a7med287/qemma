import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'teacher_theme_helpers.dart';

class TeacherBooksDetail extends StatelessWidget {
  const TeacherBooksDetail({
    super.key,
    required this.book,
    required this.isDark,
    required this.onClose,
    required this.onEdit,
  });

  final Map<String, dynamic> book;
  final bool isDark;
  final VoidCallback onClose;
  final VoidCallback onEdit;

  Widget _buildCoverImage(String? cover, double height) {
    if (cover != null && cover.isNotEmpty) {
      if (cover.startsWith('data:image')) {
        try {
          final base64Str = cover.split(',').last;
          final bytes = base64Decode(base64Str);
          return Image.memory(
            bytes,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildCoverFallback(height),
          );
        } catch (_) {
          return _buildCoverFallback(height);
        }
      } else {
        return Image.network(
          cover,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildCoverFallback(height),
        );
      }
    }
    return _buildCoverFallback(height);
  }

  Widget _buildCoverFallback(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
      ),
      child: const Center(child: Icon(Icons.menu_book, size: 56, color: Colors.white38)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = (book['price'] ?? 0) is int ? (book['price'] as int).toDouble() : (book['price'] ?? 0.0).toDouble();
    final cover = book['coverImage'] as String?;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book, size: 24, color: Color(0xFF7C3AED)),
                SizedBox(width: 8.w),
                Text('تفاصيل الكتاب',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  style: IconButton.styleFrom(foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
                ),
              ],
            ),
            Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: _buildCoverImage(cover, 180.h),
                    ),
                    SizedBox(height: 12.h),
                    Text('عنوان الكتاب',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                    Text(book['title'] ?? '',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                    Row(
                      children: [
                        Expanded(child: _infoChip('المادة الدراسية', book['subject'] ?? 'غير محدد', const Color(0xFF2563EB), const Color(0xFFEFF6FF))),
                        SizedBox(width: 8.w),
                        Expanded(child: _infoChip('الصف الدراسي', book['grade'] ?? '', const Color(0xFF7C3AED), const Color(0xFFF5F3FF))),
                        SizedBox(width: 8.w),
                        Expanded(child: _infoChip('السعر', price > 0 ? '${price.toInt()} ج.م' : 'مجاني',
                            price > 0 ? const Color(0xFFB45309) : const Color(0xFF16A34A),
                            price > 0 ? const Color(0xFFFEFCE8) : const Color(0xFFF0FDF4))),
                      ],
                    ),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                    Text('الوصف',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                    Text(book['description'] as String? ?? 'لا يوجد وصف',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, height: 1.8,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                    Row(
                      children: [
                        Expanded(child: _statBox('${book['purchases'] ?? 0}', 'مبيعة', const Color(0xFF2563EB), const Color(0xFFEFF6FF))),
                        SizedBox(width: 8.w),
                        Expanded(child: _statBox((book['createdAt'] as String?)?.split('T')[0] ?? '', 'تاريخ الإضافة', const Color(0xFFDB2777), const Color(0xFFFDF2F8))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
            Row(
              children: [
                OutlinedButton(
                  onPressed: onClose,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text('إغلاق',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                ),
                SizedBox(width: 8.w),
                OutlinedButton.icon(
                  onPressed: () { onClose(); onEdit(); },
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text('تعديل الكتاب',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7C3AED),
                    side: const BorderSide(color: Color(0xFF7C3AED)),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color, Color bg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4.r)),
          child: Text(value,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }

  Widget _statBox(String value, String label, Color iconColor, Color bg) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8.r)),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 13.sp, color: const Color(0xFF1E293B))),
          Text(label,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 9, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class TeacherBooksDeleteDialog extends StatelessWidget {
  const TeacherBooksDeleteDialog({
    super.key,
    required this.book,
    required this.isDark,
    required this.onCancel,
    required this.onConfirm,
  });

  final Map<String, dynamic> book;
  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final price = (book['price'] ?? 0) is int ? (book['price'] as int).toDouble() : (book['price'] ?? 0.0).toDouble();
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Color(0xFFEF4444), size: 24),
                SizedBox(width: 8.w),
                Text('تأكيد الحذف',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
              ],
            ),
            SizedBox(height: 12.h),
            Text('هل أنت متأكد من حذف هذا الكتاب؟',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book['title'] ?? '',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF991B1B))),
                  Text('${book['grade'] ?? ''} • ${book['subject'] ?? ''} • ${price > 0 ? '${price.toInt()} ج.م' : 'مجاني'}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFFDC2626))),
                  const SizedBox(height: 4),
                  const Text('لن تتمكن من استرجاع هذا الكتاب بعد الحذف',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFFDC2626))),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    child: Text('إلغاء',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.delete, size: 16),
                    label: Text('حذف الكتاب',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 12.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
