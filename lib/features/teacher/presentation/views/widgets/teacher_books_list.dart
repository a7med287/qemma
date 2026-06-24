import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';

import '../../../data/repositories/teacher_repository.dart';
import 'teacher_theme_helpers.dart';

class TeacherBooksList extends StatelessWidget {
  const TeacherBooksList({
    super.key,
    required this.books,
    required this.teacherSubject,
    required this.onBookTapped,
    required this.onEditBook,
    required this.onTogglePublish,
    required this.onDeleteBook,
    required this.onCreateBook,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> books;
  final String? teacherSubject;
  final void Function(Map<String, dynamic> book) onBookTapped;
  final void Function(Map<String, dynamic> book) onEditBook;
  final void Function(Map<String, dynamic> book) onTogglePublish;
  final void Function(Map<String, dynamic> book) onDeleteBook;
  final VoidCallback onCreateBook;
  final VoidCallback onRefresh;

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
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          _buildStatsRow(context),
          SizedBox(height: 16.h),
          if (books.isEmpty) _buildEmptyState(context) else _buildBooksGrid(context),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final isDark = context.isDark;
    final total = books.length;
    final purchases = books.fold<int>(0, (s, b) => s + (b['purchases'] as int? ?? 0));
    final stats = [
      {'label': 'إجمالي الكتب', 'value': '$total', 'icon': Icons.menu_book, 'bg': const Color(0xFFEFF6FF), 'color': const Color(0xFF2563EB)},
      {'label': 'إجمالي المبيعات', 'value': '$purchases', 'icon': Icons.download, 'bg': const Color(0xFFF5F3FF), 'color': const Color(0xFF7C3AED)},
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) SizedBox(width: 8.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: fieldBorderColor(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36.w, height: 36.w,
                    decoration: BoxDecoration(color: stats[i]['bg'] as Color, borderRadius: BorderRadius.circular(8.r)),
                    child: Icon(stats[i]['icon'] as IconData, color: stats[i]['color'] as Color, size: 18),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${stats[i]['value']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                        Text('${stats[i]['label']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(48.r),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book, size: 80, color: context.isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
          SizedBox(height: 12.h),
          Text('لا توجد كتب حالياً',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 16.sp,
                  color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          SizedBox(height: 8.h),
          Text('ابدأ بإضافة كتابك الأول',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp,
                  color: context.isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
          SizedBox(height: 16.h),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8.r)),
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8.r),
                onTap: onCreateBook,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 6.w),
                      const Text('إضافة كتاب جديد',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksGrid(BuildContext context) {
    final isDark = context.isDark;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: books.length,
      itemBuilder: (_, i) => _buildBookCard(context, books[i], isDark),
    );
  }

  Widget _buildBookCard(BuildContext context, Map<String, dynamic> book, bool isDark) {
    final cover = book['coverImage'] as String?;
    final price = (book['price'] ?? 0) is int ? (book['price'] as int).toDouble() : (book['price'] ?? 0.0).toDouble();
    final published = book['isPublished'] == true;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _buildCoverImage(cover, 130.h),
              Positioned(
                top: 0, left: 0,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  onSelected: (v) {
                    if (v == 'view') {
                      onBookTapped(book);
                    } else if (v == 'edit') {
                      onEditBook(book);
                    } else if (v == 'delete') {
                      onDeleteBook(book);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 20, color: Color(0xFF7C3AED)), SizedBox(width: 8), Text('عرض', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700))])),
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20, color: Color(0xFF2563EB)), SizedBox(width: 8), Text('تعديل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700))])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Color(0xFFEF4444)), SizedBox(width: 8), Text('حذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: Color(0xFFEF4444)))])),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 12.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                  SizedBox(height: 4.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 4.w, runSpacing: 4.h,
                        children: [
                          _chip(book['subject'] ?? 'غير محدد', const Color(0xFF2563EB), isDark, bg: const Color(0xFFEFF6FF)),
                          _chip(book['grade'] ?? '', const Color(0xFF7C3AED), isDark, bg: const Color(0xFFF5F3FF)),
                          _chip(price > 0 ? '${price.toInt()} ج.م' : 'مجاني', price > 0 ? const Color(0xFFB45309) : const Color(0xFF16A34A), isDark,
                              bg: price > 0 ? const Color(0xFFFEFCE8) : const Color(0xFFF0FDF4)),
                          GestureDetector(
                            onTap: () => onTogglePublish(book),
                            child: _chip(published ? 'منشور' : 'مسودة', published ? const Color(0xFF059669) : const Color(0xFFB45309), isDark,
                                bg: published ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEb)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (book['description'] != null && (book['description'] as String).isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.r),
              child: Text(book['description'], maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 4.h),
            child: Row(
              children: [
                Text('${book['purchases'] ?? 0} مبيعة',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
                const Spacer(),
                Text((book['createdAt'] as String?)?.split('T')[0] ?? '',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, bool isDark, {Color? bg}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: .2) : (bg ?? color.withValues(alpha: .1)),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
