import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../routes/student_routes.dart';
import '../widgets/student_shared_widgets.dart';

class BooksView extends StatefulWidget {
  const BooksView({super.key});

  @override
  State<BooksView> createState() => _BooksViewState();
}

class _BooksViewState extends State<BooksView> {
  List<StudyBook> _allBooks = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _selectedSubject = 'الكل';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = context.read<StudentRepository>();
      final list = await repo.getBooks();
      if (!mounted) return;
      setState(() { _allBooks = list; _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    }
  }

  List<String> get _subjects {
    final unique = _allBooks.map((b) => b.subject).where((s) => s.isNotEmpty).toSet().toList();
    return ['الكل', ...unique];
  }

  List<StudyBook> get _filteredBooks {
    var filtered = _allBooks;
    if (_search.isNotEmpty) {
      final q = _search;
      filtered = filtered.where((b) =>
        b.title.contains(q) ||
        b.subtitle.contains(q) ||
        b.teacherName.contains(q) ||
        b.subject.contains(q)
      ).toList();
    }
    if (_selectedSubject != 'الكل') {
      filtered = filtered.where((b) => b.subject == _selectedSubject).toList();
    }
    return filtered;
  }

  int get _favoriteCount => _allBooks.where((b) => b.isFavorite).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 24.h),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StudentBackButton(
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text('📚 الكتب الدراسية',
                            style: TextStyles.bold20.copyWith(color: Colors.white)),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      _statBox(context, '$_favoriteCount', 'المفضلة', '⭐'),
                      SizedBox(width: 8.w),
                      _statBox(context, '${_allBooks.length}', 'إجمالي الكتب', '📖'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: TextStyles.regular14),
                            SizedBox(height: 16.h),
                            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                          ],
                        ),
                      )
                    : _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _statBox(BuildContext context, String value, String label, String emoji) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 20.sp)),
            SizedBox(height: 4.h),
            Text(value, style: TextStyles.bold20.copyWith(color: Colors.white)),
            Text(label,
                style: TextStyles.regular13.copyWith(color: Colors.white.withValues(alpha: .85))),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // Search & Filter
        Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'ابحث عن كتاب أو مدرس...',
                  prefixIcon: Icon(Icons.search, color: context.textSecondary),
                  filled: true,
                  fillColor: context.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
                style: TextStyles.regular14.copyWith(color: context.textPrimary),
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: context.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSubject,
                    isExpanded: true,
                    dropdownColor: context.cardColor,
                    items: _subjects.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: TextStyles.regular14.copyWith(color: context.textPrimary)),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedSubject = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Books Grid
        Expanded(
          child: _filteredBooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📚', style: TextStyle(fontSize: 64.sp)),
                      SizedBox(height: 16.h),
                      Text('لا توجد كتب تطابق البحث',
                          style: TextStyles.semiBold16.copyWith(color: context.textSecondary)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.r),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.57,
                  ),
                  itemCount: _filteredBooks.length,
                  itemBuilder: (_, i) => _buildBookCard(context, _filteredBooks[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildBookCard(BuildContext context, StudyBook book) {
    return GestureDetector(
      onTap: () => StudentRoutes.pushBook(context, book.id),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient header with icon
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: book.gradient),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: const BoxDecoration(
                        color: Color(0x1AFFFFFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: const BoxDecoration(
                        color: Color(0x14FFFFFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Book icon centered
                  Center(
                    child: Container(
                      width: 56.w,
                      height: 56.w,
                      margin: EdgeInsets.only(top: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.auto_stories, color: Colors.white, size: 28.sp),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(book.subtitle,
                        style: TextStyles.regular13.copyWith(color: context.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 6.h),
                    // Teacher
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? const Color(0xFF334155)
                            : book.color.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 14.sp, color: book.color),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(book.teacherName,
                                style: TextStyles.regular13.copyWith(color: context.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // Subject chip
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: context.isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Center(
                        child: Text(book.subject,
                            style: TextStyles.regular13.copyWith(
                              color: context.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // Book type badge
                    if (book.bookType.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: book.bookType == 'pdf'
                              ? (context.isDark
                                  ? const Color(0x33EAB308)
                                  : const Color(0xFFFEFCE8))
                              : (context.isDark
                                  ? const Color(0x332563EB)
                                  : const Color(0xFFEFF6FF)),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          book.bookType == 'pdf' ? 'PDF' : '📖 مطبوع',
                          style: TextStyles.semiBold13.copyWith(
                            color: book.bookType == 'pdf'
                                ? const Color(0xFFB45309)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Open button
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: book.gradient),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'فتح الكتاب',
                        textAlign: TextAlign.center,
                        style: TextStyles.semiBold14.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
