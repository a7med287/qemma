import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../explore_colors.dart';
import '../../models/course.dart';
import '../../services/courses_service.dart';
import 'course_details_page.dart';
import 'teacher_profile_page.dart';
import 'checkout_page.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final _searchController = TextEditingController();
  final _coursesService = CoursesService();
  List<Course> _courses = [];
  bool _loading = true;
  String _selectedSubject = 'الكل';

  final List<String> _subjects = [
    'الكل', 'الرياضيات', 'الفيزياء', 'الكيمياء', 'الأحياء',
    'اللغة العربية', 'اللغة الإنجليزية', 'التاريخ', 'الجغرافيا', 'الفلسفة',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      setState(() => _loading = true);
      final courses = await _coursesService.getPublishedCourses();
      setState(() => _courses = courses);
    } catch (_) {
      setState(() => _courses = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Course> get _filteredCourses {
    var filtered = _courses;
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text;
      filtered = filtered.where((c) =>
      c.title.contains(q) || c.teacher.name.contains(q) || c.subject.contains(q) || c.description.contains(q)
      ).toList();
    }
    if (_selectedSubject != 'الكل') {
      filtered = filtered.where((c) => c.subject == _selectedSubject).toList();
    }
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: ExploreColors.mainGradient)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الكورسات التعليمية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                        Text('دروس مشروحة بالفيديو مع أفضل المدرسين في كل المواد', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن كورس أو مدرس...',
                            hintStyle: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _subjects.map((s) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text(s, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                                selected: _selectedSubject == s,
                                onSelected: (_) => setState(() => _selectedSubject = s),
                                selectedColor: ExploreColors.primary.withValues(alpha: 0.2),
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                labelStyle: TextStyle(color: _selectedSubject == s ? ExploreColors.primary : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569))),
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          _loading ? 'جاري التحميل...' : 'عرض ${_filteredCourses.length} كورس',
                          style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _loading ? _buildSkeletons(isDark) : _buildCoursesList(isDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletons(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          highlightColor: isDark ? const Color(0xFF475569) : const Color(0xFFF1F5F9),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Container(height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(14)))),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(width: 28, height: 28, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 14, color: Colors.white)),
                      ]),
                      const SizedBox(height: 8),
                      Container(height: 10, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 6),
                      Row(children: List.generate(3, (_) => Expanded(child: Column(children: [
                        Container(height: 16, width: 30, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(height: 10, width: 24, color: Colors.white),
                      ])))),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: Container(height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
                        const SizedBox(width: 10),
                        Expanded(child: Container(height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesList(bool isDark) {
    final filtered = _filteredCourses;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎓', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('لا توجد كورسات تطابق البحث', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final course = filtered[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + index * 50),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Opacity(opacity: value, child: _courseCard(course: course, isDark: isDark)),
          ),
        );
      },
    );
  }

  Widget _courseCard({required Course course, required bool isDark}) {
    final studentsText = course.studentsCount > 999
        ? '${(course.studentsCount / 1000).toStringAsFixed(1)}k'
        : '${course.studentsCount}';
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailsPage(courseId: course.id))),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // --- Taller Gradient Header ---
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: LinearGradient(colors: course.gradient)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(course.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (course.level.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                                    child: Text(course.level, style: const TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.white)),
                                  ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                                  child: Text(course.subject, style: const TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text('${course.price} جنيه', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                  ),
                  if (course.oldPrice > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('${course.oldPrice} جنيه', style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, fontFamily: 'Cairo', color: Colors.white70)),
                    ),
                ],
              ),
            ),
            // --- Body ---
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Teacher row with rating
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherProfilePage(teacherId: course.teacher.id))),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: course.color,
                          child: course.teacher.avatar != null
                              ? ClipOval(child: Image.network(course.teacher.avatar!, fit: BoxFit.cover, width: 28, height: 28, errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white, size: 16)))
                              : const Icon(Icons.person_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course.teacher.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (course.rating > 0)
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded, size: 14, color: const Color(0xFFFBBF24)),
                                    const SizedBox(width: 2),
                                    Text(course.rating.toStringAsFixed(1), style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(course.description, style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  // Stats row
                  Row(
                    children: [
                      _miniStat(Icons.play_circle_outline_rounded, '${course.lessonsCount}', 'درس', isDark),
                      const Spacer(),
                      _miniStat(Icons.access_time_rounded, course.duration, 'مدة', isDark),
                      const Spacer(),
                      _miniStat(Icons.people_rounded, studentsText, 'طالب', isDark),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailsPage(courseId: course.id))),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: course.color,
                            side: BorderSide(color: course.color),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          child: const Text('التفاصيل'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: course.gradient),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(
                              itemId: course.id,
                              itemType: 'course',
                              itemTitle: course.title,
                              itemSubject: course.subject,
                              itemPrice: course.price,
                              teacherName: course.teacher.name,
                              itemColor: course.color,
                              itemGradient: course.gradient,
                            ))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            child: const Text('اشترك الآن'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 9, fontFamily: 'Cairo', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
      ],
    );
  }
}
