import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';
import 'widgets/teacher_analytics_charts.dart';
import 'widgets/teacher_analytics_stats.dart';
import 'widgets/teacher_analytics_ai_section.dart';
import 'widgets/teacher_analytics_lesson_ratings.dart';
import 'widgets/teacher_analytics_teacher_rating.dart';

class TeacherAnalyticsView extends StatefulWidget {
  static const routeName = '/teacher/analytics';
  const TeacherAnalyticsView({super.key});

  @override
  State<TeacherAnalyticsView> createState() =>
      _TeacherAnalyticsViewState();
}

class _TeacherAnalyticsViewState extends State<TeacherAnalyticsView> {
  Map<String, dynamic>? _report;
  bool _loading = false;
  String? _error;
  String _period = 'month';

  // Course selector
  List<Map<String, dynamic>> _courses = [];
  bool _coursesLoading = false;
  String _selectedCourseId = '';

  bool _exporting = false;

  // AI Analysis
  Map<String, dynamic>? _aiAnalysis;
  bool _aiLoading = false;
  String? _aiError;

  // Ratings
  Map<String, dynamic>? _teacherRating;
  List<Map<String, dynamic>> _lessonRatings = [];
  bool _lessonRatingsLoading = false;

  static const _periods = [
    ('week', 'آخر أسبوع'),
    ('month', 'آخر شهر'),
    ('quarter', 'آخر 3 أشهر'),
    ('year', 'آخر سنة'),
  ];

  TeacherRepository get _repo => context.read<TeacherRepository>();

