import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';

class AiAssistantService {
  AiAssistantService(this._client);

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    List<Map<String, dynamic>> history = const [],
  }) async {
    try {
      final res = await _dio.post('/ai/chatbot/message', data: {
        'message': message,
        'history': history,
      });
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final msg = e.response?.data?['message'] ?? 'لقد استنفدت حد الرسائل المسموح به.';
        throw ServerFailure(msg);
      }
      throw ServerFailure('عذراً، حدث خطأ في الاتصال. حاول مرة أخرى.');
    }
  }

  Future<Map<String, dynamic>> checkUsage() async {
    try {
      final res = await _dio.get('/ai/chatbot/usage');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException {
      return {'allowed': true, 'remaining': 10, 'limit': 10, 'used': 0};
    }
  }
}
