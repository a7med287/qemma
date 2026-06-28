import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/services/socket_service.dart';
import '../../data/models/student_models.dart';
import '../../data/models/student_model_json.dart';
import '../../data/repositories/student_repository.dart';
import '../routes/student_routes.dart';
import '../views/student_chat_view.dart';
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

  // Socket
  io.Socket? _socket;

  // Notifications
  List<StudentNotification> _notifications = [];
  bool _notiLoading = false;

  StreamSubscription<Map<String, dynamic>>? _notiSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _connectSocket();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _notiSub?.cancel();
    _socket?.disconnect();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      if (_tabController.index == 3) _fetchNotifications();
    }
  }

  void _connectSocket() {
    final baseUrl = kApiBaseUrl.replaceAll('/api', '');
    _socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'auth': {'token': SocketService().token},
    });
    _socket?.on('connect', (_) {});
    _socket?.on('lesson:published', _onLessonPublished);
    _socket?.on('exam:published', _onExamPublished);
    _socket?.on('schedule:new', _onScheduleNew);
    _socket?.on('live_class:started', _onLiveClassStarted);
    _socket?.on('live_class:room_status_changed', _onRoomStatusChanged);
    _socket?.on('disconnect', (_) {});
  }

  void _onLessonPublished(dynamic data) {
    if (!mounted || _course == null) return;
    final map = data as Map<String, dynamic>;
    final lesson = StudentModelJson.courseLessonFromJson(map);
    setState(() {
      final idx = _course!.lessons.indexWhere((l) => l.id == lesson.id);
      final lessons = [..._course!.lessons];
      if (idx >= 0) {
        lessons[idx] = lesson;
      } else {
        lessons.add(lesson);
        lessons.sort((a, b) => a.order.compareTo(b.order));
      }
      _course = _course!.copyWith(lessons: lessons);
    });
  }

  void _onExamPublished(dynamic data) {
    if (!mounted || _course == null) return;
    final map = data as Map<String, dynamic>;
    final exam = StudentModelJson.courseExamFromJson(map);
    setState(() {
      final idx = _course!.exams.indexWhere((e) => e.id == exam.id);
      final exams = [..._course!.exams];
      if (idx >= 0) {
        exams[idx] = exam;
      } else {
        exams.add(exam);
      }
      _course = _course!.copyWith(exams: exams);
    });
  }

  void _onScheduleNew(dynamic data) {
    if (!mounted || _course == null) return;
    final map = data as Map<String, dynamic>;
    final session = StudentModelJson.upcomingSessionFromJson(map);
    setState(() {
      final list = [...?_course!.upcomingSessions, session];
      _course = _course!.copyWith(upcomingSessions: list);
    });
  }

  void _onLiveClassStarted(dynamic data) {
    if (!mounted || _course == null) return;
    final map = data as Map<String, dynamic>;
    _notifications.insert(0, StudentNotification(
      id: 'live-${DateTime.now().millisecondsSinceEpoch}',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      time: DateTime.now().toIso8601String(),
      unread: true,
      type: 'live_class',
    ));
    final roomName = map['roomName']?.toString() ?? '';
    setState(() {
      var liveRooms = _course!.liveSessions.map((r) {
        if (r.roomName == roomName) {
          return LiveSession(
            id: r.id, title: r.title, teacher: r.teacher,
            time: r.time, courseId: r.courseId, isLive: true,
            participants: r.participants, roomName: r.roomName,
            status: 'live', roomCode: r.roomCode, maxCapacity: r.maxCapacity,
            description: r.description, scheduledAt: r.scheduledAt,
          );
        }
        return r;
      }).toList();
      if (!liveRooms.any((r) => r.roomName == roomName)) {
        liveRooms.insert(0, LiveSession(
          id: map['roomId']?.toString() ?? '',
          title: (map['title']?.toString() ?? '').replaceAll('📡 حصة مباشرة: ', ''),
          teacher: '', time: '', courseId: widget.courseId,
          isLive: true, roomName: roomName, status: 'live',
          roomCode: map['roomCode']?.toString(),
        ));
      }
      _course = _course!.copyWith(liveSessions: liveRooms);
    });
  }

  void _onRoomStatusChanged(dynamic data) {
    if (!mounted || _course == null) return;
    final map = data as Map<String, dynamic>;
    final roomName = map['roomName']?.toString();
    setState(() {
      _course = _course!.copyWith(liveSessions: _course!.liveSessions.map((r) {
        if (r.roomName == roomName || r.id == map['roomId']?.toString()) {
          return LiveSession(
            id: map['id']?.toString() ?? r.id,
            title: map['title']?.toString() ?? r.title,
            teacher: map['teacherName']?.toString() ?? r.teacher,
            time: r.time, courseId: r.courseId,
            isLive: map['isActive'] == true || map['status']?.toString() == 'live',
            participants: _toInt(map['participantCount'], r.participants),
            roomName: map['roomName']?.toString() ?? r.roomName,
            status: map['status']?.toString() ?? r.status,
            roomCode: map['roomCode']?.toString() ?? r.roomCode,
            maxCapacity: map['maxCapacity'] != null ? _toInt(map['maxCapacity'], 0) : r.maxCapacity,
            description: map['description']?.toString() ?? r.description,
            scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ?? r.scheduledAt,
          );
        }
        return r;
      }).toList());
    });
  }

  int _toInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? fallback;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _course == null && _error == null) {
      _load();
    }
    // Subscribe to global notification stream
    _notiSub ??= SocketService().notificationStream.listen((data) {
      if (!mounted) return;
      final cId = data['data'] is Map ? (data['data'] as Map)['courseId']?.toString() : null;
      if (cId == null || cId == widget.courseId) {
        setState(() {
          _notifications.insert(0, StudentNotification(
            id: data['id']?.toString() ?? 'noti-${DateTime.now().millisecondsSinceEpoch}',
            title: data['title']?.toString() ?? '',
            body: data['body']?.toString() ?? '',
            time: data['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
            unread: !(data['isRead'] == true),
            type: data['type']?.toString() ?? 'general',
          ));
        });
      }
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = context.read<StudentRepository>();
      final course = await repo.getCourseDetail(widget.courseId);
      if (!mounted) return;
      setState(() { _course = course; _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'حدث خطأ غير متوقع'; _loading = false; });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accent = const Color(0xFF2563EB);
    final unreadCount = _notifications.where((n) => n.unread).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => StudentChatView(
            courseId: course.id,
            courseTitle: course.title,
            teacherName: course.teacherName,
            teacherAvatar: course.teacherAvatar,
            teacherUserId: course.teacherUserId ?? '',
          )));
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_rounded),
        label: const Text('التواصل مع المدرس', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            leading: const SizedBox.shrink(),
            expandedHeight: 320.h,
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
                      children: [
                        // Back + Refresh
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                              onPressed: _load,
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        // Course info
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 72.r, height: 72.r,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12.r),
                                        child: _buildImage(course.thumbnail!, fit: BoxFit.cover, fallback: Icon(Icons.school_rounded, size: 36.r, color: Colors.white)),
                                      )
                                    : Icon(Icons.school_rounded, size: 36.r, color: Colors.white),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(course.title,
                                      style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
                                      maxLines: 2, overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        Container(
                                          width: 28.r, height: 28.r,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                        child: course.teacherAvatar != null && course.teacherAvatar!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(14.r),
                                                child: _buildImage(course.teacherAvatar!, fit: BoxFit.cover, fallback: Icon(Icons.person_rounded, size: 16.r, color: Colors.white)),
                                              )
                                            : Icon(Icons.person_rounded, size: 16.r, color: Colors.white),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(course.teacherName,
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.sp, fontFamily: 'Cairo'),
                                            overflow: TextOverflow.ellipsis,
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
                        // Stats row
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatBox('درس', course.stats?.totalLessons ?? course.lessons.length),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildStatBox('امتحان', course.stats?.totalExams ?? course.exams.length),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildStatBox('طالب', course.stats?.totalStudents ?? 0),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildStatBox('حضرت', course.stats?.attendedCount ?? 0),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        // Progress
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('تقدمك في الكورس',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.sp, fontFamily: 'Cairo')),
                                  SizedBox(height: 4.h),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4.r),
                                    child: LinearProgressIndicator(
                                      value: course.progress / 100,
                                      backgroundColor: Colors.white24,
                                      color: Colors.white,
                                      minHeight: 8.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text('${course.progress}%',
                              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                          ],
                        ),
                        SizedBox(height: 8.h),
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
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                tabs: [
                  const Tab(text: 'الدروس'),
                  const Tab(text: 'الامتحانات'),
                  const Tab(text: 'الجلسات'),
                  Tab(child: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount', style: const TextStyle(fontSize: 10)),
                    child: const Text('الإشعارات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                  )),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLessonsTab(course, isDark, cardBg, borderColor, textColor, subTextColor),
                  _buildExamsTab(course, isDark, cardBg, borderColor, textColor, subTextColor, accent),
                  _buildSessionsTab(course, isDark, cardBg, borderColor, textColor, subTextColor, accent),
                  _buildNotificationsTab(isDark, cardBg, borderColor, textColor, subTextColor, accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover, Widget? fallback}) {
    if (url.startsWith('data:')) {
      final parts = url.split(',');
      if (parts.length >= 2) {
        try {
          return Image.memory(base64Decode(parts[1]), fit: fit, width: width, height: height);
        } catch (_) {
          return fallback ?? const SizedBox.shrink();
        }
      }
    }
    return Image.network(url, fit: fit, width: width, height: height,
      errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
    );
  }

  Widget _buildStatBox(String label, int value) {
    return Column(
      children: [
        Text('$value',
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
        Text(label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10.sp, fontFamily: 'Cairo')),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LESSONS TAB
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLessonsTab(CourseDetail course, bool isDark, Color cardBg, Color borderColor, Color textColor, Color subTextColor) {
    final lessons = course.lessons;
    final colors = [const Color(0xFF2563EB), const Color(0xFF7C3AED), const Color(0xFF059669), const Color(0xFFDB2777), const Color(0xFF0891B2), const Color(0xFFCA8A04)];
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        Text('📖 محتوى الكورس — ${lessons.length} درس',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: textColor)),
        SizedBox(height: 16.h),
        if (lessons.isEmpty)
          _buildEmpty('📚', 'لم يتم رفع دروس بعد', subTextColor)
        else
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: lessons.asMap().entries.map((entry) {
              final i = entry.key;
              final l = entry.value;
              final color = colors[i % colors.length];
              return SizedBox(
                width: MediaQuery.of(context).size.width > 600
                    ? (MediaQuery.of(context).size.width / 2 - 32.r)
                    : MediaQuery.of(context).size.width - 32.r,
                child: _LessonCard(
                  lesson: l, color: color, isDark: isDark,
                  cardBg: cardBg, borderColor: borderColor, textColor: textColor, subTextColor: subTextColor,
                  onTap: l.isPublished
                      ? () => StudentRoutes.pushLesson(context, course.id, l.id)
                      : null,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // EXAMS TAB
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildExamsTab(CourseDetail course, bool isDark, Color cardBg, Color borderColor, Color textColor, Color subTextColor, Color accent) {
    final exams = course.exams;
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        Text('📝 الامتحانات — ${exams.length} امتحان',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: textColor)),
        SizedBox(height: 16.h),
        if (exams.isEmpty)
          _buildEmpty('📝', 'لا توجد امتحانات بعد', subTextColor)
        else
          ...exams.map((exam) => _ExamCard(
            exam: exam, isDark: isDark, cardBg: cardBg, borderColor: borderColor,
            textColor: textColor, subTextColor: subTextColor, accent: accent,
            onStart: exam.hasAttempt ? null : () => StudentRoutes.pushExamStart(context, exam.id),
          )),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SESSIONS TAB
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSessionsTab(CourseDetail course, bool isDark, Color cardBg, Color borderColor, Color textColor, Color subTextColor, Color accent) {
    final liveRooms = course.liveSessions;
    final upcomingSessions = course.upcomingSessions ?? [];

    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        Text('🔴 الجلسات — ${liveRooms.length + upcomingSessions.length} جلسة',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: textColor)),
        SizedBox(height: 16.h),
        if (liveRooms.isEmpty && upcomingSessions.isEmpty)
          _buildEmpty('📡', 'لا توجد جلسات حالياً', subTextColor)
        else ...[
          if (liveRooms.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.live_tv_rounded, size: 20.r, color: const Color(0xFF10B981)),
              SizedBox(width: 8.w),
              Text('الحصص المباشرة',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: const Color(0xFF10B981))),
            ]),
            SizedBox(height: 12.h),
            ...liveRooms.map((room) => _LiveRoomCard(
              room: room, isDark: isDark, cardBg: cardBg, borderColor: borderColor,
              textColor: textColor, subTextColor: subTextColor,
              onJoin: room.isLive ? () => StudentRoutes.pushLesson(context, course.id, room.roomName) : null,
            )),
            SizedBox(height: 24.h),
          ],
          if (upcomingSessions.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.calendar_today_rounded, size: 18.r, color: subTextColor),
              SizedBox(width: 8.w),
              Text('الجلسات المجدولة',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: subTextColor)),
            ]),
            SizedBox(height: 12.h),
            ...upcomingSessions.map((s) => _SessionCard(
              session: s, isDark: isDark, cardBg: cardBg, borderColor: borderColor,
              textColor: textColor, subTextColor: subTextColor, accent: accent,
            )),
          ],
          SizedBox(height: 16.h),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: borderColor)),
            child: ListTile(
              leading: const Icon(Icons.event, color: Color(0xFF7C3AED)),
              title: const Text('حجز Office Hour', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              subtitle: Text('موعد فيديو مع المدرس', style: TextStyle(fontFamily: 'Cairo', color: subTextColor)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(context, '/student/course/${course.id}/book-office-hour'),
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOTIFICATIONS TAB
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildNotificationsTab(bool isDark, Color cardBg, Color borderColor, Color textColor, Color subTextColor, Color accent) {
    final unreadCount = _notifications.where((n) => n.unread).length;
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🔔 إشعاراتك ($unreadCount غير مقروءة)',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: textColor)),
            if (unreadCount > 0)
              TextButton(
                onPressed: _markAllNotifRead,
                child: const Text('تعليم الكل كمقروء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        SizedBox(height: 16.h),
        if (_notiLoading)
          const Center(child: CircularProgressIndicator())
        else if (_notifications.isEmpty)
          _buildEmpty('🔔', 'لا توجد إشعارات', subTextColor)
        else
          ..._notifications.map((n) => _NotifCard(
            notif: n, isDark: isDark, cardBg: cardBg, borderColor: borderColor,
            textColor: textColor, subTextColor: subTextColor, accent: accent,
            onTap: () => _markNotifRead(n.id),
          )),
      ],
    );
  }

  Future<void> _fetchNotifications() async {
    setState(() { _notiLoading = true; });
    try {
      final repo = context.read<StudentRepository>();
      final data = await repo.getNotifications(courseId: widget.courseId, limit: 50);
      setState(() { _notifications = data.notifications; });
    } catch (_) {
      setState(() { _notifications = []; });
    }
    setState(() { _notiLoading = false; });
  }

  Future<void> _markNotifRead(String id) async {
    try {
      await context.read<StudentRepository>().markNotificationRead(id);
      setState(() {
        _notifications = _notifications.map((n) =>
          n.id == id ? StudentNotification(id: n.id, title: n.title, body: n.body, time: n.time, unread: false, type: n.type) : n
        ).toList();
      });
    } catch (_) {}
  }

  Future<void> _markAllNotifRead() async {
    try {
      await context.read<StudentRepository>().markAllNotificationsRead();
      setState(() {
        _notifications = _notifications.map((n) =>
          StudentNotification(id: n.id, title: n.title, body: n.body, time: n.time, unread: false, type: n.type)
        ).toList();
      });
    } catch (_) {}
  }

  Widget _buildEmpty(String icon, String text, Color subTextColor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48.h),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 12.h),
            Text(text, style: TextStyle(fontFamily: 'Cairo', color: subTextColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// LESSON CARD
// ═══════════════════════════════════════════════════════════════════
class _LessonCard extends StatelessWidget {
  final CourseLesson lesson;
  final Color color;
  final bool isDark;
  final Color cardBg, borderColor, textColor, subTextColor;
  final VoidCallback? onTap;

  const _LessonCard({
    required this.lesson, required this.color, required this.isDark,
    required this.cardBg, required this.borderColor, required this.textColor, required this.subTextColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44.r, height: 44.r,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                !lesson.isPublished
                    ? Icons.lock_rounded
                    : lesson.attended
                        ? Icons.check_circle_rounded
                        : Icons.play_circle_filled_rounded,
                color: Colors.white, size: 22.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.title,
                    style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: textColor),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 2.h),
                  Text('درس ${lesson.order}',
                    style: TextStyle(fontSize: 11.sp, fontFamily: 'Cairo', color: subTextColor)),
                  SizedBox(height: 4.h),
                  Wrap(
                    spacing: 6.w,
                    children: [
                      if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty)
                        _chip(Icons.play_circle_filled_rounded, 'فيديو', color),
                      if (lesson.hasPdf)
                        _chip(Icons.picture_as_pdf_rounded, 'PDF', const Color(0xFFDC2626)),
                      if (lesson.attended)
                        _chip(Icons.check_circle_rounded, 'حضرت', const Color(0xFF059669)),
                      if (!lesson.isPublished)
                        _chip(null, 'غير متاح', subTextColor),
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

  Widget _chip(IconData? icon, String label, Color chipColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 12.r, color: chipColor),
          if (icon != null) SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: chipColor)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXAM CARD
// ═══════════════════════════════════════════════════════════════════
class _ExamCard extends StatelessWidget {
  final CourseExam exam;
  final bool isDark;
  final Color cardBg, borderColor, textColor, subTextColor, accent;
  final VoidCallback? onStart;

  const _ExamCard({
    required this.exam, required this.isDark, required this.cardBg, required this.borderColor,
    required this.textColor, required this.subTextColor, required this.accent,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final from = exam.availableFrom;
    final to = exam.availableTo;
    final isAvailable = (from == null || now.isAfter(from)) && (to == null || now.isBefore(to));
    final statusColor = exam.isPassed ? const Color(0xFF059669) : exam.hasAttempt ? const Color(0xFFEA580C) : isAvailable ? accent : subTextColor;
    final statusLabel = exam.isPassed
        ? 'نجحت ✓'
        : exam.hasAttempt
            ? '${exam.attemptScore?.toStringAsFixed(0) ?? ''} درجة'
            : isAvailable
                ? 'متاح'
                : 'غير متاح';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(exam.title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: textColor, fontSize: 14.sp)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(statusLabel, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: statusColor)),
              ),
            ],
          ),
          if (exam.description.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(exam.description, style: TextStyle(fontSize: 12.sp, fontFamily: 'Cairo', color: subTextColor)),
          ],
          SizedBox(height: 16.h),
          Row(
            children: [
              _examStat('⏱', '${exam.durationMinutes} دقيقة', 'المدة'),
              SizedBox(width: 8.w),
              _examStat('❓', '${exam.questionsCount}', 'الأسئلة'),
              SizedBox(width: 8.w),
              _examStat('📊', '${exam.totalMarks}', 'الدرجة الكلية'),
              SizedBox(width: 8.w),
              _examStat('🎯', '${exam.passingMarks}', 'درجة النجاح'),
            ],
          ),
          if (from != null) ...[
            SizedBox(height: 8.h),
            Text('📅 من ${_formatDate(from)}${to != null ? ' — إلى ${_formatDate(to)}' : ''}',
              style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: subTextColor)),
          ],
          SizedBox(height: 12.h),
          if (onStart != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable ? accent : null,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                  disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text(
                  exam.hasAttempt ? 'تم التقديم' : isAvailable ? 'ابدأ الامتحان' : 'غير متاح الآن',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _examStat(String icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: 16.sp)),
            SizedBox(height: 4.h),
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: textColor, fontSize: 12.sp)),
            Text(label, style: TextStyle(fontSize: 9.sp, fontFamily: 'Cairo', color: subTextColor)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════
// LIVE ROOM CARD
// ═══════════════════════════════════════════════════════════════════
class _LiveRoomCard extends StatelessWidget {
  final LiveSession room;
  final bool isDark;
  final Color cardBg, borderColor, textColor, subTextColor;
  final VoidCallback? onJoin;

  const _LiveRoomCard({
    required this.room, required this.isDark, required this.cardBg, required this.borderColor,
    required this.textColor, required this.subTextColor,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      'live': const Color(0xFF059669),
      'scheduled': const Color(0xFF2563EB),
      'ended': const Color(0xFF64748B),
    };
    final statusLabels = {
      'live': 'مباشر الآن',
      'scheduled': 'مجدول',
      'ended': 'انتهى',
    };
    final sColor = statusColors[room.status] ?? const Color(0xFF64748B);
    final sLabel = statusLabels[room.status] ?? 'انتهى';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: room.status == 'live' ? const Color(0xFF059669) : borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(room.title.isNotEmpty ? room.title : 'حصة مباشرة',
                  style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: textColor)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(color: sColor, borderRadius: BorderRadius.circular(4.r)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (room.status == 'live')
                      Container(
                        width: 8.r, height: 8.r,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      ),
                    if (room.status == 'live') SizedBox(width: 4.w),
                    Text(sLabel, style: TextStyle(fontSize: 11.sp, fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          if (room.description != null && room.description!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(room.description!, style: TextStyle(fontFamily: 'Cairo', color: subTextColor, fontSize: 12.sp)),
          ],
          SizedBox(height: 12.h),
          _roomInfo(Icons.person_rounded, room.teacher.isNotEmpty ? room.teacher : 'المدرس', const Color(0xFF7C3AED)),
          if (room.scheduledAt != null)
            _roomInfo(Icons.calendar_today_rounded, _formatDateTime(room.scheduledAt!), const Color(0xFF2563EB)),
          _roomInfo(Icons.people_rounded, '${room.participants} مشارك${room.maxCapacity != null ? ' (الحد الأقصى: ${room.maxCapacity})' : ''}', const Color(0xFF2563EB)),
          if (room.roomCode != null && room.roomCode!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key_rounded, size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8.w),
                  Text('🔑 ${room.roomCode}', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B))),
                ],
              ),
            ),
          SizedBox(height: 12.h),
          if (room.status == 'live' && onJoin != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onJoin,
                icon: const Icon(Icons.live_tv_rounded, size: 18),
                label: const Text('🚀 انضم الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ),
          if (room.status == 'ended')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                  disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: const Text('✅ انتهت', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roomInfo(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: iconColor),
          SizedBox(width: 8.w),
          Expanded(child: Text(text, style: TextStyle(fontFamily: 'Cairo', color: subTextColor, fontSize: 12.sp))),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} — ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════
// SESSION CARD
// ═══════════════════════════════════════════════════════════════════
class _SessionCard extends StatelessWidget {
  final UpcomingSession session;
  final bool isDark;
  final Color cardBg, borderColor, textColor, subTextColor, accent;

  const _SessionCard({
    required this.session, required this.isDark, required this.cardBg, required this.borderColor,
    required this.textColor, required this.subTextColor, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = session.type == 'online' ? 'أونلاين' : 'حضوري';
    final typeColor = session.type == 'online' ? const Color(0xFF059669) : const Color(0xFF2563EB);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(session.title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: textColor)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(typeLabel, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: typeColor)),
              ),
            ],
          ),
          if (session.description != null && session.description!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(session.description!, style: TextStyle(fontFamily: 'Cairo', color: subTextColor, fontSize: 12.sp)),
          ],
          SizedBox(height: 12.h),
          if (session.date != null)
            _sessionInfo(Icons.calendar_today_rounded,
              '${session.date!.toLocal().weekday == 6 ? 'السبت' : session.date!.toLocal().weekday == 5 ? 'الجمعة' : ''} — ${_formatDate(session.date!)}'),
          if (session.startTime != null && session.endTime != null)
            _sessionInfo(Icons.access_time_rounded, '${session.startTime} — ${session.endTime}'),
          if (session.maxStudents != null)
            _sessionInfo(Icons.person_rounded, 'الحد الأقصى: ${session.maxStudents} طالب'),
          SizedBox(height: 12.h),
          if (session.meetingLink != null && session.meetingLink!.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {/* open link */},
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('انضم للجلسة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                  disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: const Text('الرابط لم يُضف بعد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sessionInfo(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: const Color(0xFF2563EB)),
          SizedBox(width: 8.w),
          Expanded(child: Text(text, style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12.sp))),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════
// NOTIFICATION CARD
// ═══════════════════════════════════════════════════════════════════
class _NotifCard extends StatelessWidget {
  final StudentNotification notif;
  final bool isDark;
  final Color cardBg, borderColor, textColor, subTextColor, accent;
  final VoidCallback onTap;

  const _NotifCard({
    required this.notif, required this.isDark, required this.cardBg, required this.borderColor,
    required this.textColor, required this.subTextColor, required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: !notif.unread
              ? (isDark ? cardBg : Colors.white)
              : (isDark ? accent.withValues(alpha: 0.08) : const Color(0xFFEFF6FF)),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: !notif.unread ? borderColor : accent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.r, height: 44.r,
              decoration: BoxDecoration(
                color: !notif.unread
                    ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                    : accent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.notifications_rounded, size: 22.r,
                color: !notif.unread ? subTextColor : Colors.white),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(notif.title,
                          style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: textColor)),
                      ),
                      if (notif.unread)
                        Container(
                          width: 8.r, height: 8.r,
                          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (notif.body.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(notif.body,
                      style: TextStyle(fontFamily: 'Cairo', color: subTextColor, fontSize: 12.sp)),
                  ],
                  SizedBox(height: 4.h),
                  Text(notif.time,
                    style: TextStyle(fontFamily: 'Cairo', color: isDark ? const Color(0xFF475569) : subTextColor, fontSize: 10.sp)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB BAR DELEGATE
// ═══════════════════════════════════════════════════════════════════
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : const Color(0xFF2563EB),
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
