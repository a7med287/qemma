import 'parent_models.dart';

abstract final class ParentModelJson {
  static ChildSummary childSummaryFromJson(Map<String, dynamic> json) {
    final courses = (json['recentCourses'] as List?)
            ?.map((e) => childCourseFromJson(e))
            .toList() ??
        [];
    return ChildSummary(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      gradeLevel: json['gradeLevel'] ?? '',
      averageGrade: _toDouble(json['averageGrade']),
      attendanceRate: _toDouble(json['attendanceRate']),
      totalCourses: _toInt(json['totalCourses']),
      pendingAssignments: _toInt(json['pendingAssignments']),
      alerts: _toInt(json['alerts']),
      behaviorAlert: json['behaviorAlert'],
      recentCourses: courses,
      overallProgress: _toDouble(json['overallProgress']),
    );
  }

  static ChildCourse childCourseFromJson(Map<String, dynamic> json) {
    return ChildCourse(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      grade: _toDouble(json['grade']),
      progress: _toDouble(json['progress']),
      attendedSessions: _toInt(json['attendedSessions']),
      totalSessions: _toInt(json['totalSessions']),
      pendingAssignments: _toInt(json['pendingAssignments']),
      teacherName: json['teacherName'],
    );
  }

  static ChildDetail childDetailFromJson(Map<String, dynamic> json) {
    return ChildDetail(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      gradeLevel: json['gradeLevel'] ?? '',
      email: json['email'],
      phone: json['phone'],
      averageGrade: _toDouble(json['averageGrade']),
      attendanceRate: _toDouble(json['attendanceRate']),
      avatar: json['avatar'],
      courses: (json['courses'] as List?)?.map((e) => childCourseFromJson(e)).toList() ?? [],
      tasks: (json['tasks'] as List?)?.map((e) => childTaskFromJson(e)).toList() ?? [],
      examResults: (json['examResults'] as List?)?.map((e) => childExamResultFromJson(e)).toList() ?? [],
      totalCourses: _toInt(json['totalCourses']),
      pendingAssignments: _toInt(json['pendingAssignments']),
      upcomingExams: _toInt(json['upcomingExams']),
      alerts: _toInt(json['alerts']),
    );
  }

  static ChildTask childTaskFromJson(Map<String, dynamic> json) {
    return ChildTask(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      courseTitle: json['courseTitle'],
      status: json['status'] ?? 'pending',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      score: _toDoubleOrNull(json['score']),
      maxScore: _toDoubleOrNull(json['maxScore']),
    );
  }

  static ChildExamResult childExamResultFromJson(Map<String, dynamic> json) {
    final score = _toDouble(json['score']);
    final maxScore = _toDouble(json['maxScore'] ?? 100);
    return ChildExamResult(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      courseTitle: json['courseTitle'],
      score: score,
      maxScore: maxScore,
      previousScore: _toDoubleOrNull(json['previousScore']),
      passed: json['passed'] ?? score >= maxScore * 0.5,
    );
  }

  static ChildPerformance childPerformanceFromJson(Map<String, dynamic> json) {
    return ChildPerformance(
      childId: json['childId'] ?? json['_id'] ?? json['id'] ?? '',
      childName: json['childName'] ?? json['name'] ?? '',
      averageGrade: _toDouble(json['averageGrade']),
      attendanceRate: _toDouble(json['attendanceRate']),
      completedAssignments: _toInt(json['completedAssignments']),
      totalAssignments: _toInt(json['totalAssignments']),
      classRank: json['classRank'] is int ? json['classRank'] as int : null,
      subjects: (json['subjects'] as List?)?.map((e) => subjectPerformanceFromJson(e)).toList() ?? [],
    );
  }

  static SubjectPerformance subjectPerformanceFromJson(Map<String, dynamic> json) {
    return SubjectPerformance(
      subject: json['subject'] ?? '',
      grade: _toDouble(json['grade']),
      attendance: _toDouble(json['attendance']),
      trend: _toDouble(json['trend']),
    );
  }

  static RecentActivity recentActivityFromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      childName: json['childName'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static UpcomingEvent upcomingEventFromJson(Map<String, dynamic> json) {
    return UpcomingEvent(
      id: json['_id'] ?? json['id'] ?? '',
      childName: json['childName'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date']) ?? DateTime.now() : DateTime.now(),
      time: json['time'],
    );
  }

  static CourseDetail courseDetailFromJson(Map<String, dynamic> json) {
    return CourseDetail(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      teacherName: json['teacherName'],
      averageGrade: _toDouble(json['averageGrade']),
      attendanceRate: _toDouble(json['attendanceRate']),
      attendedSessions: _toInt(json['attendedSessions']),
      totalSessions: _toInt(json['totalSessions']),
      pendingAssignments: _toInt(json['pendingAssignments']),
      assignments:
          (json['assignments'] as List?)?.map((e) => courseAssignmentFromJson(e)).toList() ?? [],
      sessions: (json['sessions'] as List?)?.map((e) => courseSessionFromJson(e)).toList() ?? [],
      exams: (json['exams'] as List?)?.map((e) => courseExamFromJson(e)).toList() ?? [],
      gradeRecords:
          (json['gradeRecords'] as List?)?.map((e) => gradeRecordFromJson(e)).toList() ?? [],
      attendanceRecords:
          (json['attendanceRecords'] as List?)?.map((e) => attendanceRecordFromJson(e)).toList() ?? [],
    );
  }

  static CourseAssignment courseAssignmentFromJson(Map<String, dynamic> json) {
    return CourseAssignment(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? 'pending',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      score: _toDoubleOrNull(json['score']),
      maxScore: _toDoubleOrNull(json['maxScore']),
    );
  }

  static CourseSession courseSessionFromJson(Map<String, dynamic> json) {
    return CourseSession(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date']) ?? DateTime.now() : DateTime.now(),
      attended: json['attended'] ?? false,
      isLive: json['isLive'] ?? false,
    );
  }

  static CourseExam courseExamFromJson(Map<String, dynamic> json) {
    return CourseExam(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? 'upcoming',
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      score: _toDoubleOrNull(json['score']),
      maxScore: _toDoubleOrNull(json['maxScore']),
    );
  }

  static GradeRecord gradeRecordFromJson(Map<String, dynamic> json) {
    final score = _toDouble(json['score']);
    final maxScore = _toDouble(json['maxScore'] ?? 100);
    return GradeRecord(
      examTitle: json['examTitle'] ?? '',
      score: score,
      maxScore: maxScore,
      grade: json['grade'] ?? _letterGrade(score / maxScore),
      percentage: maxScore > 0 ? (score / maxScore) * 100 : 0,
    );
  }

  static AttendanceRecord attendanceRecordFromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      sessionTitle: json['sessionTitle'] ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date']) ?? DateTime.now() : DateTime.now(),
      present: json['present'] ?? json['attended'] ?? false,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String _letterGrade(double ratio) {
    if (ratio >= 0.97) return 'A+';
    if (ratio >= 0.93) return 'A';
    if (ratio >= 0.90) return 'A-';
    if (ratio >= 0.87) return 'B+';
    if (ratio >= 0.83) return 'B';
    if (ratio >= 0.80) return 'B-';
    if (ratio >= 0.77) return 'C+';
    if (ratio >= 0.73) return 'C';
    if (ratio >= 0.70) return 'C-';
    if (ratio >= 0.67) return 'D+';
    if (ratio >= 0.60) return 'D';
    return 'F';
  }
}
