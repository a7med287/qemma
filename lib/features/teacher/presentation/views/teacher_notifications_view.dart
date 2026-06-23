import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';

// ── أيقونة ولون حسب نوع الإشعار ──
IconData _typeIcon(String type) => switch (type) {
      'exam' => Icons.assignment,
      'course' => Icons.school,
      'live' => Icons.videocam,
      'grade' => Icons.check_circle,
      'contest' => Icons.emoji_events,
      'schedule' => Icons.schedule,
      'book' => Icons.menu_book,
      'reminder' => Icons.warning_amber,
      'promotion' => Icons.campaign,
      'assignment' => Icons.assignment,
      'discussion' => Icons.forum,
      'resource' => Icons.folder,
      'badge' => Icons.emoji_events,
      'assistant_request' => Icons.person_add,
      'parent_request' => Icons.people,
      _ => Icons.notifications,
    };

Color _typeColor(String type) => switch (type) {
      'exam' => const Color(0xFFF59E0B),
      'course' => const Color(0xFF7C3AED),
      'live' => const Color(0xFFDB2777),
      'grade' => const Color(0xFF059669),
      'contest' => const Color(0xFFF59E0B),
      'schedule' => const Color(0xFF0891B2),
      'book' => const Color(0xFF4F46E5),
      'reminder' => const Color(0xFFDC2626),
      'promotion' => const Color(0xFFEA580C),
      'assignment' => const Color(0xFFF59E0B),
      'discussion' => const Color(0xFFEA580C),
      'resource' => const Color(0xFF4F46E5),
      'badge' => const Color(0xFF7C3AED),
      'assistant_request' => const Color(0xFF059669),
      'parent_request' => const Color(0xFFDB2777),
      _ => const Color(0xFF2563EB),
    };

String _typeLabel(String type) => switch (type) {
      'exam' => 'اختبار',
      'course' => 'كورس',
      'live' => 'حصة مباشرة',
      'grade' => 'درجة',
      'contest' => 'مسابقة',
      'schedule' => 'موعد',
      'book' => 'كتاب',
      'reminder' => 'تذكير',
      'promotion' => 'ترويج',
      'assignment' => 'واجب',
      'discussion' => 'مناقشة',
      'resource' => 'مورد',
      'badge' => 'شارة',
      'assistant_request' => 'طلب مساعد',
      'parent_request' => 'طلب ولي أمر',
      _ => 'عام',
    };

String _timeAgo(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  final d = DateTime.tryParse(dateStr);
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
  return '${d.month}/${d.day}';
}

class TeacherNotificationsView extends StatefulWidget {
  static const routeName = '/teacher/notifications';
  const TeacherNotificationsView({super.key});

  @override
  State<TeacherNotificationsView> createState() => _TeacherNotificationsViewState();
}

