import 'package:flutter/material.dart';
import 'package:gymaipro/features/product_experience/presentation/screens/recovery_screen.dart';

class RecoveryRoute {
  const RecoveryRoute._();

  static const String routeName = '/recovery';

  static Route<void> build(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: routeName),
      builder: (_) => const RecoveryScreen(),
    );
  }
}
