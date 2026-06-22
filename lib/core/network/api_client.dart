import 'package:dio/dio.dart';
import '../../constants.dart';
import '../services/shared_preferences_singleton.dart';

class ApiClient {
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = Prefs.getString(kAuthTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  late final Dio _dio;
  Dio get dio => _dio;

  Future<void> initToken() async {
    final token = Prefs.getString(kAuthTokenKey);
    if (token != null && token.isNotEmpty) {
      setToken(token);
    }
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
}

/// Unwrap `{ success, data }` or return raw body.
dynamic unwrapBody(dynamic body) {
  if (body is Map<String, dynamic>) {
    if (body.containsKey('data')) return body['data'];
    return body;
  }
  return body;
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => asMap(e)).toList();
}

String apiErrorMessage(DioException e, [String fallback = 'حدث خطأ في الاتصال بالخادم']) {
  final data = e.response?.data;
  if (data is Map && data['message'] != null) return data['message'].toString();
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError) {
    return 'تعذر الاتصال بالخادم. تأكد أن الباكند يعمل على $kApiBaseUrl';
  }
  return fallback;
}
