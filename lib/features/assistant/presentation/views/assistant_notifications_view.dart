import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/assistant_repository.dart';
import 'widgets/assistant_notifications_body.dart';

class AssistantNotificationsView extends StatefulWidget {
  static const routeName = '/assistant-teacher/notifications';
  const AssistantNotificationsView({super.key});

  @override
  State<AssistantNotificationsView> createState() => _AssistantNotificationsViewState();
}

class _AssistantNotificationsViewState extends State<AssistantNotificationsView>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;
  int _page = 1;
  int _totalPages = 1;
  bool _loadingMore = false;
  late final TabController _tabController;

  AssistantRepository get _repo => context.read<AssistantRepository>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
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
    setState(() { _loading = true; _error = null; _page = 1; });
    try {
      final data = await _repo.getNotifications(limit: 50);
      if (!mounted) return;
      final notifs = (data['notifications'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _notifications = notifs;
        _unreadCount = notifs.where((n) => n['isRead'] != true && n['read'] != true).length;
        _totalPages = (data['pagination'] as Map?)?['totalPages'] as int? ?? 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'فشل تحميل الإشعارات'; _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_page >= _totalPages || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final data = await _repo.getNotifications(page: _page + 1);
      if (!mounted) return;
      final notifs = (data['notifications'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _notifications = [..._notifications, ...notifs];
        _page++;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<Map<String, dynamic>> get _filtered => switch (_tabController.index) {
        1 => _notifications.where((n) => n['isRead'] != true && n['read'] != true).toList(),
        2 => _notifications.where((n) => n['isRead'] == true || n['read'] == true).toList(),
        _ => _notifications,
      };

  Future<void> _markAllRead() async {
    try {
      await _repo.markAllNotificationsRead();
      setState(() {
        _notifications = _notifications.map((n) => {...n, 'isRead': true, 'read': true}).toList();
        _unreadCount = 0;
      });
    } catch (_) {
      if (mounted) buildSnackBar(context, 'فشل تعيين الإشعارات كمقروءة', isError: true);
    }
  }

  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['isRead'] == true || n['read'] == true) return;
    final id = (n['id'] ?? n['_id'] ?? '') as String;
    try {
      await _repo.markNotificationRead(id);
      setState(() {
        _notifications = _notifications.map((x) {
          final xId = (x['id'] ?? x['_id'] ?? '') as String;
          return xId == id ? {...x, 'isRead': true, 'read': true} : x;
        }).toList();
        _unreadCount = _notifications.where((x) => x['isRead'] != true && x['read'] != true).length;
      });
    } catch (_) {}
  }

  Future<void> _deleteOne(Map<String, dynamic> n) async {
    final id = (n['id'] ?? n['_id'] ?? '') as String;
    try {
      await _repo.deleteOneNotification(id);
      setState(() {
        _notifications = _notifications.where((x) {
          final xId = (x['id'] ?? x['_id'] ?? '') as String;
          return xId != id;
        }).toList();
        _unreadCount = _notifications.where((x) => x['isRead'] != true && x['read'] != true).length;
      });
    } catch (_) {
      if (mounted) buildSnackBar(context, 'فشل حذف الإشعار', isError: true);
    }
  }

  Future<void> _deleteAll() async {
    try {
      await _repo.deleteAllNotifications();
      setState(() { _notifications = []; _unreadCount = 0; });
    } catch (_) {
      if (mounted) buildSnackBar(context, 'فشل حذف الإشعارات', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          NotificationHeader(
            isDark: isDark,
            unreadCount: _unreadCount,
            hasNotifications: _notifications.isNotEmpty,
            onMarkAllRead: _markAllRead,
            onDeleteAll: _deleteAll,
            onBack: () => Navigator.maybePop(context),
          ),
          if (_loading)
            Expanded(child: Center(child: CircularProgressIndicator(color: const Color(0xFF059669))))
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
            NotificationTabs(
              tabController: _tabController,
              isDark: isDark,
              totalCount: _notifications.length,
              unreadCount: _unreadCount,
            ),
            Expanded(
              child: NotificationList(
                isDark: isDark,
                notifications: _filtered,
                page: _page,
                totalPages: _totalPages,
                loadingMore: _loadingMore,
                onLoadMore: _loadMore,
                onMarkRead: _markRead,
                onDelete: _deleteOne,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
