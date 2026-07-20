import 'package:flutter/material.dart';
import 'package:gymaipro/features/product_experience/navigation/form_guidance_route.dart';

/// Opens the local-first form guidance screen.
class FormGuidanceNavigation {
  const FormGuidanceNavigation._();

  static bool isFormAction(String? actionId) {
    return switch (actionId) {
      'form' || 'ask_form' || 'form_tip' || 'ask_form_tip' => true,
      _ => false,
    };
  }

  static Future<void> open(
    BuildContext context, {
    String? sessionDay,
    int? catalogExerciseId,
  }) {
    return Navigator.of(context).push(
      FormGuidanceRoute.build(
        RouteSettings(
          name: FormGuidanceRoute.routeName,
          arguments: FormGuidanceRouteArgs(
            sessionDay: sessionDay,
            catalogExerciseId: catalogExerciseId,
          ),
        ),
      ),
    );
  }
}
