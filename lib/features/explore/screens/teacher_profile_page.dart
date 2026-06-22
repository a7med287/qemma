import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/helpers/build_context_extensions.dart';
import '../explore_colors.dart';
import '../models/teacher.dart';
import '../services/courses_service.dart';
import 'course_details_page.dart';
import 'teacher_book_details_page.dart';

class TeacherProfilePage extends StatefulWidget {
  final String teacherId;
  const TeacherProfilePage({super.key, required this.teacherId});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> with SingleTickerProviderStateMixin {
  final _service = CoursesService();
  Teacher? _teacher;
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchTeacher();
  }

  Future<void> _fetchTeacher() async {
    try {
      setState(() => _loading = true);
      final data = await _service.getTeacherProfile(widget.teacherId);
      setState(() => _teacher = Teacher.fromJson(data));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      body: _loading ? _buildSkeleton(isDark) : (_error != null ? _buildError(isDark) : _buildContent(isDark)),
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
              // Matches the real header's expandedHeight (280) so the
              // shimmer doesn't visibly "jump" once content loads.
              Container(height: 280, color: Colors.white),
              Container(height: 48, color: isDark ? const Color(0xFF1E293B) : Colors.white),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(height: 400, width: double.infinity, color: Colors.white),
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
          Text('المدرس غير موجود', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ExploreColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('العودة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final t = _teacher!;
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 280,
          floating: false,
          pinned: true,
          // Anchors the toolbar color to the gradient's leading color so the
          // collapse transition doesn't flash to a mismatched default color.
          backgroundColor: ExploreColors.mainGradient.first,
          foregroundColor: Colors.white,
          elevation: 0,
          // The back button now lives in `leading`, which Flutter keeps
          // pinned to the toolbar at all times. Previously it was drawn
          // inside `flexibleSpace.background`, so it scrolled away and
          // disappeared as soon as the user scrolled down — leaving no way
          // to navigate back.
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: ExploreColors.mainGradient)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFF6366F1),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(child: Text(t.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white))),
                                if (t.verified) const Icon(Icons.verified_rounded, color: Color(0xFFFBBF24), size: 24),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(t.title, style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.95))),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                _StatChip(icon: Icons.star_rounded, iconColor: const Color(0xFFFBBF24), text: '${t.rating}'),
                                _StatChip(icon: Icons.people_rounded, text: '${t.studentsCount} طالب'),
                                _StatChip(icon: Icons.school_rounded, text: '${t.coursesCount} كورسات'),
                                _StatChip(icon: Icons.menu_book_rounded, text: '${t.booksCount} كتب'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Previously this wrapped the TabBar inside a full AppBar (set as
          // its `title`), which forces the tabs into a centered 56dp title
          // slot they don't fit — causing clipped/squished tabs instead of
          // a clean 48dp tab strip. A PreferredSize + TabBar is the correct
          // way to pin a tab bar under a SliverAppBar.
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: ExploreColors.primary,
                labelColor: ExploreColors.primary,
                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'نبذة عني'),
                  Tab(text: 'الكورسات'),
                  Tab(text: 'الكتب'),
                  Tab(text: 'التقييمات'),
                ],
              ),
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAboutTab(isDark, t),
          _buildCoursesTab(isDark, t),
          _buildBooksTab(isDark, t),
          _buildReviewsTab(isDark, t),
        ],
      ),
    );
  }

  Widget _buildAboutTab(bool isDark, Teacher t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('عن المدرس', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Text(t.bio, style: TextStyle(fontFamily: 'Cairo', height: 2, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                if (t.subjects.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('المواد التي أدرسها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: t.subjects.map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569)),
                      // Material3's default Chip draws an outline border,
                      // which looked like an unintended extra ring around
                      // these flat, filled tags.
                      side: BorderSide.none,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (t.contact.email.isNotEmpty || t.contact.phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('معلومات التواصل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  if (t.contact.email.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Icon(Icons.email_rounded, size: 18, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Text(t.contact.email, style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      ]),
                    ),
                  if (t.contact.phone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Icon(Icons.phone_rounded, size: 18, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Text(t.contact.phone, style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      ]),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoursesTab(bool isDark, Teacher t) {
    return t.courses.isEmpty
        ? Center(child: Text('لا توجد كورسات متاحة حالياً', style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: t.courses.length,
      itemBuilder: (context, index) {
        final c = t.courses[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailsPage(courseId: c.id))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
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
                        style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: const Color(0xFFFBBF24)),
                          Text('${c.rating}', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          const SizedBox(width: 16),
                          Icon(Icons.people_rounded, size: 16, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          Text('${c.students} طالب', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('${c.price} جنيه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: ExploreColors.primary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBooksTab(bool isDark, Teacher t) {
    return t.books.isEmpty
        ? Center(child: Text('لا توجد كتب متاحة حالياً', style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: t.books.length,
      itemBuilder: (context, index) {
        final b = t.books[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherBookDetailsPage(bookId: b.id))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
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
                        style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: const Color(0xFFFBBF24)),
                          Text('${b.rating}', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          const SizedBox(width: 16),
                          Icon(Icons.download_rounded, size: 16, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          Text('${b.downloads} تحميل', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('${b.price} جنيه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: ExploreColors.secondary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(bool isDark, Teacher t) {
    return t.reviews.isEmpty
        ? Center(child: Text('لا توجد تقييمات متاحة حالياً', style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: t.reviews.length,
      itemBuilder: (context, index) {
        final r = t.reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      r.studentName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) => Icon(
                      i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 16, color: const Color(0xFFFBBF24),
                    )),
                  ),
                ],
              ),
              if (r.date.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(r.date, style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              ],
              if (r.comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(r.comment, style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;
  const _StatChip({required this.icon, this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? Colors.white),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, fontFamily: 'Cairo', color: Colors.white)),
      ],
    );
  }
}