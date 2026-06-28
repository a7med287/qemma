import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../explore_colors.dart';
import '../../services/courses_service.dart';
import 'teacher_profile_page.dart';
import 'checkout_page.dart';

class CourseDetailsPage extends StatefulWidget {
  final String courseId;
  const CourseDetailsPage({super.key, required this.courseId});

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  final _service = CoursesService();
  Map<String, dynamic>? _course;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourse();
  }

  Future<void> _fetchCourse() async {
    try {
      setState(() => _loading = true);
      final data = await _service.getCourse(widget.courseId);
      setState(() => _course = data);
    } catch (_) {
      setState(() => _course = null);
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _getColor() {
    final category = _course?['category'] as String? ?? '';
    final style = ExploreColors.subjectColors[category];
    return style != null ? Color(style.color) : ExploreColors.primary;
  }

  List<Color> _getGradient() {
    final category = _course?['category'] as String? ?? '';
    final style = ExploreColors.subjectColors[category];
    return style?.gradient ?? ExploreColors.blueGradient;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      body: _loading ? _buildSkeleton(isDark) : _course == null ? _buildError(isDark) : _buildContent(isDark),
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
                  children: List.generate(4, (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(height: 120, width: double.infinity, color: Colors.white),
                  )),
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
          const Text('🎓', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text('الكورس غير موجود', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: ExploreColors.primary),
            child: const Text('العودة للكورسات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final c = _course!;
    final gradient = _getGradient();
    final color = _getColor();
    final lessons = (c['lessons'] as List<dynamic>?) ?? [];
    final prerequisites = (c['prerequisites'] as List<dynamic>?) ?? [];
    final teacher = c['teacher'] as Map<String, dynamic>?;
    final stats = c['stats'] as Map<String, dynamic>?;
    final lessonsCount = stats?['lessons'] ?? lessons.length;
    final studentsCount = stats?['enrollments'] ?? 0;
    final duration = c['duration'];
    final durationText = duration != null ? '$duration ساعة' : '';

    return SingleChildScrollView(
      child: Column(
        children: [
          // ═══ HEADER ═══
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 64),
            decoration: BoxDecoration(gradient: LinearGradient(colors: gradient)),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(top: -50, right: -50, child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)))),
                Positioned(bottom: -80, left: -80, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ),
                    const SizedBox(height: 16),
                    // Subject badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                      child: Text(c['category'] ?? '', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(c['title'] ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                    const SizedBox(height: 12),
                    // Description
                    if (c['description'] != null)
                      Text(c['description'], style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.95))),
                    const SizedBox(height: 16),
                    // Stats row
                    Row(
                      children: [
                        _headerStat(Icons.people_rounded, '$studentsCount طالب', Colors.white),
                        const SizedBox(width: 24),
                        _headerStat(Icons.access_time_rounded, durationText, Colors.white),
                        const SizedBox(width: 24),
                        _headerStat(Icons.play_circle_outline_rounded, '$lessonsCount درس', Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Teacher info (clickable)
                    if (teacher != null)
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherProfilePage(teacherId: teacher['id'].toString()))),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                child: const Icon(Icons.person_rounded, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('المدرس', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.8))),
                                    Text(teacher['user']?['name'] ?? teacher['name'] ?? 'مدرس', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: Colors.white)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_left_rounded, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Price card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text('${c['price'] ?? 0} جنيه', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: color)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(
                                itemId: c['id'].toString(),
                                itemType: 'course',
                                itemTitle: c['title'] as String? ?? '',
                                itemSubject: c['category'] as String? ?? '',
                                itemPrice: (c['price'] as num?)?.toDouble() ?? 0,
                                teacherName: teacher?['user']?['name'] as String? ?? teacher?['name'] as String? ?? 'مدرس',
                                itemColor: color,
                                itemGradient: gradient,
                              ))),
                              icon: const Icon(Icons.shopping_cart_rounded),
                              label: const Text('اشتري الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('ضمان استرجاع المال خلال 30 يوم', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ═══ CONTENT ═══
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prerequisites
                if (prerequisites.isNotEmpty)
                  _infoCard(isDark, 'المتطلبات', [
                    ...prerequisites.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(p.toString(), style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))),
                      ]),
                    )),
                  ]),
                // Curriculum
                if (lessons.isNotEmpty)
                  _infoCard(isDark, 'محتوى الكورس', [
                    ...lessons.asMap().entries.map((entry) {
                      final lesson = entry.value as Map<String, dynamic>;
                      final isFree = entry.key < 2;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(isFree ? Icons.play_arrow_rounded : Icons.lock_rounded, size: 20, color: isFree ? ExploreColors.success : Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(child: Text(lesson['title'] ?? '', style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569)))),
                            if (isFree)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: ExploreColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Text('مجاني', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: ExploreColors.success)),
                              ),
                          ],
                        ),
                      );
                    }),
                  ]),
                // Teacher profile card
                if (teacher != null)
                  _teacherCard(isDark, teacher, color, gradient),
                // Course stats card
                _statsCard(isDark, c, color),
                // Course rating section
                _ratingSection(isDark, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: color)),
      ],
    );
  }

  Widget _infoCard(bool isDark, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(gradient: LinearGradient(colors: _getGradient()), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                    Text('${(_course?['stats']?['lessons'] ?? 0)} درس', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _teacherCard(bool isDark, Map<String, dynamic> teacher, Color color, List<Color> gradient) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: LinearGradient(colors: gradient)),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(teacher['user']?['name'] ?? teacher['name'] ?? 'مدرس', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherProfilePage(teacherId: teacher['id'].toString()))),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('الملف الشخصي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(bool isDark, Map<String, dynamic> c, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إحصائيات الكورس', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _statRow(Icons.trending_up_rounded, 'المستوى', c['level'] ?? '', color, isDark),
          const SizedBox(height: 8),
          _statRow(Icons.school_rounded, 'المادة', c['category'] ?? '', color, isDark),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _ratingSection(bool isDark, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تقييم الكورس', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(5, (i) => Icon(Icons.star_rounded, size: 28, color: const Color(0xFFFBBF24))),
            ],
          ),
          const SizedBox(height: 8),
          Text('0.0 ⭐ (0 تقييم)', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ],
      ),
    );
  }
}
