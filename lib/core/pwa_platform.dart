import 'package:gymaipro/core/pwa_platform_stub.dart'
    if (dart.library.html) 'package:gymaipro/core/pwa_platform_web.dart'
    as impl;

/// Detects iOS Safari vs installed Home Screen PWA (web only).
abstract final class PwaPlatform {
  static bool get isStandalone => impl.isStandalone;

  static bool get isIosDevice => impl.isIosDevice;

  /// Safari (or other iOS browser) tab — not yet added to Home Screen.
  static bool get shouldOfferIosHomeScreenInstall =>
      impl.shouldOfferIosHomeScreenInstall;
}
