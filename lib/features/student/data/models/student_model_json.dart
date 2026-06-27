import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import 'student_models.dart';

abstract final class StudentModelJson {
  static StudentDashboardData dashboardFromJson(Map<String, dynamic> json) {
    return StudentDashboardData(
      student: studentInfoFromJson(asMap(json['student'])),
      kpis: asMapList(json['kpis']).map(kpiFromJson).toList(),
      badges: asMapList(json['badges']).map(badgeFromJson).toList(),
      enrolledCourses: asMapList(json['enrolledCourses']).map(enrolledCourseFromJson).toList(),
      recentExams: asMapList(json['recentExams']).map(recentExamFromJson).toList(),
      liveSessions: asMapList(json['liveSessions']).map(liveSessionFromJson).toList(),
      alerts: asMapList(json['alerts']).map(alertFromJson).toList(),
      tasks: asMapList(json['tasks']).map(dashboardTaskFromJson).toList(),
      notifications: asMapList(json['notifications']).map(notificationFromJson).toList(),
      chart: chartFromJson(asMap(json['chart'])),
      calendarEvents: asMapList(json['calendarEvents']).map(calendarEventFromJson).toList(),
      strengths: asMapList(json['strengths']).map(performanceItemFromJson).toList(),
      weaknesses: asMapList(json['weaknesses']).map(performanceItemFromJson).toList(),
    );
  }

  static StudentInfo studentInfoFromJson(Map<String, dynamic> json) {
    return StudentInfo(
      name: json['name']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? json['name']?.toString().split(' ').first ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      gradeLevel: json['gradeLevel']?.toString() ?? '',
      stream: json['stream']?.toString() ?? '',
      overallProgress: _toInt(json['overallProgress']),
    );
  }

  static StudentKpi kpiFromJson(Map<String, dynamic> json) {
    return StudentKpi(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      change: json['change']?.toString() ?? '',
    );
  }

