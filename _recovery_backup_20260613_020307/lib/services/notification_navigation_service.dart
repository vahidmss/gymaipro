import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gymaipro/debug/global_key_debugger.dart';
import 'package:gymaipro/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationNavigationService {
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();

  // Pending navigation data - استفاده از SharedPreferences برای ذخیره‌سازی دائمی
  static Map<String, dynamic>? _pendingNavigation;

  /// مدیریت navigation بر اساس نوع نوتیفیکیشن
  static void handleNotificationNavigation(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String?;
      GlobalKeyDebugger.logNotificationHandler('handleNotificationNavigation');
      debugPrint('=== NOTIFICATION NAVIGATION: Handling type: $type ===');

      if (type == 'chat_message') {
        _navigateToChat(data);
      } else {
        debugPrint('Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('Error handling notification navigation: $e');
    }
  }

  /// Navigation به صفحه چت
  static void _navigateToChat(Map<String, dynamic> data) {
    try {
      final peerId = data['peer_id']?.toString();
      final peerName = data['peer_name']?.toString();
      final conversationId = data['conversation_id']?.toString();

      if (peerId == null || peerId.isEmpty) {
        debugPrint('Error: peer_id is null or empty in chat notification data');
        debugPrint('Available data keys: ${data.keys.toList()}');
        return;
      }

      debugPrint(
        '=== NAVIGATION: Preparing chat navigation for peer: $peerId ===',
      );
      debugPrint('=== NAVIGATION: Peer name: $peerName ===');
      debugPrint('=== NAVIGATION: Conversation ID: $conversationId ===');

      // ذخیره navigation برای اجرای بعدی در SharedPreferences
      final navigationData = {
        'route': '/chat',
        'arguments': {
          'otherUserId': peerId,
          'otherUserName': peerName ?? 'کاربر',
          if (conversationId != null) 'conversationId': conversationId,
        },
      };

      _pendingNavigation = navigationData;
      _savePendingNavigation(navigationData);

      debugPrint('=== NAVIGATION: Stored navigation for later execution ===');
    } catch (e) {
      debugPrint('Error preparing chat navigation: $e');
    }
  }

  /// بررسی و اجرای pending navigation
  static Future<void> checkPendingNavigation(BuildContext context) async {
    // بارگذاری pending navigation از SharedPreferences
    await _loadPendingNavigation();

    debugPrint(
      '=== NAVIGATION: Checking pending navigation, data: $_pendingNavigation ===',
    );

    if (_pendingNavigation != null) {
      GlobalKeyDebugger.logNavigationAttempt('checkPendingNavigation');
      debugPrint('=== NAVIGATION: Executing pending navigation ===');

      final route = _pendingNavigation!['route'] as String;
      final arguments =
          _pendingNavigation!['arguments'] as Map<String, dynamic>;

      // Clear pending navigation first
      _pendingNavigation = null;
      _clearPendingNavigation();

      // بررسی آماده بودن GlobalKey قبل از تلاش navigation
      if (MyApp.navigatorKey.currentState != null) {
        debugPrint(
          '=== NAVIGATION: GlobalKey is ready, proceeding with navigation ===',
        );
        _attemptNavigation(route, arguments, context, 0);
      } else {
        debugPrint('=== NAVIGATION: GlobalKey not ready, using fallback ===');
        _fallbackNavigation(route, arguments, context);
      }
    } else {
      debugPrint('=== NAVIGATION: No pending navigation found ===');
    }
  }

  /// Fallback navigation mechanism
  static void _fallbackNavigation(
    String route,
    Map<String, dynamic> arguments,
    BuildContext context,
  ) {
    try {
      debugPrint('=== NAVIGATION: Using fallback navigation ===');

      // استفاده از context به جای GlobalKey
      if (context.mounted) {
        Navigator.of(context).pushNamed(route, arguments: arguments);
        debugPrint('=== NAVIGATION: Fallback navigation successful ===');
      } else {
        debugPrint('=== NAVIGATION: Context not mounted, saving for later ===');
        _savePendingNavigation({'route': route, 'arguments': arguments});
      }
    } catch (e) {
      debugPrint('=== NAVIGATION: Fallback navigation failed: $e ===');
      // ذخیره برای تلاش بعدی
      _savePendingNavigation({'route': route, 'arguments': arguments});
    }
  }

  /// تلاش مکرر برای navigation
  static void _attemptNavigation(
    String route,
    Map<String, dynamic> arguments,
    BuildContext context,
    int attempt,
  ) {
    const maxAttempts = 15; // افزایش تعداد تلاش‌ها
    const delayMs = 300; // کاهش تأخیر

    if (attempt >= maxAttempts) {
      debugPrint('=== NAVIGATION: Max attempts reached, giving up ===');
      // در صورت عدم موفقیت، navigation را در SharedPreferences ذخیره کن
      _savePendingNavigation({'route': route, 'arguments': arguments});
      return;
    }

    Future.delayed(Duration(milliseconds: delayMs * (attempt + 1)), () {
      try {
        // بررسی آماده بودن GlobalKey
        final navigatorState = MyApp.navigatorKey.currentState;
        if (navigatorState != null) {
          // بررسی اینکه آیا Navigator در حال حاضر در حال navigation است
          if (navigatorState.mounted) {
            navigatorState.pushNamed(route, arguments: arguments);
            debugPrint(
              '=== NAVIGATION: Successfully executed pending navigation using GlobalKey (attempt ${attempt + 1}) ===',
            );
            return;
          } else {
            debugPrint(
              '=== NAVIGATION: NavigatorKey mounted but not ready, attempt ${attempt + 1}/$maxAttempts ===',
            );
            _attemptNavigation(route, arguments, context, attempt + 1);
          }
        } else {
          debugPrint(
            '=== NAVIGATION: NavigatorKey not ready, attempt ${attempt + 1}/$maxAttempts ===',
          );
          // تلاش مجدد
          _attemptNavigation(route, arguments, context, attempt + 1);
        }
      } catch (e) {
        debugPrint(
          '=== NAVIGATION: Error executing navigation (attempt ${attempt + 1}): $e ===',
        );

        // اگر خطا مربوط به GlobalKey است، تلاش مجدد کن
        if (e.toString().contains('GlobalKey') ||
            e.toString().contains('Navigator') ||
            e.toString().contains('context')) {
          _attemptNavigation(route, arguments, context, attempt + 1);
        } else {
          // برای خطاهای دیگر، navigation را ذخیره کن
          debugPrint(
            '=== NAVIGATION: Non-GlobalKey error, saving for later ===',
          );
          _savePendingNavigation({'route': route, 'arguments': arguments});
        }
      }
    });
  }

  /// ذخیره pending navigation در SharedPreferences
  static Future<void> _savePendingNavigation(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data);
      await prefs.setString('pending_navigation', jsonString);
      debugPrint('=== NAVIGATION: Saved to SharedPreferences: $jsonString ===');
    } catch (e) {
      debugPrint('Error saving pending navigation: $e');
    }
  }

  /// بارگذاری pending navigation از SharedPreferences
  static Future<void> _loadPendingNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('pending_navigation');
      if (jsonString != null) {
        _pendingNavigation = json.decode(jsonString) as Map<String, dynamic>;
        debugPrint(
          '=== NAVIGATION: Loaded from SharedPreferences: $jsonString ===',
        );
      } else {
        debugPrint('=== NAVIGATION: No data found in SharedPreferences ===');
      }
    } catch (e) {
      debugPrint('Error loading pending navigation: $e');
      _pendingNavigation = null;
    }
  }

  /// پاک کردن pending navigation از SharedPreferences
  static Future<void> _clearPendingNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_navigation');
      debugPrint('=== NAVIGATION: Cleared from SharedPreferences ===');
    } catch (e) {
      debugPrint('Error clearing pending navigation: $e');
    }
  }
}
