import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qemma/features/ai_qemma_chat/presentation/views/widgets/build_chat_app_bar.dart';
import 'package:qemma/features/ai_qemma_chat/presentation/views/widgets/chat_view_body_bloc_consumer.dart';

import '../../data/repos/chat_repo_impl.dart';
import '../cubits/chat_cubit/chat_cubit.dart';

class AiQemmaChatView extends StatelessWidget {
  const AiQemmaChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatCubit(ChatRepoImpl(dio: Dio())),
      child: Scaffold(
        appBar: buildChatAppBar(),
        body: ChatViewBodyBlockConsumer(),
      ),
    );
  }
}
