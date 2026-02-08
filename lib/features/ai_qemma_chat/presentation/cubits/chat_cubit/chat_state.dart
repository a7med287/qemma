import '../../../data/models/chat_message_model.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {
  final List<ChatMessageModel> messages;

  ChatLoading(this.messages);
}

class ChatSuccess extends ChatState {
  final List<ChatMessageModel> messages;

  ChatSuccess(this.messages);
}

class ChatFailure extends ChatState {
  final String error;

  ChatFailure(this.error);
}