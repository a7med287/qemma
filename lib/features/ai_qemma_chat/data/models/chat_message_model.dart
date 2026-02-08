enum MessageRole { user, model }

class ChatMessageModel {
  final String text;
  final MessageRole role;
  final bool isError;
  final bool isThinking;



  ChatMessageModel( {
    required this.text,
    required this.role,
    this.isError = false,
    this.isThinking = false,
  });


}
