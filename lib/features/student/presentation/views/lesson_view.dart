import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../../constants.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';

class LessonView extends StatefulWidget {
  const LessonView({super.key, required this.courseId, required this.lessonId});

  final String courseId;
  final String lessonId;

  @override
  State<LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends State<LessonView> {
  CourseDetail? _course;
  CourseLesson? _lesson;
  bool _loading = true;
  String? _error;
  bool _completed = false;

  // Video
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;
  bool _isPlaying = false;

  // Rating
  double _myRating = 0;
  double _avgRating = 0;
  int _totalRatings = 0;
  bool _ratingLoading = false;

  String? _absoluteUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = kApiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/${path.startsWith('/') ? path.substring(1) : path}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _videoController?.removeListener(() {});
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = context.read<StudentRepository>();
      final course = await repo.getCourseDetail(widget.courseId);
      final lesson = course.lessons.where((l) => l.id == widget.lessonId).firstOrNull;
      if (!mounted) return;
      setState(() {
        _course = course;
        _lesson = lesson;
        _loading = false;
      });
      _initVideo();
      _fetchRating();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'حدث خطأ في تحميل الدرس'; _loading = false; });
    }
  }

  void _initVideo() {
    final url = _absoluteUrl(_lesson?.videoUrl);
    if (url == null) return;

    // إعادة ضبط الحالة قبل أي محاولة تحميل (أول مرة أو إعادة محاولة)
    setState(() {
      _videoInitialized = false;
      _videoError = false;
    });

    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController!.initialize().then((_) {
      if (!mounted) return;
      setState(() => _videoInitialized = true);
    }).catchError((e) {
      debugPrint('Video init error: $e');
      if (!mounted) return;
      setState(() {
        _videoInitialized = false;
        _videoError = true;
      });
    });
    _videoController!.addListener(() {
      if (!mounted) return;
      setState(() => _isPlaying = _videoController!.value.isPlaying);
    });
  }

  Future<void> _fetchRating() async {
    try {
      final repo = context.read<StudentRepository>();
      final data = await repo.getLessonRating(widget.lessonId);
      if (!mounted) return;
      setState(() {
        _myRating = ((data['myRating'] ?? 0) as num).toDouble();
        _avgRating = ((data['averageRating'] ?? 0) as num).toDouble();
        _totalRatings = ((data['totalRatings'] ?? 0) as num).toInt();
      });
    } catch (e) {
      debugPrint('Fetch rating error: $e');
    }
  }

  Future<void> _submitRating(double rating) async {
    setState(() => _ratingLoading = true);
    try {
      final repo = context.read<StudentRepository>();
      await repo.rateLesson(widget.lessonId, rating.toInt());
      await _fetchRating();
    } catch (e) {
      debugPrint('Submit rating error: $e');
      if (mounted) buildSnackBar(context, 'فشل في حفظ التقييم', isError: true);
    }
    if (mounted) setState(() => _ratingLoading = false);
  }

  void _togglePlay() {
    if (_videoController == null || !_videoInitialized) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
  }

  void _toggleFullscreen() {}

  void _handleComplete() {
    setState(() => _completed = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _openPdf() async {
    final url = _absoluteUrl(_lesson?.pdfFileRef);
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _fmtTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _course?.progress ?? 0;
    final videoUrl = _absoluteUrl(_lesson?.videoUrl);
    final pdfUrl = _absoluteUrl(_lesson?.pdfFileRef);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')))
          : CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_course?.title ?? '',
                              style: TextStyle(fontSize: 12.sp, color: Colors.white.withValues(alpha: 0.7), fontFamily: 'Cairo')),
                          Text(_lesson?.title ?? 'الدرس',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text('$progress% مكتمل',
                          style: TextStyle(fontSize: 11.sp, color: Colors.white, fontFamily: 'Cairo')),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content Area (16:9) ──
          SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: _buildContentArea(videoUrl, pdfUrl, isDark),
              ),
            ),
          ),

          // ── Below Content ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notes
                  _buildNotesCard(isDark),
                  SizedBox(height: 16.h),
                  // Sidebar
                  _buildSidebar(isDark),
                  SizedBox(height: 16.h),
                  // Rating
                  _buildRatingCard(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(String? videoUrl, String? pdfUrl, bool isDark) {
    if (_completed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF059669)),
          SizedBox(height: 16.h),
          Text('أحسنت! 🎉',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Cairo')),
          SizedBox(height: 8.h),
          Text('لقد أكملت هذا الدرس بنجاح',
              style: TextStyle(fontSize: 14.sp, color: Colors.white.withValues(alpha: 0.8), fontFamily: 'Cairo')),
        ],
      );
    }

    if (videoUrl != null) {
      // حالة الخطأ: فشل تحميل الفيديو
      if (_videoError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 56.sp, color: Colors.white70),
              SizedBox(height: 12.h),
              Text('تعذر تحميل الفيديو',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white, fontFamily: 'Cairo')),
              SizedBox(height: 8.h),
              Text('تأكد من اتصالك بالإنترنت وحاول مرة أخرى',
                style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.6), fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: _initVideo,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
          ),
        );
      }

      return Stack(
        alignment: Alignment.center,
        children: [
          if (_videoInitialized && _videoController != null)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (_videoInitialized && !_isPlaying)
            IconButton(
              onPressed: _togglePlay,
              icon: Icon(Icons.play_circle_filled_rounded, size: 80.r, color: Colors.white.withValues(alpha: 0.8)),
            ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
              child: Column(
                children: [
                  if (_videoInitialized && _videoController != null)
                    VideoProgressIndicator(_videoController!, allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: const Color(0xFF2563EB),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                            color: Colors.white, size: 24.r),
                        onPressed: _togglePlay,
                      ),
                      IconButton(
                        icon: Icon(Icons.volume_up_rounded, color: Colors.white, size: 20.r),
                        onPressed: () {},
                      ),
                      if (_videoInitialized && _videoController != null)
                        Text(
                          '${_fmtTime(_videoController!.value.position)} / ${_fmtTime(_videoController!.value.duration)}',
                          style: TextStyle(fontSize: 11.sp, color: Colors.white, fontFamily: 'Cairo'),
                        ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.settings_rounded, color: Colors.white, size: 20.r),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20.r),
                        onPressed: _toggleFullscreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (pdfUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.white),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf_rounded, size: 64.sp, color: Colors.red.shade300),
                SizedBox(height: 12.h),
                Text('PDF', style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600, fontFamily: 'Cairo')),
              ],
            ),
          ),
          Positioned(
            bottom: 16, right: 16,
            child: ElevatedButton.icon(
              onPressed: _openPdf,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('تحميل الملف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ],
      );
    }

    // No content
    return Stack(
      alignment: Alignment.center,
      children: [
        Text('🎬', style: TextStyle(fontSize: 48.sp)),
        IconButton(
          icon: Icon(Icons.play_circle_filled_rounded, size: 80.r, color: Colors.white.withValues(alpha: 0.2)),
          onPressed: () {},
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
            child: Column(
              children: [
                LinearProgressIndicator(value: (_course?.progress ?? 0) / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  color: const Color(0xFF2563EB),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 24),
                    const Spacer(),
                    Text('15:30 / 45:00',
                        style: TextStyle(fontSize: 11.sp, color: Colors.white, fontFamily: 'Cairo')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(bool isDark) {
    final content = _lesson?.content;
    return Card(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📝 ملاحظات الدرس',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Cairo')),
            SizedBox(height: 16.h),
            if (content != null && content.isNotEmpty)
              Text(content, style: TextStyle(fontSize: 13.sp, color: Colors.white.withValues(alpha: 0.8), fontFamily: 'Cairo'))
            else ...[
              _noteItem('النقاط الأساسية في هذا الدرس...'),
              _noteItem('تعريف المفهوم الأول...'),
              _noteItem('خطوات الحل: 1. ... 2. ... 3. ...'),
              _noteItem('ملاحظة مهمة: ...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _noteItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 13.sp, color: Colors.white.withValues(alpha: 0.8))),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13.sp, color: Colors.white.withValues(alpha: 0.8), fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تقييم الدرس',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Cairo')),
            SizedBox(height: 12.h),
            Row(
              children: [
                ...List.generate(5, (i) {
                  final starVal = i + 1;
                  return IconButton(
                    onPressed: _ratingLoading ? null : () => _submitRating(starVal.toDouble()),
                    icon: Icon(
                      starVal <= _myRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFBBF24),
                      size: 28.r,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 28.r, minHeight: 28.r),
                  );
                }),
                if (_ratingLoading) ...[
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  ),
                ],
              ],
            ),
            SizedBox(height: 8.h),
            Text('متوسط التقييم: ${_avgRating.toStringAsFixed(1)} ⭐ ($_totalRatings تقييم)',
                style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.6), fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التنقل بين الدروس',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Cairo')),
            SizedBox(height: 16.h),
            SizedBox(
              width: 200.w,
              child: ElevatedButton(
                onPressed: _handleComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: Text('${_completed ? '✓' : ''} إنهاء الدرس',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}