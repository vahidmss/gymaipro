import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// دیباگر مخصوص برای بررسی مشکل GlobalKey
class GlobalKeyDebugger {
  factory GlobalKeyDebugger() => _instance;
  GlobalKeyDebugger._internal();
  static final GlobalKeyDebugger _instance = GlobalKeyDebugger._internal();

  static int _navigationAttempts = 0;
  static int _chatUnreadNotifierCalls = 0;
  static int _notificationHandlers = 0;
  static DateTime? _lastNavigationTime;
  static DateTime? _lastChatUnreadTime;
  static DateTime? _lastNotificationTime;

  /// لاگ navigation attempts
  static void logNavigationAttempt(String source) {
    _navigationAttempts++;
    _lastNavigationTime = DateTime.now();
    debugPrint(
      '=== GLOBAL KEY DEBUG: Navigation attempt #$_navigationAttempts from $source at $_lastNavigationTime ===',
    );
  }

  /// لاگ ChatUnreadNotifier calls
  static void logChatUnreadNotifierCall(String source) {
    _chatUnreadNotifierCalls++;
    _lastChatUnreadTime = DateTime.now();
    debugPrint(
      '=== GLOBAL KEY DEBUG: ChatUnreadNotifier call #$_chatUnreadNotifierCalls from $source at $_lastChatUnreadTime ===',
    );
  }

  /// لاگ notification handlers
  static void logNotificationHandler(String source) {
    _notificationHandlers++;
    _lastNotificationTime = DateTime.now();
    debugPrint(
      '=== GLOBAL KEY DEBUG: Notification handler #$_notificationHandlers from $source at $_lastNotificationTime ===',
    );
  }

  /// چک کردن آیا مشکل GlobalKey وجود دارد
  static bool hasGlobalKeyIssue() {
    final now = DateTime.now();

    // چک کردن navigation attempts در 10 ثانیه گذشته (افزایش زمان)
    if (_lastNavigationTime != null &&
        now.difference(_lastNavigationTime!).inSeconds < 10 &&
        _navigationAttempts > 15) {
      // افزایش threshold
      debugPrint(
        '=== GLOBAL KEY DEBUG: ⚠️ Too many navigation attempts detected! ===',
      );
      return true;
    }

    // چک کردن ChatUnreadNotifier calls در 10 ثانیه گذشته
    if (_lastChatUnreadTime != null &&
        now.difference(_lastChatUnreadTime!).inSeconds < 10 &&
        _chatUnreadNotifierCalls > 30) {
      // افزایش threshold
      debugPrint(
        '=== GLOBAL KEY DEBUG: ⚠️ Too many ChatUnreadNotifier calls detected! ===',
      );
      return true;
    }

    // چک کردن notification handlers در 10 ثانیه گذشته
    if (_lastNotificationTime != null &&
        now.difference(_lastNotificationTime!).inSeconds < 10 &&
        _notificationHandlers > 8) {
      // افزایش threshold
      debugPrint(
        '=== GLOBAL KEY DEBUG: ⚠️ Too many notification handlers detected! ===',
      );
      return true;
    }

    return false;
  }

  /// چک کردن وضعیت GlobalKey
  static bool isGlobalKeyReady() {
    try {
      // اینجا باید MyApp.navigatorKey را چک کنی
      // برای حالا true برمی‌گردانیم
      return true;
    } catch (e) {
      debugPrint(
        '=== GLOBAL KEY DEBUG: Error checking GlobalKey status: $e ===',
      );
      return false;
    }
  }

  /// ریست کردن counters
  static void resetCounters() {
    _navigationAttempts = 0;
    _chatUnreadNotifierCalls = 0;
    _notificationHandlers = 0;
    _lastNavigationTime = null;
    _lastChatUnreadTime = null;
    _lastNotificationTime = null;
    debugPrint('=== GLOBAL KEY DEBUG: Counters reset ===');
  }

  /// نمایش وضعیت فعلی
  static void printStatus() {
    debugPrint('=== GLOBAL KEY DEBUG STATUS ===');
    debugPrint('Navigation attempts: $_navigationAttempts');
    debugPrint('ChatUnreadNotifier calls: $_chatUnreadNotifierCalls');
    debugPrint('Notification handlers: $_notificationHandlers');
    debugPrint('Last navigation: $_lastNavigationTime');
    debugPrint('Last ChatUnread: $_lastChatUnreadTime');
    debugPrint('Last notification: $_lastNotificationTime');
    debugPrint('Has GlobalKey issue: ${hasGlobalKeyIssue()}');
    debugPrint('================================');
  }
}
