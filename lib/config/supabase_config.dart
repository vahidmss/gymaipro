import 'package:gymaipro/config/app_config.dart';

/// Deprecated: Use AppConfig instead
/// This class is kept for backward compatibility
@Deprecated('Use AppConfig.supabaseUrl and AppConfig.supabaseAnonKey instead')
class SupabaseConfig {
  static String get supabaseUrl => AppConfig.supabaseUrl;
  static String get supabaseAnonKey => AppConfig.supabaseAnonKey;
}
