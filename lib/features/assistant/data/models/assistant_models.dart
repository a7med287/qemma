class AssistantDashboardData {
  const AssistantDashboardData({
    required this.studentsCount,
    required this.activeChats,
    required this.pendingGrading,
    required this.unreadCount,
    required this.teacherName,
    required this.teacherId,
    this.recentAttempts = const [],
  });

  final int studentsCount;
  final int activeChats;
  final int pendingGrading;
  final int unreadCount;
  final String teacherName;
  final String teacherId;
  final List<Map<String, dynamic>> recentAttempts;

  factory AssistantDashboardData.fromJson(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>? ?? json;
    final teacher = info['teacher'] as Map<String, dynamic>?;
    return AssistantDashboardData(
      studentsCount: info['studentsCount'] ?? json['studentsCount'] ?? 0,
      activeChats: info['activeChats'] ?? json['activeChats'] ?? 0,
      pendingGrading: info['pendingGrading'] ?? json['pendingGrading'] ?? 0,
      unreadCount: info['unreadCount'] ?? json['unreadCount'] ?? 0,
      teacherName: teacher?['name'] ?? info['teacherName'] ?? '',
      teacherId: teacher?['id'] ?? teacher?['_id'] ?? info['teacherId'] ?? '',
      recentAttempts: (json['recentAttempts'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

class AssistantStudent {
  final String id;
  final String name;
  final String? username;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? division;
  final String? gradeLevel;
  final String? stream;
  final int coins;
  final double avgProgress;
  final double? avgScore;
  final int examAttempts;
  final List<String> enrolledCourses;
  final List<Enrollment> enrollments;

  const AssistantStudent({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.phone,
    this.avatar,
    this.division,
    this.gradeLevel,
    this.stream,
    this.coins = 0,
    this.avgProgress = 0,
    this.avgScore,
    this.examAttempts = 0,
    this.enrolledCourses = const [],
    this.enrollments = const [],
  });

  factory AssistantStudent.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    final enrollmentsList = (json['enrollments'] as List?)
        ?.map((e) => Enrollment.fromJson(e as Map<String, dynamic>))
        .toList();
    return AssistantStudent(
      id: user['_id'] ?? user['id'] ?? json['_id'] ?? json['id'] ?? '',
      name: user['name'] ?? '',
      username: user['username'],
      email: user['email'],
      phone: user['phone'],
      avatar: user['avatar'],
      division: json['division'] ?? user['division'],
      gradeLevel: json['gradeLevel'] ?? '',
      stream: json['stream'] ?? user['stream'],
      coins: json['coins'] ?? 0,
      avgProgress: (json['avgProgress'] ?? 0).toDouble(),
      avgScore: (json['avgScore'] as num?)?.toDouble(),
      examAttempts: json['examAttempts'] ?? 0,
      enrolledCourses: (json['courses'] as List?)
              ?.map((e) => e is Map ? (e['title'] ?? '').toString() : e.toString())
              .toList() ??
          [],
      enrollments: enrollmentsList ?? [],
    );
  }
}

class Enrollment {
  final String courseId;
  final String courseTitle;
  final DateTime enrolledAt;
  final double progress;

  const Enrollment({
    required this.courseId,
    required this.courseTitle,
    required this.enrolledAt,
    this.progress = 0,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      courseId: json['courseId'] ?? json['course'] ?? '',
      courseTitle: json['courseTitle'] ?? json['title'] ?? '',
      enrolledAt: json['enrolledAt'] != null
          ? DateTime.parse(json['enrolledAt'] as String)
          : DateTime.now(),
      progress: (json['progress'] ?? 0).toDouble(),
    );
  }
}

class LinkedTeacher {
  final String id;
  final String name;
  final String? avatar;
  final String? username;
  final List<String> specialties;

  const LinkedTeacher({
    required this.id,
    required this.name,
    this.avatar,
    this.username,
    this.specialties = const [],
  });

  factory LinkedTeacher.fromJson(Map<String, dynamic> json) {
    return LinkedTeacher(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      username: json['username'],
      specialties: (json['specialties'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class StudentsStats {
  final int totalStudents;
  final int totalCourses;
  final int totalEnrollments;
  final int publishedCourses;

  const StudentsStats({
    this.totalStudents = 0,
    this.totalCourses = 0,
    this.totalEnrollments = 0,
    this.publishedCourses = 0,
  });

  factory StudentsStats.fromJson(Map<String, dynamic> json) {
    return StudentsStats(
      totalStudents: json['totalStudents'] ?? 0,
      totalCourses: json['totalCourses'] ?? 0,
      totalEnrollments: json['totalEnrollments'] ?? 0,
      publishedCourses: json['publishedCourses'] ?? 0,
    );
  }
}

class Course {
  final String id;
  final String title;

  const Course({required this.id, required this.title});

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
    );
  }
}

class ExamSummary {
  final int totalAttempts;
  final double? avgScore;
  final int passedCount;
  final int failedCount;

  const ExamSummary({
    this.totalAttempts = 0,
    this.avgScore,
    this.passedCount = 0,
    this.failedCount = 0,
  });

  factory ExamSummary.fromJson(Map<String, dynamic> json) {
    return ExamSummary(
      totalAttempts: json['totalAttempts'] ?? 0,
      avgScore: (json['avgScore'] as num?)?.toDouble(),
      passedCount: json['passedCount'] ?? 0,
      failedCount: json['failedCount'] ?? 0,
    );
  }
}

class RecentAttempt {
  final String examTitle;
  final String courseTitle;
  final DateTime submittedAt;
  final double? score;
  final double rawScore;
  final double totalMarks;
  final bool isPassed;

  const RecentAttempt({
    required this.examTitle,
    required this.courseTitle,
    required this.submittedAt,
    this.score,
    this.rawScore = 0,
    this.totalMarks = 0,
    this.isPassed = false,
  });

  factory RecentAttempt.fromJson(Map<String, dynamic> json) {
    final exam = json['exam'] as Map<String, dynamic>?;
    final course = json['course'] as Map<String, dynamic>?;
    return RecentAttempt(
      examTitle: exam?['title'] ?? json['examTitle'] ?? '',
      courseTitle: course?['title'] ?? json['courseTitle'] ?? '',
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : DateTime.now(),
      score: (json['score'] as num?)?.toDouble(),
      rawScore: (json['rawScore'] ?? 0).toDouble(),
      totalMarks: (json['totalMarks'] ?? 0).toDouble(),
      isPassed: json['isPassed'] ?? false,
    );
  }
}

class StudentDetailResponse {
  final AssistantStudent student;
  final ExamSummary examSummary;
  final List<RecentAttempt> recentAttempts;

  const StudentDetailResponse({
    required this.student,
    this.examSummary = const ExamSummary(),
    this.recentAttempts = const [],
  });

  factory StudentDetailResponse.fromJson(Map<String, dynamic> json) {
    final studentData = json['student'] as Map<String, dynamic>? ?? json;
    return StudentDetailResponse(
      student: AssistantStudent.fromJson(studentData),
      examSummary: ExamSummary.fromJson(
          json['examSummary'] as Map<String, dynamic>? ?? {}),
      recentAttempts: (json['recentAttempts'] as List?)
              ?.map((e) => RecentAttempt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EnrichedStudentsResponse {
  final LinkedTeacher? linkedTeacher;
  final StudentsStats stats;
  final List<AssistantStudent> students;
  final List<Course> courses;
  final String? error;

  const EnrichedStudentsResponse({
    this.linkedTeacher,
    this.stats = const StudentsStats(),
    this.students = const [],
    this.courses = const [],
    this.error,
  });

  factory EnrichedStudentsResponse.fromJson(Map<String, dynamic> json) {
    return EnrichedStudentsResponse(
      linkedTeacher: json['linkedTeacher'] != null
          ? LinkedTeacher.fromJson(json['linkedTeacher'] as Map<String, dynamic>)
          : null,
      stats: StudentsStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      students: (json['students'] as List?)
              ?.map((e) => AssistantStudent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      courses: (json['courses'] as List?)
              ?.map((e) => Course.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
