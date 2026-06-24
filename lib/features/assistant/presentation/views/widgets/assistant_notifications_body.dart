import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

class NotificationHeader extends StatelessWidget {
  final bool isDark;
  final int unreadCount;
  final bool hasNotifications;
  final VoidCallback onMarkAllRead;
  final VoidCallback onDeleteAll;
  final VoidCallback onBack;

  const NotificationHeader({
    super.key,
    required this.isDark,
    required this.unreadCount,
    required this.hasNotifications,
    required this.onMarkAllRead,
    required this.onDeleteAll,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF047857), Color(0xFF065F46)],
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
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.white12),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text('الإشعارات', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white)),
                ),
                if (hasNotifications) ...[
                  if (unreadCount > 0)
                    Container(
                      margin: EdgeInsets.only(left: 8.w),
                      child: TextButton.icon(
                        onPressed: onMarkAllRead,
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
                    onPressed: onDeleteAll,
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
                'لديك $unreadCount إشعار غير مقروء',
                style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationTabs extends StatelessWidget {
  final TabController tabController;
  final bool isDark;
  final int totalCount;
  final int unreadCount;

  const NotificationTabs({
    super.key,
    required this.tabController,
    required this.isDark,
    required this.totalCount,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final readCount = totalCount - unreadCount;
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: TabBar(
        controller: tabController,
        indicatorColor: const Color(0xFF059669),
        labelColor: const Color(0xFF059669),
        unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'الكل ($totalCount)'),
          Tab(text: 'غير مقروء ($unreadCount)'),
          Tab(text: 'مقروء ($readCount)'),
        ],
      ),
    );
  }
}

class NotificationList extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> notifications;
  final int page;
  final int totalPages;
  final bool loadingMore;
  final VoidCallback onLoadMore;
  final void Function(Map<String, dynamic>) onMarkRead;
  final void Function(Map<String, dynamic>) onDelete;

  const NotificationList({
    super.key,
    required this.isDark,
    required this.notifications,
    required this.page,
    required this.totalPages,
    required this.loadingMore,
    required this.onLoadMore,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off, size: 64.sp, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text(
              'لا توجد إشعارات',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(12.r),
      itemCount: notifications.length + (page < totalPages ? 1 : 0),
      itemBuilder: (_, i) {
        if (i >= notifications.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: onLoadMore,
                      child: const Text('تحميل المزيد',
                          style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                    ),
            ),
          );
        }
        return _NotificationCard(
          notification: notifications[i],
          isDark: isDark,
          onMarkRead: () => onMarkRead(notifications[i]),
          onDelete: () => onDelete(notifications[i]),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final bool isDark;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = (notification['type'] ?? '') as String;
    final color = _typeColor(type);
    final title = (notification['title'] ?? '') as String;
    final body = (notification['body'] ?? notification['message'] ?? '') as String;
    final isNew = notification['isRead'] != true && notification['read'] != true;
    final createdAt = notification['createdAt'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Material(
        color: isNew ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)) : Colors.transparent,
        child: InkWell(
          onTap: onMarkRead,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isNew ? const Color(0xFF059669) : Colors.transparent,
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
                      decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
                    ),
                  ),
                Container(
                  width: 44.w, height: 44.w,
                  decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(12.r)),
                  child: Icon(_typeIcon(type), color: color, size: 20.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cairo', fontSize: 13.sp,
                            fontWeight: isNew ? FontWeight.w700 : FontWeight.w500,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                          )),
                      if (body.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(body,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      ],
                      SizedBox(height: 4.h),
                      Wrap(
                        spacing: 6.w,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(_typeLabel(type),
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp,
                                    fontWeight: FontWeight.w600, color: color)),
                          ),
                          Text(_timeAgo(createdAt),
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (isNew)
                      IconButton(
                        onPressed: onMarkRead,
                        icon: const Icon(Icons.done_all, size: 18),
                        color: const Color(0xFF059669),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'تحديد كمقروء',
                      ),
                    SizedBox(height: 4.h),
                    IconButton(
                      onPressed: onDelete,
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
