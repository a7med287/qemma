import 'parent_models.dart';

abstract final class ParentModelJson {
  static ChildSummary childSummaryFromJson(Map<String, dynamic> json) {
    final courses = (json['recentCourses'] as List?)
            ?.map((e) => childCourseFromJson(e))
            .toList() ??
        [];
    final dashboard = json['dashboard'] as Map<String, dynamic>?;
    final kpis = json['kpis'] as List? ?? [];

    double fromKpis(String type) {
      for (final k in kpis) {
        if (k is Map<String, dynamic>) {
          final t = k['type'] ?? k['key'] ?? k['metric'] ?? '';
          if (t == type) return _toDouble(k['value'] ?? k['score']);
        }
      }
      return 0;
    }

    double averageGrade = _toDouble(json['averageGrade']);
    if (averageGrade == 0 && dashboard != null) averageGrade = _toDouble(dashboard['averageGrade']);
    if (averageGrade == 0) averageGrade = fromKpis('avgGrade') + fromKpis('averageGrade');

    double attendance = _toDouble(json['attendanceRate']);
    if (attendance == 0) attendance = _toDouble(json['attendance']);
    if (attendance == 0 && dashboard != null) attendance = _toDouble(dashboard['attendance']);
    if (attendance == 0) attendance = fromKpis('attendance');

    int totalCourses = _toInt(json['totalCourses']);
    if (totalCourses == 0 && dashboard != null) totalCourses = _toInt(dashboard['totalCourses']);
    if (totalCourses == 0 && json['enrolledCourses'] is List) totalCourses = (json['enrolledCourses'] as List).length;
    if (totalCourses == 0) {
      final stats = json['stats'] as Map<String, dynamic>?;
      if (stats != null) totalCourses = _toInt(stats['totalEnrolled']);
    }

    int pendingAssignments = _toInt(json['pendingAssignments']);
    if (pendingAssignments == 0 && dashboard != null) pendingAssignments = _toInt(dashboard['pendingAssignments']);
    if (pendingAssignments == 0 && json['tasks'] is List) {
      pendingAssignments = (json['tasks'] as List).where((t) {
        if (t is Map<String, dynamic>) return t['type'] == 'assignment' && t['completed'] != true;
        return false;
      }).length;
    }

    int alerts = _toInt(json['alerts']);
    if (alerts == 0 && json['alerts'] is List) alerts = (json['alerts'] as List).length;
    if (alerts == 0 && dashboard != null) alerts = _toInt(dashboard['behaviorAlerts']);
    if (alerts == 0) alerts = _toInt(json['behaviorAlerts']);

    final rawTasks = json['tasks'] as List? ?? [];
    final tasks = rawTasks.map((t) {
      if (t is Map<String, dynamic>) return childTaskFromJson(t);
      return ChildTask(id: '', title: '');
    }).toList();

    final rawNotifications = json['notifications'] as List? ?? [];
    final notifications = rawNotifications.whereType<Map<String, dynamic>>().toList();

    return ChildSummary(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      gradeLevel: json['gradeLevel'] ?? json['grade'] ?? '',
      averageGrade: averageGrade,
      attendanceRate: attendance,
      totalCourses: totalCourses,
      pendingAssignments: pendingAssignments,
      alerts: alerts,
      behaviorAlert: json['behaviorAlert'] ?? json['behaviorAlerts']?.toString(),
      recentCourses: courses,
      overallProgress: _toDouble(json['overallProgress']),
      tasks: tasks,
      notifications: notifications,
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
    // Dashboard API returns { student: {...}, kpis: [...], ... }
    final student = json['student'] as Map<String, dynamic>? ?? json;

    final kpis = json['kpis'] as List? ?? [];
    double fromKpis(String type) {
      for (final k in kpis) {
        if (k is Map<String, dynamic>) {
          final t = k['type'] ?? k['key'] ?? '';
          if (t == type) return _toDouble(k['value'] ?? k['score']);
        }
      }
      return 0;
    }

    final rawAlerts = json['alerts'];
    final alertsCount = rawAlerts is List ? rawAlerts.length : _toInt(rawAlerts);

    double averageGrade = _toDouble(student['averageGrade']);
    if (averageGrade == 0 && kpis.isNotEmpty) {
      averageGrade = fromKpis('avgGrade') + fromKpis('averageGrade');
    }

    double attendance = _toDouble(student['attendanceRate']);
    if (attendance == 0) attendance = _toDouble(student['attendance']);
    if (attendance == 0 && kpis.isNotEmpty) attendance = fromKpis('attendance');

    return ChildDetail(
      id: student['_id'] ?? student['id'] ?? json['_id'] ?? json['id'] ?? '',
      name: student['name'] ?? json['name'] ?? '',
      gradeLevel: student['gradeLevel'] ?? student['stream'] ?? student['grade'] ?? json['gradeLevel'] ?? '',
      email: student['email'] ?? json['email'],
      phone: student['phone'] ?? json['phone'],
      averageGrade: averageGrade,
      attendanceRate: attendance,
      avatar: student['avatar'] ?? json['avatar'],
      courses: (json['courses'] as List?)?.map((e) => childCourseFromJson(e)).toList() ?? [],
      tasks: _parseDetailTasks(json),
      examResults: (json['examResults'] as List?)?.map((e) => childExamResultFromJson(e)).toList() ?? [],
      totalCourses: _toInt(student['totalCourses']),
      pendingAssignments: _toInt(json['pendingAssignments']),
      upcomingExams: _toInt(json['upcomingExams']),
      alerts: alertsCount,
    );
  }

  static List<ChildTask> _parseDetailTasks(Map<String, dynamic> json) {
    // Try flat tasks list first
    final flat = json['tasks'] as List?;
    if (flat != null) return flat.map((e) => childTaskFromJson(e)).toList();
    // Try tasks.pendingAssignments (frontend pattern)
    final tasksObj = json['tasks'] as Map<String, dynamic>?;
    if (tasksObj != null) {
      final pending = tasksObj['pendingAssignments'] as List? ?? [];
      final result = pending.map((e) => childTaskFromJson(e)).toList();
      // Also add pending exams as tasks
      final exams = tasksObj['pendingExams'] as List? ?? [];
      for (final e in exams) {
        if (e is Map<String, dynamic>) {
          result.add(ChildTask(
            id: e['_id'] ?? e['id'] ?? '',
            title: e['title'] ?? '',
            courseTitle: e['courseName'] ?? e['courseTitle'],
            status: 'upcoming',
            dueDate: e['dueDate'] != null ? DateTime.tryParse(e['dueDate']) : null,
          ));
        }
      }
      return result;
    }
    return [];
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
