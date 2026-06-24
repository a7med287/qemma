import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../data/models/parent_models.dart';
import '../../routes/parent_routes.dart';

String formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'منذ لحظات';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
  return '${dt.day}/${dt.month}/${dt.year}';
}

String formatDate(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year}';
}

class EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40.sp,
            color: context.textSecondary.withValues(alpha: .3),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyles.semiBold14.copyWith(color: context.textSecondary),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyles.regular13.copyWith(
              color: context.textSecondary.withValues(alpha: .7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool showViewAll;
  final bool showAdd;
  final VoidCallback? onAdd;

  const DashboardSectionHeader(
    this.title,
    this.icon, {
    super.key,
    this.showViewAll = false,
    this.showAdd = false,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20.sp, color: context.textPrimary),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyles.bold18.copyWith(color: context.textPrimary),
            ),
          ),
          if (showAdd)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'إضافة طالب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (showViewAll)
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, ParentRoutes.children),
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: accent ? const Color(0xFFDB2777) : context.borderColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: accent ? const Color(0xFFDB2777) : context.textPrimary,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyles.semiBold13.copyWith(
                color: accent ? const Color(0xFFDB2777) : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionsSection extends StatelessWidget {
  final VoidCallback onAddChild;

  const QuickActionsSection({super.key, required this.onAddChild});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.borderColor.withValues(alpha: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إجراءات سريعة',
              style: TextStyles.bold18.copyWith(color: context.textPrimary),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.people,
                    label: 'الأبناء',
                    onTap: () =>
                        Navigator.pushNamed(context, ParentRoutes.children),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.assessment,
                    label: 'التقارير',
                    onTap: () =>
                        Navigator.pushNamed(context, ParentRoutes.reports),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.person_add,
                    label: 'إضافة طالب',
                    accent: true,
                    onTap: onAddChild,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  final RecentActivity activity;

  const ActivityItem({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    switch (activity.type) {
      case 'success':
      case 'exam':
        icon = Icons.check_circle;
        iconColor = const Color(0xFF059669);
      case 'warning':
      case 'assignment':
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFD97706);
      case 'error':
        icon = Icons.cancel;
        iconColor = const Color(0xFFEF4444);
      default:
        icon = Icons.event_available;
        iconColor = const Color(0xFF2563EB);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${activity.childName}: ',
                        style: TextStyles.semiBold14.copyWith(
                          color: context.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: activity.text,
                        style: TextStyles.regular14.copyWith(
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  formatTimestamp(activity.timestamp),
                  style: TextStyles.regular13.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecentActivitiesSection extends StatelessWidget {
  final List<RecentActivity> activities;

  const RecentActivitiesSection({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.borderColor.withValues(alpha: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'النشاط الأخير',
              style: TextStyles.bold18.copyWith(color: context.textPrimary),
            ),
            SizedBox(height: 12.h),
            if (activities.isEmpty)
              const EmptyPlaceholder(
                icon: Icons.history,
                title: 'لا توجد أنشطة حديثة',
                subtitle: 'ستظهر أنشطة أبنائك هنا',
              )
            else
              ...activities.take(5).map((a) => ActivityItem(activity: a)),
          ],
        ),
      ),
    );
  }
}

class EventItem extends StatelessWidget {
  final UpcomingEvent event;

  const EventItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isExam = event.type == 'exam';
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: context.borderColor.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  event.childName,
                  style: TextStyles.semiBold13.copyWith(color: Colors.white),
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isExam
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  isExam ? 'اختبار' : 'مهمة',
                  style: TextStyles.semiBold13.copyWith(
                    color: isExam
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            event.title,
            style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 12.sp,
                color: context.textSecondary,
              ),
              SizedBox(width: 4.w),
              Text(
                formatDate(event.date),
                style: TextStyles.regular13.copyWith(
                  color: context.textSecondary,
                ),
              ),
              if (event.time != null && event.time!.isNotEmpty) ...[
                SizedBox(width: 12.w),
                Icon(
                  Icons.access_time,
                  size: 12.sp,
                  color: context.textSecondary,
                ),
                SizedBox(width: 4.w),
                Text(
                  event.time!,
                  style: TextStyles.regular13.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class UpcomingEventsSection extends StatelessWidget {
  final List<UpcomingEvent> events;

  const UpcomingEventsSection({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.borderColor.withValues(alpha: .5)),
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'الأحداث القادمة',
                style: TextStyles.bold18.copyWith(color: context.textPrimary),
              ),
              SizedBox(height: 12.h),
              if (events.isEmpty)
                const EmptyPlaceholder(
                  icon: Icons.calendar_today,
                  title: 'لا توجد أحداث قادمة',
                  subtitle: 'ستظهر اختبارات وواجبات أبنائك هنا',
                )
              else
                ...events.take(5).map((e) => EventItem(event: e)),
            ],
          ),
        ),
      ),
    );
  }
}