  @override
  void initState() {
    super.initState();
    _fetchReport();
    _fetchCourses();
    _fetchTeacherRating();
    _fetchLessonRatings();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _repo.getAnalytics(_period);
      if (!mounted) return;
      setState(() {
        _report = res;
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

  Future<void> _fetchCourses() async {
    setState(() => _coursesLoading = true);
    try {
      final courses = await _repo.getAnalyticsCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _coursesLoading = false;
        if (courses.isNotEmpty) _selectedCourseId = courses.first['id'] ?? '';
      });
    } catch (_) {
      if (mounted) setState(() => _coursesLoading = false);
    }
  }

  Future<void> _fetchTeacherRating() async {
    try {
      final rating = await _repo.getTeacherRating();
      if (mounted) setState(() => _teacherRating = rating);
    } catch (_) {}
  }

  Future<void> _fetchLessonRatings() async {
    setState(() => _lessonRatingsLoading = true);
    try {
      final meRes = await _repo.getTeacherProfile();
      final teacherId = (meRes['teacher'] as Map?)?['id'];
      if (teacherId == null) {
        if (mounted) setState(() => _lessonRatingsLoading = false);
        return;
      }
      List<Map<String, dynamic>> teacherCourses;
      try {
        teacherCourses = await _repo.getAnalyticsCourses();
      } catch (_) {
        teacherCourses = [];
      }
      if (teacherCourses.isEmpty || !mounted) {
        if (mounted) setState(() => _lessonRatingsLoading = false);
        return;
      }
      final List<Map<String, dynamic>> allLessons = [];
      for (final c in teacherCourses) {
        try {
          final courseDetail = await _repo.getCourseDetail(c['id'] ?? '');
          final lessons = (courseDetail['lessons'] as List?) ?? [];
          final courseTitle = c['title'] ?? '';
          for (final l in lessons) {
            allLessons.add({
              'id': l['id'],
              'title': l['title'],
              'courseTitle': courseTitle,
            });
          }
        } catch (_) {}
      }
      if (allLessons.isEmpty || !mounted) {
        if (mounted) setState(() => _lessonRatingsLoading = false);
        return;
      }
      final List<Map<String, dynamic>> ratings = [];
      for (final l in allLessons) {
        try {
          final rating = await _repo.getLessonRating(l['id'] ?? '');
          ratings.add({
            'id': l['id'],
            'title': l['title'],
            'courseTitle': l['courseTitle'],
            'rating': rating,
          });
        } catch (_) {
          ratings.add({
            'id': l['id'],
            'title': l['title'],
            'courseTitle': l['courseTitle'],
            'rating': null,
          });
        }
      }
      if (mounted) {
        setState(() {
          _lessonRatings = ratings;
          _lessonRatingsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _lessonRatingsLoading = false);
    }
  }

  Future<void> _handleAnalyzeWithAI() async {
    if (_selectedCourseId.isEmpty) return;
    setState(() {
      _aiLoading = true;
      _aiError = null;
      _aiAnalysis = null;
    });
    try {
      final result = await _repo.analyzeCourse(_selectedCourseId);
      if (mounted) {
        setState(() {
          _aiAnalysis = result;
          _aiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiError = e is Failure ? e.message : 'فشل تحليل الكورس. حاول مرة أخرى.';
          _aiLoading = false;
        });
      }
    }
  }

  Future<void> _handleExport() async {
    setState(() => _exporting = true);
    try {
      final result = await _repo.exportAnalytics();
      final bytes = result['bytes'] as List<int>;
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ التقرير',
        fileName: result['filename'] as String,
        bytes: Uint8List.fromList(bytes),
      );
      if (path != null && mounted) {
        buildSnackBar(context, 'تم حفظ التقرير بنجاح');
      }
    } catch (_) {
      if (mounted) buildSnackBar(context, 'فشل تصدير التقرير', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Map<String, dynamic> get _summary =>
      (_report?['summary'] as Map<String, dynamic>?) ?? {};
  List<dynamic> get _enrollmentTrend =>
      (_report?['enrollmentTrend'] as List?) ?? [];
  List<dynamic> get _scoreDist =>
      (_report?['scoreDist'] as List?) ?? [];
  List<dynamic> get _topStudents =>
      (_report?['topStudents'] as List?) ?? [];
  List<dynamic> get _coursePerformance =>
      (_report?['coursePerformance'] as List?) ?? [];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 20.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [
          Color(0xFF2563EB),
          Color(0xFF7C3AED),
          Color(0xFFDB2777)
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white12),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 44.w, height: 44.w,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  gradient: LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]),
                ),
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الإحصائيات والتحليلات',
                      style: TextStyles.bold20.copyWith(color: Colors.white)),
                  Text('تابع أداء طلابك وتحليلات شاملة',
                      style: TextStyles.regular13.copyWith(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              SizedBox(height: 12.h),
              Text(_error!, textAlign: TextAlign.center, style: TextStyles.regular14),
              SizedBox(height: 16.h),
              ElevatedButton(onPressed: _fetchReport, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReport,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.r),
        children: [
          _buildToolbar(context),
          SizedBox(height: 20.h),
          TeacherAnalyticsStats(summary: _summary),
          SizedBox(height: 20.h),
          TeacherAnalyticsCharts(
            enrollmentTrend: _enrollmentTrend,
            scoreDist: _scoreDist,
            topStudents: _topStudents,
            coursePerformance: _coursePerformance,
            summary: _summary,
          ),
          SizedBox(height: 20.h),
          TeacherAnalyticsAiSection(
            analysis: _aiAnalysis ?? {},
            courseTitle: _courses.firstWhere(
              (c) => c['id'] == _selectedCourseId,
              orElse: () => <String, dynamic>{},
            )['title'] ?? '',
            isLoading: _aiLoading,
            error: _aiError,
            onDismissError: () => setState(() => _aiError = null),
          ),
          SizedBox(height: 20.h),
          TeacherAnalyticsLessonRatings(
            ratings: _lessonRatings,
            isLoading: _lessonRatingsLoading,
          ),
          SizedBox(height: 20.h),
          TeacherAnalyticsTeacherRating(rating: _teacherRating),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (_coursesLoading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCourseId.isNotEmpty ? _selectedCourseId : null,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      hint: Text('اختر الكورس',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E)),
                      items: _courses.map((c) => DropdownMenuItem<String>(
                        value: (c['id'] ?? '') as String,
                        child: Text((c['title'] ?? '') as String, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedCourseId = v;
                            _aiAnalysis = null;
                            _aiError = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
              SizedBox(width: 8.w),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.r),
                    onTap: (_selectedCourseId.isEmpty || _aiLoading) ? null : _handleAnalyzeWithAI,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _aiLoading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                              : const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                          SizedBox(width: 4.w),
                          Text(_aiLoading ? 'جارٍ التحليل...' : 'تحليل AI',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _period,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E)),
                    items: _periods.map((p) => DropdownMenuItem(value: p.$1, child: Text(p.$2))).toList(),
                    onChanged: (v) => setState(() => _period = v ?? 'month'),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              OutlinedButton.icon(
                onPressed: _exporting ? null : _handleExport,
                icon: _exporting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
                    : const Icon(Icons.download, size: 16),
                label: Text(_exporting ? 'جارٍ التصدير...' : 'تصدير',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11.sp)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFFF1F5F9) : null,
                  side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }
}