class _TeacherNotificationsViewState extends State<TeacherNotificationsView>
    with SingleTickerProviderStateMixin {
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  String? _error;
  int _tab = 0;
  int _unreadCount = 0;
  int _page = 1;
  int _totalPages = 1;
  bool _loadingMore = false;
  late final TabController _tabController;

  TeacherRepository get _repo => context.read<TeacherRepository>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tab = _tabController.index);
      }
    });
    _load();
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
      _page = 1;
    });
    try {
      final page = await _repo.getNotifications(limit: 50);
      if (!mounted) return;
      setState(() {
        _notifications = page.notifications;
        _unreadCount = page.unreadCount;
        _totalPages = page.totalPages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل تحميل الإشعارات';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_page >= _totalPages || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.getNotifications(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _notifications = [..._notifications, ...page.notifications];
        _page++;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<NotificationModel> get _filtered => switch (_tab) {
        1 => _notifications.where((n) => !n.isRead).toList(),
        2 => _notifications.where((n) => n.isRead).toList(),
        _ => _notifications,
      };

  Future<void> _markAllRead() async {
    try {
      await _repo.markAllNotificationsRead();
      setState(() {
        _notifications = _notifications.map((n) => NotificationModel(
          id: n.id, title: n.title, body: n.body, type: n.type,
          isRead: true, createdAt: n.createdAt,
        )).toList();
        _unreadCount = 0;
      });
    } catch (_) {
      if (mounted) _showSnackbar('فشل تعيين الإشعارات كمقروءة', Colors.red);
    }
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.isRead) return;
    try {
      await _repo.markNotificationRead(n.id);
      setState(() {
        _notifications = _notifications.map((x) =>
          x.id == n.id ? NotificationModel(
            id: x.id, title: x.title, body: x.body, type: x.type,
            isRead: true, createdAt: x.createdAt,
          ) : x,
        ).toList();
        _unreadCount = _notifications.where((x) => !x.isRead).length;
      });
    } catch (_) {}
  }

  Future<void> _deleteOne(NotificationModel n) async {
    try {
      await _repo.deleteOneNotification(n.id);
      setState(() {
        _notifications = _notifications.where((x) => x.id != n.id).toList();
        _unreadCount = _notifications.where((x) => !x.isRead).length;
      });
    } catch (_) {
      if (mounted) _showSnackbar('فشل حذف الإشعار', Colors.red);
    }
  }

  Future<void> _deleteAll() async {
    try {
      await _repo.deleteAllNotifications();
      setState(() {
        _notifications = [];
        _unreadCount = 0;
      });
    } catch (_) {
      if (mounted) _showSnackbar('فشل حذف الإشعارات', Colors.red);
    }
  }

  void _showSnackbar(String msg, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: color ?? Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(isDark),
          if (_loading)
            Expanded(child: Center(
              child: CircularProgressIndicator(color: const Color(0xFF7C3AED)),
            ))
          else if (_error != null)
            Expanded(child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48.sp, color: Colors.grey),
                  SizedBox(height: 12.h),
                  Text(_error!, style: TextStyles.regular14),
                  SizedBox(height: 16.h),
                  ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                ],
              ),
            ))
          else ...[
            _buildTabs(isDark),
            Expanded(child: _buildList(isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 20.h),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.white12),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text('الإشعارات',
                      style: TextStyles.bold20.copyWith(color: Colors.white)),
                ),
                if (_notifications.isNotEmpty) ...[
                  if (_unreadCount > 0)
                    Container(
                      margin: EdgeInsets.only(left: 8.w),
                      child: TextButton.icon(
                        onPressed: _markAllRead,
                        icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
                        label: Text('تحديد الكل مقروء',
                            style: TextStyle(color: Colors.white, fontSize: 11.sp)),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white12,
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        ),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: _deleteAll,
                    icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 18),
                    label: Text('حذف الكل',
                        style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white10,
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text(
                _loading ? 'جارٍ التحميل...' : 'لديك $_unreadCount إشعار غير مقروء',
                style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    final readCount = _notifications.length - _unreadCount;
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF7C3AED),
        labelColor: const Color(0xFF7C3AED),
        unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'الكل (${_notifications.length})'),
          Tab(text: 'غير مقروء ($_unreadCount)'),
          Tab(text: 'مقروء ($readCount)'),
        ],
      ),
    );
  }

  Widget _buildList(bool isDark) {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off, size: 64.sp,
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text(
              _tab == 1 ? 'لا توجد إشعارات غير مقروءة' : 'لا توجد إشعارات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(12.r),
      itemCount: list.length + (_page < _totalPages ? 1 : 0),
      itemBuilder: (_, i) {
        if (i >= list.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: _loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _loadMore,
                      child: Text('تحميل المزيد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: const Color(0xFF7C3AED),
                            fontWeight: FontWeight.w600,
                          )),
                    ),
            ),
          );
        }
        return _buildNotificationCard(list[i], isDark);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel n, bool isDark) {
    final color = _typeColor(n.type);
    final isNew = !n.isRead;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Material(
        color: isNew
            ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))
            : Colors.transparent,
        child: InkWell(
          onTap: () => _markRead(n),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isNew ? const Color(0xFF2563EB) : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNew)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h, left: 6.w),
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Container(
                  width: 44.w, height: 44.w,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(_typeIcon(n.type), color: color, size: 20.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.sp,
                            fontWeight: isNew ? FontWeight.w700 : FontWeight.w500,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                          )),
                      if (n.body.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(n.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.sp,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            )),
                      ],
                      SizedBox(height: 4.h),
                      Wrap(
                        spacing: 6.w,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              _typeLabel(n.type),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          Text(
                            _timeAgo(n.createdAt),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.sp,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (isNew)
                      IconButton(
                        onPressed: () => _markRead(n),
                        icon: const Icon(Icons.done_all, size: 18),
                        color: const Color(0xFF2563EB),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'تحديد كمقروء',
                      ),
                    SizedBox(height: 4.h),
                    IconButton(
                      onPressed: () => _deleteOne(n),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
