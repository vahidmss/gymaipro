import 'package:flutter/material.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_route.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

/// Opens the unified program-modify flow.
class ProgramModifyNavigation {
  const ProgramModifyNavigation._();

  static bool isModifyAction(String? actionId) {
    return switch (actionId) {
      'modify' ||
      'modify_program' ||
      'modify_workout' ||
      'replace' ||
      'replace_exercise' => true,
      _ => false,
    };
  }

  static Future<bool?> open(
    BuildContext context, {
    String? initialRequest,
    String? quickActionId,
    String? sessionDay,
    int? catalogExerciseId,
  }) {
    final prompt = initialRequest ??
        (quickActionId != null
            ? ProductExperienceFormatter.promptForQuickAction(quickActionId)
            : null);
    // Push typed route directly — avoids RouteService MaterialPageRoute<dynamic>
    // cast errors with pushNamed<bool>.
    return Navigator.of(context).push<bool>(
      ProgramModifyRoute.build(
        RouteSettings(
          name: ProgramModifyRoute.routeName,
          arguments: ProgramModifyRouteArgs(
            initialRequest: prompt,
            sessionDay: sessionDay,
            catalogExerciseId: catalogExerciseId,
          ),
        ),
      ),
    );
  }
}
