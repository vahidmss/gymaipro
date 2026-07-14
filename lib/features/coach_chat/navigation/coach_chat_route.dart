import 'package:flutter/material.dart';
import 'package:gymaipro/features/coach_chat/presentation/screens/coach_chat_screen.dart';

class CoachChatRouteArgs {
  const CoachChatRouteArgs({required this.initialPrompt});

  final String initialPrompt;
}

class CoachChatRoute {
  const CoachChatRoute._();

  static const String routeName = '/coach-chat';

  static Route<dynamic> build(RouteSettings settings) {
    final args = settings.arguments;
    final String? initialPrompt = switch (args) {
      CoachChatRouteArgs(:final initialPrompt) => initialPrompt,
      final String prompt => prompt,
      _ => null,
    };

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => CoachChatScreen(initialPrompt: initialPrompt),
    );
  }
}
