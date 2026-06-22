import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import 'teacher_edit_course_view.dart';

class TeacherMyCoursesView extends StatefulWidget {
  static const routeName = '/teacher/my-courses';
  const TeacherMyCoursesView({super.key});

  @override
  State<TeacherMyCoursesView> createState() => _TeacherMyCoursesViewState();
}

class _TeacherMyCoursesViewState extends State<TeacherMyCoursesView> {
  List<TeacherCourse> _courses = [];
  bool _loading = true;
  String? _error;

  String _searchQuery = '';
  int _tabValue = 0;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() { _loading = true; _error = null; });
    try {
      final courses = await context.read<TeacherRepository>().getMyCourses();
      if (!mounted) return;
      setState(() { _courses = courses; _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'فشل تحميل الكورسات'; _loading = false; });
    }
  }

  List<TeacherCourse> get _filteredCourses {
    return _courses.where((c) {
      final matchSearch = _searchQuery.isEmpty ||
          c.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchTab = _tabValue == 0 ? true :
      _tabValue == 1 ? c.isPublished : !c.isPublished;
      return matchSearch && matchTab;
    }).toList();
  }

  Future<void> _handleDelete(TeacherCourse course) async {
    try {
      await context.read<TeacherRepository>().deleteCourse(course.id);
      if (!mounted) return;
      setState(() {
        _courses.removeWhere((c) => c.id == course.id);
      });
      _showToast('تم حذف الكورس: ${course.title}');
    } on Failure catch (e) {
      if (!mounted) return;
      _showToast(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _showToast('فشل حذف الكورس', error: true);
    }
  }

  Future<void> _handleTogglePublish(TeacherCourse course) async {
    try {
      final newVal = await context.read<TeacherRepository>().togglePublish(course.id);
      if (!mounted) return;
      setState(() {
        _courses = _courses.map((c) =>
        c.id == course.id ? c.copyWith(isPublished: newVal) : c).toList();
      });
      _showToast(newVal ? 'تم نشر الكورس ✅' : 'تم إخفاء الكورس');
    } on Failure catch (e) {
      _showToast(e.message, error: true);
    } catch (_) {
      _showToast('فشل تغيير حالة الكورس', error: true);
    }
  }

  void _showToast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/teacher/courses/create');
          if (result == true) _fetchCourses();
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إنشاء كورس', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _showDeleteDialog(TeacherCourse course) async {
    final isDark = context.isDark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Row(
          children: [
            Container(
              width: 36.w, height: 36.w,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: const Icon(Icons.warning, color: Color(0xFFDC2626), size: 20),
            ),
            SizedBox(width: 12.w),
            Text('تأكيد حذف الكورس',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('هل أنت متأكد أنك تريد حذف الكورس التالي؟',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title,
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14.sp,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                    if (course.description != null && course.description!.isNotEmpty)
                      Text(course.description!,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3A1))),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8.r)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Color(0xFFDC2626), size: 16),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text('⚠️ هذا الإجراء لا يمكن التراجع عنه',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: const Color(0xFFDC2626))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('نعم، احذف الكورس', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _handleDelete(course);
    }
  }

  Future<void> _openEdit(TeacherCourse course) async {
    final result = await Navigator.pushNamed(context, TeacherEditCourseView.routeName, arguments: course);
    if (result == true) {
      _showToast('تم تحديث الكورس بنجاح ✅');
      _fetchCourses();
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 16.h),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.white12),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('كورساتي 📚',
                          style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                      Text('إدارة ومتابعة جميع كورساتك',
                          style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontFamily: 'Cairo')),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildStatsRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final totalStudents = _courses.fold(0, (sum, c) => sum + (c.stats?.enrollments ?? 0));
    final totalLessons = _courses.fold(0, (sum, c) => sum + (c.stats?.lessons ?? 0));
    final publishedCount = _courses.where((c) => c.isPublished).length;

    final stats = [
      _StatItem(label: 'إجمالي الكورسات', value: '${_courses.length}',
          icon: Icons.school, gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)])),
      _StatItem(label: 'إجمالي الطلاب', value: '$totalStudents',
          icon: Icons.people, gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)])),
      _StatItem(label: 'إجمالي الدروس', value: '$totalLessons',
          icon: Icons.video_library, gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFDB2777)])),
      _StatItem(label: 'المنشور', value: '$publishedCount',
          icon: Icons.trending_up, gradient: const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFF59E0B)])),
    ];

    return Row(
      children: stats.map((s) => Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: [
              Text(s.value,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
              Text(s.label,
                  style: TextStyle(color: Colors.white70, fontSize: 9.sp, fontFamily: 'Cairo')),
            ],
          ),
        ),
      )).toList(),
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
              Icon(Icons.cloud_off, size: 48.sp, color: Colors.grey),
              SizedBox(height: 12.h),
              Text(_error!, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
              SizedBox(height: 16.h),
              ElevatedButton(onPressed: _fetchCourses, child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo'))),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchCourses,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSearchAndTabs(context)),
          if (_filteredCourses.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(context))
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 80.h),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildCourseCard(context, _filteredCourses[i]),
                  childCount: _filteredCourses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndTabs(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.r),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : null),
              decoration: InputDecoration(
                hintText: 'ابحث عن كورس...',
                hintTextDirection: TextDirection.rtl,
                hintStyle: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
                prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF94A3B8) : null),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
          Row(
            children: [
              _buildTab(0, 'الكل (${_courses.length})'),
              _buildTab(1, 'منشور (${_courses.where((c) => c.isPublished).length})'),
              _buildTab(2, 'مسودة (${_courses.where((c) => !c.isPublished).length})'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isDark = context.isDark;
    final selected = _tabValue == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabValue = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF2563EB)) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 11.sp, fontWeight: FontWeight.w700,
                color: selected
                    ? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF2563EB))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
              )),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = context.isDark;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64.sp, color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
            SizedBox(height: 16.h),
            Text(_searchQuery.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا توجد كورسات بعد',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 16.sp,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
            SizedBox(height: 8.h),
            Text(_searchQuery.isNotEmpty ? 'جرّب كلمة بحث مختلفة' : 'ابدأ بإنشاء كورسك الأول الآن',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  /// يعرض صورة الكورس سواء كانت base64 أو URL عادي
  Widget _buildThumbnailImage(String thumbnail) {
    if (thumbnail.startsWith('data:image')) {
      try {
        final base64Str = thumbnail.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
        );
      } catch (_) {
        return _thumbnailPlaceholder();
      }
    }
    return Image.network(
      thumbnail,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
    );
  }

  Widget _buildCourseCard(BuildContext context, TeacherCourse course) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (course.thumbnail != null && course.thumbnail!.isNotEmpty)
                  Positioned.fill(
                    child: _buildThumbnailImage(course.thumbnail!),
                  )
                else
                  _thumbnailPlaceholder(),
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: [
                      if (course.category != null)
                        _badge(course.category!, const Color(0xFF2563EB)),
                      if (course.level != null)
                        _badge(course.level!, const Color(0xFF7C3AED)),
                      _badge(course.isPublished ? 'منشور' : 'مسودة',
                          course.isPublished ? const Color(0xFF059669) : const Color(0xFFF59E0B)),
                    ],
                  ),
                ),
                Positioned(
                  left: 6.w,
                  top: 6.h,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: (v) {
                      if (v == 'edit') _openEdit(course);
                      if (v == 'toggle') _handleTogglePublish(course);
                      if (v == 'delete') _showDeleteDialog(course);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Row(
                        children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('تعديل', style: TextStyle(fontFamily: 'Cairo'))],
                      )),
                      PopupMenuItem(value: 'toggle', child: Row(
                        children: [
                          Icon(course.isPublished ? Icons.visibility_off : Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text(course.isPublished ? 'إخفاء' : 'نشر', style: const TextStyle(fontFamily: 'Cairo')),
                        ],
                      )),
                      const PopupMenuItem(value: 'delete', child: Row(
                        children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8),
                          Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.red))],
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 11.sp,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      _miniStat(Icons.people, '${course.stats?.enrollments ?? 0}', 'طالب'),
                      _miniStat(Icons.video_library, '${course.stats?.lessons ?? 0}', 'درس'),
                      _miniStat(Icons.attach_money, '${course.price}', 'ج.م'),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 26.h,
                    child: TextButton(
                      onPressed: () => _openEdit(course),
                      style: TextButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('تعديل الكورس',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 10.sp,
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF374151))),
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

  Widget _thumbnailPlaceholder() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 32.sp, color: const Color(0xFF475569)),
          Text('بدون صورة', style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.r)),
      child: Text(label,
          style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
    );
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 12.sp, color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10.sp, fontFamily: 'Cairo',
                  color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          Text(label,
              style: TextStyle(fontSize: 8.sp, fontFamily: 'Cairo',
                  color: context.isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  const _StatItem({required this.label, required this.value, required this.icon, required this.gradient});
}