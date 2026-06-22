import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/helpers/build_context_extensions.dart';
import '../explore_colors.dart';
import '../services/courses_service.dart';
import 'teacher_profile_page.dart';

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
              Container(height: 300, color: Colors.white),
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

  Color _getColor() {
    if (_course?['color'] != null) return Color(_course!['color']);
    return ExploreColors.primary;
  }

  List<Color> _getGradient() {
    final category = _course?['category'] as String? ?? '';
    final style = ExploreColors.subjectColors[category];
    return style?.gradient ?? ExploreColors.blueGradient;
  }

  Widget _buildContent(bool isDark) {
    final c = _course!;
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 64),
            decoration: BoxDecoration(gradient: LinearGradient(colors: _getGradient())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                  child: Text(c['category'] ?? '', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.white)),
                ),
                const SizedBox(height: 12),
                Text(c['title'] ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                const SizedBox(height: 12),
                if (c['description'] != null)
                  Text(c['description'], style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.95))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeaderStat(icon: Icons.people_rounded, text: '${c['stats']?['enrollments'] ?? 0} طالب'),
                    const SizedBox(width: 24),
                    _HeaderStat(icon: Icons.access_time_rounded, text: '${c['duration'] ?? 0} ساعة'),
                    const SizedBox(width: 24),
                    _HeaderStat(icon: Icons.play_circle_outline_rounded, text: '${c['stats']?['lessons'] ?? 0} درس'),
                  ],
                ),
                const SizedBox(height: 16),
                if (c['teacher'] != null)
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherProfilePage(teacherId: c['teacher']['id'].toString()))),
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
                          Expanded(child: Text(c['teacher']['name'] ?? 'مدرس', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: Colors.white))),
                          const Icon(Icons.chevron_left_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Transform.translate(
              offset: const Offset(0, -32),
              child: Column(
                children: [
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
                    ),
                    child: Column(
                      children: [
                        Text('${c['price'] ?? 0} جنيه', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: _getColor())),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.shopping_cart_rounded),
                            label: const Text('اشتري الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getColor(),
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
                  const SizedBox(height: 16),
                  if ((c['prerequisites'] as List?)?.isNotEmpty ?? false)
                    _InfoCard(isDark: isDark, title: 'المتطلبات', children: (c['prerequisites'] as List).map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: _getColor())),
                        const SizedBox(width: 12),
                        Text(p.toString(), style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      ]),
                    )).toList()),
                  if ((c['lessons'] as List?)?.isNotEmpty ?? false)
                    _InfoCard(isDark: isDark, title: 'محتوى الكورس', children: [
                      ...(c['lessons'] as List).asMap().entries.map((entry) {
                        final i = entry.value;
                        final isFree = entry.key < 2;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(isFree ? Icons.play_arrow_rounded : Icons.lock_rounded, size: 20, color: isFree ? ExploreColors.success : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(child: Text(i['title'] ?? '', style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569)))),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeaderStat({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white)),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.isDark, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
