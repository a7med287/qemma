import 'package:flutter/material.dart';

class StudentInfo {
  const StudentInfo({
    required this.name,
    required this.firstName,
    required this.email,
    this.avatar,
    this.gradeLevel = '',
    this.stream = '',
    this.overallProgress = 0,
  });

  final String name;
  final String firstName;
  final String email;
  final String? avatar;
  final String gradeLevel;
  final String stream;
  final int overallProgress;
}

class StudentKpi {
  const StudentKpi({
    required this.id,
    required this.type,
    required this.value,
    required this.label,
    required this.change,
  });

  final String id;
  final String type;
  final String value;
  final String label;
  final String change;
}

class StudentBadge {
  const StudentBadge({required this.id, required this.label});

  final String id;
  final String label;
}

class EnrolledCourse {
  const EnrolledCourse({
    required this.id,
    required this.title,
    required this.teacher,
    required this.progress,
    this.rating = 4.5,
    this.totalLessons = 10,
    this.completedLessons = 0,
    this.category = '',
    this.level = '',
    this.thumbnail,
  });

  final String id;
  final String title;
  final String teacher;
  final int progress;
  final double rating;
  final int totalLessons;
  final int completedLessons;
  final String category;
  final String level;
  final String? thumbnail;
}

class StudentTask {
  const StudentTask({
    required this.id,
    required this.title,
    required this.courseName,
    required this.courseId,
    required this.dueDate,
    this.completed = false,
    this.type = 'assignment',
    this.duration,
    this.totalMarks,
    this.maxScore,
    this.order,
  });

  final String id;
  final String title;
  final String courseName;
  final String courseId;
  final String dueDate;
  final bool completed;
  final String type;
  final int? duration;
  final int? totalMarks;
  final int? maxScore;
  final int? order;
}

class StudentAlert {
  const StudentAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final String actionLabel;
}

class LiveSession {
  const LiveSession({
    required this.id,
    required this.title,
    required this.teacher,
    required this.time,
    required this.courseId,
    this.isLive = false,
    this.participants = 0,
    this.roomName = '',
    this.status = 'scheduled',
    this.roomCode,
    this.maxCapacity,
    this.description,
    this.scheduledAt,
  });

  final String id;
  final String title;
  final String teacher;
  final String time;
  final String courseId;
  final bool isLive;
  final int participants;
  final String roomName;
  final String status;
  final String? roomCode;
  final int? maxCapacity;
  final String? description;
  final DateTime? scheduledAt;
}

class RecentExam {
  const RecentExam({
    required this.id,
    required this.title,
    required this.courseTitle,
    required this.score,
  });

  final String id;
  final String title;
  final String courseTitle;
  final double score;
}

class StudentNotification {
  const StudentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.unread = true,
    this.type = 'general',
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final bool unread;
  final String type;
  final DateTime? createdAt;
}

class PerformanceItem {
  const PerformanceItem({
    required this.id,
    required this.subject,
    required this.score,
    this.topic = '',
    this.trend = 'up',
    this.trendValue = '',
  });

  final String id;
  final String subject;
  final String topic;
  final int score;
  final String trend;
  final String trendValue;
}

class CalendarEvent {
  const CalendarEvent({required this.date});

  final String date;
}

class DashboardChart {
  const DashboardChart({
    required this.labels,
    required this.grades,
    required this.studyHours,
  });

  final List<String> labels;
  final List<double> grades;
  final List<double> studyHours;
}

class StudentDashboardData {
  const StudentDashboardData({
    required this.student,
    required this.kpis,
    required this.badges,
    required this.enrolledCourses,
    required this.recentExams,
    required this.liveSessions,
    required this.alerts,
    required this.tasks,
    required this.notifications,
    required this.chart,
    required this.calendarEvents,
    required this.strengths,
    required this.weaknesses,
  });

  final StudentInfo student;
  final List<StudentKpi> kpis;
  final List<StudentBadge> badges;
  final List<EnrolledCourse> enrolledCourses;
  final List<RecentExam> recentExams;
  final List<LiveSession> liveSessions;
  final List<StudentAlert> alerts;
  final List<StudentTask> tasks;
  final List<StudentNotification> notifications;
  final DashboardChart chart;
  final List<CalendarEvent> calendarEvents;
  final List<PerformanceItem> strengths;
  final List<PerformanceItem> weaknesses;
}

class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.title,
    required this.order,
    this.isPublished = true,
    this.attended = false,
    this.videoUrl,
    this.hasPdf = false,
    this.pdfFileRef,
    this.content,
  });

  final String id;
  final String title;
  final int order;
  final bool isPublished;
  final bool attended;
  final String? videoUrl;
  final bool hasPdf;
  final String? pdfFileRef;
  final String? content;
}

