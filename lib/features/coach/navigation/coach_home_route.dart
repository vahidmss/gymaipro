import 'package:flutter/material.dart';
import 'package:gymaipro/features/coach/presentation/screens/coach_home_screen.dart';

class CoachHomeRoute {
  const CoachHomeRoute._();

  static const String routeName = '/coach';

  static Route<dynamic> build(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: routeName),
      builder: (_) => const CoachHomeScreen(),
    );
  }
}
