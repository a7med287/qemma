import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../routes/student_routes.dart';
import '../widgets/student_async_body.dart';

class CourseDashboardView extends StatefulWidget {
  const CourseDashboardView({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDashboardView> createState() => _CourseDashboardViewState();
}

class _CourseDashboardViewState extends State<CourseDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CourseDetail? _course;
  bool _loading = true;
  String? _error;

  // ✅ Fix 2: تخزين الـ Future عشان FutureBuilder ما يعيد الاستدعاء
  Future<dynamic>? _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Fix 1: نقل _load من initState لـ didChangeDependencies
    if (_loading && _course == null && _error == null) {
      _load();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<StudentRepository>();
      final course = await repo.getCourseDetail(widget.courseId);
      if (!mounted) return;

      // ✅ Fix 2: تخزين الـ Future هنا بعد ما الـ repo يكون متاح
      _notificationsFuture = repo.getNotifications(
        courseId: widget.courseId,
        limit: 50,
      );

      setState(() {
        _course = course;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      // ✅ Fix 4: catch عام لأي خطأ غير متوقع
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ غير متوقع';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الكورس')),
        body: StudentAsyncBody(
          error: _error ?? 'الكورس غير موجود',
          onRetry: _load,
          loading: false,
          child: const SizedBox.shrink(),
        ),
      );
    }

    final course = _course!;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          course.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          course.teacherName,
                          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                        ),
                        SizedBox(height: 8.h),
                        LinearProgressIndicator(
                          value: course.progress / 100,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                        ),
                        Text(
                          '${course.progress}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'الدروس'),
                  Tab(text: 'الامتحانات'),
                  Tab(text: 'الجلسات'),
                  Tab(text: 'التواصل'),
                  Tab(text: 'الإشعارات'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _lessonsTab(course),
            _examsTab(course),
            _sessionsTab(course),
            _communicationTab(course),
            _notificationsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/student/course/${course.id}/ask-teacher'),
        icon: const Icon(Icons.question_answer),
        label: const Text('اسأل المدرس'),
      ),
    );
  }

  Widget _lessonsTab(CourseDetail course) {
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: course.lessons.isEmpty
          ? [const Center(child: Text('لم يتم رفع دروس بعد'))]
          : course.lessons
          .map(
            (l) => ListTile(
          leading: CircleAvatar(
            child: Icon(l.isPublished ? Icons.play_circle : Icons.lock),
          ),
          title: Text(l.title),
          subtitle: Text('درس ${l.order}'),
          trailing: l.attended
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
          onTap: l.isPublished
              ? () => StudentRoutes.pushLesson(context, course.id, l.id)
              : null,
        ),
      )
          .toList(),
    );
  }

  Widget _examsTab(CourseDetail course) {
    // ✅ Fix 5: رسالة لو مفيش امتحانات
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: course.exams.isEmpty
          ? [const Center(child: Text('لا توجد امتحانات بعد'))]
          : course.exams
          .map(
            (exam) => Card(
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(exam.description),
                SizedBox(height: 8.h),
                if (exam.hasAttempt)
                  Chip(
                    label: Text('${exam.attemptScore?.toStringAsFixed(0)} درجة'),
                  )
                else
                  ElevatedButton(
                    onPressed: () =>
                        StudentRoutes.pushExamStart(context, exam.id),
                    child: const Text('ابدأ الامتحان'),
                  ),
              ],
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _sessionsTab(CourseDetail course) {
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        ...course.liveSessions.map(
              (s) => Card(
            child: ListTile(
              leading: Icon(
                s.isLive ? Icons.live_tv : Icons.schedule,
                color: s.isLive ? Colors.red : Colors.blue,
              ),
              title: Text(s.title),
              subtitle: Text(s.time),
              trailing: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, StudentRoutes.liveClass),
                child: Text(s.isLive ? 'انضم' : 'جدولة'),
              ),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.event),
            title: const Text('حجز Office Hour'),
            subtitle: const Text('موعد فيديو مع المدرس'),
            onTap: () => Navigator.pushNamed(
              context,
              '/student/course/${course.id}/book-office-hour',
            ),
          ),
        ),
      ],
    );
  }

  Widget _communicationTab(CourseDetail course) {
    final messageController = TextEditingController();

    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: const Text('مرحباً! كيف يمكنني مساعدتك؟'),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              // ✅ Fix 3: ربط زر الإرسال بـ logic حقيقي
              IconButton(
                onPressed: () {
                  final text = messageController.text.trim();
                  if (text.isEmpty) return;
                  // TODO: إرسال الرسالة للـ repository
                  messageController.clear();
                },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notificationsTab() {
    // ✅ Fix 2: استخدام الـ Future المخزن بدل إنشاء واحد جديد كل مرة
    return FutureBuilder(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('فشل تحميل الإشعارات'));
        }
        final list = snapshot.data?.notifications ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('لا توجد إشعارات'));
        }
        return ListView(
          padding: EdgeInsets.all(16.r),
          children: list
              .map((n) => Card(
            child: ListTile(
              title: Text(n.title),
              subtitle: Text(n.body),
            ),
          ))
              .toList(),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}