class CourseExam {
  const CourseExam({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.questionsCount,
    required this.totalMarks,
    required this.passingMarks,
    this.availableFrom,
    this.availableTo,
    this.hasAttempt = false,
    this.isPassed = false,
    this.attemptScore,
  });

  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final int questionsCount;
  final int totalMarks;
  final int passingMarks;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final bool hasAttempt;
  final bool isPassed;
  final double? attemptScore;
}

class CourseStats {
  const CourseStats({
    this.totalLessons = 0,
    this.totalExams = 0,
    this.totalStudents = 0,
    this.attendedCount = 0,
  });

  final int totalLessons;
  final int totalExams;
  final int totalStudents;
  final int attendedCount;
}

class UpcomingSession {
  const UpcomingSession({
    required this.id,
    required this.title,
    this.description,
    this.date,
    this.startTime,
    this.endTime,
    this.type = 'online',
    this.meetingLink,
    this.maxStudents,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final String type;
  final String? meetingLink;
  final int? maxStudents;
}

class CourseDetail {
  const CourseDetail({
    required this.id,
    required this.title,
    required this.teacherName,
    required this.progress,
    required this.lessons,
    required this.exams,
    required this.liveSessions,
    this.category = '',
    this.level = '',
    this.thumbnail,
    this.teacherAvatar,
    this.description,
    this.teacherEmail,
    this.teacherUserId,
    this.teacherVerified = false,
    this.stats,
    this.upcomingSessions,
  });

  final String id;
  final String title;
  final String teacherName;
  final int progress;
  final List<CourseLesson> lessons;
  final List<CourseExam> exams;
  final List<LiveSession> liveSessions;
  final String category;
  final String level;
  final String? thumbnail;
  final String? teacherAvatar;
  final String? description;
  final String? teacherEmail;
  final String? teacherUserId;
  final bool teacherVerified;
  final CourseStats? stats;
  final List<UpcomingSession>? upcomingSessions;

  CourseDetail copyWith({
    String? id,
    String? title,
    String? teacherName,
    int? progress,
    String? category,
    String? level,
    String? thumbnail,
    String? teacherAvatar,
    String? description,
    String? teacherEmail,
    String? teacherUserId,
    bool? teacherVerified,
    CourseStats? stats,
    List<CourseLesson>? lessons,
    List<CourseExam>? exams,
    List<LiveSession>? liveSessions,
    List<UpcomingSession>? upcomingSessions,
  }) {
    return CourseDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      teacherName: teacherName ?? this.teacherName,
      progress: progress ?? this.progress,
      category: category ?? this.category,
      level: level ?? this.level,
      thumbnail: thumbnail ?? this.thumbnail,
      teacherAvatar: teacherAvatar ?? this.teacherAvatar,
      description: description ?? this.description,
      teacherEmail: teacherEmail ?? this.teacherEmail,
      teacherUserId: teacherUserId ?? this.teacherUserId,
      teacherVerified: teacherVerified ?? this.teacherVerified,
      stats: stats ?? this.stats,
      lessons: lessons ?? this.lessons,
      exams: exams ?? this.exams,
      liveSessions: liveSessions ?? this.liveSessions,
      upcomingSessions: upcomingSessions ?? this.upcomingSessions,
    );
  }
}

class EnrollmentItem {
  const EnrollmentItem({
    required this.enrollmentId,
    required this.course,
    required this.progress,
    required this.enrolledAt,
  });

  final String enrollmentId;
  final EnrolledCourse course;
  final int progress;
  final DateTime enrolledAt;
}

class ExamItem {
  const ExamItem({
    required this.id,
    required this.title,
    required this.courseTitle,
    required this.durationMinutes,
    required this.totalMarks,
    required this.passingMarks,
    required this.isPublished,
    this.availableFrom,
    this.availableTo,
    this.hasCompleted = false,
    this.score,
    this.isPassed = false,
    this.pendingEssays = false,
  });

  final String id;
  final String title;
  final String courseTitle;
  final int durationMinutes;
  final int totalMarks;
  final int passingMarks;
  final bool isPublished;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final bool hasCompleted;
  final double? score;
  final bool isPassed;
  final bool pendingEssays;
}

class TaskStats {
  const TaskStats({
    required this.total,
    required this.exams,
    required this.assignments,
    required this.lessons,
  });

