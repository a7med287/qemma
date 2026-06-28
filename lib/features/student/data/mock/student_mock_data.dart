import 'package:flutter/material.dart';
import '../models/student_models.dart';

abstract final class StudentMockData {
  static const studentColors = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFDB2777),
    Color(0xFF0891B2),
    Color(0xFFF59E0B),
  ];

  static StudentDashboardData get dashboard => StudentDashboardData(
        student: const StudentInfo(
          name: 'أحمد محمد علي',
          firstName: 'أحمد',
          email: 'ahmed@student.com',
          gradeLevel: 'الصف الثالث الثانوي',
          stream: 'علمي رياضة',
          overallProgress: 68,
        ),
        kpis: const [
          StudentKpi(id: '1', type: 'avgGrade', value: '87%', label: 'متوسط الدرجات', change: '+3%'),
          StudentKpi(id: '2', type: 'homework', value: '12/15', label: 'الواجبات', change: '+2'),
          StudentKpi(id: '3', type: 'attendance', value: '94%', label: 'الحضور', change: '+1%'),
          StudentKpi(id: '4', type: 'studyTime', value: '24س', label: 'ساعات الدراسة', change: '+5س'),
        ],
        badges: const [
          StudentBadge(id: '1', label: '⭐ متفوق'),
          StudentBadge(id: '2', label: '🏆 مسابقات'),
          StudentBadge(id: '3', label: '📚 نشط'),
        ],
        enrolledCourses: courses.take(4).toList(),
        recentExams: const [
          RecentExam(id: '1', title: 'امتحان التفاضل', courseTitle: 'الرياضيات', score: 92),
          RecentExam(id: '2', title: 'امتحان الميكانيكا', courseTitle: 'الفيزياء', score: 85),
          RecentExam(id: '3', title: 'امتحان الكيمياء العضوية', courseTitle: 'الكيمياء', score: 78),
        ],
        liveSessions: liveSessions,
        alerts: const [
          StudentAlert(
            id: '1',
            type: 'exam',
            title: 'امتحان الرياضيات غداً',
            message: 'امتحان التفاضل والتكامل - 9:00 ص',
            actionLabel: 'استعد الآن',
          ),
          StudentAlert(
            id: '2',
            type: 'assignment',
            title: 'واجب الفيزياء',
            message: 'موعد التسليم بعد يومين',
            actionLabel: 'سلّم الواجب',
          ),
        ],
        tasks: dashboardTasks,
        notifications: notifications.take(5).toList(),
        chart: const DashboardChart(
          labels: ['ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون'],
          grades: [75, 78, 82, 80, 85, 87],
          studyHours: [12, 15, 18, 14, 20, 24],
        ),
        calendarEvents: [
          CalendarEvent(date: _todayOffset(0)),
          CalendarEvent(date: _todayOffset(2)),
          CalendarEvent(date: _todayOffset(5)),
        ],
        strengths: const [
          PerformanceItem(id: '1', subject: 'الرياضيات', topic: 'التفاضل', score: 92, trend: 'up', trendValue: '+5%'),
          PerformanceItem(id: '2', subject: 'الفيزياء', topic: 'الميكانيكا', score: 88, trend: 'up', trendValue: '+3%'),
        ],
        weaknesses: const [
          PerformanceItem(id: '3', subject: 'الكيمياء', topic: 'العضوية', score: 65, trend: 'down', trendValue: '-2%'),
          PerformanceItem(id: '4', subject: 'اللغة العربية', topic: 'النحو', score: 70, trend: 'down', trendValue: '-1%'),
        ],
      );

  static List<EnrolledCourse> get courses => const [
        EnrolledCourse(
          id: '1',
          title: 'الرياضيات - التفاضل والتكامل',
          teacher: 'أ/ محمد أحمد',
          progress: 75,
          rating: 4.8,
          totalLessons: 24,
          completedLessons: 18,
          category: 'رياضيات',
          level: 'ثالث ثانوي',
        ),
        EnrolledCourse(
          id: '2',
          title: 'الفيزياء - الميكانيكا',
          teacher: 'أ/ أحمد علي',
          progress: 60,
          rating: 4.6,
          totalLessons: 20,
          completedLessons: 12,
          category: 'فيزياء',
          level: 'ثالث ثانوي',
        ),
        EnrolledCourse(
          id: '3',
          title: 'الكيمياء العضوية',
          teacher: 'أ/ سارة محمود',
          progress: 45,
          rating: 4.5,
          totalLessons: 18,
          completedLessons: 8,
          category: 'كيمياء',
          level: 'ثالث ثانوي',
        ),
        EnrolledCourse(
          id: '4',
          title: 'اللغة العربية - النحو',
          teacher: 'أ/ فاطمة حسن',
          progress: 90,
          rating: 4.9,
          totalLessons: 16,
          completedLessons: 14,
          category: 'عربي',
          level: 'ثالث ثانوي',
        ),
      ];

  static List<EnrollmentItem> get enrollments => [
        EnrollmentItem(
          enrollmentId: 'e1',
          course: courses[0],
          progress: 75,
          enrolledAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        EnrollmentItem(
          enrollmentId: 'e2',
          course: courses[1],
          progress: 60,
          enrolledAt: DateTime.now().subtract(const Duration(days: 45)),
        ),
        EnrollmentItem(
          enrollmentId: 'e3',
          course: courses[2],
          progress: 45,
          enrolledAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        EnrollmentItem(
          enrollmentId: 'e4',
          course: courses[3],
          progress: 90,
          enrolledAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
      ];

  static List<StudentTask> get dashboardTasks => const [
        StudentTask(
          id: 't1',
          title: 'حل تمارين التفاضل - الفصل 3',
          courseName: 'الرياضيات',
          courseId: '1',
          dueDate: '2025-06-25',
        ),
        StudentTask(
          id: 't2',
          title: 'تقرير تجربة الميكانيكا',
          courseName: 'الفيزياء',
          courseId: '2',
          dueDate: '2025-06-28',
        ),
        StudentTask(
          id: 't3',
          title: 'مراجعة الكيمياء العضوية',
          courseName: 'الكيمياء',
          courseId: '3',
          dueDate: '2025-06-30',
          completed: true,
        ),
      ];

  static TaskStats get taskStats => const TaskStats(
        total: 8,
        exams: 2,
        assignments: 3,
        lessons: 3,
      );

  static List<StudentTask> get allTasks => const [
        StudentTask(
          id: 'e1',
          title: 'امتحان التفاضل',
          courseName: 'الرياضيات',
          courseId: '1',
          dueDate: '2025-06-22',
          type: 'exam',
          duration: 90,
          totalMarks: 100,
        ),
        StudentTask(
          id: 'e2',
          title: 'امتحان الميكانيكا',
          courseName: 'الفيزياء',
          courseId: '2',
          dueDate: '2025-06-24',
          type: 'exam',
          duration: 60,
          totalMarks: 50,
        ),
        StudentTask(
          id: 'a1',
          title: 'واجب التفاضل',
          courseName: 'الرياضيات',
          courseId: '1',
          dueDate: '2025-06-25',
          type: 'assignment',
          maxScore: 20,
        ),
        StudentTask(
          id: 'a2',
          title: 'تقرير الفيزياء',
          courseName: 'الفيزياء',
          courseId: '2',
          dueDate: '2025-06-28',
          type: 'assignment',
          maxScore: 15,
        ),
        StudentTask(
          id: 'l1',
          title: 'درس التكامل المحدد',
          courseName: 'الرياضيات',
          courseId: '1',
          dueDate: '',
          type: 'lesson',
          order: 5,
        ),
      ];

  static List<LiveSession> get liveSessions => const [
        LiveSession(
          id: 'ls1',
          title: 'حصة التفاضل المباشرة',
          teacher: 'أ/ محمد أحمد',
          time: '🔴 الآن',
          courseId: '1',
          isLive: true,
          participants: 45,
          roomName: 'math-live-001',
        ),
        LiveSession(
          id: 'ls2',
          title: 'مراجعة الميكانيكا',
          teacher: 'أ/ أحمد علي',
          time: '⏰ 4:00 م',
          courseId: '2',
          participants: 0,
          roomName: 'physics-live-002',
        ),
      ];

  static List<ExamItem> get exams => [
        ExamItem(
          id: '1',
          title: 'امتحان التفاضل والتكامل',
          courseTitle: 'الرياضيات',
          durationMinutes: 90,
          totalMarks: 100,
          passingMarks: 50,
          isPublished: true,
          availableFrom: DateTime.now().subtract(const Duration(days: 1)),
          availableTo: DateTime.now().add(const Duration(days: 7)),
        ),
        ExamItem(
          id: '2',
          title: 'امتحان الميكانيكا',
          courseTitle: 'الفيزياء',
          durationMinutes: 60,
          totalMarks: 50,
          passingMarks: 25,
          isPublished: true,
          availableFrom: DateTime.now().add(const Duration(days: 3)),
          availableTo: DateTime.now().add(const Duration(days: 10)),
        ),
        ExamItem(
          id: '3',
          title: 'امتحان الكيمياء العضوية',
          courseTitle: 'الكيمياء',
          durationMinutes: 75,
          totalMarks: 80,
          passingMarks: 40,
          isPublished: true,
          hasCompleted: true,
          score: 78,
          isPassed: true,
        ),
      ];

  static List<StudentNotification> get notifications => const [
        StudentNotification(
          id: '1',
          title: '📝 تم رفع درجات الرياضيات',
          body: 'تم نشر نتائج امتحان التفاضل',
          time: 'منذ 5 دقائق',
          type: 'grade',
        ),
        StudentNotification(
          id: '2',
          title: '📚 واجب جديد في الفيزياء',
          body: 'واجب الميكانيكا - موعد التسليم بعد يومين',
          time: 'منذ ساعة',
          type: 'assignment',
        ),
        StudentNotification(
          id: '3',
          title: '🎥 حصة الكيمياء بعد ساعتين',
          body: 'حصة مراجعة الكيمياء العضوية',
          time: 'منذ ساعتين',
          type: 'live',
          unread: false,
        ),
        StudentNotification(
          id: '4',
          title: '🏆 مسابقة ذهبية جديدة',
          body: 'مسابقة الرياضيات - علمي رياضة',
          time: 'منذ 3 ساعات',
          type: 'contest',
        ),
        StudentNotification(
          id: '5',
          title: '📖 درس جديد في الرياضيات',
          body: 'تم نشر درس التكامل المحدد',
          time: 'أمس',
          type: 'course',
          unread: false,
        ),
      ];

  static List<StudyBook> get books => [
        StudyBook(
          id: '1',
          title: 'الرياضيات البحتة',
          subtitle: 'التفاضل والتكامل',
          subject: 'الرياضيات',
          teacherName: 'أ/ محمد أحمد',
          chapters: 8,
          pages: 320,
          price: 0,
          bookType: 'pdf',
          color: studentColors[0],
          gradient: [studentColors[0], const Color(0xFF1D4ED8)],
          isFavorite: true,
          description: 'كتاب التفاضل والتكامل للصف الثالث الثانوي',
          rating: 4.8,
          reviewsCount: 120,
        ),
        StudyBook(
          id: '2',
          title: 'الفيزياء',
          subtitle: 'الميكانيكا والكهربية',
          subject: 'الفيزياء',
          teacherName: 'أ/ أحمد علي',
          chapters: 10,
          pages: 400,
          price: 150,
          bookType: 'pdf',
          color: studentColors[2],
          gradient: [studentColors[2], const Color(0xFF047857)],
          isFavorite: true,
        ),
        StudyBook(
          id: '3',
          title: 'الكيمياء',
          subtitle: 'الكيمياء العضوية',
          subject: 'الكيمياء',
          teacherName: 'أ/ سارة محمود',
          chapters: 7,
          pages: 350,
          price: 200,
          bookType: 'physical',
          color: studentColors[3],
          gradient: [studentColors[3], const Color(0xFFBE185D)],
        ),
        StudyBook(
          id: '4',
          title: 'اللغة العربية',
          subtitle: 'النحو والبلاغة',
          subject: 'العربية',
          teacherName: 'أ/ فاطمة حسن',
          chapters: 12,
          pages: 380,
          price: 0,
          bookType: 'pdf',
          color: studentColors[5],
          gradient: [studentColors[5], const Color(0xFFD97706)],
        ),
      ];

  static List<BookChapter> chaptersForBook(String bookId) => const [
        BookChapter(
          id: '1',
          title: 'الفصل الأول: المقدمة',
          description: 'مقدمة في الموضوع الأساسي',
          lessonsCount: 4,
          pagesCount: 40,
        ),
        BookChapter(
          id: '2',
          title: 'الفصل الثاني: المفاهيم الأساسية',
          description: 'شرح المفاهيم الأساسية',
          lessonsCount: 5,
          pagesCount: 55,
        ),
        BookChapter(
          id: '3',
          title: 'الفصل الثالث: التطبيقات',
          description: 'تطبيقات عملية',
          lessonsCount: 6,
          pagesCount: 60,
        ),
      ];

  static StudyBook? bookById(String id) {
    try {
      return books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<ContestItem> get contests => const [
        ContestItem(
          id: '1',
          title: 'مسابقة الرياضيات الذهبية',
          difficulty: 'medium',
          startTime: '2025-06-28T10:00:00',
          endTime: '2025-06-28T12:00:00',
          duration: 120,
          questionCount: 20,
          participants: 450,
          status: 'upcoming',
          aiGenerated: true,
        ),
        ContestItem(
          id: '2',
          title: 'مسابقة الفيزياء',
          difficulty: 'hard',
          startTime: '2025-07-05T10:00:00',
          endTime: '2025-07-05T11:30:00',
          duration: 90,
          questionCount: 15,
          participants: 320,
          status: 'upcoming',
        ),
        ContestItem(
          id: '3',
          title: 'مسابقة الكيمياء',
          difficulty: 'easy',
          startTime: '2025-05-15T10:00:00',
          endTime: '2025-05-15T11:00:00',
          duration: 60,
          questionCount: 10,
          participants: 280,
          status: 'completed',
        ),
      ];

  static List<ContestHistoryItem> get contestHistory => const [
        ContestHistoryItem(
          id: '1',
          contestName: 'مسابقة الرياضيات - مايو',
          date: '2025-05-10',
          difficulty: 'medium',
          rank: 12,
          totalParticipants: 500,
          score: 85,
          ratingChange: 45,
          newRating: 1547,
          solvedProblems: 8,
          totalProblems: 10,
          duration: '1:45:00',
        ),
        ContestHistoryItem(
          id: '2',
          contestName: 'مسابقة الفيزياء - أبريل',
          date: '2025-04-20',
          difficulty: 'hard',
          rank: 25,
          totalParticipants: 380,
          score: 72,
          ratingChange: 22,
          newRating: 1502,
          solvedProblems: 6,
          totalProblems: 10,
          duration: '2:10:00',
        ),
      ];

  static List<RatingPoint> get ratingHistory => const [
        RatingPoint(date: 'ينا', rating: 1200, contestName: ''),
        RatingPoint(date: 'فبر', rating: 1280, contestName: 'مسابقة 1'),
        RatingPoint(date: 'مار', rating: 1350, contestName: 'مسابقة 2'),
        RatingPoint(date: 'أبر', rating: 1420, contestName: 'مسابقة 3'),
        RatingPoint(date: 'ماي', rating: 1502, contestName: 'مسابقة 4'),
        RatingPoint(date: 'يون', rating: 1547, contestName: 'مسابقة 5'),
      ];

  static CourseDetail? courseById(String id) {
    final course = courses.where((c) => c.id == id).firstOrNull;
    if (course == null) return null;
    return CourseDetail(
      id: course.id,
      title: course.title,
      teacherName: course.teacher,
      progress: course.progress,
      category: course.category,
      level: course.level,
      lessons: [
        CourseLesson(id: 'l1', title: 'مقدمة في التفاضل', order: 1, attended: true, hasPdf: true),
        CourseLesson(id: 'l2', title: 'قواعد التفاضل', order: 2, attended: true, videoUrl: 'video'),
        CourseLesson(id: 'l3', title: 'تطبيقات التفاضل', order: 3, attended: false, videoUrl: 'video'),
        CourseLesson(id: 'l4', title: 'التكامل المحدد', order: 4, isPublished: false),
      ],
      exams: [
        CourseExam(
          id: '1',
          title: 'امتحان التفاضل',
          description: 'امتحان شامل على الفصول 1-3',
          durationMinutes: 90,
          questionsCount: 20,
          totalMarks: 100,
          passingMarks: 50,
          availableFrom: DateTime.now().subtract(const Duration(days: 1)),
          availableTo: DateTime.now().add(const Duration(days: 7)),
        ),
        CourseExam(
          id: '3',
          title: 'امتحان سابق',
          description: 'امتحان مراجعة',
          durationMinutes: 60,
          questionsCount: 15,
          totalMarks: 80,
          passingMarks: 40,
          hasAttempt: true,
          isPassed: true,
          attemptScore: 78,
        ),
      ],
      liveSessions: liveSessions.where((s) => s.courseId == id).toList(),
    );
  }

  static List<AssignmentItem> get assignments => const [
        AssignmentItem(
          id: 'a1',
          title: 'واجب التفاضل - الفصل 3',
          courseTitle: 'الرياضيات',
          maxScore: 20,
          dueDate: '2025-06-25',
        ),
        AssignmentItem(
          id: 'a2',
          title: 'تقرير تجربة الميكانيكا',
          courseTitle: 'الفيزياء',
          maxScore: 15,
          dueDate: '2025-06-28',
        ),
        AssignmentItem(
          id: 'a3',
          title: 'مراجعة الكيمياء',
          courseTitle: 'الكيمياء',
          maxScore: 10,
          dueDate: '2025-06-20',
          submitted: true,
          submissionScore: 9,
        ),
      ];

  static ExamStartData examStartData(String examId) => ExamStartData(
        examId: examId,
        title: 'امتحان التفاضل والتكامل',
        courseTitle: 'الرياضيات',
        durationMinutes: 90,
        attemptId: 'attempt-1',
        questions: const [
          ExamQuestion(
            id: 'q1',
            questionText: 'ما مشتقة x²؟',
            type: 'multiple-choice',
            marks: 5,
            options: ['2x', 'x', 'x²', '2'],
          ),
          ExamQuestion(
            id: 'q2',
            questionText: ' ∫ 2x dx = ?',
            type: 'multiple-choice',
            marks: 5,
            options: ['x² + C', '2x + C', 'x + C', '2x² + C'],
          ),
          ExamQuestion(
            id: 'q3',
            questionText: 'اشرح مفهوم التفاضل',
            type: 'essay',
            marks: 10,
          ),
        ],
      );

  static List<ExamReviewQuestion> get examReviewQuestions => const [
        ExamReviewQuestion(
          id: 'q1',
          questionText: 'ما مشتقة x²؟',
          type: 'multiple-choice',
          options: ['2x', 'x', 'x²', '2'],
          studentAnswer: '2x',
          correctAnswer: '2x',
          isCorrect: true,
          marks: 5,
          marksAwarded: 5,
        ),
        ExamReviewQuestion(
          id: 'q2',
          questionText: ' ∫ 2x dx = ?',
          type: 'multiple-choice',
          options: ['x² + C', '2x + C', 'x + C', '2x² + C'],
          studentAnswer: 'x + C',
          correctAnswer: 'x² + C',
          isCorrect: false,
          marks: 5,
          marksAwarded: 0,
        ),
        ExamReviewQuestion(
          id: 'q3',
          questionText: 'اشرح مفهوم التفاضل',
          type: 'essay',
          options: [],
          studentAnswer: 'التفاضل هو حساب معدل التغير...',
          correctAnswer: '',
          isCorrect: false,
          marks: 10,
          marksAwarded: 0,
          isEssay: true,
          pending: true,
        ),
      ];

  static PerformanceReportData get performance => PerformanceReportData(
        studentName: 'أحمد محمد',
        studentLevel: 'الصف الثالث الثانوي - علمي رياضة',
        kpis: dashboard.kpis,
        classRank: 5,
        totalStudents: 35,
        percentile: 86,
        rankImproved: true,
        courseProgress: const {
          'completed': 1,
          'inProgress': 3,
          'notStarted': 0,
          'total': 4,
        },
        subjects: [
          SubjectPerformance(
            name: 'الرياضيات',
            grade: 92,
            classAvg: 78,
            color: studentColors[0],
            trend: 'up',
            trendValue: '+5%',
            examsCount: 4,
          ),
          SubjectPerformance(
            name: 'الفيزياء',
            grade: 85,
            classAvg: 72,
            color: studentColors[2],
            trend: 'up',
            trendValue: '+3%',
            examsCount: 3,
          ),
          SubjectPerformance(
            name: 'الكيمياء',
            grade: 70,
            classAvg: 68,
            color: studentColors[3],
            trend: 'down',
            trendValue: '-2%',
            examsCount: 2,
          ),
        ],
        weeklyLabels: const ['أسبوع 1', 'أسبوع 2', 'أسبوع 3', 'أسبوع 4'],
        studentGrades: const [78, 82, 85, 87],
        classAverage: const [72, 74, 76, 78],
        strengths: dashboard.strengths,
        weaknesses: dashboard.weaknesses,
        maxScore: 100,
        minScore: 0,
      );

  static List<PreviousQuestion> get previousQuestions => const [
        PreviousQuestion(
          id: '1',
          question: 'كيف أحل مسائل التكامل المحدد؟',
          answer: 'ابدأ بتحديد حدود التكامل ثم طبّق القواعد...',
          date: '2025-06-10',
          answered: true,
        ),
        PreviousQuestion(
          id: '2',
          question: 'ما الفرق بين التفاضل والتكامل؟',
          date: '2025-06-15',
        ),
      ];

  static String _todayOffset(int days) {
    final d = DateTime.now().add(Duration(days: days));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class RatingPoint {
  const RatingPoint({
    required this.date,
    required this.rating,
    required this.contestName,
  });

  final String date;
  final int rating;
  final String contestName;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
