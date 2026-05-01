import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:http/http.dart' as http;

/// Checks if the app backend is reachable from current network.
///
/// This is intentionally independent from Firebase and SDK-specific clients,
/// so startup decisions are based on your own infrastructure availability.
class BackendReachabilityService {
  BackendReachabilityService._();

  static Future<bool> isBackendReachable({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final endpoint = AppConfig.backendHealthCheckUrl;
    if (endpoint.isEmpty) {
      if (kDebugMode) {
        debugPrint('Backend health check URL is empty');
      }
      return false;
    }

    try {
      final uri = Uri.parse(endpoint);
      final response = await http.get(uri).timeout(timeout);
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Backend reachability check failed: $e');
      }
      return false;
    }
  }
}
