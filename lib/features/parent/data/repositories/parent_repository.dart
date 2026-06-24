import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/parent_model_json.dart';
import '../models/parent_models.dart';

class ParentRepository {
  final ApiClient _client;
  ParentRepository(this._client);
  Dio get _dio => _client.dio;

  Future<T> _guard<T>(Future<T> Function() fn, [String fallback = 'حدث خطأ']) async {
    try {
      return await fn();
    } on DioException catch (e) {
      throw ServerFailure(apiErrorMessage(e, fallback));
    }
  }

  Future<List<ChildSummary>> getChildren() => _guard(() async {
        final res = await _dio.get('/parents/children');
        final data = unwrapBody(res.data);
        final list = data is List ? data : (data['children'] ?? data['data'] ?? []);
        return (list as List).map((e) => ParentModelJson.childSummaryFromJson(e)).toList();
      }, 'فشل تحميل الأبناء');

  Future<ChildDetail> getChildDashboard(String childId) => _guard(() async {
        final res = await _dio.get('/parents/children/$childId/dashboard');
        final data = unwrapBody(res.data);
        return ParentModelJson.childDetailFromJson(data);
      }, 'فشل تحميل لوحة الطالب');

  Future<ChildPerformance> getChildPerformance(String childId) => _guard(() async {
        final res = await _dio.get('/parents/children/$childId/performance');
        final data = unwrapBody(res.data);
        return ParentModelJson.childPerformanceFromJson(data);
      }, 'فشل تحميل أداء الطالب');

  Future<List<ChildTask>> getChildTasks(String childId) => _guard(() async {
        final res = await _dio.get('/parents/children/$childId/tasks');
        final data = unwrapBody(res.data);
        final list = data is List ? data : (data['pendingAssignments'] ?? data['tasks'] ?? data['data'] ?? []);
        return (list as List).map((e) => ParentModelJson.childTaskFromJson(e)).toList();
      }, 'فشل تحميل الواجبات');

  Future<List<Map<String, dynamic>>> getChildPendingExams(String childId) => _guard(() async {
        final res = await _dio.get('/parents/children/$childId/tasks');
        final data = unwrapBody(res.data) as Map<String, dynamic>? ?? {};
        final exams = data['pendingExams'] as List? ?? [];
        return exams.cast<Map<String, dynamic>>();
      }, 'فشل تحميل الاختبارات القادمة');

  Future<List<ChildExamResult>> getChildExamResults(String childId) => _guard(() async {
        final res = await _dio.get('/parents/children/$childId/exam-results');
        final data = unwrapBody(res.data);
        final list = data is List ? data : (data['examResults'] ?? data['data'] ?? []);
        return (list as List).map((e) => ParentModelJson.childExamResultFromJson(e)).toList();
      }, 'فشل تحميل نتائج الامتحانات');

  Future<List<ChildCourse>> getChildCourses(String childId) => _guard(() async {
        final res = await _dio.get('/parents/children/$childId/courses');
        final data = unwrapBody(res.data);
        final list = data is List ? data : (data['courses'] ?? data['data'] ?? []);
        return (list as List).map((e) => ParentModelJson.childCourseFromJson(e)).toList();
      }, 'فشل تحميل الكورسات');

  Future<CourseDetail> getChildCourseDetails(String childId, String courseId) =>
      _guard(() async {
        final res = await _dio.get('/parents/children/$childId/courses/$courseId');
        final data = unwrapBody(res.data);
        return ParentModelJson.courseDetailFromJson(data);
      }, 'فشل تحميل تفاصيل الكورس');

  Future<List<ChildNotification>> getChildNotifications(String childId) =>
      _guard(() async {
        final res = await _dio.get('/parents/children/$childId/notifications');
        final data = unwrapBody(res.data);
        final list = data is List ? data : (data['notifications'] ?? data['data'] ?? []);
        return (list as List).map((e) => ChildNotification(
              id: e['_id'] ?? e['id'] ?? '',
              text: e['text'] ?? e['message'] ?? '',
              type: e['type'] ?? '',
              timestamp: e['timestamp'] != null
                  ? DateTime.tryParse(e['timestamp']) ?? DateTime.now()
                  : DateTime.now(),
              read: e['read'] ?? e['isRead'] ?? false,
            )).toList();
      });

  Future<void> linkChild(String studentUsername) => _guard(() async {
        await _dio.post('/parents/link-child', data: {'studentUsername': studentUsername});
      });
}

class ChildNotification {
  final String id;
  final String text;
  final String type;
  final DateTime timestamp;
  final bool read;

  const ChildNotification({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    this.read = false,
  });
}
