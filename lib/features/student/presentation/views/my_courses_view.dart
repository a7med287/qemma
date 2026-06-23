import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/mock/student_mock_data.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../routes/student_routes.dart';
import '../widgets/student_async_body.dart';
import '../widgets/student_shared_widgets.dart';

class MyCoursesView extends StatefulWidget {
  const MyCoursesView({super.key});

  @override
  State<MyCoursesView> createState() => _MyCoursesViewState();
}

class _MyCoursesViewState extends State<MyCoursesView>
    with SingleTickerProviderStateMixin {
  List<EnrollmentItem> _enrollments = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int _tab = 0;
  CourseDetail? _selected;
  bool _detailLoading = false;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tab = _tabController.index);
      }
    });
    _loadEnrollments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrollments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<StudentRepository>().getMyEnrollments();
      if (!mounted) return;
      setState(() {
        _enrollments = list;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openCourse(String courseId) async {
    setState(() {
      _detailLoading = true;
      _selected = null;
    });
    try {
      final detail =
      await context.read<StudentRepository>().getCourseDetail(courseId);
      if (!mounted) return;
      setState(() {
        _selected = detail;
        _detailLoading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      buildSnackBar(context, e.message, isError: true);
      setState(() => _detailLoading = false);
    }
  }

  List<EnrollmentItem> get _filtered {
    var list = List<EnrollmentItem>.from(_enrollments);
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((e) =>
      e.course.title.toLowerCase().contains(q) ||
          e.course.teacher.toLowerCase().contains(q))
          .toList();
    }
    list = switch (_tab) {
      1 => list.where((e) => e.progress > 0 && e.progress < 100).toList(),
      2 => list.where((e) => e.progress == 100).toList(),
      3 => list.where((e) => e.progress == 0).toList(),
      _ => list,
    };
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_detailLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_selected != null) return _buildDetail(context, _selected!);

    return StudentPageShell(
      title: '📚 كورساتي',
      headerChild: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'ابحث عن كورس أو مدرس...',
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.white12,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none),
        ),
        style: const TextStyle(color: Colors.white),
      ),
      body: StudentAsyncBody(
        loading: _loading,
        error: _error,
        onRetry: _loadEnrollments,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(text: 'الكل (${_enrollments.length})'),
                const Tab(text: 'قيد التقدم'),
                const Tab(text: 'مكتملة'),
                const Tab(text: 'لم تبدأ'),
              ],
            ),
            SizedBox(height: 16.h),
            if (_filtered.isEmpty)
              Center(
                  child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: Text('لا توجد كورسات',
                          style: TextStyles.regular14
                              .copyWith(color: context.textSecondary))))
            else
              ..._filtered.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final color = StudentMockData
                    .studentColors[i % StudentMockData.studentColors.length];
                return _courseCard(context, e, color);
              }),
          ],
        ),
      ),
    );
  }

  Widget _courseCard(BuildContext context, EnrollmentItem e, Color color) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _openCourse(e.course.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 100.h,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: .7)])),
              child: Stack(
                children: [
                  Center(
                      child:
                      Icon(Icons.school, size: 48.sp, color: Colors.white70)),
                  Positioned(
                      top: 8,
                      right: 8,
                      child: Chip(
                          label: Text('${e.progress}%'),
                          backgroundColor: Colors.white)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.course.title,
                      style: TextStyles.semiBold16
                          .copyWith(color: context.textPrimary)),
                  Text(e.course.teacher,
                      style: TextStyles.regular13
                          .copyWith(color: context.textSecondary)),
                  SizedBox(height: 8.h),
                  LinearProgressIndicator(value: e.progress / 100, color: color),
                  SizedBox(height: 8.h),
                  ElevatedButton.icon(
                    onPressed: () => _openCourse(e.course.id),
                    icon: const Icon(Icons.play_circle),
                    label: Text(e.progress == 0
                        ? 'ابدأ الآن'
                        : e.progress == 100
                        ? 'مراجعة'
                        : 'استمر'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: color.withValues(alpha: .15),
                        foregroundColor: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, CourseDetail course) {
    return DefaultTabController(
      length: 3,
      child: StudentPageShell(
        title: course.title,
        onBack: () => setState(() => _selected = null),
        headerChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.teacherName,
                style: TextStyles.regular14.copyWith(color: Colors.white70)),
            SizedBox(height: 8.h),
            LinearProgressIndicator(
                value: course.progress / 100,
                backgroundColor: Colors.white24,
                color: Colors.white),
            Text('${course.progress}%',
                style: TextStyles.semiBold14.copyWith(color: Colors.white)),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: () => StudentRoutes.pushCourse(context, course.id),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: Colors.black),
              child: const Text('اظهار جميع محتويات الكورس'),
            ),
          ],
        ),
        body: Column(
          children: [
            const TabBar(
                tabs: [
                  Tab(text: 'الدروس'),
                  Tab(text: 'الامتحانات'),
                  Tab(text: 'الحصص'),
                ]),
            Expanded(
              child: TabBarView(
                children: [
                  _lessonsTab(context, course),
                  _examsTab(context, course),
                  _sessionsTab(context, course),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lessonsTab(BuildContext context, CourseDetail course) {
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: course.lessons.isEmpty
          ? [const Center(child: Text('لم يتم رفع دروس بعد'))]
          : course.lessons
          .map((l) => ListTile(
        leading: CircleAvatar(
            child: Icon(l.isPublished
                ? Icons.play_circle
                : Icons.lock)),
        title: Text(l.title),
        subtitle: Text('درس ${l.order}'),
        onTap: l.isPublished
            ? () =>
            StudentRoutes.pushLesson(context, course.id, l.id)
            : null,
      ))
          .toList(),
    );
  }

  Widget _examsTab(BuildContext context, CourseDetail course) {
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: course.exams
          .map((exam) => Card(
        child: ListTile(
          title: Text(exam.title),
          subtitle: Text(
              '${exam.durationMinutes} دقيقة • ${exam.questionsCount} سؤال'),
          trailing: exam.hasAttempt
              ? Chip(
              label: Text(
                  '${exam.attemptScore?.toStringAsFixed(0)}'))
              : ElevatedButton(
              onPressed: () =>
                  StudentRoutes.pushExamStart(context, exam.id),
              child: const Text('ابدأ')),
        ),
      ))
          .toList(),
    );
  }

  Widget _sessionsTab(BuildContext context, CourseDetail course) {
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: course.liveSessions
          .map((s) => Card(
        child: ListTile(
          leading: Icon(s.isLive ? Icons.live_tv : Icons.schedule,
              color: s.isLive ? Colors.red : Colors.blue),
          title: Text(s.title),
          subtitle: Text(s.time),
          trailing: ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, StudentRoutes.liveClass),
            child: Text(s.isLive ? 'انضم' : 'عرض'),
          ),
        ),
      ))
          .toList(),
    );
  }
}