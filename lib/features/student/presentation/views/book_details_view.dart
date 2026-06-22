import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../widgets/student_async_body.dart';
import '../widgets/student_shared_widgets.dart';

class BookDetailsView extends StatefulWidget {
  const BookDetailsView({super.key, required this.bookId});

  final String bookId;

  @override
  State<BookDetailsView> createState() => _BookDetailsViewState();
}

class _BookDetailsViewState extends State<BookDetailsView> {
  StudyBook? _book;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final book = await context.read<StudentRepository>().getBook(widget.bookId);
      if (!mounted) return;
      setState(() {
        _book = book;
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
    return Scaffold(
      body: StudentAsyncBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: _book == null
            ? const SizedBox.shrink()
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200.h,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(gradient: LinearGradient(colors: _book!.gradient)),
                        child: SafeArea(
                          child: Padding(
                            padding: EdgeInsets.all(16.r),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.auto_stories, size: 40.sp, color: Colors.white),
                                Text(_book!.title, style: TextStyles.bold20.copyWith(color: Colors.white)),
                                Text(_book!.subtitle, style: TextStyles.regular14.copyWith(color: Colors.white70)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.all(16.r),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        StudentGlassCard(
                          title: 'عن الكتاب',
                          child: Text(_book!.description.isNotEmpty ? _book!.description : 'كتاب ${_book!.subject}'),
                        ),
                        SizedBox(height: 16.h),
                        StudentGlassCard(
                          title: '👨‍🏫 المدرس',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_book!.teacher, style: TextStyles.semiBold16),
                              if (_book!.teacherBio.isNotEmpty) Text(_book!.teacherBio),
                              Text('⭐ ${_book!.rating} (${_book!.reviewsCount} تقييم)', style: TextStyles.regular14),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download),
                          label: Text('تحميل الكتاب'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48.h),
                            backgroundColor: _book!.color,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
