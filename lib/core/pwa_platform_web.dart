import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

bool get isStandalone {
  try {
    final displayMode = web.window.matchMedia('(display-mode: standalone)');
    if (displayMode.matches) return true;
  } catch (_) {}

  try {
    // Legacy iOS Home Screen flag (WebKit `navigator.standalone`).
    final value = web.window.navigator.getProperty('standalone'.toJS);
    if (value != null && value.isA<JSBoolean>()) {
      return (value as JSBoolean).toDart;
    }
  } catch (_) {}

  return false;
}

bool get isIosDevice {
  try {
    final ua = web.window.navigator.userAgent.toLowerCase();
    final isAppleMobile = ua.contains('iphone') ||
        ua.contains('ipad') ||
        ua.contains('ipod');
    // iPadOS 13+ may report as Mac with touch.
    final isIpadOs =
        ua.contains('macintosh') && web.window.navigator.maxTouchPoints > 1;
    return isAppleMobile || isIpadOs;
  } catch (_) {
    return false;
  }
}

bool get shouldOfferIosHomeScreenInstall => isIosDevice && !isStandalone;
