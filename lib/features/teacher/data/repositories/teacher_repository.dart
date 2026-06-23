import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/teacher_models.dart';

class TeacherRepository {
  TeacherRepository(this._client);

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<T> _guard<T>(Future<T> Function() call, [String fallback = 'حدث خطأ في جلب البيانات']) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ServerFailure(apiErrorMessage(e, fallback));
    }
  }

  Future<TeacherDashboardData> getDashboard() => _guard(() async {
        int totalStudents = 0;
        int activeCourses = 0;
        List<String> subjects = [];
        String teacherName = '';

        final coursesRes = await _dio.get('/courses/my');
        final coursesData = unwrapBody(coursesRes.data);
        final coursesList = asMapList(coursesData);
        totalStudents = coursesList.fold(0, (sum, c) => sum + ((c['stats'] as Map?)?['enrollments'] as int? ?? 0));
        activeCourses = coursesList.where((c) => c['isPublished'] == true).length;

        double? passRate;
        try {
          final analyticsRes = await _dio.get('/analytics/teacher');
          final report = asMap(unwrapBody(analyticsRes.data));
          final summary = report['summary'] as Map?;
          if (summary != null && summary['passRate'] != null) {
            passRate = (summary['passRate'] as num).toDouble();
          }
        } catch (_) {}

        try {
          final profileRes = await _dio.get('/auth/me');
          final profile = asMap(unwrapBody(profileRes.data));
          final teacher = profile['teacher'] as Map?;
          if (teacher != null) {
            final specialties = teacher['specialties'];
            if (specialties is List) {
              subjects = specialties.map((e) => e.toString()).toList();
            }
          }
          teacherName = profile['name'] ?? '';
        } catch (_) {}

        List<ScheduleItem> schedules = [];
        try {
          final schedRes = await _dio.get('/schedule/upcoming');
          final schedData = unwrapBody(schedRes.data);
          final schedList = asMapList(schedData);
          schedules = schedList.map(ScheduleItem.fromJson).toList();
        } catch (_) {}

        return TeacherDashboardData(
          totalStudents: totalStudents,
          activeCourses: activeCourses,
          passRate: passRate,
          upcomingSchedules: schedules,
          subjects: subjects,
          teacherName: teacherName,
        );
      }, 'فشل تحميل لوحة تحكم المعلم');

  Future<void> createCourse({
    required String title,
    required String description,
    required String category,
    required String level,
    required double price,
    required int duration,
    int? maxStudents,
    required String startDate,
    String? endDate,
    List<String> prerequisites = const [],
    PlatformFile? thumbnailFile,
    bool isPublished = false,
  }) =>
      _guard(() async {
        String? thumbnailBase64;
        if (thumbnailFile != null && thumbnailFile.path != null) {
          final bytes = await File(thumbnailFile.path!).readAsBytes();
          thumbnailBase64 = 'data:image/${thumbnailFile.extension ?? 'png'};base64,${base64Encode(bytes)}';
        }
        await _dio.post('/courses', data: {
          'title': title.trim(),
          'description': description.trim(),
          'category': category,
          'level': level,
          'price': price,
          'duration': duration,
          if (maxStudents != null) 'maxStudents': maxStudents,
          'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
          'prerequisites': prerequisites,
          if (thumbnailBase64 != null) 'thumbnailBase64': thumbnailBase64,
          'isPublished': isPublished,
        });
      }, 'فشل إنشاء الكورس');

  Future<List<TeacherCourse>> getMyCourses() => _guard(() async {
        final res = await _dio.get('/courses/my');
        final data = unwrapBody(res.data);
        final list = asMapList(data);
        return list.map(TeacherCourse.fromJson).toList();
      }, 'فشل تحميل الكورسات');

  Future<void> deleteCourse(String courseId) => _guard(() async {
        await _dio.delete('/courses/$courseId');
      }, 'فشل حذف الكورس');

  Future<bool> togglePublish(String courseId) => _guard(() async {
        final res = await _dio.patch('/courses/$courseId/publish');
        final data = asMap(unwrapBody(res.data));
        return data['isPublished'] ?? false;
      }, 'فشل تغيير حالة الكورس');

  Future<Map<String, dynamic>> getTeacherProfile() => _guard(() async {
        final res = await _dio.get('/auth/me');
        return asMap(unwrapBody(res.data));
      }, 'فشل تحميل الملف الشخصي');

  Future<List<Map<String, dynamic>>> getNotificationCourses() => _guard(() async {
        final res = await _dio.get('/courses/my');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل الكورسات');

  Future<List<Map<String, dynamic>>> getNotificationStudents() => _guard(() async {
        final res = await _dio.get('/notifications/students');
        final data = unwrapBody(res.data);
        final students = data['students'] as List? ?? [];
        return students.map((e) => e as Map<String, dynamic>).toList();
      }, 'فشل تحميل الطلاب');

  Future<void> createLesson({
    required String courseId,
    required String title,
    String? content,
    String? summary,
    int order = 1,
    bool isPublished = true,
    String? videoPath,
    String? pdfPath,
  }) => _guard(() async {
        final formData = FormData.fromMap({
          'courseId': courseId,
          'title': title.trim(),
          if (content != null && content.isNotEmpty) 'content': content,
          if (summary != null && summary.isNotEmpty) 'summary': summary,
          'order': order.toString(),
          'isPublished': isPublished.toString(),
        });
        if (videoPath != null) {
          formData.files.add(MapEntry('video', await MultipartFile.fromFile(videoPath)));
        }
        if (pdfPath != null) {
          formData.files.add(MapEntry('pdf', await MultipartFile.fromFile(pdfPath)));
        }
        await _dio.post('/lessons', data: formData);
      }, 'فشل رفع الدرس');

  Future<void> updateCourse(String courseId, {
    required String title,
    required String description,
    required String category,
    required String level,
    required int price,
    int? duration,
    bool isPublished = false,
    PlatformFile? thumbnailFile,
    bool removeThumbnail = false,
  }) =>
      _guard(() async {
        String? thumbnailBase64;
        if (thumbnailFile != null && thumbnailFile.path != null) {
          final bytes = await File(thumbnailFile.path!).readAsBytes();
          thumbnailBase64 = 'data:image/${thumbnailFile.extension ?? 'png'};base64,${base64Encode(bytes)}';
        }
        final payload = <String, dynamic>{
          'title': title.trim(),
          'description': description.trim(),
          'category': category,
          'level': level,
          'price': price,
          if (duration != null) 'duration': duration,
          'isPublished': isPublished,
        };
        if (thumbnailBase64 != null) {
          payload['thumbnailBase64'] = thumbnailBase64;
        } else if (removeThumbnail) {
          payload['thumbnailBase64'] = null;
        }
        await _dio.put('/courses/$courseId', data: payload);
      }, 'فشل تحديث الكورس');

  Future<Map<String, dynamic>> sendNotification({
    required String type,
    required String title,
    required String message,
    required String recipient,
    String? courseId,
    String? studentId,
    String? scheduleType,
    String? scheduledDate,
    String? scheduledTime,
  }) => _guard(() async {
        final res = await _dio.post('/notifications/send', data: {
          'type': type,
          'title': title.trim(),
          'message': message.trim(),
          'recipient': recipient,
          if (courseId != null) 'courseId': courseId,
          if (studentId != null) 'studentId': studentId,
          if (scheduleType != null) 'scheduleType': scheduleType,
          if (scheduledDate != null) 'scheduledDate': scheduledDate,
          if (scheduledTime != null) 'scheduledTime': scheduledTime,
        });
        return asMap(unwrapBody(res.data));
      }, 'فشل إرسال الإشعار');

  // ── Books ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyBooks() => _guard(() async {
        final res = await _dio.get('/books/my');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل الكتب');

  Future<Map<String, dynamic>> createBook({
    required String title,
    required String grade,
    String description = '',
    required double price,
    required bool isPublished,
    String? coverBase64,
  }) => _guard(() async {
        final res = await _dio.post('/books', data: {
          'title': title.trim(),
          'grade': grade,
          'description': description,
          'price': price,
          'isPublished': isPublished,
          if (coverBase64 != null) 'coverBase64': coverBase64,
        });
        return asMap(unwrapBody(res.data));
      }, 'فشل إضافة الكتاب');

  Future<Map<String, dynamic>> updateBook(String bookId, {
    required String title,
    required String grade,
    String description = '',
    required double price,
    required bool isPublished,
    String? coverBase64,
  }) => _guard(() async {
        final res = await _dio.put('/books/$bookId', data: {
          'title': title.trim(),
          'grade': grade,
          'description': description,
          'price': price,
          'isPublished': isPublished,
          if (coverBase64 != null) 'coverBase64': coverBase64,
        });
        return asMap(unwrapBody(res.data));
      }, 'فشل تحديث الكتاب');

  Future<void> deleteBook(String bookId) => _guard(() async {
        await _dio.delete('/books/$bookId');
      }, 'فشل حذف الكتاب');

  Future<bool> toggleBookPublish(String bookId) => _guard(() async {
        final res = await _dio.patch('/books/$bookId/publish');
        final data = asMap(unwrapBody(res.data));
        return data['isPublished'] ?? false;
      }, 'فشل تغيير حالة الكتاب');

  // ── Analytics ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAnalytics() => _guard(() async {
        final res = await _dio.get('/analytics/teacher');
        return asMap(unwrapBody(res.data));
      }, 'فشل تحميل التقارير');

  // ── Exams ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTeacherExams() => _guard(() async {
        final res = await _dio.get('/exams/teacher');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل الاختبارات');

  Future<Map<String, dynamic>> createExam({
    required String title,
    required String courseId,
    required int durationMinutes,
    required int totalMarks,
    required int passingMarks,
    required List<Map<String, dynamic>> questions,
    String? description,
    String? availableFrom,
    String? availableTo,
    bool proctored = false,
    bool isPublished = true,
  }) => _guard(() async {
        final res = await _dio.post('/exams', data: {
          'title': title.trim(),
          'courseId': courseId,
          if (description != null && description.isNotEmpty) 'description': description.trim(),
          'durationMinutes': durationMinutes,
          'totalMarks': totalMarks,
          'passingMarks': passingMarks,
          if (availableFrom != null && availableFrom.isNotEmpty) 'availableFrom': availableFrom,
          if (availableTo != null && availableTo.isNotEmpty) 'availableTo': availableTo,
          'proctored': proctored,
          'isPublished': isPublished,
          'questions': questions,
        });
        return asMap(unwrapBody(res.data));
      }, 'فشل إنشاء الاختبار');

  Future<void> deleteExam(String examId) => _guard(() async {
        await _dio.delete('/exams/$examId');
      }, 'فشل حذف الاختبار');

  Future<Map<String, dynamic>> toggleExamPublish(String examId) => _guard(() async {
        final res = await _dio.patch('/exams/$examId/publish');
        return asMap(unwrapBody(res.data));
      }, 'فشل تغيير حالة الاختبار');

  Future<List<Map<String, dynamic>>> getExamAttempts(String examId) => _guard(() async {
        final res = await _dio.get('/exams/$examId/attempts');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل محاولات الاختبار');

  Future<Map<String, dynamic>> gradeAttempt({
    required String examId,
    required String attemptId,
    required Map<String, dynamic> gradeData,
  }) => _guard(() async {
        final res = await _dio.patch('/exams/$examId/attempts/$attemptId/grade', data: gradeData);
        return asMap(unwrapBody(res.data));
      }, 'فشل تصحيح المحاولة');

  Future<Map<String, dynamic>> autoGradeExam(String examId) => _guard(() async {
        final res = await _dio.post('/exams/$examId/auto-grade');
        return asMap(unwrapBody(res.data));
      }, 'فشل التصحيح الآلي');

  // ── Assignments ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTeacherCourses() => _guard(() async {
        final res = await _dio.get('/assignments/teacher/courses');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل الكورسات');

  Future<List<Map<String, dynamic>>> getCourseLessons(String courseId) => _guard(() async {
        final res = await _dio.get('/assignments/teacher/courses/$courseId/lessons');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل الدروس');

  Future<List<Map<String, dynamic>>> getTeacherAssignments({String? courseId}) => _guard(() async {
        final queryParams = courseId != null ? {'courseId': courseId} : null;
        final res = await _dio.get('/assignments/teacher', queryParameters: queryParams);
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل الواجبات');

  Future<Map<String, dynamic>> createAssignment({
    required String title,
    required String courseId,
    required String dueDate,
    String? lessonId,
    String? description,
    int totalMarks = 100,
    bool isPublished = true,
    String? filePath,
  }) => _guard(() async {
        if (filePath != null) {
          final formData = FormData.fromMap({
            'title': title.trim(),
            'courseId': courseId,
            'dueDate': dueDate,
            if (lessonId != null) 'lessonId': lessonId,
            if (description != null && description.isNotEmpty) 'description': description,
            'maxScore': totalMarks.toString(),
            'isPublished': isPublished.toString(),
          });
          formData.files.add(MapEntry('file', await MultipartFile.fromFile(filePath)));
          final res = await _dio.post('/assignments', data: formData);
          return asMap(unwrapBody(res.data));
        }
        final res = await _dio.post('/assignments', data: {
          'title': title.trim(),
          'courseId': courseId,
          'dueDate': dueDate,
          if (lessonId != null && lessonId.isNotEmpty) 'lessonId': lessonId,
          if (description != null && description.isNotEmpty) 'description': description.trim(),
          'maxScore': totalMarks,
          'isPublished': isPublished,
        });
        return asMap(unwrapBody(res.data));
      }, 'فشل إنشاء الواجب');

  Future<void> deleteAssignment(String assignmentId) => _guard(() async {
        await _dio.delete('/assignments/$assignmentId');
      }, 'فشل حذف الواجب');

  Future<Map<String, dynamic>> getAssignmentDetail(String assignmentId) => _guard(() async {
        final res = await _dio.get('/assignments/teacher/$assignmentId');
        return asMap(unwrapBody(res.data));
      }, 'فشل تحميل تفاصيل الواجب');

  Future<Map<String, dynamic>> gradeSubmission({
    required String submissionId,
    required int score,
    String? feedback,
  }) => _guard(() async {
        final res = await _dio.patch('/assignments/submissions/$submissionId/grade', data: {
          'score': score,
          if (feedback != null) 'feedback': feedback,
        });
        return asMap(unwrapBody(res.data));
      }, 'فشل تصحيح التسليم');

  // ── Contests ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTeacherContests() => _guard(() async {
        final res = await _dio.get('/contests/teacher');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل المسابقات');

  Future<Map<String, dynamic>> createContest({
    required String title,
    required String courseId,
    required int duration,
    required int questionCount,
    required String difficulty,
    String? description,
    bool isPublished = false,
  }) => _guard(() async {
        final res = await _dio.post('/contests', data: {
          'title': title.trim(),
          'courseId': courseId,
          'duration': duration,
          'questionCount': questionCount,
          'difficulty': difficulty,
          if (description != null) 'description': description.trim(),
          'isPublished': isPublished,
        });
        return asMap(unwrapBody(res.data));
      }, 'فشل إنشاء المسابقة');

  Future<void> deleteContest(String contestId) => _guard(() async {
        await _dio.delete('/contests/$contestId');
      }, 'فشل حذف المسابقة');

  Future<Map<String, dynamic>> toggleContestPublish(String contestId) => _guard(() async {
        final res = await _dio.patch('/contests/$contestId/publish');
        return asMap(unwrapBody(res.data));
      }, 'فشل تغيير حالة المسابقة');

  // ── Live Classes ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTeacherLiveClasses() => _guard(() async {
        final res = await _dio.get('/live-classes/teacher');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل الحصص المباشرة');

  Future<Map<String, dynamic>> createLiveClass({
    required String title,
    required String courseId,
    required String date,
    required String startTime,
    String? endTime,
    String? description,
    bool isActive = false,
  }) => _guard(() async {
        final res = await _dio.post('/live-classes', data: {
          'title': title.trim(),
          'courseId': courseId,
          'date': date,
          'startTime': startTime,
          if (endTime != null) 'endTime': endTime,
          if (description != null) 'description': description.trim(),
          'isActive': isActive,
        });
        return asMap(unwrapBody(res.data));
      }, 'فشل إنشاء الحصة المباشرة');

  Future<void> deleteLiveClass(String roomName) => _guard(() async {
        await _dio.delete('/live-classes/$roomName');
      }, 'فشل حذف الحصة المباشرة');

  // ── Chats ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getChatCourses() => _guard(() async {
        final res = await _dio.get('/chat/teacher/courses');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل الكورسات');

  Future<List<Map<String, dynamic>>> getChatStudents() => _guard(() async {
        final res = await _dio.get('/chat/teacher/students');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل الطلاب');

  Future<List<Map<String, dynamic>>> getSessions() => _guard(() async {
        final res = await _dio.get('/chat/sessions');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل المحادثات');

  Future<Map<String, dynamic>> openSessionWithStudent({
    required String studentUserId,
    required String courseId,
  }) => _guard(() async {
        final res = await _dio.post('/chat/teacher/open-session', data: {
          'studentUserId': studentUserId,
          'courseId': courseId,
        });
        return asMap(unwrapBody(res.data));
      }, 'فشل فتح المحادثة');

  Future<List<Map<String, dynamic>>> getChatMessages(String sessionId) => _guard(() async {
        final res = await _dio.get('/chat/sessions/$sessionId/messages');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل الرسائل');

  Future<Map<String, dynamic>> sendChatMessage({
    required String sessionId,
    required String message,
  }) => _guard(() async {
        final res = await _dio.post('/chat/sessions/$sessionId/messages', data: {
          'message': message.trim(),
        });
        return asMap(unwrapBody(res.data));
      }, 'فشل إرسال الرسالة');

  // ── Notifications (teacher sent list) ──────────────────────────

  Future<List<Map<String, dynamic>>> getSentNotifications() => _guard(() async {
        final res = await _dio.get('/notifications/sent');
        final data = unwrapBody(res.data);
        return asMapList(data);
      }, 'فشل تحميل الإشعارات المرسلة');

  Future<void> deleteSentNotification(String notificationId) => _guard(() async {
        await _dio.delete('/notifications/$notificationId');
      }, 'فشل حذف الإشعار');
}
