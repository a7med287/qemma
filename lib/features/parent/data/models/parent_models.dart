class ChildSummary {
  final String id;
  final String name;
  final String gradeLevel;
  final double averageGrade;
  final double attendanceRate;
  final int totalCourses;
  final int pendingAssignments;
  final int alerts;
  final String? behaviorAlert;
  final List<ChildCourse> recentCourses;
  final double overallProgress;
  final List<ChildTask> tasks;
  final List<Map<String, dynamic>> notifications;

  const ChildSummary({
    required this.id,
    required this.name,
    required this.gradeLevel,
    this.averageGrade = 0,
    this.attendanceRate = 0,
    this.totalCourses = 0,
    this.pendingAssignments = 0,
    this.alerts = 0,
    this.behaviorAlert,
    this.recentCourses = const [],
    this.overallProgress = 0,
    this.tasks = const [],
    this.notifications = const [],
  });
}

class ChildCourse {
  final String id;
  final String title;
  final double grade;
  final double progress;
  final int attendedSessions;
  final int totalSessions;
  final int pendingAssignments;
  final String? teacherName;

  const ChildCourse({
    required this.id,
    required this.title,
    this.grade = 0,
    this.progress = 0,
    this.attendedSessions = 0,
    this.totalSessions = 0,
    this.pendingAssignments = 0,
    this.teacherName,
  });
}

class ChildDetail {
  final String id;
  final String name;
  final String gradeLevel;
  final String? email;
  final String? phone;
  final double averageGrade;
  final double attendanceRate;
  final String? avatar;
  final List<ChildCourse> courses;
  final List<ChildTask> tasks;
  final List<ChildExamResult> examResults;
  final int totalCourses;
  final int pendingAssignments;
  final int upcomingExams;
  final int alerts;
  final List<Map<String, dynamic>> notifications;

  const ChildDetail({
    required this.id,
    required this.name,
    required this.gradeLevel,
    this.email,
    this.phone,
    this.averageGrade = 0,
    this.attendanceRate = 0,
    this.avatar,
    this.courses = const [],
    this.tasks = const [],
    this.examResults = const [],
    this.totalCourses = 0,
    this.pendingAssignments = 0,
    this.upcomingExams = 0,
    this.alerts = 0,
    this.notifications = const [],
  });
}

class ChildTask {
  final String id;
  final String title;
  final String? courseTitle;
  final String status;
  final DateTime? dueDate;
  final double? score;
  final double? maxScore;
  final bool completed;
  final String type;
  final String? dueLabel;

  const ChildTask({
    required this.id,
    required this.title,
    this.courseTitle,
    this.status = 'pending',
    this.dueDate,
    this.score,
    this.maxScore,
    this.completed = false,
    this.type = 'assignment',
    this.dueLabel,
  });
}

class ChildExamResult {
  final String id;
  final String title;
  final String? courseTitle;
  final double score;
  final double maxScore;
  final double? previousScore;
  final bool passed;
  final double? percentage;
  final int totalMarks;
  final DateTime? submittedAt;

  const ChildExamResult({
    required this.id,
    required this.title,
    this.courseTitle,
    this.score = 0,
    this.maxScore = 100,
    this.previousScore,
    this.passed = false,
    this.percentage,
    this.totalMarks = 0,
    this.submittedAt,
  });
}

class ChildPerformance {
  final String childId;
  final String childName;
  final double averageGrade;
  final double attendanceRate;
  final int completedAssignments;
  final int totalAssignments;
  final int? classRank;
  final List<SubjectPerformance> subjects;

  const ChildPerformance({
    required this.childId,
    required this.childName,
    this.averageGrade = 0,
    this.attendanceRate = 0,
    this.completedAssignments = 0,
    this.totalAssignments = 0,
    this.classRank,
    this.subjects = const [],
  });
}

class SubjectPerformance {
  final String subject;
  final double grade;
  final double attendance;
  final double trend;

  const SubjectPerformance({
    required this.subject,
    this.grade = 0,
    this.attendance = 0,
    this.trend = 0,
  });
}

class ParentDashboardData {
  final List<ChildSummary> children;
  final int totalChildren;
  final int activeCourses;
  final int pendingAssignments;
  final int alerts;
  final List<RecentActivity> recentActivities;
  final List<UpcomingEvent> upcomingEvents;

  const ParentDashboardData({
    this.children = const [],
    this.totalChildren = 0,
    this.activeCourses = 0,
    this.pendingAssignments = 0,
    this.alerts = 0,
    this.recentActivities = const [],
    this.upcomingEvents = const [],
  });
}

class RecentActivity {
  final String id;
  final String type;
  final String childName;
  final String text;
  final DateTime timestamp;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.childName,
    required this.text,
    required this.timestamp,
  });
}

class UpcomingEvent {
  final String id;
  final String childName;
  final String type;
  final String title;
  final DateTime date;
  final String? time;

  const UpcomingEvent({
    required this.id,
    required this.childName,
    required this.type,
    required this.title,
    required this.date,
    this.time,
  });
}

class CourseDetail {
  final String id;
  final String title;
  final String? teacherName;
  final double averageGrade;
  final double attendanceRate;
  final int attendedSessions;
  final int totalSessions;
  final int pendingAssignments;
  final List<CourseAssignment> assignments;
  final List<CourseSession> sessions;
  final List<CourseExam> exams;
  final List<GradeRecord> gradeRecords;
  final List<AttendanceRecord> attendanceRecords;

  const CourseDetail({
    required this.id,
    required this.title,
    this.teacherName,
    this.averageGrade = 0,
    this.attendanceRate = 0,
    this.attendedSessions = 0,
    this.totalSessions = 0,
    this.pendingAssignments = 0,
    this.assignments = const [],
    this.sessions = const [],
    this.exams = const [],
    this.gradeRecords = const [],
    this.attendanceRecords = const [],
  });
}

class CourseAssignment {
  final String id;
  final String title;
  final String status;
  final DateTime? dueDate;
  final double? score;
  final double? maxScore;

  const CourseAssignment({
    required this.id,
    required this.title,
    this.status = 'pending',
    this.dueDate,
    this.score,
    this.maxScore,
  });
}

class CourseSession {
  final String id;
  final String title;
  final DateTime date;
  final bool attended;
  final bool isLive;

  const CourseSession({
    required this.id,
    required this.title,
    required this.date,
    this.attended = false,
    this.isLive = false,
  });
}

class CourseExam {
  final String id;
  final String title;
  final String status;
  final DateTime? date;
  final double? score;
  final double? maxScore;

  const CourseExam({
    required this.id,
    required this.title,
    this.status = 'upcoming',
    this.date,
    this.score,
    this.maxScore,
  });
}

class GradeRecord {
  final String examTitle;
  final double score;
  final double maxScore;
  final String grade;
  final double percentage;

  const GradeRecord({
    required this.examTitle,
    required this.score,
    required this.maxScore,
    required this.grade,
    this.percentage = 0,
  });
}

class AttendanceRecord {
  final String sessionTitle;
  final DateTime date;
  final bool present;

  const AttendanceRecord({
    required this.sessionTitle,
    required this.date,
    this.present = false,
  });
}
