import 'package:flutter/material.dart';
import '../views/parent_dashboard_view.dart';
import '../views/parent_notifications_view.dart';
import '../views/child_progress_view.dart';
import '../views/child_details_view.dart';
import '../views/course_details_view.dart';
import '../views/reports_view.dart';
import '../views/parent_profile_view.dart';

abstract final class ParentRoutes {
  static const dashboard = '/parent/dashboard';
  static const notifications = '/parent/notifications';
  static const children = '/parent/children';
  static const childDetails = '/parent/child';
  static const courseDetails = '/parent/child/course';
  static const reports = '/parent/reports';
  static const profile = '/parent/profile';

  static Map<String, WidgetBuilder> get routes => {
        dashboard: (_) => const ParentDashboardView(),
        notifications: (_) => const ParentNotificationsView(),
        children: (_) => const ChildProgressView(),
        reports: (_) => const ReportsView(),
        profile: (_) => const ParentProfileView(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');
    if (uri == null) return null;

    final path = uri.path;

    if (path.startsWith('/parent/child/') && path.contains('/course/')) {
      final parts = path.split('/');
      final courseIdx = parts.indexOf('course');
      if (courseIdx >= 2 && courseIdx + 1 < parts.length) {
        final childId = parts[courseIdx - 1];
        final courseId = parts[courseIdx + 1];
        return MaterialPageRoute(
          builder: (_) => CourseDetailsView(childId: childId, courseId: courseId),
        );
      }
    }

    final childMatch = RegExp(r'^/parent/child/([^/]+)$').firstMatch(path);
    if (childMatch != null) {
      return MaterialPageRoute(
        builder: (_) => ChildDetailsView(childId: childMatch.group(1)!),
      );
    }

    return null;
  }
}
