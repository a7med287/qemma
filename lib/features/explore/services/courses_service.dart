import '../models/course.dart';
import 'api_service.dart';

class CoursesService {
  final ApiService _api = ApiService();

  Future<List<Course>> getPublishedCourses() async {
    final res = await _api.get('/courses/public');
    final data = res['data'];
    final coursesList = data['courses'] as List<dynamic>? ?? [];
    return coursesList.map((c) => Course.fromJson(c)).toList();
  }

  Future<Map<String, dynamic>> getCourse(String courseId) async {
    final res = await _api.get('/courses/public/$courseId');
    return res['data'];
  }

  Future<Map<String, dynamic>> getTeacherProfile(String teacherId) async {
    try {
      final res = await _api.get('/courses/teacher/$teacherId');
      return res['data'];
    } catch (_) {
      final res = await _api.get('/courses/teacher-by-user/$teacherId');
      return res['data'];
    }
  }
}
