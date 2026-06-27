import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/repositories/teacher_repository.dart';
import 'teacher_create_book_view.dart';
import 'teacher_edit_book_view.dart';
import 'widgets/teacher_books_list.dart';
import 'widgets/teacher_books_detail.dart';

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
      if (specialties != null && specialties.isNotEmpty) {
        return specialties[0].toString();
      }
      return teacher?['expertise'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _showToast(String msg, {bool error = false}) {
    buildSnackBar(context, msg, isError: error);
  }

  Future<void> _deleteBook() async {
    try {
      await context
          .read<TeacherRepository>()
          .deleteBook(_selectedBook!['id']);
      if (!mounted) return;
      setState(() {
        _books.removeWhere((b) => b['id'] == _selectedBook!['id']);
        _openDelete = false;
        _selectedBook = null;
      });
      _showToast('تم حذف الكتاب بنجاح');
    } on Failure catch (e) {
      _showToast(e.message, error: true);
    } catch (_) {
      _showToast('فشل حذف الكتاب', error: true);
    }
  }

  Future<void> _togglePublish(Map<String, dynamic> book) async {
    try {
      final newVal = await context
          .read<TeacherRepository>()
          .toggleBookPublish(book['id']);
      _books = _books
          .map((b) =>
              b['id'] == book['id'] ? {...b, 'isPublished': newVal} : b)
          .toList();
      _showToast(newVal ? 'تم نشر الكتاب ✅' : 'تم إخفاء الكتاب');
    } catch (e) {
      _showToast('فشل تغيير حالة الكتاب', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(isDark),
                      Expanded(
                        child: TeacherBooksList(
                          books: _books,
                          teacherSubject: _teacherSubject,
                          onBookTapped: (book) => setState(() {
                            _selectedBook = book;
                            _openView = true;
                          }),
                          onEditBook: (book) =>
                              Navigator.pushNamed(
                                      context,
                                      TeacherEditBookView.routeName,
                                      arguments: book)
                                  .then((_) => _fetchData()),
                          onTogglePublish: _togglePublish,
                          onDeleteBook: (book) => setState(() {
                            _selectedBook = book;
                            _openDelete = true;
                          }),
                          onCreateBook: () =>
                              Navigator.pushNamed(
                                      context,
                                      TeacherCreateBookView.routeName)
                                  .then((_) => _fetchData()),
                          onRefresh: _fetchData,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (_openView && _selectedBook != null)
          TeacherBooksDetail(
            book: _selectedBook!,
            isDark: isDark,
            onClose: () =>
                setState(() {
                  _openView = false;
                  _selectedBook = null;
                }),
            onEdit: () => Navigator.pushNamed(
                    context,
                    TeacherEditBookView.routeName,
                    arguments: _selectedBook)
                .then((_) => _fetchData()),
          ),
        if (_openDelete && _selectedBook != null)
          TeacherBooksDeleteDialog(
            book: _selectedBook!,
            isDark: isDark,
            onCancel: () => setState(() {
              _openDelete = false;
              _selectedBook = null;
            }),
            onConfirm: () => _deleteBook(),
          ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [
              Color(0xFF2563EB),
              Color(0xFF7C3AED),
              Color(0xFFDB2777)
            ]),
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
              const Icon(Icons.menu_book,
                  color: Colors.white, size: 32),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مكتبة الكتب',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 18.sp,
                            color: Colors.white)),
                    Row(
                      children: [
                        Text('إدارة كتبك الدراسية',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.sp,
                                color: Colors.white70)),
                        if (_teacherSubject != null) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: .2),
                                borderRadius:
                                    BorderRadius.circular(8.r)),
                            child: Text(_teacherSubject!,
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
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
                  onTap: () => Navigator.pushNamed(
                          context,
                          TeacherCreateBookView.routeName)
                      .then((_) => _fetchData()),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add,
                            color: Color(0xFF7C3AED), size: 18),
                        SizedBox(width: 4.w),
                        Text('إضافة كتاب جديد',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w900,
                                fontSize: 11.sp,
                                color: const Color(0xFF7C3AED))),
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
}
