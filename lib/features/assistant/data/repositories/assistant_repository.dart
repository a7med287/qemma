import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/assistant_models.dart';

class AssistantRepository {
  AssistantRepository(this._client);

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<T> _guard<T>(Future<T> Function() call, [String fallback = 'حدث خطأ']) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ServerFailure(apiErrorMessage(e, fallback));
    }
  }

  Future<AssistantDashboardData> getDashboard() => _guard(() async {
        int studentsCount = 0;
        int activeChats = 0;
        int pendingGrading = 0;
        int unreadCount = 0;
        String teacherName = '';
        String teacherId = '';
        List<Map<String, dynamic>> recentAttempts = [];

        try {
          final infoRes = await _dio.get('/assistant/info');
          final infoData = asMap(unwrapBody(infoRes.data));
          final teacher = infoData['teacher'] as Map<String, dynamic>?;
          teacherName = teacher?['name'] ?? infoData['teacherName'] ?? '';
          teacherId = teacher?['id'] ?? teacher?['_id'] ?? infoData['teacherId'] ?? '';
        } catch (_) {}

        try {
          final studentsRes = await _dio.get('/assistant/students');
          final studentsData = unwrapBody(studentsRes.data);
          if (studentsData is List) {
            studentsCount = studentsData.length;
          } else if (studentsData is Map && studentsData['students'] is List) {
            studentsCount = (studentsData['students'] as List).length;
          }
        } catch (_) {}

        try {
          final sessionsRes = await _dio.get('/chat/sessions');
          final sessionsData = unwrapBody(sessionsRes.data);
          if (sessionsData is List) {
            activeChats = sessionsData.where((s) {
              final m = s as Map<String, dynamic>;
              return (m['messagesCount'] ?? 0) > 0;
            }).length;
          }
        } catch (_) {}

        try {
          final pendingRes = await _dio.get('/attempts', queryParameters: {
            'status': 'pending',
            'limit': 1,
          });
          final pendingData = unwrapBody(pendingRes.data);
          if (pendingData is Map) {
            final pagination = pendingData['pagination'] as Map?;
            pendingGrading = pagination?['total'] as int? ?? 0;
          } else if (pendingData is List) {
            pendingGrading = pendingData.length;
          }
        } catch (_) {}

        try {
          final notifRes = await _dio.get('/notifications/unread-count');
          final notifData = asMap(unwrapBody(notifRes.data));
          unreadCount = notifData['unreadCount'] as int? ?? 0;
        } catch (_) {}

        try {
          final attemptsRes = await _dio.get('/attempts', queryParameters: {
            'status': 'pending',
            'limit': 10,
          });
          final attemptsData = unwrapBody(attemptsRes.data);
          if (attemptsData is Map) {
            recentAttempts = (attemptsData['attempts'] as List?)
                    ?.map((e) => e as Map<String, dynamic>)
                    .toList() ??
                [];
          } else if (attemptsData is List) {
            recentAttempts = attemptsData.cast<Map<String, dynamic>>();
          }
        } catch (_) {}

        return AssistantDashboardData(
          studentsCount: studentsCount,
          activeChats: activeChats,
          pendingGrading: pendingGrading,
          unreadCount: unreadCount,
          teacherName: teacherName,
          teacherId: teacherId,
          recentAttempts: recentAttempts,
        );
      }, 'فشل تحميل لوحة تحكم المدرس المساعد');

  Future<List<AssistantStudent>> getStudents() => _guard(() async {
        final res = await _dio.get('/assistant/students');
        final data = unwrapBody(res.data);
        final list = data is List ? data : (data['students'] as List? ?? []);
        return list.map((e) => AssistantStudent.fromJson(e as Map<String, dynamic>)).toList();
      }, 'فشل تحميل الطلاب');

  Future<Map<String, dynamic>> getStudentDetail(String studentId) => _guard(() async {
        final res = await _dio.get('/assistant/students/$studentId');
        return asMap(unwrapBody(res.data));
      }, 'فشل تحميل تفاصيل الطالب');

  Future<List<Map<String, dynamic>>> getPendingAttempts({int limit = 50}) => _guard(() async {
        final res = await _dio.get('/attempts', queryParameters: {
          'status': 'pending',
          'limit': limit,
        });
        final data = unwrapBody(res.data);
        if (data is Map) {
          return (data['attempts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        }
        if (data is List) return data.cast<Map<String, dynamic>>();
        return [];
      }, 'فشل تحميل المحاولات');

  Future<Map<String, dynamic>> getAttemptDetail(String attemptId) => _guard(() async {
        final res = await _dio.get('/attempts/$attemptId');
        return asMap(unwrapBody(res.data));
      }, 'فشل تحميل تفاصيل المحاولة');

  Future<void> gradeEssays(String attemptId, List<Map<String, dynamic>> essayScores) =>
      _guard(() async {
        await _dio.post('/attempts/$attemptId/assistant-grade', data: {
          'essayScores': essayScores,
        });
      }, 'فشل تصحيح المقالات');

  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) =>
      _guard(() async {
        final res = await _dio.get('/notifications', queryParameters: {
          'page': page,
          'limit': limit,
        });
        return asMap(unwrapBody(res.data));
      }, 'فشل تحميل الإشعارات');

  Future<void> markNotificationRead(String id) => _guard(() async {
        await _dio.patch('/notifications/$id/read');
      }, 'فشل تعيين الإشعار كمقروء');

  Future<void> markAllNotificationsRead() => _guard(() async {
        await _dio.patch('/notifications/read-all');
      }, 'فشل تعيين الكل كمقروء');

  Future<void> deleteOneNotification(String id) => _guard(() async {
        await _dio.delete('/notifications/$id');
      }, 'فشل حذف الإشعار');

  Future<void> deleteAllNotifications() => _guard(() async {
        await _dio.delete('/notifications');
      }, 'فشل حذف الإشعارات');

  Future<int> getUnreadCount() => _guard(() async {
        final res = await _dio.get('/notifications/unread-count');
        final data = asMap(unwrapBody(res.data));
        return data['unreadCount'] as int? ?? 0;
      }, 'فشل تحميل عدد الإشعارات');

  Future<List<Map<String, dynamic>>> getChatCourses() => _guard(() async {
        final res = await _dio.get('/chat/teacher/courses');
        final data = unwrapBody(res.data);
        return (data is List ? data : []).cast<Map<String, dynamic>>();
      }, 'فشل تحميل الكورسات');

  Future<List<Map<String, dynamic>>> getChatStudents() => _guard(() async {
        final res = await _dio.get('/chat/teacher/students');
        final data = unwrapBody(res.data);
        return (data is List ? data : []).cast<Map<String, dynamic>>();
      }, 'فشل تحميل الطلاب');

  Future<List<Map<String, dynamic>>> getSessions() => _guard(() async {
        final res = await _dio.get('/chat/sessions');
        final data = unwrapBody(res.data);
        return (data is List ? data : []).cast<Map<String, dynamic>>();
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
        return (data is List ? data : []).cast<Map<String, dynamic>>();
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
}
