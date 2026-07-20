import 'package:flutter/material.dart';
import 'package:gymaipro/features/coach_chat/navigation/coach_chat_route.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_navigation.dart';
import 'package:gymaipro/features/product_experience/navigation/recovery_navigation.dart';
import 'package:gymaipro/features/product_experience/navigation/workout_program_request_navigation.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

/// Opens coach chat, optionally with a pre-filled user prompt.
class CoachChatNavigation {
  const CoachChatNavigation._();

  static Future<void> open(
    BuildContext context, {
    String? initialPrompt,
    String? quickActionId,
    String? sessionDay,
    int? catalogExerciseId,
  }) async {
    if (quickActionId == 'build_program') {
      await WorkoutProgramRequestNavigation.open<void>(context);
      return;
    }

    if (quickActionId == 'nutrition_program' ||
        quickActionId == 'meal_plan') {
      await Navigator.of(context).pushNamed('/program-type-selection');
      return;
    }

    if (ProgramModifyNavigation.isModifyAction(quickActionId)) {
      await ProgramModifyNavigation.open(
        context,
        initialRequest: initialPrompt,
        quickActionId: quickActionId,
        sessionDay: sessionDay,
        catalogExerciseId: catalogExerciseId,
      );
      return;
    }

    if (RecoveryNavigation.isRecoveryAction(quickActionId)) {
      await RecoveryNavigation.open(context);
      return;
    }

    final prompt = initialPrompt ??
        (quickActionId != null
            ? ProductExperienceFormatter.promptForQuickAction(quickActionId)
            : null);
    await Navigator.of(context).pushNamed(
      CoachChatRoute.routeName,
      arguments: prompt == null || prompt.isEmpty
          ? null
          : CoachChatRouteArgs(initialPrompt: prompt),
    );
  }
}
