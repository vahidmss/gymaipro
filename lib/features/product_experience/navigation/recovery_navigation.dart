import 'package:flutter/material.dart';
import 'package:gymaipro/features/product_experience/navigation/recovery_route.dart';

/// Opens the dedicated recovery readiness screen.
class RecoveryNavigation {
  const RecoveryNavigation._();

  static bool isRecoveryAction(String? actionId) {
    return actionId == 'recovery';
  }

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      RecoveryRoute.build(
        const RouteSettings(name: RecoveryRoute.routeName),
      ),
    );
  }
}
