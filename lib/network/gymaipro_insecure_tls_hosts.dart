import 'package:gymaipro/config/app_config.dart';

/// دامنه‌هایی که تا تمدید SSL روی سرور، اتصال با گواهی نامعتبر هم قبول می‌شود (فقط همان میزبان‌ها).
class GymaiproInsecureTlsHosts {
  GymaiproInsecureTlsHosts._();

  static bool allowInsecureConnectionTo(String host) {
    final h = host.toLowerCase();
    if (h == 'gymaipro.ir' || h.endsWith('.gymaipro.ir')) {
      return true;
    }
    final origin = Uri.tryParse(AppConfig.wordpressApiOrigin);
    final configured = origin?.host.toLowerCase();
    if (configured != null && configured.isNotEmpty) {
      if (h == configured || h.endsWith('.$configured')) {
        return true;
      }
    }
    return false;
  }

  static bool urlLooksLikeGymaiproHttps(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    if (uri.scheme != 'https') return false;
    return allowInsecureConnectionTo(uri.host);
  }
}
