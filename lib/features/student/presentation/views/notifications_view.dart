import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../widgets/student_async_body.dart';
import '../widgets/student_shared_widgets.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView>
    with SingleTickerProviderStateMixin {
  List<StudentNotification> _notifications = [];
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<StudentRepository>().getNotifications(limit: 50);
      if (!mounted) return;
      setState(() {
        _notifications = page.notifications;
        _unreadCount = page.unreadCount;
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

  Future<void> _markAllRead() async {
    await context.read<StudentRepository>().markAllNotificationsRead();
    await _load();
  }

  Future<void> _markRead(String id) async {
    await context.read<StudentRepository>().markNotificationRead(id);
    setState(() {
      _notifications = _notifications.map((n) {
        if (n.id == id) {
          return StudentNotification(
            id: n.id,
            title: n.title,
            body: n.body,
            time: n.time,
            type: n.type,
            unread: false,
          );
        }
        return n;
      }).toList();
      _unreadCount = _notifications.where((n) => n.unread).length;
    });
  }

  List<StudentNotification> get _filtered => switch (_tab) {
    1 => _notifications.where((n) => n.unread).toList(),
    2 => _notifications.where((n) => !n.unread).toList(),
    _ => _notifications,
  };

  @override
  Widget build(BuildContext context) {
    return StudentPageShell(
      title: '🔔 الإشعارات',
      headerChild: Row(
        children: [
          Chip(
            label: Text('$_unreadCount غير مقروء'),
            backgroundColor: Colors.white24,
            labelStyle: const TextStyle(color: Colors.white),
          ),
          const Spacer(),
          TextButton(
            onPressed: _unreadCount > 0 ? _markAllRead : null,
            child: const Text('تعليم الكل كمقروء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StudentAsyncBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'الكل (${_notifications.length})'),
                Tab(text: 'غير مقروء ($_unreadCount)'),
                const Tab(text: 'مقروء'),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.r),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final n = _filtered[i];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8.h),
                    color: n.unread
                        ? (context.isDark
                        ? AppColors.primaryColor.withValues(alpha: .08)
                        : const Color(0xFFEFF6FF))
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        n.unread ? AppColors.primaryColor : context.borderColor,
                        child: Icon(
                          Icons.notifications,
                          color: n.unread ? Colors.white : context.textSecondary,
                          size: 20.sp,
                        ),
                      ),
                      title: Text(
                        n.title,
                        style: TextStyles.semiBold14.copyWith(
                          color: context.textPrimary,
                          fontWeight: n.unread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.body,
                            style: TextStyles.regular13.copyWith(color: context.textSecondary),
                          ),
                          Text(
                            n.time,
                            style: TextStyles.regular13.copyWith(color: context.textSecondary),
                          ),
                        ],
                      ),
                      trailing: n.unread
                          ? Icon(Icons.circle, color: AppColors.primaryColor, size: 8.sp)
                          : null,
                      onTap: () => _markRead(n.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}