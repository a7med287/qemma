import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/student_model_json.dart';
import '../models/student_models.dart';

class StudentRepository {
  StudentRepository(this._client);

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<T> _guard<T>(Future<T> Function() call, [String fallback = 'حدث خطأ في جلب البيانات']) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ServerFailure(apiErrorMessage(e, fallback));
    }
  }

  Future<StudentDashboardData> getDashboard() => _guard(() async {
        final res = await _dio.get('/students/dashboard');
        return StudentModelJson.dashboardFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تحميل لوحة التحكم');

  Future<PerformanceReportData> getPerformance() => _guard(() async {
        final res = await _dio.get('/students/performance');
        return StudentModelJson.performanceFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تحميل تقرير الأداء');

  Future<TasksResponse> getTasks() => _guard(() async {
        final res = await _dio.get('/students/tasks');
        return StudentModelJson.tasksResponseFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تحميل المهام');

  Future<List<EnrollmentItem>> getMyEnrollments() => _guard(() async {
        final res = await _dio.get('/enrollments/my');
        final data = unwrapBody(res.data);
        return asMapList(data).map(StudentModelJson.enrollmentFromJson).toList();
      }, 'فشل تحميل الكورسات');

  Future<CourseDetail> getCourseDetail(String courseId) => _guard(() async {
        final res = await _dio.get('/enrollments/my/$courseId');
        return StudentModelJson.courseDetailFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تحميل تفاصيل الكورس');

  Future<List<ExamItem>> getStudentExams() => _guard(() async {
        final res = await _dio.get('/exams/student');
        final data = unwrapBody(res.data);
        return asMapList(data).map(StudentModelJson.examItemFromJson).toList();
      }, 'فشل تحميل الاختبارات');

  Future<ExamStartData> startExam(String examId) => _guard(() async {
        final res = await _dio.post('/attempts/exam/$examId/start');
        return StudentModelJson.examStartFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل بدء الامتحان');

  Future<ExamSubmitResult> submitExam(String examId, Map<String, dynamic> answers) => _guard(() async {
        final res = await _dio.post('/attempts/exam/$examId/submit', data: {'answers': answers});
        return StudentModelJson.examSubmitFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تسليم الامتحان');

  Future<ExamReviewData> getExamReview(String examId) => _guard(() async {
        final res = await _dio.get('/attempts/exam/$examId/review');
        return StudentModelJson.examReviewFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تحميل مراجعة الامتحان');

  Future<List<AssignmentItem>> getStudentAssignments() => _guard(() async {
        final res = await _dio.get('/assignments/student');
        final data = unwrapBody(res.data);
        return asMapList(data).map(StudentModelJson.assignmentFromJson).toList();
      }, 'فشل تحميل الواجبات');

  Future<void> submitAssignment({
    required String assignmentId,
    required String filePath,
    String? notes,
    void Function(int progress)? onProgress,
  }) =>
      _guard(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        });
        await _dio.post(
          '/assignments/$assignmentId/submit',
          data: form,
          onSendProgress: (sent, total) {
            if (onProgress != null && total > 0) {
              onProgress((sent * 100 / total).round());
            }
          },
        );
      }, 'فشل تسليم الواجب');

  Future<NotificationsPageData> getNotifications({
    int page = 1,
    int limit = 20,
    String? courseId,
  }) =>
      _guard(() async {
        final res = await _dio.get('/notifications', queryParameters: {
          'page': page,
          'limit': limit,
          if (courseId != null) 'courseId': courseId,
        });
        return StudentModelJson.notificationsPageFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تحميل الإشعارات');

  Future<void> markNotificationRead(String id) => _guard(() async {
        await _dio.patch('/notifications/$id/read');
      });

  Future<void> markAllNotificationsRead() => _guard(() async {
        await _dio.patch('/notifications/read-all');
      });

  Future<void> deleteNotification(String id) => _guard(() async {
        await _dio.delete('/notifications/$id');
      });

  Future<LiveRoomInfo> joinLiveByCode(String code) => _guard(() async {
        final res = await _dio.get('/live-classes/join/$code');
        return StudentModelJson.liveRoomInfoFromJson(asMap(unwrapBody(res.data)));
      }, 'كود الحصة غير صحيح');

  Future<LiveRoomInfo> getLiveRoom(String roomName) => _guard(() async {
        final res = await _dio.get('/live-classes/room/$roomName');
        return StudentModelJson.liveRoomInfoFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تحميل بيانات الحصة');

  Future<List<StudyBook>> getBooks({String? search, String? subject}) => _guard(() async {
        final res = await _dio.get('/books', queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (subject != null && subject.isNotEmpty) 'subject': subject,
          'limit': 50,
        });
        final data = unwrapBody(res.data);
        final list = data is Map ? data['books'] ?? data['data'] ?? data : data;
        return asMapList(list).asMap().entries.map((e) => StudentModelJson.bookFromJson(e.value, index: e.key)).toList();
      }, 'فشل تحميل الكتب');

  Future<StudyBook> getBook(String bookId) => _guard(() async {
        final res = await _dio.get('/books/$bookId');
        return StudentModelJson.bookFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تحميل تفاصيل الكتاب');

  Future<List<StudyBook>> getPurchasedBooks() => _guard(() async {
        final res = await _dio.get('/books/purchased');
        final data = unwrapBody(res.data);
        return asMapList(data).asMap().entries.map((e) => StudentModelJson.bookFromJson(e.value, index: e.key)).toList();
      }, 'فشل تحميل مكتبتك');

  Future<CourseLesson> getLesson(String lessonId) => _guard(() async {
        final res = await _dio.get('/lessons/$lessonId');
        return StudentModelJson.courseLessonFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تحميل الدرس');

  Future<List<CourseLesson>> getLessonsByCourse(String courseId) => _guard(() async {
        final res = await _dio.get('/lessons/course/$courseId');
        final data = unwrapBody(res.data);
        return asMapList(data).map(StudentModelJson.courseLessonFromJson).toList();
      }, 'فشل تحميل الدروس');

  // ── Contests ──────────────────────────────────────────────────────

  Future<List<ContestItem>> getAvailableContests() => _guard(() async {
        final res = await _dio.get('/contests/available');
        final data = unwrapBody(res.data);
        return asMapList(data).map(StudentModelJson.contestItemFromJson).toList();
      }, 'فشل تحميل المسابقات');

  Future<ContestDashboardData> getContestDashboard() => _guard(() async {
        final res = await _dio.get('/contests/dashboard');
        return StudentModelJson.contestDashboardFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تحميل لوحة المسابقات');

  Future<List<ContestHistoryItem>> getContestHistory() => _guard(() async {
        final res = await _dio.get('/contests/my-history');
        final data = unwrapBody(res.data);
        return asMapList(data).map(StudentModelJson.contestHistoryFromJson).toList();
      }, 'فشل تحميل تاريخ المسابقات');

  Future<ContestParticipation> startContest(String contestId) => _guard(() async {
        final res = await _dio.post('/contests/$contestId/start');
        return StudentModelJson.contestParticipationFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل بدء المسابقة');

  Future<ContestParticipation> getParticipation(String contestId) => _guard(() async {
        final res = await _dio.get('/contests/$contestId/participation');
        return StudentModelJson.contestParticipationFromJson(asMap(unwrapBody(res.data)));
      }, 'فشل تحميل المشاركة');

  Future<void> submitAnswer({
    required String contestId,
    required String questionId,
    required String selectedOptionId,
  }) => _guard(() async {
        await _dio.post('/contests/$contestId/questions/$questionId/submit', data: {
          'selectedOptionId': selectedOptionId,
        });
      }, 'فشل إرسال الإجابة');

  Future<void> submitContest(String contestId) => _guard(() async {
        await _dio.post('/contests/$contestId/submit');
      }, 'فشل تقديم المسابقة');
}
