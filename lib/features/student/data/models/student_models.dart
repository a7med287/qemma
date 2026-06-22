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
  });

  final String id;
  final String title;
  final String teacher;
  final String time;
  final String courseId;
  final bool isLive;
  final int participants;
  final String roomName;
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
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final bool unread;
  final String type;
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
  });

  final String id;
  final String title;
  final int order;
  final bool isPublished;
  final bool attended;
  final String? videoUrl;
  final bool hasPdf;
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
    required this.subtitle,
    required this.subject,
    required this.teacher,
    required this.chapters,
    required this.pages,
    required this.color,
    required this.gradient,
    this.isFavorite = false,
    this.description = '',
    this.teacherId = '1',
    this.teacherBio = '',
    this.rating = 4.8,
    this.reviewsCount = 120,
    this.downloadSize = '15 MB',
    this.lastUpdated = '2025',
  });

  final String id;
  final String title;
  final String subtitle;
  final String subject;
  final String teacher;
  final int chapters;
  final int pages;
  final Color color;
  final List<Color> gradient;
  final bool isFavorite;
  final String description;
  final String teacherId;
  final String teacherBio;
  final double rating;
  final int reviewsCount;
  final String downloadSize;
  final String lastUpdated;
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

class ContestItem {
  const ContestItem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.date,
    required this.duration,
    required this.questionCount,
    required this.participants,
    required this.status,
    this.aiGenerated = false,
  });

  final String id;
  final String title;
  final String difficulty;
  final String date;
  final int duration;
  final int questionCount;
  final int participants;
  final String status;
  final bool aiGenerated;
}

class ContestHistoryItem {
  const ContestHistoryItem({
    required this.id,
    required this.contestName,
    required this.date,
    required this.difficulty,
    required this.rank,
    required this.totalParticipants,
    required this.score,
    required this.ratingChange,
    required this.newRating,
    required this.solvedProblems,
    required this.totalProblems,
    required this.duration,
  });

  final String id;
  final String contestName;
  final String date;
  final String difficulty;
  final int rank;
  final int totalParticipants;
  final int score;
  final int ratingChange;
  final int newRating;
  final int solvedProblems;
  final int totalProblems;
  final String duration;
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
