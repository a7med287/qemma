import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/chat_message_model.dart';
import '../../cubits/chat_cubit/chat_cubit.dart';
import 'chat_buble.dart';
import 'chat_response_buble.dart';
import 'custom_text_field.dart';
import 'loading_indicator.dart';

class ChatViewBody extends StatelessWidget {
  const ChatViewBody({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.controller,
  });

  final ScrollController controller;
  final List<ChatMessageModel> messages;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          controller: controller,
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 80,
          ),
          itemCount: messages.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (isLoading && index == messages.length) {
              return const LoadingIndicator();
            }

            final msg = messages[index];
            return msg.role == MessageRole.user
                ? ChatBubble(text: msg.text)
                : ChatResponseBubble(text: msg.text, isError: msg.isError);
          },
        ),
        Positioned(
          bottom: 15,
          right: 0,
          left: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CustomTextField(
              onSend: (text) {
                context.read<ChatCubit>().sendMessage(text);
              },
            ),
          ),
        ),
      ],
    );
  }
}
