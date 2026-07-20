import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:http/http.dart' as http;

/// Checks if the app backend is reachable from current network.
class BackendReachabilityService {
  BackendReachabilityService._();

  static const Duration _defaultTimeout = Duration(seconds: 5);

  static Future<bool> isBackendReachable({
    Duration timeout = _defaultTimeout,
  }) async {
    final endpoint = AppConfig.backendHealthCheckUrl
        .replaceFirst(RegExp(r':443(?=/|$)'), '');
    if (endpoint.isEmpty) {
      if (kDebugMode) {
        debugPrint('Backend health check URL is empty');
      }
      return false;
    }

    final headers = <String, String>{
      'Accept': 'application/json',
    };
    final anonKey = AppConfig.supabaseAnonKey;
    if (anonKey.isNotEmpty) {
      headers['apikey'] = anonKey;
      headers['Authorization'] = 'Bearer $anonKey';
    }

    try {
      final response =
          await http.get(Uri.parse(endpoint), headers: headers).timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 500) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Backend reachability check failed: $e');
      }
    }

    return _probeSupabaseRest(timeout: timeout, headers: headers);
  }

  static Future<bool> _probeSupabaseRest({
    required Duration timeout,
    required Map<String, String> headers,
  }) async {
    final base = AppConfig.supabaseUrl
        .replaceFirst(RegExp(r':443(?=/|$)'), '')
        .replaceFirst(RegExp(r'/$'), '');
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
