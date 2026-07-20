import 'package:flutter/material.dart';
import 'package:gymaipro/features/product_experience/presentation/screens/form_guidance_screen.dart';

class FormGuidanceRoute {
  const FormGuidanceRoute._();

  static const String routeName = '/form-guidance';

  static Route<void> build(RouteSettings settings) {
    final args = settings.arguments;
    String? sessionDay;
    int? catalogExerciseId;
    if (args is FormGuidanceRouteArgs) {
      sessionDay = args.sessionDay;
      catalogExerciseId = args.catalogExerciseId;
    } else if (args is Map) {
      sessionDay = args['sessionDay']?.toString();
      catalogExerciseId =
          int.tryParse(args['catalogExerciseId']?.toString() ?? '');
    }

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: routeName),
      builder: (_) => FormGuidanceScreen(
        sessionDay: sessionDay,
        catalogExerciseId: catalogExerciseId,
      ),
    );
  }
}

class FormGuidanceRouteArgs {
  const FormGuidanceRouteArgs({
    this.sessionDay,
    this.catalogExerciseId,
  });

  final String? sessionDay;
  final int? catalogExerciseId;
}
