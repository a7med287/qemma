import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/chat_message_model.dart';
import '../../cubits/chat_cubit/chat_cubit.dart';
import '../../cubits/chat_cubit/chat_state.dart';
import 'chat_view_body.dart';

class ChatViewBodyBlockConsumer extends StatefulWidget {
  const ChatViewBodyBlockConsumer({super.key});

  @override
  State<ChatViewBodyBlockConsumer> createState() =>
      _ChatViewBodyBlockConsumerState();
}

class _ChatViewBodyBlockConsumerState extends State<ChatViewBodyBlockConsumer> {
  final controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state is ChatSuccess || state is ChatLoading) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        final messages = state is ChatSuccess
            ? state.messages
            : state is ChatLoading
            ? state.messages
            : <ChatMessageModel>[];

        final isLoading = state is ChatLoading;

        return ChatViewBody(
          controller: controller,
          messages: messages,
          isLoading: isLoading,
        );
      },
    );
  }
}

