import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../explore_colors.dart';
import '../../explore_image_helper.dart';
import '../../services/books_service.dart';
import 'widgets/info_card.dart';
import 'widgets/info_row.dart';
import 'teacher_profile_page.dart';

class TeacherBookDetailsPage extends StatefulWidget {
  final String bookId;
  const TeacherBookDetailsPage({super.key, required this.bookId});

  @override
  State<TeacherBookDetailsPage> createState() => _TeacherBookDetailsPageState();
}

class _TeacherBookDetailsPageState extends State<TeacherBookDetailsPage> {
  final _service = BooksService();
  Map<String, dynamic>? _book;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBook();
  }

  Future<void> _fetchBook() async {
    try {
      setState(() => _loading = true);
      final data = await _service.getBook(widget.bookId);
      setState(() => _book = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _getColor() {
    final subject = _book?['subject'] as String? ?? '';
    final style = ExploreColors.subjectColors[subject];
    return style != null ? Color(style.color) : ExploreColors.primary;
  }

  Widget _buildCoverFallback() {
    return Container(
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 48),
    );
  }

  List<Color> _getGradient() {
    final subject = _book?['subject'] as String? ?? '';
    final style = ExploreColors.subjectColors[subject];
    return style?.gradient ?? ExploreColors.blueGradient;
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
              Container(height: 300, color: Colors.white),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(3, (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(height: 100, width: double.infinity, color: Colors.white),
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
          const Text('📚', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text('الكتاب غير موجود', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: ExploreColors.primary),
            child: const Text('العودة للكتب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final b = _book!;
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 100,
                        height: 130,
                        child: b['coverImage'] != null
                            ? ExploreImage(
                                imageUrl: b['coverImage'],
                                fit: BoxFit.cover,
                                fallback: _buildCoverFallback(),
                              )
                            : _buildCoverFallback(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                            child: Text(b['subject'] ?? '', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.white)),
                          ),
                          const SizedBox(height: 8),
                          Text(b['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                          const SizedBox(height: 8),
                          Text(b['description'] ?? '', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.9))),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherProfilePage(teacherId: '${b['teacherId']}'))),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(b['teacherName'] ?? 'مدرس', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: Colors.white)),
                                  const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                        Text('${b['price'] ?? 0} جنيه', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: _getColor())),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InfoCard(isDark: isDark, title: '📖 عن الكتاب', titleFontSize: 16, titleFontWeight: FontWeight.w800, children: [
                    Text(b['description'] ?? 'لا يوجد وصف متاح', style: TextStyle(fontFamily: 'Cairo', height: 2, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  ]),
                  InfoCard(isDark: isDark, title: '📋 معلومات الكتاب', titleFontSize: 16, titleFontWeight: FontWeight.w800, children: [
                    InfoRow(icon: Icons.folder_rounded, label: 'المادة', value: b['subject'] ?? 'غير محدد', isDark: isDark),
                    const Divider(),
                    InfoRow(icon: Icons.update_rounded, label: 'آخر تحديث', value: b['updatedAt']?.toString() ?? 'غير محدد', isDark: isDark),
                    const Divider(),
                    InfoRow(icon: Icons.school_rounded, label: 'المستوى', value: b['grade'] ?? 'عام', isDark: isDark),
                  ]),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherProfilePage(teacherId: '${b['teacherId']}'))),
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('👨‍🏫 المدرس', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                              const Icon(Icons.chevron_left_rounded),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: _getColor(),
                                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 12),
                              Text(b['teacherName'] ?? 'مدرس', style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherProfilePage(teacherId: '${b['teacherId']}'))),
                              icon: const Icon(Icons.chevron_left_rounded),
                              label: const Text('عرض صفحة المدرس', style: TextStyle(fontFamily: 'Cairo')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _getColor(),
                                side: BorderSide(color: _getColor()),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
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
        ],
      ),
    );
  }
}
