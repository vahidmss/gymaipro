import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens external URLs reliably across Android/iOS (incl. Android 11+ visibility).
class ExternalUrlLauncher {
  ExternalUrlLauncher._();

  static bool _paymentBrowserOpen = false;

  /// درگاه پرداخت — وب: همان تب (ضروری برای برگشت PWA روی iOS).
  /// نیتیو: Custom Tab که با deeplink بسته می‌شود.
  static Future<bool> openPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (kDebugMode) {
      debugPrint('ExternalUrlLauncher: payment URL $uri');
    }

    // Web / iOS PWA: same-tab navigation so Zibal → WP → /app/?payment=…
    // returns into the Flutter SPA instead of a dead Safari tab.
    if (kIsWeb) {
      try {
        final launched = await launchUrl(
          uri,
          webOnlyWindowName: '_self',
        );
        if (launched) {
          _paymentBrowserOpen = true;
          if (kDebugMode) {
            debugPrint('ExternalUrlLauncher: web same-tab payment navigate');
          }
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('ExternalUrlLauncher: web same-tab failed: $e');
        }
      }
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (launched) {
        _paymentBrowserOpen = true;
        if (kDebugMode) {
          debugPrint('ExternalUrlLauncher: opened in-app browser (Custom Tab)');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ExternalUrlLauncher: inAppBrowserView failed: $e');
      }
    }

    final fallback = await open(
      uri,
    );
    if (fallback) {
      _paymentBrowserOpen = true;
    }
    return fallback;
  }

  static Future<bool> open(
    Uri uri, {
    LaunchMode preferredMode = LaunchMode.externalApplication,
  }) async {
    if (kDebugMode) {
      debugPrint('ExternalUrlLauncher: opening $uri');
    }

    final modes = <LaunchMode>{
      preferredMode,
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
    };

    for (final mode in modes) {
      try {
        final launched = await launchUrl(uri, mode: mode);
        if (launched) {
          if (kDebugMode) {
            debugPrint('ExternalUrlLauncher: opened with $mode');
          }
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('ExternalUrlLauncher: $mode failed: $e');
        }
      }
    }

    return false;
  }

  static Future<bool> openString(
    String url, {
    LaunchMode preferredMode = LaunchMode.externalApplication,
  }) {
    return open(Uri.parse(url), preferredMode: preferredMode);
  }

  /// بعد از بازگشت deeplink — Custom Tab را ببند تا در recents نماند.
  static Future<void> closePaymentBrowserIfOpen({bool force = false}) async {
    if (!force && !_paymentBrowserOpen) return;
    try {
      await closeInAppWebView();
      if (kDebugMode) {
        debugPrint('ExternalUrlLauncher: closed in-app payment browser');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ExternalUrlLauncher: closeInAppWebView: $e');
      }
    } finally {
      _paymentBrowserOpen = false;
    }
  }

  static Future<void> copyToClipboard(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }
}
