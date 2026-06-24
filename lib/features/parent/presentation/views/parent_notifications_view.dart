import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../widgets/parent_async_body.dart';
import '../widgets/parent_shared_widgets.dart';

class ParentNotificationsView extends StatefulWidget {
  static const routeName = '/parent/notifications';
  const ParentNotificationsView({super.key});

  @override
  State<ParentNotificationsView> createState() => _ParentNotificationsViewState();
}

class _ParentNotificationsViewState extends State<ParentNotificationsView>
    with SingleTickerProviderStateMixin {
  List<_ParentNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;
  String? _error;
  int _tab = 0;
  late final TabController _tabController;

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

  Dio get _dio => context.read<ApiClient>().dio;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.get('/notifications');
      final data = unwrapBody(res.data);
      final list = data is List ? data : (data['notifications'] ?? data['data'] ?? []);
      final notifications = (list as List).map((e) => _ParentNotification(
        id: e['_id'] ?? e['id'] ?? '',
        text: e['text'] ?? e['message'] ?? '',
        type: e['type'] ?? 'general',
        timestamp: e['timestamp'] != null ? DateTime.tryParse(e['timestamp']) ?? DateTime.now() : DateTime.now(),
        read: e['read'] ?? e['isRead'] ?? false,
        category: e['category'] ?? '',
      )).toList();
      setState(() {
        _notifications = notifications;
        _unreadCount = notifications.where((n) => !n.read).length;
      });
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'فشل تحميل الإشعارات');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await _dio.put('/notifications/$id/read');
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == id);
        if (idx != -1) {
          _notifications[idx] = _notifications[idx].copyWith(read: true);
          _unreadCount = _notifications.where((n) => !n.read).length;
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _dio.put('/notifications/read-all');
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
        _unreadCount = 0;
      });
      if (mounted) buildSnackBar(context, 'تم تحديد الكل كمقروء');
    } catch (_) {}
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _dio.delete('/notifications/$id');
      setState(() {
        final removed = _notifications.firstWhere((n) => n.id == id);
        _notifications.removeWhere((n) => n.id == id);
        if (!removed.read) _unreadCount = _notifications.where((n) => !n.read).length;
      });
    } catch (_) {}
  }

  Future<void> _deleteAll() async {
    try {
      await Future.wait(_notifications.map((n) => _dio.delete('/notifications/${n.id}')));
      setState(() { _notifications = []; _unreadCount = 0; });
      if (mounted) buildSnackBar(context, 'تم حذف جميع الإشعارات');
    } catch (_) {}
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'exam': return Icons.quiz;
      case 'grade': return Icons.grade;
      case 'assignment': return Icons.assignment;
      case 'course': return Icons.menu_book;
      case 'live': return Icons.videocam;
      case 'schedule': return Icons.calendar_today;
      case 'contest': return Icons.emoji_events;
      case 'badge': return Icons.workspace_premium;
      case 'reminder': return Icons.notifications_active;
      default: return Icons.notifications_outlined;
    }
  }

  List<_ParentNotification> get _filtered {
    switch (_tab) {
      case 1: return _notifications.where((n) => !n.read).toList();
      case 2: return _notifications.where((n) => n.read).toList();
      default: return _notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ParentGradientHeader(
            title: 'الإشعارات',
            subtitle: _loading ? null : '$_unreadCount غير مقروء',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_unreadCount > 0)
                  IconButton(
                    onPressed: _markAllRead,
                    icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
                    tooltip: 'تحديد الكل كمقروء',
                  ),
                if (_notifications.isNotEmpty)
                  IconButton(
                    onPressed: _deleteAll,
                    icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 20),
                    tooltip: 'حذف الكل',
                  ),
              ],
            ),
            height: 150,
          ),
          Material(
            color: context.cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.gradientMid,
              unselectedLabelColor: context.textSecondary,
              indicatorColor: AppColors.gradientMid,
              tabs: const [
                Tab(text: 'الكل'),
                Tab(text: 'غير مقروء'),
                Tab(text: 'مقروء'),
              ],
            ),
          ),
          Expanded(
            child: ParentAsyncBody(
              loading: _loading,
              error: _error,
              onRetry: _load,
              builder: () {
                final items = _filtered;
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64.sp, color: context.textSecondary.withValues(alpha: .5)),
                        SizedBox(height: 16.h),
                        Text('لا توجد إشعارات', style: TextStyles.semiBold16.copyWith(color: context.textSecondary)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: context.borderColor, indent: 16.w, endIndent: 16.w),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.w),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteNotification(n.id),
                        child: ListTile(
                          leading: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: AppColors.gradientMid.withValues(alpha: n.read ? .05 : .12),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(_typeIcon(n.type), color: AppColors.gradientMid, size: 20.sp),
                          ),
                          title: Text(
                            n.text,
                            style: TextStyles.semiBold14.copyWith(
                              color: context.textPrimary,
                              fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            _formatTime(n.timestamp),
                            style: TextStyles.regular13.copyWith(color: context.textSecondary),
                          ),
                          trailing: n.read
                              ? null
                              : GestureDetector(
                                  onTap: () => _markRead(n.id),
                                  child: Container(
                                    width: 8.w,
                                    height: 8.w,
                                    decoration: const BoxDecoration(
                                      color: AppColors.gradientMid,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                          onTap: n.read ? null : () => _markRead(n.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ParentNotification {
  final String id;
  final String text;
  final String type;
  final DateTime timestamp;
  final bool read;
  final String category;

  const _ParentNotification({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    this.read = false,
    this.category = '',
  });

  _ParentNotification copyWith({bool? read}) => _ParentNotification(
    id: id, text: text, type: type, timestamp: timestamp,
    read: read ?? this.read, category: category,
  );
}
