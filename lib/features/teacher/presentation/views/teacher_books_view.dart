import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../data/repositories/teacher_repository.dart';
import 'teacher_create_book_view.dart';
import 'teacher_edit_book_view.dart';

class TeacherBooksView extends StatefulWidget {
  static const routeName = '/teacher/books';
  const TeacherBooksView({super.key});

  @override
  State<TeacherBooksView> createState() => _TeacherBooksViewState();
}

class _TeacherBooksViewState extends State<TeacherBooksView> {
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;
  String? _teacherSubject;

  bool _openView = false;
  bool _openDelete = false;
  Map<String, dynamic>? _selectedBook;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<TeacherRepository>();
      final results = await Future.wait([
        repo.getMyBooks(),
        _loadTeacherSubject(repo),
      ]);
      _books = results[0] as List<Map<String, dynamic>>;
      _teacherSubject = results[1] as String?;
    } catch (e) {
      _showToast(e is Failure ? e.message : 'فشل تحميل الكتب', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<String?> _loadTeacherSubject(TeacherRepository repo) async {
    try {
      final res = await repo.getTeacherProfile();
      final teacher = res['teacher'] as Map?;
      final specialties = teacher?['specialties'] as List?;
      if (specialties != null && specialties.isNotEmpty) return specialties[0].toString();
      return teacher?['expertise'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _showToast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _deleteBook() async {
    try {
      await context.read<TeacherRepository>().deleteBook(_selectedBook!['id']);
      _books.removeWhere((b) => b['id'] == _selectedBook!['id']);
      _showToast('تم حذف الكتاب بنجاح');
      _openDelete = false;
      _selectedBook = null;
    } on Failure catch (e) { _showToast(e.message, error: true); }
    catch (_) { _showToast('فشل حذف الكتاب', error: true); }
  }

  Future<void> _togglePublish(Map<String, dynamic> book) async {
    try {
      final newVal = await context.read<TeacherRepository>().toggleBookPublish(book['id']);
      _books = _books.map((b) => b['id'] == book['id'] ? {...b, 'isPublished': newVal} : b).toList();
      _showToast(newVal ? 'تم نشر الكتاب ✅' : 'تم إخفاء الكتاب');
    } catch (e) {
      _showToast('فشل تغيير حالة الكتاب', error: true);
    }
  }

  /// Builds a cover image widget that supports both Base64 and Network URLs
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

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)]),
      ),
      padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 16.h),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Icon(Icons.menu_book, color: Colors.white, size: 32),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مكتبة الكتب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 18.sp, color: Colors.white)),
                    Row(
                      children: [
                        Text('إدارة كتبك الدراسية', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: Colors.white70)),
                        if (_teacherSubject != null) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(8.r)),
                            child: Text(_teacherSubject!, style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: () => Navigator.pushNamed(context, TeacherCreateBookView.routeName).then((_) => _fetchData()),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Color(0xFF7C3AED), size: 18),
                        SizedBox(width: 4.w),
                        Text('إضافة كتاب جديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 11.sp, color: const Color(0xFF7C3AED))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          _buildStatsRow(isDark),
          SizedBox(height: 16.h),
          if (_books.isEmpty) _buildEmptyState() else _buildBooksGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final total = _books.length;
    final purchases = _books.fold<int>(0, (s, b) => s + (b['purchases'] as int? ?? 0));
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
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
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
                        Text('${stats[i]['value']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                        Text('${stats[i]['label']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
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

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(48.r),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book, size: 80, color: context.isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
          SizedBox(height: 12.h),
          Text('لا توجد كتب حالياً', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 16.sp, color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          SizedBox(height: 8.h),
          Text('ابدأ بإضافة كتابك الأول', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: context.isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
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
                onTap: () => Navigator.pushNamed(context, TeacherCreateBookView.routeName).then((_) => _fetchData()),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 6.w),
                      const Text('إضافة كتاب جديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
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

  Widget _buildBooksGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: _books.length,
      itemBuilder: (_, i) => _buildBookCard(_books[i], isDark),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book, bool isDark) {
    final cover = book['coverImage'] as String?;
    final price = (book['price'] ?? 0) is int ? (book['price'] as int).toDouble() : (book['price'] ?? 0.0).toDouble();
    final published = book['isPublished'] == true;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
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
                      setState(() { _selectedBook = book; _openView = true; });
                    } else if (v == 'edit') {
                      Navigator.pushNamed(context, TeacherEditBookView.routeName, arguments: book).then((_) => _fetchData());
                    } else if (v == 'delete') {
                      setState(() { _selectedBook = book; _openDelete = true; });
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
                            onTap: () => _togglePublish(book),
                            child: _chip(published ? '🟢 منشور' : '🟡 مسودة', published ? const Color(0xFF059669) : const Color(0xFFB45309), isDark,
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
                Text('${book['purchases'] ?? 0} مبيعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
                const Spacer(),
                Text((book['createdAt'] as String?)?.split('T')[0] ?? '', style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
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
      child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _viewDialog(bool isDark) {
    final book = _selectedBook;
    if (book == null) return const SizedBox();
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
                Text('تفاصيل الكتاب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() { _openView = false; _selectedBook = null; }),
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
                    Text('عنوان الكتاب', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                    Text(book['title'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
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
                    Text('الوصف', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                    Text(book['description'] as String? ?? 'لا يوجد وصف',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, height: 1.8, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                    Row(
                      children: [
                        Expanded(child: _statBox('${book['purchases'] ?? 0}', 'مبيعة', const Color(0xFF2563EB), const Color(0xFFEFF6FF))),
                        SizedBox(width: 8.w),
                        // Expanded(child: _statBox(price > 0 ? '${price.toInt()} ج.م' : 'مجاني', 'السعر',
                        //     price > 0 ? const Color(0xFFB45309) : const Color(0xFF16A34A),
                        //     price > 0 ? const Color(0xFFFEFCE8) : const Color(0xFFF0FDF4))),
                        // SizedBox(width: 8.w),
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
                  onPressed: () => setState(() { _openView = false; _selectedBook = null; }),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                ),
                SizedBox(width: 8.w),
                OutlinedButton.icon(
                  onPressed: () {
                    _openView = false;
                    Navigator.pushNamed(context, TeacherEditBookView.routeName, arguments: book).then((_) => _fetchData());
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text('تعديل الكتاب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp)),
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
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4.r)),
          child: Text(value, style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: color)),
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
          Text(value, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 13.sp, color: const Color(0xFF1E293B))),
          Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 9, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _deleteDialog(bool isDark) {
    final book = _selectedBook;
    if (book == null) return const SizedBox();
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
                Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
              ],
            ),
            SizedBox(height: 12.h),
            Text('هل أنت متأكد من حذف هذا الكتاب؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
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
                  Text(book['title'] ?? '', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF991B1B))),
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
                    onPressed: () => setState(() { _openDelete = false; _selectedBook = null; }),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _deleteBook,
                    icon: const Icon(Icons.delete, size: 16),
                    label: Text('حذف الكتاب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 12.sp)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(child: _buildBody(isDark)),
              ],
            ),
          ),
        ),
        if (_openView) _viewDialog(isDark),
        if (_openDelete) _deleteDialog(isDark),
      ],
    );
  }
}