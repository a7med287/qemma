import '../../../../constants.dart';
import '../models/chat_message_model.dart';
import 'package:dio/dio.dart';

import 'chat_repo.dart';

class ChatRepoImpl extends ChatRepo {
  final Dio dio;

  var url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:streamGenerateContent";
  var apiKey = kApiGeminiKey;

  ChatRepoImpl({required this.dio});

  @override
  Future<String> sendMessage({required List<ChatMessageModel> messages}) async {
    final response = await dio.post(
      url,
      data: {
        "contents": messages.map((m) {
          return {
            "role": m.role == MessageRole.user ? "user" : "model",
            "parts": [
              {"text": m.text},
            ],
          };
        }).toList(),
      },
      options: Options(
        headers: {"Content-Type": "application/json", "x-goog-api-key": apiKey},
      ),
    );

    return parseGeminiResponse(response.data);
  }

  String parseGeminiResponse(List<dynamic> data) {
    final buffer = StringBuffer();

    for (final chunk in data) {
      final parts = chunk['candidates']?[0]?['content']?['parts'];
      if (parts != null && parts.isNotEmpty) {
        buffer.write(parts[0]['text']);
      }
    }

    return buffer.toString();
  }
}
