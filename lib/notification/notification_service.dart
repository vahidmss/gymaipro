import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/notification_navigation_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  // IMPORTANT:
  // Do NOT touch FirebaseMessaging.instance in the constructor.
  // Firebase may not be initialized yet during early app startup (e.g., splash/bootstrap).
  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;
  Future<void>? _initializingFuture;
  bool _handlersConfigured = false;
  final Map<String, DateTime> _recentChatNotificationAttempts = {};
  final Map<String, DateTime> _recentIncomingNotificationKeys = {};
  DateTime? _lastChatNotificationTimeoutAt;

  // Callbacks for handling notifications
  void Function(Map<String, dynamic>)? onNotificationTapped;
  void Function(Map<String, dynamic>)? onNotificationReceived;

  int _safeNotificationId([int? preferred]) {
    const maxSigned32 = 2147483647;
    final raw = preferred ?? DateTime.now().millisecondsSinceEpoch;
    final normalized = raw % maxSigned32;
    return normalized <= 0 ? 1 : normalized;
  }

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializingFuture != null) {
      await _initializingFuture;
      return;
    }

    _initializingFuture = _initializeInternal();
    try {
      await _initializingFuture;
    } finally {
      _initializingFuture = null;
    }
  }

  Future<void> _initializeInternal() async {
    try {
      // Skip Firebase initialization for web
      if (kIsWeb) {
        debugPrint('⚠️ Skipping Firebase initialization for web platform');
        _isInitialized = true;
        return;
      }

      // Initialize Firebase (idempotent)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      debugPrint('✅ Firebase initialized successfully');

      // Safe to access messaging after Firebase init
      _firebaseMessaging = FirebaseMessaging.instance;

      // Initialize local notifications
      await _initializeLocalNotifications();
      debugPrint('✅ Local notifications initialized successfully');

      // Request permissions
      await _requestPermissions();
      debugPrint('✅ Permissions requested successfully');

      // Get FCM token (may fail on emulator: SERVICE_NOT_AVAILABLE)
      await _getFCMToken();
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        debugPrint('✅ FCM token retrieved successfully');
      } else {
        debugPrint(
          'ℹ️ FCM token unavailable (common on emulator without Play services)',
        );
      }

      // Setup Firebase message handlers
      await _setupFirebaseHandlers();
      debugPrint('✅ Firebase message handlers setup successfully');

      // Handle initial message (app opened from notification)
      await _handleInitialMessage();
      debugPrint('✅ Initial message handling completed');

      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
      debugPrint('❌ Error details: $e');
      // Continue with local notifications even if Firebase fails
      try {
        await _initializeLocalNotifications();
        await _requestPermissions();
        debugPrint('✅ Local notifications initialized as fallback');
      } catch (localError) {
        debugPrint('❌ Error initializing local notifications: $localError');
      }
      // Mark initialized so startup/feature flows never loop on external dependency failures.
      _isInitialized = true;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    if (io.Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'gymai_pro_channel',
        'GymAI Pro Notifications',
        description: 'Notifications for GymAI Pro app',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      debugPrint('✅ Notification channel created');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (_firebaseMessaging == null) {
      // Firebase not ready; skip silently (initialize() should set it)
      debugPrint('⚠️ FirebaseMessaging not ready; skipping permission request');
      return;
    }
    // Request FCM permissions
    final NotificationSettings settings = await _firebaseMessaging!
        .requestPermission();

    // Request local notification permissions
    await Permission.notification.request();

    debugPrint(
      '📱 Notification permission status: ${settings.authorizationStatus}',
    );
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      if (_firebaseMessaging == null) {
        debugPrint('⚠️ FirebaseMessaging not ready; skipping FCM token fetch');
        return;
      }
      _fcmToken = await _firebaseMessaging!.getToken();
      if (_fcmToken != null) {
        debugPrint('🔑 FCM Token: $_fcmToken');
        await _saveFCMToken(_fcmToken!);
      }
      // Listen for token refresh
      _firebaseMessaging!.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM token refreshed');
        _fcmToken = newToken;
        await _saveFCMToken(newToken);
      });
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Save FCM token locally and sync with Supabase
  Future<void> _saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);

    try {
      // If offline, keep token locally and skip backend sync for now
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        debugPrint('ℹ️ Offline: skipping FCM token sync to Supabase');
        return;
      }

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final String platform = io.Platform.isAndroid
            ? 'android'
            : (io.Platform.isIOS ? 'ios' : 'other');
        await supabase.from('device_tokens').upsert({
          'user_id': user.id,
          'token': token,
          'platform': platform,
          'is_push_enabled': true,
          'last_seen': DateTime.now().toIso8601String(),
        }, onConflict: 'token');
        debugPrint('✅ FCM token saved to Supabase');

        // Subscribe to default topics after ensuring token is registered
        await _subscribeDefaultTopics();

        // Update user's last active timestamp
        await _updateLastActiveAt();
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token to Supabase: $e');
    }
  }

  Future<void> _subscribeDefaultTopics() async {
    try {
      if (_firebaseMessaging == null) {
        debugPrint('⚠️ FirebaseMessaging not ready; skipping topic subscribe');
        return;
      }
      final String lang = ui.PlatformDispatcher.instance.locale.languageCode;
      
      // Subscribe to 'all' topic - this is critical for broadcast notifications
      try {
        await _firebaseMessaging!.subscribeToTopic('all');
        debugPrint('✅ Successfully subscribed to topic: all');
      } catch (e) {
        debugPrint('❌ Error subscribing to topic "all": $e');
        // Retry once after a short delay
        await Future<void>.delayed(const Duration(seconds: 1));
        try {
          await _firebaseMessaging!.subscribeToTopic('all');
          debugPrint('✅ Successfully subscribed to topic "all" on retry');
        } catch (retryError) {
          debugPrint('❌ Error subscribing to topic "all" on retry: $retryError');
        }
      }
      
      // Subscribe to language topic
      try {
        await _firebaseMessaging!.subscribeToTopic(lang);
        debugPrint('✅ Successfully subscribed to topic: $lang');
      } catch (e) {
        debugPrint('❌ Error subscribing to topic "$lang": $e');
      }
      
      debugPrint('📡 Subscribed to topics: all, $lang');
    } catch (e) {
      debugPrint('❌ Error subscribing to topics: $e');
    }
  }

  /// Force subscribe to 'all' topic (useful for troubleshooting)
  Future<bool> forceSubscribeToAll() async {
    try {
      if (_firebaseMessaging == null) {
        // Try to initialize messaging if Firebase is ready
        if (!kIsWeb && Firebase.apps.isNotEmpty) {
          _firebaseMessaging = FirebaseMessaging.instance;
        }
      }
      if (_firebaseMessaging == null) return false;

      await _firebaseMessaging!.subscribeToTopic('all');
      debugPrint('✅ Force subscribed to topic: all');
      return true;
    } catch (e) {
      debugPrint('❌ Error force subscribing to topic "all": $e');
      return false;
    }
  }

  Future<void> _updateLastActiveAt() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile != null) {
        final profileId = profile['id'] as String?;
        if (profileId != null && profileId.isNotEmpty) {
          await Supabase.instance.client
              .from('profiles')
              .update({'last_active_at': DateTime.now().toIso8601String()})
              .eq('id', profileId);
          debugPrint('🕒 Updated last_active_at for user');
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating last_active_at: $e');
    }
  }

  /// Public method to mark user active and bump device last_seen
  Future<void> markUserActive() async {
    try {
      await _updateLastActiveAt();
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null && _fcmToken != null) {
        await supabase
            .from('device_tokens')
            .update({'last_seen': DateTime.now().toIso8601String()})
            .eq('token', _fcmToken!);
        debugPrint('🕒 Updated device last_seen');
      }
    } catch (e) {
      debugPrint('❌ Error in markUserActive: $e');
    }
  }

  /// Get saved FCM token
  Future<String?> getSavedFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  /// Setup Firebase message handlers
  Future<void> _setupFirebaseHandlers() async {
    if (_firebaseMessaging == null) {
      debugPrint('⚠️ FirebaseMessaging not ready; skipping handler setup');
      return;
    }
    if (_handlersConfigured) return;

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    _handlersConfigured = true;
  }

  /// Handle initial message (app opened from notification)
  Future<void> _handleInitialMessage() async {
    try {
      if (_firebaseMessaging == null) {
        debugPrint('⚠️ FirebaseMessaging not ready; skipping initial message');
        return;
      }
      final RemoteMessage? initialMessage =
          await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📱 App opened from notification: ${initialMessage.data}');
        // تأخیر در navigation تا اپ کاملاً آماده شود
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            try {
              NotificationNavigationService.handleNotificationNavigation(
                initialMessage.data,
              );
            } catch (e) {
              debugPrint('❌ Error handling initial message navigation: $e');
            }
          });
        });
      }
    } catch (e) {
      debugPrint('❌ Error handling initial message: $e');
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final incomingMessageId = message.data['message_id'] as String?;
    final fallbackKey = [
      message.data['type'],
      message.data['conversation_id'],
      message.data['sender_id'],
      message.data['message'],
    ].join('|');
    final dedupeKey = (incomingMessageId != null && incomingMessageId.isNotEmpty)
        ? 'id:$incomingMessageId'
        : 'payload:$fallbackKey';
    final now = DateTime.now();
    _recentIncomingNotificationKeys.removeWhere(
      (_, at) => now.difference(at) > const Duration(seconds: 20),
    );
    if (_recentIncomingNotificationKeys.containsKey(dedupeKey)) {
      debugPrint('ℹ️ Skip duplicate incoming notification: $dedupeKey');
      return;
    }
    _recentIncomingNotificationKeys[dedupeKey] = now;

    debugPrint('📨 Foreground message received: ${message.data}');

    // بررسی اینکه آیا این نوتیفیکیشن چت است
    final messageType = message.data['type'] as String?;
    if (messageType == 'chat_message') {
      // In foreground, show an in-app alert only if user is not inside
      // the same conversation to avoid silent delivery gaps.
      final conversationId = message.data['conversation_id'] as String?;
      bool isUserInChat = false;
      if (conversationId != null && conversationId.isNotEmpty) {
        isUserInChat = await _checkUserPresenceInChat(conversationId);
        if (isUserInChat) {
          debugPrint('✅ User is active in chat, skipping notification');
        }
      }

      if (!isUserInChat) {
        final senderName =
            (message.data['sender_name'] as String?)?.trim().isNotEmpty ?? false
            ? (message.data['sender_name'] as String).trim()
            : (message.notification?.title ?? 'کاربر');
        final body =
            (message.data['message'] as String?)?.trim().isNotEmpty ?? false
            ? (message.data['message'] as String).trim()
            : (message.notification?.body ?? 'پیام جدید دریافت کردید');
        await showInAppChatAlert(
          senderName: senderName,
          message: body,
          conversationId: conversationId,
        );
      }
      onNotificationReceived?.call(message.data);
      return;
    }

    // Show local notification
    showLocalNotification(message);

    // Call callback if provided
    onNotificationReceived?.call(message.data);
  }

  /// بررسی حضور کاربر در چت
  Future<bool> _checkUserPresenceInChat(String conversationId) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      // بررسی حضور کاربر در چت (آخرین 45 ثانیه)
      final cutoffTime = DateTime.now()
          .subtract(const Duration(seconds: 45))
          .toIso8601String();

      final response = await supabase
          .from('chat_presence')
          .select('id')
          .eq('user_id', user.id)
          .eq('conversation_id', conversationId)
          .eq('is_active', true)
          .gt('last_seen', cutoffTime)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ Error checking user presence in chat: $e');
      return false;
    }
  }

  /// Handle notification taps
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    onNotificationTapped?.call(message.data);

    // تأخیر در navigation تا اپ کاملاً آماده شود
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          // Handle navigation for chat notifications
          NotificationNavigationService.handleNotificationNavigation(
            message.data,
          );
        } catch (e) {
          debugPrint('❌ Error handling notification tap navigation: $e');
        }
      });
    });
  }

  /// Handle local notification taps
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      final data = json.decode(response.payload!) as Map<String, dynamic>;
      onNotificationTapped?.call(data);

      // تأخیر در navigation تا اپ کاملاً آماده شود
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            // Handle navigation for chat notifications
            NotificationNavigationService.handleNotificationNavigation(data);
          } catch (e) {
            debugPrint('❌ Error handling local notification navigation: $e');
          }
        });
      });
    }
  }

  /// Parse hex color string to Color
  Color _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return AppTheme.goldColor;
    }

    try {
      // Remove # if present
      String hex = hexString.replaceAll('#', '');
      
      // Handle 6-digit hex
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add alpha channel
      }
      
      // Parse hex to int
      final intValue = int.parse(hex, radix: 16);
      return Color(intValue);
    } catch (e) {
      debugPrint('❌ Error parsing hex color "$hexString": $e');
      return AppTheme.goldColor;
    }
  }

  /// Get icon resource name from icon string
  /// Note: Always uses app launcher icon for consistency
  /// Users can add emojis in the notification text if they want visual icons
  String _getIconResource(String? iconName) {
    // Always use app launcher icon - simple and consistent like other apps
    // Users can add emojis (😊, 🎉, etc.) in the notification text if needed
    return '@mipmap/ic_launcher';
  }

  /// Get or create notification channel with specific color
  /// Uses a dynamic channel ID based on color to ensure color is applied correctly
  /// For Android 8.0+, we need to set the channel color after creating it
  Future<String> _getOrCreateNotificationChannel(Color color) async {
    if (!io.Platform.isAndroid) {
      return 'gymai_pro_channel';
    }

    // Create a channel ID based on color (first 6 hex digits)
    // This ensures each color gets its own channel
    final colorHex = color.value.toRadixString(16).substring(2, 8);
    final channelId = 'gymai_pro_channel_$colorHex';

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      try {
        // Try to delete existing channel first (if it exists)
        // This ensures we can recreate it with the correct color
        try {
          await androidImplementation.deleteNotificationChannel(channelId);
          debugPrint('🗑️ Deleted existing channel: $channelId');
        } catch (e) {
          // Channel might not exist, ignore error
          debugPrint('ℹ️ Channel does not exist yet: $channelId');
        }

        // Create new channel
        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          channelId,
          'GymAI Pro Notifications',
          description: 'Notifications for GymAI Pro app',
          importance: Importance.high,
        );

        await androidImplementation.createNotificationChannel(channel);
        debugPrint('✅ Created notification channel: $channelId');

        // Try to set channel color (Android 8.0+)
        // Note: This method might not be available in all versions of the plugin
        try {
          // Use reflection or method channel to set color
          // For now, we'll rely on the color property in AndroidNotificationDetails
          // which should work for most cases
          debugPrint('🎨 Channel color will be set via AndroidNotificationDetails');
        } catch (e) {
          debugPrint('⚠️ Could not set channel color directly: $e');
        }
      } catch (e) {
        debugPrint('⚠️ Error creating notification channel: $e');
      }
    }

    return channelId;
  }

  /// Show local notification
  Future<void> showLocalNotification(RemoteMessage message) async {
    // Extract custom styling from message data
    final backgroundColorHex = message.data['background_color'] as String?;
    final iconName = message.data['icon'] as String?;
    final imageUrl = message.data['image_url'] as String?;

    // Debug: Print all message data to see what we're receiving
    debugPrint('🎨 Full message data: ${message.data}');
    debugPrint('🎨 Notification data received:');
    debugPrint('   - background_color: $backgroundColorHex');
    debugPrint('   - icon: $iconName');
    debugPrint('   - image_url: $imageUrl');

    // Parse color
    final notificationColor = _parseHexColor(backgroundColorHex);
    final colorHex = notificationColor.value.toRadixString(16).substring(2);
    debugPrint('   - Parsed color: #$colorHex (ARGB: ${notificationColor.value})');
    
    // Get icon resource - use ic_notification if available, otherwise ic_launcher
    final iconResource = _getIconResource(iconName);
    debugPrint('   - Icon resource: $iconResource');

    // For image support, we need to download the image first
    // This is a simplified version - full image support requires downloading
    // the image and saving it locally, then using FilePathSource
    // TODO: Implement full image support with download and caching
    if (imageUrl != null && imageUrl.isNotEmpty) {
      debugPrint('📷 Image URL provided: $imageUrl (image support coming soon)');
    }

    // Get or create notification channel with the specified color
    // This is important for Android 8.0+ where channel color affects notification appearance
    final channelId = await _getOrCreateNotificationChannel(notificationColor);

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          channelId,
          'GymAI Pro Notifications',
          channelDescription: 'Notifications for GymAI Pro app',
          importance: Importance.high,
          priority: Priority.high,
          icon: iconResource,
          color: notificationColor,
          // LED settings for older Android versions (pre-Oreo)
          // Must specify both ledOnMs and ledOffMs when enableLights is true
          enableLights: true,
          ledColor: notificationColor,
          ledOnMs: 1000,
          ledOffMs: 500,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'GymAI Pro',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
    
    debugPrint('✅ Notification shown with color: #${notificationColor.value.toRadixString(16).substring(2)}');
    if (imageUrl != null && imageUrl.isNotEmpty) {
      debugPrint('📷 Image URL saved in payload (full image support coming soon)');
    }
  }

  Future<bool> isFcmProviderReadyCached() async {
    if (kIsWeb) return false;
    return _isInitialized && _firebaseMessaging != null;
  }

  Future<void> showInAppFriendRequestAlert({
    required String title,
    required String body,
    String? requestId,
    String? requesterId,
    String? friendId,
    bool isAccepted = false,
  }) async {
    await showCustomNotification(
      title: title,
      body: body,
      payload: json.encode({
        'type': isAccepted ? 'friend_request_accepted' : 'friend_request',
        if (requestId != null) 'request_id': requestId,
        if (requesterId != null) 'requester_id': requesterId,
        if (friendId != null) 'friend_id': friendId,
      }),
    );
  }

  Future<void> showInAppGenericAlert({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await showCustomNotification(
      title: title,
      body: body,
      payload: json.encode(data ?? <String, dynamic>{}),
    );
  }

  /// Show custom local notification
  Future<void> showCustomNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'gymai_pro_custom_channel',
          'GymAI Pro Custom Notifications',
          channelDescription: 'Custom notifications for GymAI Pro app',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFD4AF37),
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      _safeNotificationId(id),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Show professional in-app chat alert (fallback when push is unavailable).
  Future<void> showInAppChatAlert({
    required String senderName,
    required String message,
    String? conversationId,
    String? peerId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final safeSender = senderName.trim().isNotEmpty ? senderName.trim() : 'کاربر';
    final safeMessage = message.trim().isNotEmpty
        ? message.trim()
        : 'پیام جدید دریافت شد';

    final androidDetails = AndroidNotificationDetails(
      'chat_realtime_channel',
      'Chat Messages',
      channelDescription: 'Realtime in-app chat alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: AppTheme.goldColor,
      category: AndroidNotificationCategory.message,
      styleInformation: BigTextStyleInformation(
        safeMessage,
        contentTitle: '💬 $safeSender',
        summaryText: 'GymAI',
      ),
      ticker: 'پیام جدید از $safeSender',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: 'GymAI Pro Chat',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = json.encode({
      'type': 'chat_message',
      'sender_name': safeSender,
      if (conversationId != null) 'conversation_id': conversationId,
      if (peerId != null && peerId.isNotEmpty) 'peer_id': peerId,
      if (peerId != null && peerId.isNotEmpty) 'peer_name': safeSender,
    });

    await _localNotifications.show(
      _safeNotificationId(),
      'پیام جدید از $safeSender',
      safeMessage,
      details,
      payload: payload,
    );
  }

  /// Show workout reminder notification
  Future<void> showWorkoutReminder({
    required String workoutName,
    required String time,
  }) async {
    await showCustomNotification(
      title: '⏰ یادآوری تمرین',
      body: 'زمان تمرین "$workoutName" فرا رسیده است. ساعت $time',
      payload: json.encode({
        'type': 'workout_reminder',
        'workout_name': workoutName,
        'time': time,
      }),
    );
  }

  /// Show meal reminder notification
  Future<void> showMealReminder({
    required String mealName,
    required String time,
  }) async {
    await showCustomNotification(
      title: '🍽️ یادآوری وعده غذایی',
      body: 'زمان وعده "$mealName" فرا رسیده است. ساعت $time',
      payload: json.encode({
        'type': 'meal_reminder',
        'meal_name': mealName,
        'time': time,
      }),
    );
  }

  /// Show weight tracking reminder
  Future<void> showWeightReminder() async {
    await showCustomNotification(
      title: '⚖️ یادآوری ثبت وزن',
      body: 'امروز وزن خود را ثبت کنید تا پیشرفت خود را دنبال کنید',
      payload: json.encode({'type': 'weight_reminder'}),
    );
  }

  /// Show chat notification
  Future<void> showChatNotification({
    required String senderName,
    required String message,
  }) async {
    await showCustomNotification(
      title: '💬 پیام جدید از $senderName',
      body: message,
      payload: json.encode({
        'type': 'chat_message',
        'sender_name': senderName,
        'message': message,
      }),
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    if (_firebaseMessaging == null && !kIsWeb && Firebase.apps.isNotEmpty) {
      _firebaseMessaging = FirebaseMessaging.instance;
    }
    if (_firebaseMessaging == null) {
      throw Exception(
        'Firebase messaging is not available in current network/runtime state',
      );
    }
    return _firebaseMessaging!.getNotificationSettings();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    if (_firebaseMessaging == null && !kIsWeb && Firebase.apps.isNotEmpty) {
      _firebaseMessaging = FirebaseMessaging.instance;
    }
    if (_firebaseMessaging == null) {
      debugPrint('⚠️ Skipping subscribeToTopic("$topic"): Firebase unavailable');
      return;
    }
    await _firebaseMessaging!.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_firebaseMessaging == null && !kIsWeb && Firebase.apps.isNotEmpty) {
      _firebaseMessaging = FirebaseMessaging.instance;
    }
    if (_firebaseMessaging == null) {
      debugPrint('⚠️ Skipping unsubscribeFromTopic("$topic"): Firebase unavailable');
      return;
    }
    await _firebaseMessaging!.unsubscribeFromTopic(topic);
  }

  /// Trigger processing of broadcast queue (Edge Function)
  Future<bool> processBroadcastQueue() async {
    if (!AppConfig.supabaseEdgeFunctionsEnabled) return false;
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.functions.invoke(
        'send-notifications', // New function name
        body: {},
      );
      debugPrint('☁️ send-notifications result: ${res.data}');
      return true;
    } catch (e) {
      debugPrint('❌ Error invoking send-notifications: $e');
      return false;
    }
  }

  /// Send notification directly to a topic via Edge Function (bypasses queue)
  Future<bool> sendDirectToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (!AppConfig.supabaseEdgeFunctionsEnabled) return false;
    try {
      final supabase = Supabase.instance.client;
      
      // Debug: Print what we're sending
      debugPrint('📤 Sending to Edge Function:');
      debugPrint('   - topic: $topic');
      debugPrint('   - title: $title');
      debugPrint('   - body: $body');
      debugPrint('   - data: $data');
      
      final res = await supabase.functions.invoke(
        'send-notifications',
        body: {
          'mode': 'direct',
          'target_type': 'topic',
          'topic': topic,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
      debugPrint('☁️ direct send result: ${res.data}');
      return true;
    } catch (e) {
      debugPrint('❌ Error in sendDirectToTopic: $e');
      return false;
    }
  }

  /// Schedule daily weight reminder
  Future<void> scheduleWeightReminder({required TimeOfDay time}) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      1001, // Unique ID for weight reminder
      '⚖️ یادآوری ثبت وزن',
      'امروز وزن خود را ثبت کنید تا پیشرفت خود را دنبال کنید',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weight_reminder_channel',
          'Weight Reminders',
          channelDescription: 'Daily weight logging reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFD4AF37),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule workout reminder
  Future<void> scheduleWorkoutReminder({
    required String workoutName,
    required DateTime scheduledTime,
  }) async {
    await _localNotifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '⏰ یادآوری تمرین',
      'زمان تمرین "$workoutName" فرا رسیده است',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_reminder_channel',
          'Workout Reminders',
          channelDescription: 'Workout schedule reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFD4AF37),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Schedule meal reminder
  Future<void> scheduleMealReminder({
    required String mealName,
    required DateTime scheduledTime,
  }) async {
    await _localNotifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🍽️ یادآوری وعده غذایی',
      'زمان وعده "$mealName" فرا رسیده است',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminder_channel',
          'Meal Reminders',
          channelDescription: 'Meal schedule reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFD4AF37),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllScheduledNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _localNotifications.pendingNotificationRequests();
  }

  /// Ensure the current user's FCM token is synced to backend (use after login/signup)
  Future<void> syncFCMTokenIfAvailable() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        return;
      }

      // Prefer fresh token from Firebase; fallback to saved one
      String? token;
      try {
        if (_firebaseMessaging == null) {
          if (!kIsWeb && Firebase.apps.isNotEmpty) {
            _firebaseMessaging = FirebaseMessaging.instance;
          }
        }
        token = await _firebaseMessaging?.getToken();
      } catch (_) {}

      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('fcm_token');
      }

      if (token != null && token.isNotEmpty) {
        await _saveFCMToken(token);
      }
    } catch (e) {
      debugPrint('❌ Error in syncFCMTokenIfAvailable: $e');
    }
  }

  /// Send chat notification to specific user
  Future<bool> sendChatNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String message,
    required String messageId,
    required String messageType,
    String? conversationId,
  }) async {
    if (!AppConfig.supabaseEdgeFunctionsEnabled) return false;
    try {
      // If provider/network recently timed out, back off briefly to avoid
      // repeated expensive calls that hurt chat responsiveness.
      if (_lastChatNotificationTimeoutAt != null &&
          DateTime.now().difference(_lastChatNotificationTimeoutAt!) <
              const Duration(seconds: 4)) {
        if (kDebugMode) {
          debugPrint('ℹ️ Skip chat notification due to timeout backoff');
        }
        return false;
      }

      // Prevent duplicate server calls for same message in short window.
      final now = DateTime.now();
      _recentChatNotificationAttempts.removeWhere(
        (_, at) => now.difference(at) > const Duration(seconds: 30),
      );
      final lastAttemptAt = _recentChatNotificationAttempts[messageId];
      if (lastAttemptAt != null &&
          now.difference(lastAttemptAt) < const Duration(seconds: 10)) {
        if (kDebugMode) {
          debugPrint('ℹ️ Skip duplicate chat notification attempt: $messageId');
        }
        return false;
      }
      _recentChatNotificationAttempts[messageId] = now;

      // Fast-fail when internet is unavailable to avoid noisy socket errors.
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        if (kDebugMode) {
          debugPrint('ℹ️ Skip send-chat-notification: offline');
        }
        return false;
      }

      final supabase = Supabase.instance.client;

      final response = await supabase.functions.invoke(
            'send-chat-notification',
            body: {
              'receiver_id': receiverId,
              'sender_id': senderId,
              'sender_name': senderName,
              'message': message,
              'message_id': messageId,
              'message_type': messageType,
              if (conversationId != null) 'conversation_id': conversationId,
            },
          )
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () => FunctionResponse(status: 408, data: 'timeout'),
          );

      if (response.status == 200) {
        debugPrint('✅ Chat notification sent successfully');
        return true;
      } else {
        final isTimeout =
            response.status == 408 || response.data?.toString() == 'timeout';
        if (isTimeout) {
          _lastChatNotificationTimeoutAt = DateTime.now();
          // One quick retry before giving up, to improve delivery on flaky links.
          try {
            final retryResponse = await supabase.functions
                .invoke(
                  'send-chat-notification',
                  body: {
                    'receiver_id': receiverId,
                    'sender_id': senderId,
                    'sender_name': senderName,
                    'message': message,
                    'message_id': messageId,
                    'message_type': messageType,
                    if (conversationId != null) 'conversation_id': conversationId,
                  },
                )
                .timeout(
                  const Duration(seconds: 4),
                  onTimeout: () => FunctionResponse(status: 408, data: 'timeout'),
                );
            if (retryResponse.status == 200) {
              debugPrint('✅ Chat notification sent successfully (retry)');
              return true;
            }
          } catch (_) {}
        }
        if (kDebugMode) {
          debugPrint('❌ Chat notification failed: ${response.data}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending chat notification: $e');
      }
      return false;
    }
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📨 Background message received: ${message.data}');
  debugPrint('📨 Message notification: ${message.notification?.title}');
  debugPrint('📨 Message notification body: ${message.notification?.body}');

  // برای notification messages، سیستم خودش نمایش می‌دهد
  // فقط برای data messages نیاز به نمایش دستی داریم
  if (message.notification == null && message.data.isNotEmpty) {
    try {
      final notificationService = NotificationService();
      await notificationService.showLocalNotification(message);
      debugPrint('📱 Background notification displayed for data message');
    } catch (e) {
      debugPrint('❌ Error showing background notification: $e');
    }
  } else {
    debugPrint('📱 System will handle notification display automatically');
  }

  // Handle navigation for background messages
  try {
    NotificationNavigationService.handleNotificationNavigation(message.data);
  } catch (e) {
    debugPrint('❌ Error handling background notification navigation: $e');
  }
}
