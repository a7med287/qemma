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
}
