import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final totalPurchases = books.fold<int>(0, (s, b) => s + (b['purchases'] as int? ?? 0));
    final netProfit = books.fold<double>(
      0,
      (s, b) {
        final price = (b['price'] ?? 0) is int ? (b['price'] as int).toDouble() : (b['price'] ?? 0.0).toDouble();
        final purchases = (b['purchases'] as int? ?? 0);
        return s + (price > 0 ? price * 0.9 * purchases : 0);
      },
    );
    final lastUpdate = books.isNotEmpty
        ? (books.first['updatedAt'] as String?)?.split('T')[0] ?? (books.first['createdAt'] as String?)?.split('T')[0] ?? '—'
        : '—';
    final stats = [
      {'label': 'إجمالي الكتب', 'value': '$total', 'icon': Icons.menu_book, 'color': const Color(0xFF2563EB)},
      {'label': 'إجمالي المبيعات', 'value': '$totalPurchases', 'icon': Icons.download, 'color': const Color(0xFF7C3AED)},
      {'label': 'صافي أرباحك', 'value': '${netProfit.toStringAsFixed(2)} ج.م', 'icon': Icons.card_giftcard, 'color': const Color(0xFF059669)},
      {'label': 'آخر تحديث', 'value': lastUpdate, 'icon': Icons.cloud_upload, 'color': const Color(0xFFDB2777)},
    ];
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 48.r) / 2 - 4.w,
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
                  decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(8.r)),
                  child: Icon(stat['icon'] as IconData, color: color, size: 18),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${stat['value']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14.sp,
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                      Text('${stat['label']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, i) => _buildBookCard(context, books[i], isDark),
    );
  }

  Widget _buildBookCard(BuildContext context, Map<String, dynamic> book, bool isDark) {
    final cover = book['coverImage'] as String?;
    final price = (book['price'] ?? 0) is int ? (book['price'] as int).toDouble() : (book['price'] ?? 0.0).toDouble();
    final published = book['isPublished'] == true;
    final bookType = book['bookType'] as String? ?? 'physical';
    final purchases = book['purchases'] as int? ?? 0;
    final netProfit = price > 0 ? price * 0.9 * purchases : 0.0;
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
          _buildCoverImage(cover, 130.h),
          Padding(
            padding: EdgeInsets.all(10.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 12.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 4.w, runSpacing: 4.h,
                  children: [
                    _chip(book['subject'] ?? 'غير محدد', const Color(0xFF2563EB), isDark, bg: const Color(0xFFEFF6FF)),
                    _chip(book['grade'] ?? '', const Color(0xFF7C3AED), isDark, bg: const Color(0xFFF5F3FF)),
                    _chip(price > 0 ? '${price.toInt()} ج.م' : 'مجاني', price > 0 ? const Color(0xFFB45309) : const Color(0xFF16A34A), isDark,
                        bg: price > 0 ? const Color(0xFFFEFCE8) : const Color(0xFFF0FDF4)),
                    _chip(bookType == 'pdf' ? 'PDF' : 'مطبوع', bookType == 'pdf' ? const Color(0xFFB45309) : const Color(0xFF2563EB), isDark,
                        bg: bookType == 'pdf' ? const Color(0xFFFEFCE8) : const Color(0xFFEFF6FF)),
                    GestureDetector(
                      onTap: () => onTogglePublish(book),
                      child: _chip(published ? 'منشور' : 'مسودة', published ? const Color(0xFF059669) : const Color(0xFFB45309), isDark,
                          bg: published ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEb)),
                    ),
                  ],
                ),
                if (book['description'] != null && (book['description'] as String).isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(book['description'], maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                ],
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text('$purchases مبيعة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
                    if (netProfit > 0) ...[
                      SizedBox(width: 8.w),
                      Text('${netProfit.toStringAsFixed(2)} ج.م صافي',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
                    ],
                    const Spacer(),
                    Text((book['createdAt'] as String?)?.split('T')[0] ?? '',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32.h,
                    child: OutlinedButton(
                      onPressed: () => onEditBook(book),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 14),
                          SizedBox(width: 4.w),
                          Text('تعديل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 10.sp)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                SizedBox(
                  height: 32.h,
                  child: OutlinedButton(
                    onPressed: () => onDeleteBook(book),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(6.r),
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                    ),
                    child: const Icon(Icons.delete, size: 16),
                  ),
                ),
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