  final int total;
  final int exams;
  final int assignments;
  final int lessons;
}

class StudyBook {
  const StudyBook({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.subject,
    this.teacherName = '',
    this.grade = '',
    this.description = '',
    this.price = 0,
    this.bookType = 'pdf',
    this.pdfFileRef,
    this.coverImage,
    this.teacherId = '',
    this.teacherAvatar,
    this.isPublished = true,
    this.hasPurchased = false,
    this.purchases = 0,
    this.rating = 0,
    this.reviewsCount = 0,
    this.chapters = 0,
    this.pages = 0,
    this.isFavorite = false,
    this.color = const Color(0xFF7C3AED),
    this.gradient = const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
  });

  final String id;
  final String title;
  final String subtitle;
  final String subject;
  final String teacherName;
  final String grade;
  final String description;
  final int price;
  final String bookType;
  final String? pdfFileRef;
  final String? coverImage;
  final String teacherId;
  final String? teacherAvatar;
  final bool isPublished;
  final bool hasPurchased;
  final int purchases;
  final double rating;
  final int reviewsCount;
  final int chapters;
  final int pages;
  final bool isFavorite;
  final Color color;
  final List<Color> gradient;

  String get teacher => teacherName;
}

class StudentParentItem {
  const StudentParentItem({
    required this.id,
    required this.name,
    required this.email,
    this.isActivated = false,
    this.username,
    this.linkedAt,
  });

  final String id;
  final String name;
  final String email;
  final bool isActivated;
  final String? username;
  final DateTime? linkedAt;
}

class BookChapter {
  const BookChapter({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonsCount,
    required this.pagesCount,
  });

  final String id;
  final String title;
  final String description;
  final int lessonsCount;
  final int pagesCount;
}

class BookReview {
  const BookReview({
    required this.id,
    required this.studentName,
    required this.rating,
    this.comment = '',
  });

  final String id;
  final String studentName;
  final double rating;
  final String comment;
}

class BookRatingData {
  const BookRatingData({
    this.averageRating = 0,
    this.totalRatings = 0,
    this.myRating = 0,
    this.reviews = const [],
  });

  final double averageRating;
  final int totalRatings;
  final int myRating;
  final List<BookReview> reviews;
}

class ContestItem {
  const ContestItem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.questionCount,
    required this.participants,
    required this.status,
    this.stream = '',
    this.aiGenerated = false,
    this.hasSubmitted = false,
    this.eligible = true,
  });

  final String id;
  final String title;
  final String difficulty;
  final String startTime;
  final String endTime;
  final int duration;
  final int questionCount;
  final int participants;
  final String status;
  final String stream;
  final bool aiGenerated;
  final bool hasSubmitted;
  final bool eligible;

  bool get isUpcoming => status == 'upcoming';
  bool get isPast => !isUpcoming;
}

class ContestHistoryItem {
  const ContestHistoryItem({
    required this.id,
    required this.contestName,
    required this.date,
    required this.difficulty,
    this.rank,
    required this.totalParticipants,
    this.score,
    this.ratingChange,
    required this.newRating,
    required this.solvedProblems,
    required this.totalProblems,
    required this.duration,
  });

  final String id;
  final String contestName;
  final String date;
  final String difficulty;
  final int? rank;
  final int totalParticipants;
  final int? score;
  final int? ratingChange;
  final int newRating;
  final int solvedProblems;
  final int totalProblems;
  final String duration;
}

class ContestOption {
  final String id;
  final String text;
  const ContestOption({required this.id, required this.text});
}

class ContestQuestion {
  final String id;
  final String text;
  final int pointValue;
  final String questionType;
  final List<ContestOption> options;
  const ContestQuestion({
    required this.id,
    required this.text,
    required this.pointValue,
    required this.questionType,
    required this.options,
  });
}

class ContestParticipation {
  final String participationId;
  final String contestId;
  final String contestTitle;
  final String stream;
  final String difficulty;
  final String startTime;
  final String endTime;
  final bool isTest;
  final List<ContestQuestion> questions;
  final List<String> answeredQuestionIds;
  const ContestParticipation({
    required this.participationId,
    required this.contestId,
    required this.contestTitle,
    required this.stream,
    required this.difficulty,
    required this.startTime,
    required this.endTime,
    required this.isTest,
    required this.questions,
    required this.answeredQuestionIds,
  });
}

class ContestDashboardData {
  final int currentRating;
  final List<ContestRatingPoint> ratingHistory;
  final ContestStats stats;
  final List<ContestHistoryItem> contests;
  const ContestDashboardData({
    required this.currentRating,
    required this.ratingHistory,
    required this.stats,
    required this.contests,
  });
}

