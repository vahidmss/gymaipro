import 'package:flutter/material.dart';
import 'package:gymaipro/features/live_workout/presentation/screens/live_workout_screen.dart';

class LiveWorkoutRoute {
  const LiveWorkoutRoute._();

  static const String routeName = '/live-workout';

  static Route<dynamic> build(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: routeName),
      builder: (_) => const LiveWorkoutScreen(),
    );
  }
}
