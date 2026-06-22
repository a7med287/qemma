import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../routes/student_routes.dart';
import '../widgets/student_async_body.dart';
import '../widgets/student_shared_widgets.dart';

class BooksView extends StatefulWidget {
  const BooksView({super.key});

  @override
  State<BooksView> createState() => _BooksViewState();
}

class _BooksViewState extends State<BooksView> {
  List<StudyBook> _books = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  bool _showPurchased = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<StudentRepository>();
      final list = _showPurchased ? await repo.getPurchasedBooks() : await repo.getBooks(search: _search);
      if (!mounted) return;
      setState(() {
        _books = list;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentPageShell(
      title: '📚 الكتب الدراسية',
      headerChild: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _search = v),
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'ابحث عن كتاب...',
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              ChoiceChip(
                label: const Text('كل الكتب'),
                selected: !_showPurchased,
                onSelected: (_) {
                  setState(() => _showPurchased = false);
                  _load();
                },
              ),
              SizedBox(width: 8.w),
              ChoiceChip(
                label: const Text('مكتبتي'),
                selected: _showPurchased,
                onSelected: (_) {
                  setState(() => _showPurchased = true);
                  _load();
                },
              ),
            ],
          ),
        ],
      ),
      body: StudentAsyncBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: GridView.builder(
          padding: EdgeInsets.all(16.r),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.75,
          ),
          itemCount: _books.length,
          itemBuilder: (_, i) {
            final book = _books[i];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => StudentRoutes.pushBook(context, book.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(gradient: LinearGradient(colors: book.gradient)),
                        child: Center(child: Icon(Icons.auto_stories, size: 40.sp, color: Colors.white)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.all(8.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.title, style: TextStyles.semiBold14.copyWith(color: context.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(book.subtitle, style: TextStyles.regular13.copyWith(color: context.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Text(book.teacher, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
