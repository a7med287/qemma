import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import 'teacher_edit_course_view.dart';
import 'widgets/teacher_course_card.dart';
import 'widgets/teacher_course_filter_bar.dart';

class TeacherMyCoursesView extends StatefulWidget {
  static const routeName = '/teacher/my-courses';
  const TeacherMyCoursesView({super.key});

  @override
  State<TeacherMyCoursesView> createState() =>
      _TeacherMyCoursesViewState();
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

  List<TeacherCourse> get _filteredCourses => _courses.where((c) {
    final matchSearch = _searchQuery.isEmpty ||
        c.title.toLowerCase().contains(_searchQuery.toLowerCase());
    final matchTab = _tabValue == 0 ? true
        : _tabValue == 1 ? c.isPublished : !c.isPublished;
    return matchSearch && matchTab;
  }).toList();

  Future<void> _handleDelete(TeacherCourse course) async {
    try {
      await context.read<TeacherRepository>().deleteCourse(course.id);
      if (!mounted) return;
      setState(() => _courses.removeWhere((c) => c.id == course.id));
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
      setState(() => _courses = _courses.map((c) =>
          c.id == course.id ? c.copyWith(isPublished: newVal) : c).toList());
      _showToast(newVal ? 'تم نشر الكورس ✅' : 'تم إخفاء الكورس');
    } on Failure catch (e) {
      _showToast(e.message, error: true);
    } catch (_) {
      _showToast('فشل تغيير حالة الكورس', error: true);
    }
  }

  void _showToast(String message, {bool error = false}) =>
      buildSnackBar(context, message, isError: error);

  Future<void> _showDeleteDialog(TeacherCourse course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => TeacherCourseDeleteDialog(
        course: course,
        isDark: context.isDark,
      ),
    );
    if (confirmed == true) _handleDelete(course);
  }

  Future<void> _openEdit(TeacherCourse course) async {
    final result = await Navigator.pushNamed(
      context, TeacherEditCourseView.routeName, arguments: course);
    if (result == true) {
      _showToast('تم تحديث الكورس بنجاح ✅');
      _fetchCourses();
    }
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
        label: const Text('إنشاء كورس',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final totalStudents = _courses.fold(0, (sum, c) => sum + (c.stats?.enrollments ?? 0));
    final totalLessons = _courses.fold(0, (sum, c) => sum + (c.stats?.lessons ?? 0));
    final publishedCount = _courses.where((c) => c.isPublished).length;

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
                          style: TextStyle(color: Colors.white, fontSize: 22.sp,
                              fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                      Text('إدارة ومتابعة جميع كورساتك',
                          style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontFamily: 'Cairo')),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _statItem('${_courses.length}', 'إجمالي الكورسات'),
                _statItem('$totalStudents', 'إجمالي الطلاب'),
                _statItem('$totalLessons', 'إجمالي الدروس'),
                _statItem('$publishedCount', 'المنشور'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) => Expanded(
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8.r)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: Colors.white, fontSize: 16.sp,
              fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 9.sp, fontFamily: 'Cairo')),
        ],
      ),
    ),
  );

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
              ElevatedButton(onPressed: _fetchCourses,
                  child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo'))),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchCourses,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TeacherCourseFilterBar(
              searchQuery: _searchQuery,
              tabValue: _tabValue,
              totalCourses: _courses.length,
              publishedCount: _courses.where((c) => c.isPublished).length,
              draftCount: _courses.where((c) => !c.isPublished).length,
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              onTabChanged: (v) => setState(() => _tabValue = v),
            ),
          ),
          if (_filteredCourses.isEmpty)
            SliverFillRemaining(
              child: TeacherCourseEmptyState(isSearching: _searchQuery.isNotEmpty),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 80.h),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.7,
                  crossAxisSpacing: 12.w, mainAxisSpacing: 12.h,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => TeacherCourseCard(
                    course: _filteredCourses[i],
                    onEdit: () => _openEdit(_filteredCourses[i]),
                    onTogglePublish: () => _handleTogglePublish(_filteredCourses[i]),
                    onDelete: () => _showDeleteDialog(_filteredCourses[i]),
                  ),
                  childCount: _filteredCourses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
