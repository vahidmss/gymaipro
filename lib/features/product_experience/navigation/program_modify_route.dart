import 'package:flutter/material.dart';
import 'package:gymaipro/features/product_experience/presentation/screens/program_modify_screen.dart';

class ProgramModifyRoute {
  const ProgramModifyRoute._();

  static const String routeName = '/program-modify';

  static Route<bool> build(RouteSettings settings) {
    final args = settings.arguments;
    String? initialRequest;
    String? sessionDay;
    int? catalogExerciseId;
    if (args is ProgramModifyRouteArgs) {
      initialRequest = args.initialRequest;
      sessionDay = args.sessionDay;
      catalogExerciseId = args.catalogExerciseId;
    } else if (args is Map) {
      initialRequest = args['initialRequest']?.toString();
      sessionDay = args['sessionDay']?.toString();
      catalogExerciseId = int.tryParse(args['catalogExerciseId']?.toString() ?? '');
    }

    return MaterialPageRoute<bool>(
      settings: const RouteSettings(name: routeName),
      builder: (_) => ProgramModifyScreen(
        initialRequest: initialRequest,
        sessionDay: sessionDay,
        catalogExerciseId: catalogExerciseId,
      ),
    );
  }
}

class ProgramModifyRouteArgs {
  const ProgramModifyRouteArgs({
    this.initialRequest,
    this.sessionDay,
    this.catalogExerciseId,
  });

  final String? initialRequest;
  final String? sessionDay;
  final int? catalogExerciseId;
}
