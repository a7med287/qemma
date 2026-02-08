import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/repos/chat_repo.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this.repo) : super(ChatInitial());

  final ChatRepo repo;
  final List<ChatMessageModel> messages = [];

  void sendMessage(String text) async {
    final userMessage =
    ChatMessageModel(text: text, role: MessageRole.user);

    messages.add(userMessage);
    emit(ChatSuccess(List.from(messages)));

    try {
      emit(ChatLoading(List.from(messages)));

      final response = await repo.sendMessage(messages: messages);

      messages.add(
        ChatMessageModel(
          text: response,
          role: MessageRole.model,
        ),
      );

      emit(ChatSuccess(List.from(messages)));
    } catch (e) {
      messages.add(
        ChatMessageModel(
          text: 'Something went wrong',
          role: MessageRole.model,
          isError: true,
        ),
      );

      emit(ChatFailure(e.toString()));
      emit(ChatSuccess(List.from(messages)));
    }
  }
}