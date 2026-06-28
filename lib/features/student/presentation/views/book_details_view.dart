import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../constants.dart' as constants;
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

  // Rating state
  BookRatingData? _ratingData;
  int _userRating = 0;
  String _ratingComment = '';
  bool _submittingRating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        context.read<StudentRepository>().getBook(widget.bookId),
        context.read<StudentRepository>().getBookRating(widget.bookId),
      ]);
      if (!mounted) return;
      setState(() {
        _book = results[0] as StudyBook;
        _ratingData = results[1] as BookRatingData;
        _userRating = _ratingData!.myRating;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    }
  }

  Future<void> _refreshRating() async {
    try {
      final data = await context.read<StudentRepository>().getBookRating(widget.bookId);
      if (!mounted) return;
      setState(() {
        _ratingData = data;
        _userRating = data.myRating;
      });
    } catch (_) {}
  }

  Future<void> _submitRating() async {
    if (_userRating == 0) return;
    final submittedRating = _userRating;
    final submittedComment = _ratingComment;
    setState(() => _submittingRating = true);
    try {
      await context.read<StudentRepository>().rateBook(
        widget.bookId,
        rating: submittedRating,
        comment: submittedComment,
      );

      // Optimistic update — نضيف الـ review محلياً فوراً عشان يظهر فورًا للمستخدم
      final oldRating = _ratingData;
      BookRatingData? optimisticData;
      if (oldRating != null) {
        final oldTotal = oldRating.totalRatings;
        final oldAvg = oldRating.averageRating;
        final newAvg = ((oldAvg * oldTotal) + submittedRating) / (oldTotal + 1);
        final newReview = BookReview(
          id: 'new-${DateTime.now().millisecondsSinceEpoch}',
          studentName: 'أنت',
          rating: submittedRating.toDouble(),
          comment: submittedComment,
        );
        optimisticData = BookRatingData(
          averageRating: newAvg,
          totalRatings: oldTotal + 1,
          myRating: submittedRating,
          reviews: [newReview, ...oldRating.reviews],
        );
        if (!mounted) return;
        setState(() {
          _ratingData = optimisticData;
          _ratingComment = '';
          _submittingRating = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _ratingComment = '';
          _submittingRating = false;
        });
      }

      // بعدين نحاول نجيب البيانات الفعلية من السيرفر، لكن من غير ما نمسح
      // الـ optimistic update لو السيرفر لسه مرجّعش الريفيو الجديد
      // (مثلاً لو فيه تأخير أو كاش على الـ endpoint)
      try {
        final fresh = await context.read<StudentRepository>().getBookRating(widget.bookId);
        if (!mounted) return;
        final expectedMinTotal = optimisticData?.totalRatings ?? (oldRating?.totalRatings ?? 0);
        if (fresh.totalRatings >= expectedMinTotal) {
          // السيرفر فعليًا عنده الريفيو الجديد (أو أكتر) → نستخدم نسخة السيرفر
          setState(() {
            _ratingData = fresh;
            _userRating = fresh.myRating;
          });
        }
        // لو السيرفر لسه متأخر (totalRatings أقل من المتوقع)، نسيب الـ optimistic
        // update زي ما هو ومتمسحوش، عشان التقييم مش يختفي من قدام المستخدم.
      } catch (_) {
        // لو الـ refresh فشل، نسيب الـ optimistic update كما هو.
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submittingRating = false);
    }
  }

  String? get _downloadUrl {
    if (_book?.pdfFileRef == null || _book!.pdfFileRef!.isEmpty) return null;
    final ref = _book!.pdfFileRef!;
    if (ref.startsWith('http://') || ref.startsWith('https://')) return ref;
    final base = constants.kApiBaseUrl.replaceAll('/api', '').replaceAll('/api/', '');
    return '$base$ref';
  }

  ImageProvider _resolveImage(String source) {
    if (source.startsWith('data:image')) {
      final commaIndex = source.indexOf(',');
      final base64Str = commaIndex != -1 ? source.substring(commaIndex + 1) : source;
      try {
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return const AssetImage('assets/images/placeholder.png');
      }
    }
    return NetworkImage(source);
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
            // Gradient Header
            SliverAppBar(
              expandedHeight: 280.h,
              pinned: true,
              leading: StudentBackButton(
                onPressed: () => Navigator.maybePop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _book!.coverImage != null
                        ? Image(
                      image: _resolveImage(_book!.coverImage!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                      ),
                    )
                        : Container(
                      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                      child: Center(
                        child: Icon(Icons.menu_book,
                            size: 64.sp, color: Colors.white.withValues(alpha: .6)),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .05),
                            Colors.black.withValues(alpha: .75),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_book!.title,
                                style: TextStyles.bold20.copyWith(color: Colors.white)),
                            SizedBox(height: 4.h),
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 4.h,
                              children: [
                                _chip(context, _book!.subject, Icons.school),
                                _chip(context, _book!.grade.isNotEmpty ? _book!.grade : _book!.subtitle,
                                    Icons.menu_book),
                                _chip(context,
                                    _book!.price > 0 ? '${_book!.price} جنيه' : 'مجاني',
                                    Icons.attach_money),
                                _chip(context,
                                    _book!.bookType == 'pdf' ? 'PDF' : '📖 مطبوع', null),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 16.r,
                                    backgroundColor: Colors.white.withValues(alpha: .3),
                                    backgroundImage: _book!.teacherAvatar != null
                                        ? _resolveImage(_book!.teacherAvatar!)
                                        : null,
                                    child: _book!.teacherAvatar == null
                                        ? const Icon(Icons.person, color: Colors.white, size: 18)
                                        : null,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(_book!.teacherName,
                                      style: TextStyles.semiBold14.copyWith(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Body
            SliverPadding(
              padding: EdgeInsets.all(16.r),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _glassCard(context, '📖 عن الكتاب',
                    Text(_book!.description.isNotEmpty ? _book!.description : 'لا يوجد وصف لهذا الكتاب',
                        style: TextStyles.regular14.copyWith(color: context.textSecondary),
                        textAlign: TextAlign.start),
                  ),
                  SizedBox(height: 16.h),
                  _glassCard(context, '👨‍🏫 المدرس',
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28.r,
                          backgroundColor: _book!.color.withValues(alpha: .15),
                          backgroundImage: _book!.teacherAvatar != null
                              ? _resolveImage(_book!.teacherAvatar!)
                              : null,
                          child: _book!.teacherAvatar == null
                              ? Icon(Icons.person, color: _book!.color, size: 28.sp)
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_book!.teacherName,
                                style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                            Text(_book!.subject,
                                style: TextStyles.regular13.copyWith(color: _book!.color)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _glassCard(context, '📋 معلومات الكتاب',
                    Column(
                      children: [
                        _infoRow(context, 'المادة', _book!.subject),
                        _infoRow(context, 'الصف الدراسي',
                            _book!.grade.isNotEmpty ? _book!.grade : _book!.subtitle),
                        _infoRow(context, 'السعر',
                            _book!.price > 0 ? '${_book!.price} جنيه' : 'مجاني'),
                        _infoRow(context, 'النوع',
                            _book!.bookType == 'pdf' ? 'PDF' : 'كتاب مطبوع'),
                        _infoRow(context, 'عدد المشتريات', '${_book!.purchases} طالب',
                            isLast: true),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildActionButton(context),
                  SizedBox(height: 16.h),
                  // ⭐ Rating Section
                  _buildRatingSection(context),
                  SizedBox(height: 80.h),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, IconData? icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: icon != null
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(label, style: TextStyles.regular13.copyWith(color: Colors.white)),
        ],
      )
          : Text(label, style: TextStyles.regular13.copyWith(color: Colors.white)),
    );
  }

  Widget _glassCard(BuildContext context, String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, {bool isLast = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: isLast
          ? null
          : BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyles.regular14.copyWith(color: context.textSecondary)),
          Text(value, style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
        ],
      ),
    );
  }

  // ── Rating Section ───────────────────────────────────────────────

  Widget _buildRatingSection(BuildContext context) {
    final rd = _ratingData;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text('⭐ تقييم الكتاب',
              style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 16.h),

          // Average Rating
          Row(
            children: [
              Text(
                (rd?.averageRating ?? 0).toStringAsFixed(1),
                style: TextStyles.bold28.copyWith(color: context.textPrimary),
              ),
              SizedBox(width: 8.w),
              _buildStars(context, rd?.averageRating ?? 0, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                '(${rd?.totalRatings ?? 0} تقييم)',
                style: TextStyles.regular14.copyWith(color: context.textSecondary),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: context.borderColor, height: 1),
          SizedBox(height: 16.h),

          // Submit Rating
          Text(
            _userRating > 0 ? 'تعديل تقييمك' : 'قم بتقييم هذا الكتاب',
            style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildStars(context, _userRating.toDouble(), interactive: true, size: 28.sp),
              if (_userRating > 0) ...[
                SizedBox(width: 8.w),
                Text(
                  '$_userRating / 5',
                  style: TextStyles.regular13.copyWith(color: context.textSecondary),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            onChanged: (v) => _ratingComment = v,
            decoration: InputDecoration(
              hintText: 'أكتب تعليقاً (اختياري)...',
              filled: true,
              fillColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.borderColor),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
            style: TextStyles.regular14.copyWith(color: context.textPrimary),
            maxLines: 2,
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _userRating > 0 && !_submittingRating ? _submitRating : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.borderColor,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: _submittingRating
                  ? SizedBox(
                width: 20.sp,
                height: 20.sp,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : Text('إرسال التقييم',
                  style: TextStyles.semiBold14.copyWith(
                    color: _userRating > 0 ? Colors.white : context.textSecondary,
                  )),
            ),
          ),
          SizedBox(height: 16.h),
          Divider(color: context.borderColor, height: 1),
          SizedBox(height: 16.h),

          // Reviews List
          Text(
            'تقييمات الطلاب (${rd?.reviews.length ?? 0})',
            style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
          ),
          SizedBox(height: 12.h),
          if (rd == null || rd.reviews.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: Text('لا توجد تقييمات بعد',
                    style: TextStyles.regular14.copyWith(color: context.textSecondary)),
              ),
            )
          else
            ...rd.reviews.map((review) => _buildReviewItem(context, review)),
        ],
      ),
    );
  }

  Widget _buildStars(BuildContext context, double rating, {double size = 20, bool interactive = false}) {
    final color = const Color(0xFFFBBF24);
    if (interactive) {
      return StatefulBuilder(
        builder: (context, setLocalState) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final starValue = i + 1;
            final filled = starValue <= _userRating;
            return GestureDetector(
              onTap: () => setState(() => _userRating = starValue),
              child: Icon(
                filled ? Icons.star : Icons.star_border,
                color: filled ? color : context.textSecondary.withValues(alpha: .3),
                size: size,
              ),
            );
          }),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        final filled = starValue <= rating;
        final half = !filled && starValue - 0.5 <= rating;
        return Icon(
          filled ? Icons.star : (half ? Icons.star_half : Icons.star_border),
          color: filled || half ? color : context.textSecondary.withValues(alpha: .3),
          size: size,
        );
      }),
    );
  }

  Widget _buildReviewItem(BuildContext context, BookReview review) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14.r,
                backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                child: Text(
                  review.studentName.isNotEmpty ? review.studentName[0] : 'ط',
                  style: TextStyles.semiBold13.copyWith(
                    color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(review.studentName,
                    style: TextStyles.semiBold13.copyWith(color: context.textPrimary)),
              ),
              _buildStars(context, review.rating, size: 14.sp),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(review.comment,
                style: TextStyles.regular13.copyWith(color: context.textSecondary)),
          ],
        ],
      ),
    );
  }

  // ── Action Button ────────────────────────────────────────────────

  Widget _buildActionButton(BuildContext context) {
    if (_book!.price == 0 && _downloadUrl != null) {
      return _gradientButton(
        context,
        label: 'تحميل الكتاب مجاناً',
        icon: Icons.download,
        gradientColors: const [Color(0xFF059669), Color(0xFF047857)],
        onTap: _openDownload,
      );
    }
    if (_book!.price == 0) {
      return Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(12.r),
          color: context.cardColor,
        ),
        child: Column(
          children: [
            Icon(Icons.menu_book,
                size: 32.sp, color: context.textSecondary.withValues(alpha: .5)),
            SizedBox(height: 8.h),
            Text('الملف الرقمي غير متاح للتحميل بعد',
                style: TextStyles.semiBold14.copyWith(color: context.textSecondary)),
            SizedBox(height: 4.h),
            Text(
              _book!.bookType == 'pdf'
                  ? 'يرجى العودة لاحقاً'
                  : 'هذا الكتاب متاح بنسخة مطبوعة فقط',
              style: TextStyles.regular13.copyWith(color: context.textSecondary.withValues(alpha: .7)),
            ),
          ],
        ),
      );
    }
    if (_book!.bookType == 'pdf' && _book!.hasPurchased && _downloadUrl != null) {
      return _gradientButton(
        context,
        label: 'تحميل الكتاب',
        icon: Icons.download,
        gradientColors: const [Color(0xFF059669), Color(0xFF047857)],
        onTap: _openDownload,
      );
    }
    if (_book!.bookType == 'pdf' && !_book!.hasPurchased) {
      return _gradientButton(
        context,
        label: 'شراء الكتاب - ${_book!.price} جنيه',
        icon: Icons.shopping_cart,
        gradientColors: const [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
        onTap: () {},
      );
    }
    return _gradientButton(
      context,
      label: 'اشتري الآن (توصيل للمنزل) - ${_book!.price} جنيه',
      icon: Icons.shopping_cart,
      gradientColors: const [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
      onTap: () {},
    );
  }

  Widget _gradientButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required List<Color> gradientColors,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text(label, style: TextStyles.semiBold16.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _openDownload() {
    final url = _downloadUrl;
    if (url != null) {}
  }
}