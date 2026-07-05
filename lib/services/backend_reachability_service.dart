import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:http/http.dart' as http;

/// Checks if the app backend is reachable from current network.
///
/// This is intentionally independent from Firebase and SDK-specific clients,
/// so startup decisions are based on your own infrastructure availability.
class BackendReachabilityService {
  BackendReachabilityService._();

  static const Duration _defaultTimeout = Duration(seconds: 8);

  static Future<bool> isBackendReachable({
    Duration timeout = _defaultTimeout,
  }) async {
    final endpoint = AppConfig.backendHealthCheckUrl;
    if (endpoint.isEmpty) {
      if (kDebugMode) {
        debugPrint('Backend health check URL is empty');
      }
      return false;
    }

    final headers = <String, String>{};
    final anonKey = AppConfig.supabaseAnonKey;
    if (anonKey.isNotEmpty) {
      headers['apikey'] = anonKey;
      headers['Authorization'] = 'Bearer $anonKey';
    }

    try {
      final uri = Uri.parse(endpoint);
      final response = await http.get(uri, headers: headers).timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 500) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Backend reachability check failed: $e');
      }
    }

    // Cold start / DNS warmup may fail health while REST is already usable.
    return _probeSupabaseRest(timeout: timeout, headers: headers);
  }

  static Future<bool> _probeSupabaseRest({
    required Duration timeout,
    required Map<String, String> headers,
  }) async {
    final base = AppConfig.supabaseUrl.replaceFirst(RegExp(r'/$'), '');
    if (base.isEmpty) return false;

    try {
      final uri = Uri.parse('$base/rest/v1/');
      final response = await http.get(uri, headers: headers).timeout(timeout);
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Backend REST probe failed: $e');
      }
      return false;
    }
  }
}