class ContestStats {
  final int totalContests;
  final int totalSolved;
  final int avgRank;
  final int bestRank;
  const ContestStats({
    required this.totalContests,
    required this.totalSolved,
    required this.avgRank,
    required this.bestRank,
  });
}

class ContestRatingPoint {
  final String date;
  final int rating;
  final String contestName;
  const ContestRatingPoint({
    required this.date,
    required this.rating,
    required this.contestName,
  });
}

class AssignmentItem {
  const AssignmentItem({
    required this.id,
    required this.title,
    required this.courseTitle,
    required this.maxScore,
    required this.dueDate,
    this.submitted = false,
    this.submissionScore,
  });

  final String id;
  final String title;
  final String courseTitle;
  final int maxScore;
  final String dueDate;
  final bool submitted;
  final double? submissionScore;
}

class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    required this.marks,
    this.options = const [],
  });

  final String id;
  final String questionText;
  final String type;
  final int marks;
  final List<String> options;
}

class ExamStartData {
  const ExamStartData({
    required this.examId,
    required this.title,
    required this.courseTitle,
    required this.durationMinutes,
    required this.questions,
    required this.attemptId,
  });

  final String examId;
  final String title;
  final String courseTitle;
  final int durationMinutes;
  final List<ExamQuestion> questions;
  final String attemptId;
}

class ExamReviewQuestion {
  const ExamReviewQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    required this.options,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.marks,
    required this.marksAwarded,
    this.isEssay = false,
    this.pending = false,
  });

  final String id;
  final String questionText;
  final String type;
  final List<String> options;
  final String studentAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int marks;
  final int marksAwarded;
  final bool isEssay;
  final bool pending;
}

class PerformanceReportData {
  const PerformanceReportData({
    required this.studentName,
    required this.studentLevel,
    required this.kpis,
    required this.classRank,
    required this.totalStudents,
    required this.percentile,
    required this.rankImproved,
    required this.courseProgress,
    required this.subjects,
    required this.weeklyLabels,
    required this.studentGrades,
    required this.classAverage,
    required this.strengths,
    required this.weaknesses,
    required this.maxScore,
    required this.minScore,
  });

  final String studentName;
  final String studentLevel;
  final List<StudentKpi> kpis;
  final int classRank;
  final int totalStudents;
  final int percentile;
  final bool rankImproved;
  final Map<String, int> courseProgress;
  final List<SubjectPerformance> subjects;
  final List<String> weeklyLabels;
  final List<double> studentGrades;
  final List<double> classAverage;
  final List<PerformanceItem> strengths;
  final List<PerformanceItem> weaknesses;
  final int maxScore;
  final int minScore;
}

class SubjectPerformance {
  const SubjectPerformance({
    required this.name,
    required this.grade,
    required this.classAvg,
    required this.color,
    required this.trend,
    required this.trendValue,
    required this.examsCount,
  });

  final String name;
  final int grade;
  final int classAvg;
  final Color color;
  final String trend;
  final String trendValue;
  final int examsCount;
}

class PreviousQuestion {
  const PreviousQuestion({
    required this.id,
    required this.question,
    required this.date,
    this.answer,
    this.answered = false,
  });

  final String id;
  final String question;
  final String? answer;
  final String date;
  final bool answered;
}

class ChatSession {
  const ChatSession({
    required this.id,
    this.courseId,
    this.teacherUserId,
    this.studentUserId,
    this.sessionType = 'teacher_support',
    this.status = 'active',
    this.teacherName,
    this.teacherAvatar,
  });

  final String id;
  final String? courseId;
  final String? teacherUserId;
  final String? studentUserId;
  final String sessionType;
  final String status;
  final String? teacherName;
  final String? teacherAvatar;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderUserId,
    this.senderName,
    this.senderRole,
    required this.message,
    this.sentAt,
  });

  final String id;
  final String sessionId;
  final String senderUserId;
  final String? senderName;
  final String? senderRole;
  final String message;
  final DateTime? sentAt;
}

class AiAnalysis {
  const AiAnalysis({
    this.overallAssessment,
    this.strengths = const [],
    this.weaknesses = const [],
    this.weakLessons = const [],
    this.topicsToStudy = const [],
    this.advice,
    this.improvements = const [],
    this.studyPlan,
    this.motivationalMessage,
  });

  final String? overallAssessment;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> weakLessons;
  final List<String> topicsToStudy;
  final String? advice;
  final List<String> improvements;
  final String? studyPlan;
  final String? motivationalMessage;
}
