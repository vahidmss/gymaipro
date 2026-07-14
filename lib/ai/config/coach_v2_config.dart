import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';

/// Feature flags for GymAI Coach v2 runtime integration.
///
/// Enabled by default for product builds; set `COACH_V2_ENABLED=false` to
/// fall back to preview/dry-run paths in facades.
class CoachV2Config {
  const CoachV2Config._();

  @visibleForTesting
  static bool? debugOverride;

  /// Enables the Coach v2 chat pipeline when true.
  static bool get coachV2Enabled {
    if (debugOverride != null) {
      return debugOverride!;
    }
    const env = String.fromEnvironment('COACH_V2_ENABLED');
    if (env.isNotEmpty) {
      return _isTruthy(env);
    }
    final dotenv = AppConfig.dotenvValue('COACH_V2_ENABLED');
    if (dotenv != null && dotenv.isNotEmpty) {
      return _isTruthy(dotenv);
    }
    return true;
  }

  static bool _isTruthy(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
  }
}
