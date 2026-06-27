import 'package:flutter/material.dart';
import '../views/ask_teacher_view.dart';
import '../views/book_details_view.dart';
import '../views/book_office_hour_view.dart';
import '../views/books_view.dart';
import '../views/contests_view.dart';
import '../views/course_dashboard_view.dart';
import '../views/exam_review_view.dart';
import '../views/exams_view.dart';
import '../views/lesson_view.dart';
import '../views/live_class_view.dart';
import '../views/my_courses_view.dart';
import '../views/notifications_view.dart';
import '../views/performance_report_view.dart';
import '../views/student_contest_dashboard_view.dart';
import '../views/student_dashboard_view.dart';
import '../views/student_profile_view.dart';
import '../views/submit_assignment_view.dart';
import '../views/take_contest_view.dart';
import '../views/take_exam_view.dart';
import '../views/tasks_view.dart';

abstract final class StudentRoutes {
  static const dashboard = '/student/dashboard';
  static const courses = '/student/courses';
  static const exams = '/student/exams';
  static const liveClass = '/student/live-class';
  static const notifications = '/student/notifications';
  static const tasks = '/student/tasks';
  static const books = '/student/books';
  static const contests = '/student/contests';
  static const contestDashboard = '/student/contests/dashboard';
  static const submitAssignment = '/student/submit-assignment';
  static const performance = '/student/performance';
  static const profile = '/student/profile';
  static Map<String, WidgetBuilder> get routes => {
    dashboard: (_) => const StudentDashboardView(),
    courses: (_) => const MyCoursesView(),
    exams: (_) => const ExamsView(),
    liveClass: (_) => const LiveClassView(),
    notifications: (_) => const NotificationsView(),
    tasks: (_) => const TasksView(),
    books: (_) => const BooksView(),
    contests: (_) => const ContestsView(),
    contestDashboard: (_) => const StudentContestDashboardView(),
    submitAssignment: (_) => const SubmitAssignmentView(),
    performance: (_) => const PerformanceReportView(),
    profile: (_) => const StudentProfileView(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    final args = settings.arguments;

    if (name.startsWith('/student/course/')) {
      final segments = name.split('/');
      if (segments.length >= 4) {
        final courseId = segments[3];
        if (segments.length >= 6 && segments[4] == 'lesson') {
          return _page(LessonView(courseId: courseId, lessonId: segments[5]));
        }
        if (segments.length >= 5 && segments[4] == 'ask-teacher') {
          return _page(AskTeacherView(courseId: courseId));
        }
        if (segments.length >= 5 && segments[4] == 'book-office-hour') {
          return _page(BookOfficeHourView(courseId: courseId));
        }
        return _page(CourseDashboardView(courseId: courseId));
      }
    }

    if (name.startsWith('/student/contests/') && name != contestDashboard) {
      final segments = name.split('/');
      if (segments.length >= 4) {
        return _page(TakeContestView(contestId: segments[3]));
      }
    }

    if (name.startsWith('/student/exam/')) {
      final segments = name.split('/');
      if (segments.length >= 4) {
        final examId = segments[3];
        if (segments.length >= 5 && segments[4] == 'start') {
          return _page(TakeExamView(examId: examId));
        }
        if (segments.length >= 5 && segments[4] == 'review') {
          return _page(ExamReviewView(examId: examId));
        }
      }
    }

    if (name.startsWith('/student/books/')) {
      final segments = name.split('/');
      if (segments.length >= 4) {
        return _page(BookDetailsView(bookId: segments[3]));
      }
    }

    if (name == submitAssignment && args is Map<String, dynamic>) {
      return _page(SubmitAssignmentView(
        assignmentId: args['assignmentId'] as String?,
      ));
    }

    return null;
  }

  static MaterialPageRoute<dynamic> _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }

  static void pushCourse(BuildContext context, String courseId) {
    Navigator.pushNamed(context, '/student/course/$courseId');
  }

  static void pushLesson(BuildContext context, String courseId, String lessonId) {
    Navigator.pushNamed(context, '/student/course/$courseId/lesson/$lessonId');
  }

  static void pushExamStart(BuildContext context, String examId) {
    Navigator.pushNamed(context, '/student/exam/$examId/start');
  }

  static void pushExamReview(BuildContext context, String examId) {
    Navigator.pushNamed(context, '/student/exam/$examId/review');
  }

  static void pushBook(BuildContext context, String bookId) {
    Navigator.pushNamed(context, '/student/books/$bookId');
  }
}