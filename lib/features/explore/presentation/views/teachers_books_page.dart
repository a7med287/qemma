import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../explore_colors.dart';
import '../../models/book.dart';
import '../../services/books_service.dart';
import 'teacher_book_details_page.dart';

class TeachersBooksPage extends StatefulWidget {
  const TeachersBooksPage({super.key});

  @override
  State<TeachersBooksPage> createState() => _TeachersBooksPageState();
}

class _TeachersBooksPageState extends State<TeachersBooksPage> {
  final _searchController = TextEditingController();
  final _service = BooksService();
  List<Book> _books = [];
  bool _loading = true;
  String _selectedSubject = 'الكل';

  final List<String> _subjects = [
    'الكل', 'الرياضيات', 'الفيزياء', 'الكيمياء', 'الأحياء',
    'اللغة العربية', 'اللغة الإنجليزية', 'التاريخ', 'الجغرافيا', 'الفلسفة',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    try {
      setState(() => _loading = true);
      final books = await _service.getBooks();
      setState(() => _books = books);
    } catch (_) {
      setState(() => _books = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Book> get _filteredBooks {
    var filtered = _books;
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text;
      filtered = filtered.where((b) =>
        b.title.contains(q) || b.teacher.name.contains(q) || b.subject.contains(q) || b.description.contains(q)
      ).toList();
    }
    if (_selectedSubject != 'الكل') {
      filtered = filtered.where((b) => b.subject == _selectedSubject).toList();
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
                        const Text('📚 كتب المدرسين', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.white)),
                        Text('ملخصات ومذكرات من أفضل مدرسي الثانوية العامة', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: Colors.white.withValues(alpha: 0.9))),
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
                            hintText: 'ابحث عن كتاب أو مدرس...',
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
                        Text('عرض ${_filteredBooks.length} كتاب', style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _loading ? _buildSkeletons(isDark) : _buildBooksList(isDark),
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
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        highlightColor: isDark ? const Color(0xFF475569) : const Color(0xFFF1F5F9),
        child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  Widget _buildBooksList(bool isDark) {
    final filtered = _filteredBooks;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('لا توجد كتب تطابق البحث', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final book = filtered[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherBookDetailsPage(bookId: book.id))),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: book.coverImage != null ? null : LinearGradient(colors: book.gradient),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: book.coverImage != null ? DecorationImage(image: NetworkImage(book.coverImage!), fit: BoxFit.cover) : null,
                  ),
                  child: Stack(
                    children: [
                      if (book.coverImage != null)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)]),
                          ),
                        ),
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(8)),
                          child: Text('${book.price} جنيه', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'Cairo', color: book.color)),
                        ),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: Text(book.subject, style: const TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.white)),
                        ),
                      ),
                      if (!book.coverImage!.isNotEmpty && book.coverImage == null)
                        const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 32)),
                      Positioned(
                        bottom: 0, right: 0, left: 0,
                        child: Text(book.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(color: book.color, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(book.teacher.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(book.description, style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.download_rounded, size: 14, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text('${(book.downloads / 1000).toStringAsFixed(1)}K', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                            const Spacer(),
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                            Text('${book.rating}', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
