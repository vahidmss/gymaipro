import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CORS-safe URLs for Flutter Web (images, WordPress REST, CDN files).
abstract final class WebProxyUrl {
  static bool get enabled => kIsWeb;

  static const _allowedHosts = {
    'dl.gymaipro.ir',
    'gymaipro.ir',
    'www.gymaipro.ir',
    'api.gymaipro.ir',
  };

  static bool needsProxy(String url) {
    if (!enabled || url.trim().isEmpty) return false;
    try {
      final host = Uri.parse(url).host.toLowerCase();
      return _allowedHosts.contains(host);
    } catch (_) {
      return false;
    }
  }

  static String resolve(String url) {
    if (!needsProxy(url)) return url;
    final base = AppConfig.supabaseUrl.replaceFirst(RegExp(r'/$'), '');
    final anon = AppConfig.supabaseAnonKey;
    return Uri.parse('$base/functions/v1/music-proxy')
        .replace(
          queryParameters: {
            'url': url,
            'apikey': anon,
          },
        )
        .toString();
  }

  static Map<String, String> fetchHeaders() {
    final headers = <String, String>{
      'apikey': AppConfig.supabaseAnonKey,
    };
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    return headers;
  }

  static Uri proxyUri(Uri original) => Uri.parse(resolve(original.toString()));
}
