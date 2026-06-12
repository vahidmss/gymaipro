import 'package:shared_preferences/shared_preferences.dart';

/// جلوگیری از پردازش دوباره deeplink پرداخت (مثلاً بعد از باز کردن مجدد اپ).
class PaymentDeeplinkGuard {
  PaymentDeeplinkGuard._();

  static const _key = 'handled_payment_deeplinks_v1';
  static const _maxEntries = 30;

  static Future<bool> shouldHandle(Uri uri) async {
    if (uri.scheme != 'gymaipro') return true;

    final fingerprint = _fingerprint(uri);
    final prefs = await SharedPreferences.getInstance();
    final handled = prefs.getStringList(_key) ?? <String>[];

    if (handled.contains(fingerprint)) {
      return false;
    }

    final updated = [...handled, fingerprint];
    if (updated.length > _maxEntries) {
      updated.removeRange(0, updated.length - _maxEntries);
    }
    await prefs.setStringList(_key, updated);
    return true;
  }

  /// کلید پایدار برای topup: host + path + status (بدون پارامترهای اضافی)
  static String _fingerprint(Uri uri) {
    if (uri.host == 'wallet' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'topup') {
      final status = uri.queryParameters['status'] ?? '';
      return 'wallet/topup?status=$status';
    }
    return uri.toString();
  }
}
