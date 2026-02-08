import '../models/chat_message_model.dart';

abstract class ChatRepo {
  Future<String> sendMessage({required List<ChatMessageModel> messages});
}
