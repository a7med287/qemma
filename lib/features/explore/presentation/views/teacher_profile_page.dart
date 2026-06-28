import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../explore_colors.dart';
import '../../models/teacher.dart';
import '../../services/api_service.dart';
import '../../services/courses_service.dart';
import 'course_details_page.dart';
import 'teacher_book_details_page.dart';

class TeacherProfilePage extends StatefulWidget {
  final String teacherId;
  const TeacherProfilePage({super.key, required this.teacherId});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage>
    with SingleTickerProviderStateMixin {
  final _service = CoursesService();
  final _api = ApiService();
  late TabController _tabController;
  int _activeTab = 0;

  Teacher? _teacher;
  bool _loading = true;
  String? _error;

  // Rating state
  Map<String, dynamic>? _teacherRatingData;
  double _userRating = 0;
  String _ratingComment = '';
  bool _submittingRating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
    _fetchTeacher();
  }

  Future<void> _fetchTeacher() async {
    try {
      setState(() => _loading = true);
      final data = await _service.getTeacherProfile(widget.teacherId);
      final t = Teacher.fromJson(data);
      setState(() => _teacher = t);
      _fetchRating(t.teacherId);
      _fetchItemRatings(t);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchRating(String teacherId) async {
    try {
      final res = await _api.get('/students/rate/teacher/$teacherId');
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        setState(() => _teacherRatingData = data);
        if (data['myRating'] != null) {
          setState(() => _userRating = (data['myRating']['rating'] as num?)?.toDouble() ?? 0);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchItemRatings(Teacher t) async {
    for (int i = 0; i < t.courses.length; i++) {
      try {
        final res = await _api.get('/students/rate/course/${t.courses[i].id}');
        final data = res['data'] as Map<String, dynamic>?;
        if (data != null && data['averageRating'] != null) {
          t.courses[i].rating = (data['averageRating'] as num).toDouble();
        }
      } catch (_) {}
    }
    for (int i = 0; i < t.books.length; i++) {
      try {
        final res = await _api.get('/students/rate/book/${t.books[i].id}');
        final data = res['data'] as Map<String, dynamic>?;
        if (data != null && data['averageRating'] != null) {
          t.books[i].rating = (data['averageRating'] as num).toDouble();
        }
      } catch (_) {}
    }
    setState(() {});
  }

  Future<void> _submitRating() async {
    if (_userRating == 0) return;
    setState(() => _submittingRating = true);
    try {
      await _api.post(
        '/students/rate/teacher/${_teacher!.teacherId}',
        body: {'rating': _userRating, 'comment': _ratingComment},
      );
      _fetchRating(_teacher!.teacherId);
      setState(() {
        _userRating = 0;
        _ratingComment = '';
      });
    } catch (_) {}
    setState(() => _submittingRating = false);
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      body: _loading
          ? _buildSkeleton(isDark)
          : _error != null || _teacher == null
              ? _buildError(isDark)
              : _buildContent(isDark),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        highlightColor: isDark ? const Color(0xFF475569) : const Color(0xFFF1F5F9),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(height: 280, color: Colors.white),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 48, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👨‍🏫', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(
            _error ?? 'المدرس غير موجود',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ExploreColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('العودة',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MAIN CONTENT
  // ─────────────────────────────────────────────────────────────

  Widget _buildContent(bool isDark) {
    final t = _teacher!;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(isDark, t),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                _buildTabsCard(isDark, t),
                const SizedBox(height: 16),
                _buildContactSection(isDark, t),
                if (t.yearsOfExperience > 0) ...[
                  const SizedBox(height: 16),
                  _buildStatsSection(isDark, t),
                ],
                const SizedBox(height: 16),
                _buildBadgeSection(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, Teacher t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: ExploreColors.mainGradient),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: -20,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 24, offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF6366F1),
                        backgroundImage: t.avatar != null
                            ? NetworkImage(t.avatar!)
                            : null,
                        child: t.avatar == null
                            ? const Icon(Icons.person_rounded, color: Colors.white, size: 60)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                t.name,
                                style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo', color: Colors.white,
                                ),
                              ),
                            ),
                            if (t.verified)
                              const Icon(Icons.verified_rounded,
                                  color: Color(0xFFFBBF24), size: 28),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.title} • ${t.specialization}',
                          style: TextStyle(
                            fontSize: 14, fontFamily: 'Cairo',
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          children: [
                            _headerStat(Icons.star_rounded, const Color(0xFFFBBF24),
                                t.rating.toStringAsFixed(1),
                                t.reviewsCount > 0 ? '(${t.reviewsCount} تقييم)' : null),
                            _headerStat(Icons.people_rounded, null,
                                _formatNum(t.studentsCount), 'طالب'),
                            _headerStat(Icons.school_rounded, null,
                                '${t.coursesCount}', 'كورسات'),
                            _headerStat(Icons.menu_book_rounded, null,
                                '${t.booksCount}', 'كتب'),
                            if (t.yearsOfExperience > 0)
                              _headerStat(Icons.calendar_today_rounded, null,
                                  '${t.yearsOfExperience}', 'سنة خبرة'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(IconData icon, Color? iconColor, String value, String? label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor ?? Colors.white70),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700,
            fontFamily: 'Cairo', color: Colors.white,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12, fontFamily: 'Cairo',
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  // ─────────────────────────────────────────────────────────────
  // TABS CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildTabsCard(bool isDark, Teacher t) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: ExploreColors.primary,
            labelColor: ExploreColors.primary,
            unselectedLabelColor: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
            labelStyle: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'نبذة عني'),
              Tab(text: 'الكورسات'),
              Tab(text: 'الكتب'),
              Tab(text: 'التقييمات'),
            ],
          ),
          if (_activeTab == 0)
            _buildAboutTab(isDark, t)
          else if (_activeTab == 1)
            _buildCoursesTab(isDark, t)
          else if (_activeTab == 2)
            _buildBooksTab(isDark, t)
          else
            _buildReviewsTab(isDark, t),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ABOUT TAB
  // ─────────────────────────────────────────────────────────────

  Widget _buildAboutTab(bool isDark, Teacher t) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عن المدرس',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.bio,
            style: TextStyle(
              fontFamily: 'Cairo', height: 2, fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),

          if (t.qualifications.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'المؤهلات',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            ...t.qualifications.map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: Color(0xFF059669)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q,
                      style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 13,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],

          if (t.achievements.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'الإنجازات',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            ...t.achievements.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      size: 18, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      a,
                      style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 13,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],

          if (t.subjects.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'المواد التي أدرسها',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: t.subjects.map((s) => Chip(
                label: Text(s, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                labelStyle: TextStyle(
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                ),
                side: BorderSide.none,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COURSES TAB
  // ─────────────────────────────────────────────────────────────

  Widget _buildCoursesTab(bool isDark, Teacher t) {
    if (t.courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'لا توجد كورسات متاحة حالياً',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'كورسات المدرس (${t.courses.length})',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ...t.courses.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildCourseItem(isDark, c),
          )),
        ],
      ),
    );
  }

  Widget _buildCourseItem(bool isDark, TeacherCourse c) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDetailsPage(courseId: c.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _courseMeta(Icons.star_rounded, const Color(0xFFFBBF24),
                          c.rating.toStringAsFixed(1), isDark),
                      const SizedBox(width: 16),
                      _courseMeta(Icons.people_rounded, null,
                          '${c.students} طالب', isDark),
                      if (c.category.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            c.category,
                            style: TextStyle(
                              fontSize: 10, fontFamily: 'Cairo',
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${c.price} جنيه',
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900,
                fontFamily: 'Cairo', color: ExploreColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseMeta(IconData icon, Color? iconColor, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor ??
            (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11, fontFamily: 'Cairo',
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BOOKS TAB
  // ─────────────────────────────────────────────────────────────

  Widget _buildBooksTab(bool isDark, Teacher t) {
    if (t.books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'لا توجد كتب متاحة حالياً',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'كتب المدرس (${t.books.length})',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ...t.books.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildBookItem(isDark, b),
          )),
        ],
      ),
    );
  }

  Widget _buildBookItem(bool isDark, TeacherBook b) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherBookDetailsPage(bookId: b.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _courseMeta(Icons.star_rounded, const Color(0xFFFBBF24),
                          b.rating.toStringAsFixed(1), isDark),
                      const SizedBox(width: 16),
                      _courseMeta(Icons.play_circle_outline_rounded, null,
                          '${b.downloads} تحميل', isDark),
                      if (b.subject.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            b.subject,
                            style: TextStyle(
                              fontSize: 10, fontFamily: 'Cairo',
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${b.price} جنيه',
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900,
                fontFamily: 'Cairo', color: ExploreColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // REVIEWS TAB
  // ─────────────────────────────────────────────────────────────

  Widget _buildReviewsTab(bool isDark, Teacher t) {
    final avgRating = (_teacherRatingData?['averageRating'] as num?)?.toDouble() ?? 0;
    final totalRatings = (_teacherRatingData?['totalRatings'] as num?)?.toInt() ?? 0;
    final reviews = (_teacherRatingData?['reviews'] as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Average rating
          Row(
            children: [
              Column(
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                    ),
                  ),
                  _buildRatingStars(avgRating, 20),
                  Text(
                    '($totalRatings تقييم)',
                    style: TextStyle(
                      fontSize: 11, fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Submit rating
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تقييمك للمدرس',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildRatingInput(),
                    if (_userRating > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${_userRating.toInt()} / 5',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'أكتب تعليقك (اختياري)',
                    hintStyle: TextStyle(
                      fontFamily: 'Cairo', fontSize: 13,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 13,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                  ),
                  onChanged: (v) => _ratingComment = v,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_userRating == 0 || _submittingRating)
                        ? null
                        : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ExploreColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE5E7EB),
                      disabledForegroundColor: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _submittingRating
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'إرسال التقييم',
                            style: TextStyle(
                              fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reviews list
          Text(
            'تقييمات الطلاب (${reviews.length})',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'لا توجد تقييمات متاحة حالياً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...reviews.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildReviewItem(isDark, r),
            )),
        ],
      ),
    );
  }

  Widget _buildReviewItem(bool isDark, dynamic r) {
    final rating = (r['rating'] as num?)?.toDouble() ?? 0;
    final studentName = r['studentName'] as String? ?? '';
    final comment = r['comment'] as String? ?? '';
    final createdAt = r['createdAt'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      ),
                    ),
                    if (createdAt.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        createdAt,
                        style: TextStyle(
                          fontSize: 11, fontFamily: 'Cairo',
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildRatingStars(rating, 14),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SIDEBAR CARDS
  // ─────────────────────────────────────────────────────────────

  Widget _buildContactSection(bool isDark, Teacher t) {
    if (t.contact.email.isEmpty && t.contact.phone.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات التواصل',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (t.contact.email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.email_rounded, size: 20,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  const SizedBox(width: 10),
                  Text(
                    t.contact.email,
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          if (t.contact.phone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.phone_rounded, size: 20,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  const SizedBox(width: 10),
                  Text(
                    t.contact.phone,
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isDark, Teacher t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات المدرس',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          _statProgress(isDark, 'معدل الإتمام', t.stats.completionRate,
              ExploreColors.primary),
          const SizedBox(height: 16),
          _statProgress(isDark, 'رضا الطلاب', t.stats.satisfaction,
              ExploreColors.success),
        ],
      ),
    );
  }

  Widget _statProgress(bool isDark, String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            Text(
              '$value%',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100.0,
            minHeight: 8,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      size: 48, color: Colors.white),
                const SizedBox(height: 8),
                const Text(
                  'مدرس معتمد',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo', color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'هذا المدرس معتمد من منصة قِمّة ويتمتع بسجل حافل من النجاحات مع الطلاب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RATING STARS HELPERS
  // ─────────────────────────────────────────────────────────────

  Widget _buildRatingStars(double rating, double size) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final fill = rating - i;
          return Icon(
            fill >= 1 ? Icons.star_rounded
                : fill >= 0.25 ? Icons.star_half_rounded
                : Icons.star_border_rounded,
            size: size,
            color: const Color(0xFFFBBF24),
          );
        }),
      ),
    );
  }

  Widget _buildRatingInput() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final starVal = (i + 1).toDouble();
          return GestureDetector(
            onTap: () => setState(() => _userRating = starVal),
            child: Icon(
              _userRating >= starVal
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 32,
              color: const Color(0xFFFBBF24),
            ),
          );
        }),
      ),
    );
  }
}
