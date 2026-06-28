import 'api_service.dart';

class AiExamService {
  static final AiExamService _instance = AiExamService._internal();
  factory AiExamService() => _instance;
  AiExamService._internal();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> generateAiExam({
    required String grade,
    required String subject,
    required String chapter,
    required String difficulty,
  }) async {
    final res = await _api.post('/ai-exams/generate', body: {
      'grade': grade,
      'subject': subject,
      'chapter': chapter,
      'difficulty': difficulty,
    });
    return res['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkAiExamLimit() async {
    final res = await _api.get('/ai-exams/check-limit');
    return res['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyAiExams() async {
    final res = await _api.get('/ai-exams/my');
    return res['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> submitAiExam(String examId, Map<String, dynamic> answers) async {
    final res = await _api.post('/ai-exams/submit/$examId', body: {'answers': answers});
    return res['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAiExamReview(String examId) async {
    final res = await _api.get('/ai-exams/review/$examId');
    return res['data'] as Map<String, dynamic>;
  }
}
