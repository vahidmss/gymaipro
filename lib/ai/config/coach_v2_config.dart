import 'package:gymaipro/config/app_config.dart';

/// Feature flags for GymAI Coach v2 runtime integration.
///
/// Default is disabled so existing chat behavior remains unchanged.
class CoachV2Config {
  const CoachV2Config._();

  /// Enables the Coach v2 chat pipeline when true.
  static bool get coachV2Enabled {
    const env = String.fromEnvironment('COACH_V2_ENABLED');
    if (env.isNotEmpty) {
      return _isTruthy(env);
    }
    final dotenv = AppConfig.dotenvValue('COACH_V2_ENABLED');
    if (dotenv != null && dotenv.isNotEmpty) {
      return _isTruthy(dotenv);
    }
    return false;
  }

  static bool _isTruthy(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
  }
}