  static StudentBadge badgeFromJson(Map<String, dynamic> json) {
    return StudentBadge(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  static EnrolledCourse enrolledCourseFromJson(Map<String, dynamic> json) {
    return EnrolledCourse(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      teacher: json['teacher']?.toString() ?? '',
      progress: _toInt(json['progress']),
      totalLessons: _toInt(json['totalLessons']),
      completedLessons: _toInt(json['completedLessons']),
      thumbnail: json['thumbnail']?.toString(),
    );
  }

  static StudentTask dashboardTaskFromJson(Map<String, dynamic> json) {
    return StudentTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? json['dueLabel']?.toString() ?? '',
      completed: json['completed'] == true,
      type: json['type']?.toString() ?? 'assignment',
    );
  }

  static StudentAlert alertFromJson(Map<String, dynamic> json) {
    return StudentAlert(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      actionLabel: json['actionLabel']?.toString() ?? 'عرض',
    );
  }

  static LiveSession liveSessionFromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      teacher: json['teacher']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      isLive: json['isLive'] == true,
      participants: _toInt(json['participants']),
      roomName: json['roomName']?.toString() ?? '',
    );
  }

  static RecentExam recentExamFromJson(Map<String, dynamic> json) {
    return RecentExam(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      score: _toDouble(json['score'] ?? json['grade']),
    );
  }

  static StudentNotification notificationFromJson(Map<String, dynamic> json) {
    return StudentNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      time: json['time']?.toString() ?? _formatDate(json['createdAt']),
      unread: json['unread'] == true || json['isRead'] == false,
      type: json['type']?.toString() ?? 'general',
    );
  }

  static DashboardChart chartFromJson(Map<String, dynamic> json) {
    return DashboardChart(
      labels: _toStringList(json['labels']),
      grades: _toDoubleList(json['grades']),
      studyHours: _toDoubleList(json['studyHours']),
    );
  }

  static CalendarEvent calendarEventFromJson(Map<String, dynamic> json) {
    return CalendarEvent(date: json['date']?.toString() ?? '');
  }

  static PerformanceItem performanceItemFromJson(Map<String, dynamic> json) {
    return PerformanceItem(
      id: json['id']?.toString() ?? json['subject']?.toString() ?? '',
      subject: json['subject']?.toString() ?? json['name']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      score: _toInt(json['score'] ?? json['grade']),
      trend: json['trend']?.toString() ?? 'up',
      trendValue: json['trendValue']?.toString() ?? '',
    );
  }

  static TaskStats taskStatsFromJson(Map<String, dynamic> json) {
    return TaskStats(
      total: _toInt(json['total']),
      exams: _toInt(json['exams']),
      assignments: _toInt(json['assignments']),
      lessons: _toInt(json['lessons']),
    );
  }

  static StudentTask taskFromJson(Map<String, dynamic> json) {
    return StudentTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      type: json['type']?.toString() ?? 'assignment',
      duration: json['duration'] != null ? _toInt(json['duration']) : null,
      totalMarks: json['totalMarks'] != null ? _toInt(json['totalMarks']) : null,
      maxScore: json['maxScore'] != null ? _toInt(json['maxScore']) : null,
      order: json['order'] != null ? _toInt(json['order']) : null,
    );
  }

  static TasksResponse tasksResponseFromJson(Map<String, dynamic> json) {
    return TasksResponse(
      stats: taskStatsFromJson(asMap(json['stats'])),
      pendingExams: asMapList(json['pendingExams']).map((e) => taskFromJson({...e, 'type': 'exam'})).toList(),
      pendingAssignments: asMapList(json['pendingAssignments']).map((e) => taskFromJson({...e, 'type': 'assignment'})).toList(),
      unviewedLessons: asMapList(json['unviewedLessons']).map((e) => taskFromJson({...e, 'type': 'lesson'})).toList(),
    );
  }

  static EnrollmentItem enrollmentFromJson(Map<String, dynamic> json) {
    final course = asMap(json['course']);
    final teacher = asMap(course['teacher']);
    return EnrollmentItem(
      enrollmentId: json['enrollmentId']?.toString() ?? json['id']?.toString() ?? '',
      progress: _toInt(json['progress']),
      enrolledAt: DateTime.tryParse(json['enrolledAt']?.toString() ?? '') ?? DateTime.now(),
      course: EnrolledCourse(
        id: course['id']?.toString() ?? '',
        title: course['title']?.toString() ?? '',
        teacher: teacher['name']?.toString() ?? course['teacherName']?.toString() ?? '',
        progress: _toInt(json['progress']),
        totalLessons: _toInt(course['totalLessons']),
        category: course['category']?.toString() ?? '',
        level: course['level']?.toString() ?? '',
        thumbnail: course['thumbnail']?.toString(),
      ),
    );
  }

  static CourseDetail courseDetailFromJson(Map<String, dynamic> json) {
    final course = asMap(json['course']);
    final enrollment = asMap(json['enrollment']);
    final teacher = asMap(course['teacher']);

    return CourseDetail(
      id: course['id']?.toString() ?? '',
      title: course['title']?.toString() ?? '',
      teacherName: teacher['name']?.toString() ?? '',
      progress: _toInt(enrollment['progress']),
      category: course['category']?.toString() ?? '',
      level: course['level']?.toString() ?? '',
      thumbnail: course['thumbnail']?.toString(),
      teacherAvatar: teacher['avatar']?.toString(),
      lessons: asMapList(course['lessons']).map(courseLessonFromJson).toList(),
      exams: asMapList(course['exams']).map(courseExamFromJson).toList(),
      liveSessions: asMapList(course['liveRooms']).map(liveRoomFromJson).toList(),
    );
  }

  static CourseLesson courseLessonFromJson(Map<String, dynamic> json) {
    return CourseLesson(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      order: _toInt(json['order']),
      isPublished: json['isPublished'] != false,
      attended: json['attended'] == true,
      videoUrl: json['videoUrl']?.toString(),
      hasPdf: json['pdfFileRef'] != null && json['pdfFileRef'].toString().isNotEmpty,
    );
  }

  static CourseExam courseExamFromJson(Map<String, dynamic> json) {
    final attempt = json['myAttempt'] != null ? asMap(json['myAttempt']) : null;
    return CourseExam(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      durationMinutes: _toInt(json['durationMinutes'] ?? json['duration']),
      questionsCount: _toInt(json['questionsCount']),
      totalMarks: _toInt(json['totalMarks']),
      passingMarks: _toInt(json['passingMarks']),
      availableFrom: DateTime.tryParse(json['availableFrom']?.toString() ?? ''),
      availableTo: DateTime.tryParse(json['availableTo']?.toString() ?? ''),
      hasAttempt: attempt != null,
      isPassed: attempt?['isPassed'] == true,
      attemptScore: attempt != null ? _toDouble(attempt['score']) : null,
    );
  }

  static LiveSession liveRoomFromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      teacher: json['teacherName']?.toString() ?? '',
      time: json['scheduledAt']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      isLive: json['isActive'] == true || json['status']?.toString() == 'live',
      participants: _toInt(json['participantCount']),
      roomName: json['roomName']?.toString() ?? '',
    );
  }

  static ExamItem examItemFromJson(Map<String, dynamic> json) {
    final attempt = json['myAttempt'] != null ? asMap(json['myAttempt']) : null;
    return ExamItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      durationMinutes: _toInt(json['durationMinutes'] ?? json['duration']),
      totalMarks: _toInt(json['totalMarks']),
      passingMarks: _toInt(json['passingMarks']),
      isPublished: json['isPublished'] != false,
      availableFrom: DateTime.tryParse(json['availableFrom']?.toString() ?? ''),
      availableTo: DateTime.tryParse(json['availableTo']?.toString() ?? ''),
      hasCompleted: json['hasCompleted'] == true || attempt != null,
      score: attempt != null ? _toDouble(attempt['score']) : null,
      isPassed: attempt?['isPassed'] == true,
      pendingEssays: json['pendingEssays'] == true,
    );
  }

  static ExamStartData examStartFromJson(Map<String, dynamic> json) {
    final exam = asMap(json['exam']);
    return ExamStartData(
      examId: exam['id']?.toString() ?? '',
      title: exam['title']?.toString() ?? '',
      courseTitle: exam['courseTitle']?.toString() ?? '',
      durationMinutes: _toInt(exam['durationMinutes']),
      attemptId: json['attemptId']?.toString() ?? '',
      questions: asMapList(json['questions']).map(examQuestionFromJson).toList(),
    );
  }

  static ExamQuestion examQuestionFromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id']?.toString() ?? '',
      questionText: json['questionText']?.toString() ?? '',
      type: json['type']?.toString() ?? 'multiple-choice',
      marks: _toInt(json['marks']),
      options: _toStringList(json['options']),
    );
  }

  static ExamSubmitResult examSubmitFromJson(Map<String, dynamic> json) {
    return ExamSubmitResult(
      score: _toDouble(json['score']),
      totalMarks: _toDouble(json['totalMarks']),
      isPassed: json['isPassed'] == true,
      hasEssayQuestions: json['hasEssayQuestions'] == true,
      essayCount: _toInt(json['essayCount']),
    );
  }

  static ExamReviewData examReviewFromJson(Map<String, dynamic> json) {
    return ExamReviewData(
      examTitle: json['examTitle']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      score: _toDouble(json['score']),
      totalMarks: _toInt(json['totalMarks']),
      passingMarks: _toInt(json['passingMarks']),
      isPassed: json['isPassed'] == true,
      hasEssayQuestions: json['hasEssayQuestions'] == true,
      autoGradedCount: _toInt(json['autoGradedCount']),
      essayCount: _toInt(json['essayCount']),
      questions: asMapList(json['questions']).map(examReviewQuestionFromJson).toList(),
    );
  }

  static ExamReviewQuestion examReviewQuestionFromJson(Map<String, dynamic> json) {
    return ExamReviewQuestion(
      id: json['id']?.toString() ?? '',
      questionText: json['questionText']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      options: _toStringList(json['options']),
      studentAnswer: json['studentAnswer']?.toString() ?? '',
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
      marks: _toInt(json['marks']),
      marksAwarded: _toInt(json['marksAwarded']),
      isEssay: json['isEssay'] == true || json['type']?.toString() == 'essay',
      pending: json['pending'] == true,
    );
  }

  static AssignmentItem assignmentFromJson(Map<String, dynamic> json) {
    final submission = json['submission'] != null ? asMap(json['submission']) : null;
    return AssignmentItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      maxScore: _toInt(json['maxScore']),
      dueDate: json['dueDate']?.toString() ?? '',
      submitted: json['submitted'] == true || submission != null,
      submissionScore: submission != null ? _toDouble(submission['score']) : null,
    );
  }

  static PerformanceReportData performanceFromJson(Map<String, dynamic> json) {
    final ranking = asMap(json['ranking']);
    final weekly = asMap(json['weeklyProgress']);
    final courseProgress = asMap(json['courseProgress']);

    return PerformanceReportData(
      studentName: json['studentName']?.toString() ?? '',
      studentLevel: json['studentLevel']?.toString() ?? '',
      kpis: asMapList(json['stats']).map(kpiFromJson).toList(),
      classRank: _toInt(ranking['classRank']),
      totalStudents: _toInt(ranking['totalStudents']),
      percentile: _toInt(ranking['percentile']),
      rankImproved: ranking['rankImproved'] == true,
      courseProgress: {
        'completed': _toInt(courseProgress['completed']),
        'inProgress': _toInt(courseProgress['inProgress']),
        'notStarted': _toInt(courseProgress['notStarted']),
        'total': _toInt(courseProgress['total']),
      },
      subjects: asMapList(json['subjectsPerformance']).map(subjectPerformanceFromJson).toList(),
      weeklyLabels: _toStringList(weekly['labels']),
      studentGrades: _toDoubleList(weekly['studentGrades']),
      classAverage: _toDoubleList(weekly['classAverage']),
      strengths: asMapList(json['strengths']).map(performanceItemFromJson).toList(),
      weaknesses: asMapList(json['weaknesses']).map(performanceItemFromJson).toList(),
      maxScore: _toInt(json['maxScore']),
      minScore: _toInt(json['minScore']),
    );
  }

  static SubjectPerformance subjectPerformanceFromJson(Map<String, dynamic> json) {
    final colorHex = json['color']?.toString();
    return SubjectPerformance(
      name: json['name']?.toString() ?? '',
      grade: _toInt(json['grade']),
      classAvg: _toInt(json['classAvg']),
      color: _parseColor(colorHex),
      trend: json['trend']?.toString() ?? 'up',
      trendValue: json['trendValue']?.toString() ?? '',
      examsCount: _toInt(json['examsCount']),
    );
  }

  static StudyBook bookFromJson(Map<String, dynamic> json, {int index = 0}) {
    const palette = [
      Color(0xFF2563EB),
      Color(0xFF059669),
      Color(0xFFDB2777),
      Color(0xFFF59E0B),
      Color(0xFF7C3AED),
    ];
    final color = palette[index % palette.length];
    return StudyBook(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subject']?.toString() ?? json['grade']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      teacher: json['teacherName']?.toString() ?? '',
      chapters: _toInt(json['chapters'], fallback: 0),
      pages: _toInt(json['pages'], fallback: 0),
      color: color,
      gradient: [color, color.withValues(alpha: .8)],
      description: json['description']?.toString() ?? '',
      teacherId: json['teacherId']?.toString() ?? '',
      rating: _toDouble(json['rating'], fallback: 4.5),
      reviewsCount: _toInt(json['reviewsCount'] ?? json['purchases']),
      downloadSize: json['downloadSize']?.toString() ?? '',
      lastUpdated: json['updatedAt']?.toString() ?? '',
    );
  }

  static NotificationsPageData notificationsPageFromJson(Map<String, dynamic> json) {
    return NotificationsPageData(
      notifications: asMapList(json['notifications']).map(notificationFromJson).toList(),
      unreadCount: _toInt(json['unreadCount']),
      page: _toInt(json['pagination']?['page'], fallback: 1),
      totalPages: _toInt(json['pagination']?['totalPages'], fallback: 1),
    );
  }

  static LiveRoomInfo liveRoomInfoFromJson(Map<String, dynamic> json) {
    final course = asMap(json['course']);
    final host = asMap(json['host']);
    final hostUser = asMap(host['user']);
    final count = asMap(json['_count']);
    return LiveRoomInfo(
      roomName: json['roomName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      courseTitle: course['title']?.toString() ?? json['courseTitle']?.toString() ?? '',
      teacherName: json['teacherName']?.toString() ?? hostUser['name']?.toString() ?? '',
      isActive: json['isActive'] == true,
      participants: _toInt(count['participants'] ?? json['participantCount']),
      roomCode: json['roomCode']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).toList();
  }

  static List<double> _toDoubleList(dynamic value) {
    if (value is! List) return [];
    return value.map(_toDouble).toList();
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '';
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return value.toString();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF2563EB);
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return const Color(0xFF2563EB);
  }

  static ContestItem contestItemFromJson(Map<String, dynamic> json) {
    return ContestItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      duration: json['duration'] is int ? json['duration'] as int : int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      questionCount: json['questionCount'] is int ? json['questionCount'] as int : int.tryParse(json['questionCount']?.toString() ?? '0') ?? 0,
      participants: json['participationCount'] is int ? json['participationCount'] as int : int.tryParse(json['participationCount']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'upcoming',
      stream: json['stream']?.toString() ?? '',
      aiGenerated: json['aiGenerated'] == true || json['isTest'] == true,
      hasSubmitted: json['hasSubmitted'] == true,
      eligible: json['eligible'] != false,
    );
  }

  static ContestHistoryItem contestHistoryFromJson(Map<String, dynamic> json) {
    return ContestHistoryItem(
      id: json['id']?.toString() ?? '',
      contestName: json['contestName']?.toString() ?? json['contest']?['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      rank: json['rank'] != null ? (json['rank'] is int ? json['rank'] as int : int.tryParse(json['rank'].toString()) ?? 0) : null,
      totalParticipants: json['totalParticipants'] is int ? json['totalParticipants'] as int : int.tryParse(json['totalParticipants']?.toString() ?? '0') ?? 0,
      score: json['score'] != null ? (json['score'] is int ? json['score'] as int : int.tryParse(json['score'].toString()) ?? 0) : null,
      ratingChange: json['ratingChange'] != null ? (json['ratingChange'] is int ? json['ratingChange'] as int : int.tryParse(json['ratingChange'].toString()) ?? 0) : null,
      newRating: json['newRating'] is int ? json['newRating'] as int : int.tryParse(json['newRating']?.toString() ?? '0') ?? 0,
      solvedProblems: json['solvedProblems'] is int ? json['solvedProblems'] as int : int.tryParse(json['solvedProblems']?.toString() ?? '0') ?? 0,
      totalProblems: json['totalProblems'] is int ? json['totalProblems'] as int : int.tryParse(json['totalProblems']?.toString() ?? '0') ?? 0,
      duration: json['duration']?.toString() ?? '',
    );
  }

  static ContestOption contestOptionFromJson(Map<String, dynamic> json) {
    return ContestOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }

  static ContestQuestion contestQuestionFromJson(Map<String, dynamic> json) {
    return ContestQuestion(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? json['questionText']?.toString() ?? '',
      pointValue: json['pointValue'] is int ? json['pointValue'] as int : int.tryParse(json['pointValue']?.toString() ?? '0') ?? 0,
      questionType: json['questionType']?.toString() ?? 'mcq',
      options: asMapList(json['options']).map(contestOptionFromJson).toList(),
    );
  }

  static ContestParticipation contestParticipationFromJson(Map<String, dynamic> json) {
    final contest = asMap(json['contest']);
    return ContestParticipation(
      participationId: json['participationId']?.toString() ?? '',
      contestId: contest['id']?.toString() ?? '',
      contestTitle: contest['title']?.toString() ?? '',
      stream: contest['stream']?.toString() ?? '',
      difficulty: contest['difficulty']?.toString() ?? 'medium',
      startTime: contest['startTime']?.toString() ?? '',
      endTime: contest['endTime']?.toString() ?? '',
      isTest: contest['isTest'] == true,
      questions: asMapList(json['questions']).map(contestQuestionFromJson).toList(),
      answeredQuestionIds: (json['answeredQuestionIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  static ContestDashboardData contestDashboardFromJson(Map<String, dynamic> json) {
    final statsMap = asMap(json['stats']);
    return ContestDashboardData(
      currentRating: json['currentRating'] is int ? json['currentRating'] as int : int.tryParse(json['currentRating']?.toString() ?? '0') ?? 0,
      ratingHistory: asMapList(json['ratingHistory']).map(contestRatingPointFromJson).toList(),
      stats: ContestStats(
        totalContests: statsMap['totalContests'] is int ? statsMap['totalContests'] as int : int.tryParse(statsMap['totalContests']?.toString() ?? '0') ?? 0,
        totalSolved: statsMap['totalSolved'] is int ? statsMap['totalSolved'] as int : int.tryParse(statsMap['totalSolved']?.toString() ?? '0') ?? 0,
        avgRank: statsMap['avgRank'] is int ? statsMap['avgRank'] as int : int.tryParse(statsMap['avgRank']?.toString() ?? '0') ?? 0,
        bestRank: statsMap['bestRank'] is int ? statsMap['bestRank'] as int : int.tryParse(statsMap['bestRank']?.toString() ?? '0') ?? 0,
      ),
      contests: asMapList(json['contests']).map(contestHistoryFromJson).toList(),
    );
  }

  static ContestRatingPoint contestRatingPointFromJson(Map<String, dynamic> json) {
    return ContestRatingPoint(
      date: json['date']?.toString() ?? '',
      rating: json['rating'] is int ? json['rating'] as int : int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      contestName: json['contestName']?.toString() ?? '',
    );
  }
}

class TasksResponse {
  const TasksResponse({
    required this.stats,
    required this.pendingExams,
    required this.pendingAssignments,
    required this.unviewedLessons,
  });

  final TaskStats stats;
  final List<StudentTask> pendingExams;
  final List<StudentTask> pendingAssignments;
  final List<StudentTask> unviewedLessons;

  List<StudentTask> get all => [...pendingExams, ...pendingAssignments, ...unviewedLessons];
}

class ExamSubmitResult {
  const ExamSubmitResult({
    required this.score,
    required this.totalMarks,
    required this.isPassed,
    required this.hasEssayQuestions,
    required this.essayCount,
  });

  final double score;
  final double totalMarks;
  final bool isPassed;
  final bool hasEssayQuestions;
  final int essayCount;
}

class ExamReviewData {
  const ExamReviewData({
    required this.examTitle,
    required this.courseTitle,
    required this.score,
    required this.totalMarks,
    required this.passingMarks,
    required this.isPassed,
    required this.hasEssayQuestions,
    required this.autoGradedCount,
    required this.essayCount,
    required this.questions,
  });

  final String examTitle;
  final String courseTitle;
  final double score;
  final int totalMarks;
  final int passingMarks;
  final bool isPassed;
  final bool hasEssayQuestions;
  final int autoGradedCount;
  final int essayCount;
  final List<ExamReviewQuestion> questions;
}

class NotificationsPageData {
  const NotificationsPageData({
    required this.notifications,
    required this.unreadCount,
    required this.page,
    required this.totalPages,
  });

  final List<StudentNotification> notifications;
  final int unreadCount;
  final int page;
  final int totalPages;
}

class LiveRoomInfo {
  const LiveRoomInfo({
    required this.roomName,
    required this.title,
    required this.courseTitle,
    required this.teacherName,
    required this.isActive,
    required this.participants,
    required this.roomCode,
  });

  final String roomName;
  final String title;
  final String courseTitle;
  final String teacherName;
  final bool isActive;
  final int participants;
  final String roomCode;
}
