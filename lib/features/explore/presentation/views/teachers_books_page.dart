import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../explore_colors.dart';
import '../../explore_image_helper.dart';
import '../../models/book.dart';
import '../../services/api_service.dart';
import '../../services/books_service.dart';
import 'checkout_page.dart';
import 'teacher_book_details_page.dart';
import 'teacher_profile_page.dart';

class TeachersBooksPage extends StatefulWidget {
  const TeachersBooksPage({super.key});

  @override
  State<TeachersBooksPage> createState() => _TeachersBooksPageState();
}

class _TeachersBooksPageState extends State<TeachersBooksPage> {
  final _searchController = TextEditingController();
  final _service = BooksService();
  final _api = ApiService();
  List<Book> _books = [];
  bool _loading = true;
  String _selectedSubject = 'الكل';

  static const List<String> _subjects = [
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

      final uniqueTeachers = <String, BookTeacher>{};
      for (final b in books) {
        if (b.teacher.id.isNotEmpty) {
          uniqueTeachers[b.teacher.id] = b.teacher;
        }
      }
      if (uniqueTeachers.isNotEmpty) {
        final results = await Future.wait(
          uniqueTeachers.values.map((t) async {
            try {
              final res = await _api.get('/students/rate/teacher/${t.id}');
              return {t.id: (res['data']?['averageRating'] as num?)?.toDouble() ?? t.rating};
            } catch (_) {
              return <String, double>{t.id: t.rating};
            }
          }),
        );
        final ratingMap = <String, double>{};
        for (final r in results) {
          ratingMap.addAll(r);
        }
        for (final b in books) {
          b.teacher.rating = ratingMap[b.teacher.id] ?? b.teacher.rating;
        }
      }

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

  void _handleBuy(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          itemId: book.id,
          itemType: 'book',
          itemTitle: book.title,
          itemSubject: book.subject,
          itemPrice: book.price,
          itemOldPrice: book.oldPrice,
          teacherName: book.teacher.name,
          teacherAvatar: book.teacher.avatar,
          itemColor: book.color,
          itemGradient: book.gradient,
        ),
      ),
    );
  }

  void _handleDetails(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherBookDetailsPage(bookId: book.id),
      ),
    );
  }

  void _handleTeacherTap(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherProfilePage(teacherId: book.teacher.id),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final book = filtered[index];
        return _BookCard(
          isDark: isDark,
          book: book,
          onTeacherTap: () => _handleTeacherTap(book),
          onDetails: () => _handleDetails(book),
          onBuy: () => _handleBuy(book),
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  final bool isDark;
  final Book book;
  final VoidCallback onTeacherTap;
  final VoidCallback onDetails;
  final VoidCallback onBuy;

  const _BookCard({
    required this.isDark,
    required this.book,
    required this.onTeacherTap,
    required this.onDetails,
    required this.onBuy,
  });

  Color get _borderColor => isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetails,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          if (book.coverImage != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: ExploreImage(
                  imageUrl: book.coverImage,
                  fit: BoxFit.cover,
                  fallback: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: book.gradient),
                    ),
                    child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 36)),
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: book.gradient),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
          if (book.coverImage != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: book.price > 0 ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF059669),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
              ),
              child: Text(
                book.price > 0 ? '${book.price} جنيه' : 'مجاني',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Cairo',
                  color: book.price > 0 ? book.color : Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(book.subject, style: const TextStyle(fontSize: 9, fontFamily: 'Cairo', color: Colors.white)),
            ),
          ),
          if (book.coverImage == null)
            Positioned(
              top: 28, right: 0, left: 0,
              child: Center(
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          Positioned(
            bottom: 8, right: 8, left: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: Colors.white),
                ),
                if (book.grade.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(book.grade, style: const TextStyle(fontSize: 9, fontFamily: 'Cairo', color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTeacherTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : book.color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(color: book.color, borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.teacher.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 10, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 2),
                              Text(book.teacher.rating.toStringAsFixed(1), style: TextStyle(fontSize: 9, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_left_rounded, size: 14, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              book.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.4),
            ),
            const Spacer(),
            Row(
              children: [
                if (book.pages > 0) ...[
                  Icon(Icons.description_rounded, size: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  const SizedBox(width: 2),
                  Text('${book.pages}', style: TextStyle(fontSize: 9, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  const SizedBox(width: 6),
                ],
                Icon(Icons.download_rounded, size: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                const SizedBox(width: 2),
                Text('${(book.downloads / 1000).toStringAsFixed(1)}K', style: TextStyle(fontSize: 9, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                const Spacer(),
                const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFBBF24)),
                Text(book.rating.toStringAsFixed(1), style: TextStyle(fontSize: 9, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: OutlinedButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.arrow_back_rounded, size: 12),
                      label: const Text('التفاصيل', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: book.color,
                        side: BorderSide(color: book.color),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildActionButton(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (book.price > 0) {
      return SizedBox(
        height: 24,
        child: ElevatedButton.icon(
          onPressed: onBuy,
          icon: const Icon(Icons.shopping_cart_rounded, size: 12),
          label: const Text('اشتري', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
          style: ElevatedButton.styleFrom(
            backgroundColor: book.color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            elevation: 0,
          ),
        ),
      );
    }
    if (book.pdfFileRef != null) {
      return SizedBox(
        height: 24,
        child: ElevatedButton.icon(
          onPressed: () {
            final baseUrl = 'http://localhost:5000';
            final url = '$baseUrl${book.pdfFileRef}';
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          },
          icon: const Icon(Icons.download_rounded, size: 12),
          label: const Text('تحميل مجاني', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            elevation: 0,
          ),
        ),
      );
    }
    return SizedBox(
      height: 24,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 2),
        ),
        child: const Text('غير متاح', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
      ),
    );
  }
}
