import 'package:flutter/material.dart';
import 'package:gymaipro/features/coach_chat/navigation/coach_chat_route.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

/// Opens coach chat, optionally with a pre-filled user prompt.
class CoachChatNavigation {
  const CoachChatNavigation._();

  static Future<void> open(
    BuildContext context, {
    String? initialPrompt,
    String? quickActionId,
  }) {
    final prompt = initialPrompt ??
        (quickActionId != null
            ? ProductExperienceFormatter.promptForQuickAction(quickActionId)
            : null);
    return Navigator.of(context).pushNamed(
      CoachChatRoute.routeName,
      arguments: prompt == null || prompt.isEmpty
          ? null
          : CoachChatRouteArgs(initialPrompt: prompt),
    );
  }
}
