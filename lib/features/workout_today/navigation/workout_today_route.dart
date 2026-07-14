import 'package:flutter/material.dart';
import 'package:gymaipro/features/workout_today/presentation/screens/workout_today_screen.dart';

class WorkoutTodayRoute {
  const WorkoutTodayRoute._();

  static const String routeName = '/workout-today';

  static Route<dynamic> build(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: routeName),
      builder: (_) => const WorkoutTodayScreen(),
    );
  }
}
