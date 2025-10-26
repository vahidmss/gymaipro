import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gymaipro/services/notification_navigation_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  // Callbacks for handling notifications
  Function(Map<String, dynamic>)? onNotificationTapped;
  Function(Map<String, dynamic>)? onNotificationReceived;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Skip Firebase initialization for web
      if (kIsWeb) {
        debugPrint('⚠️ Skipping Firebase initialization for web platform');
        _isInitialized = true;
        return;
      }

      // Initialize Firebase
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized successfully');

      // Initialize local notifications
      await _initializeLocalNotifications();
      debugPrint('✅ Local notifications initialized successfully');

      // Request permissions
      await _requestPermissions();
      debugPrint('✅ Permissions requested successfully');

      // Get FCM token
      await _getFCMToken();
      debugPrint('✅ FCM token retrieved successfully');

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
    // Request FCM permissions
    final NotificationSettings settings = await _firebaseMessaging
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
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        debugPrint('🔑 FCM Token: $_fcmToken');
        await _saveFCMToken(_fcmToken!);
      }
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
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
      final String lang = ui.PlatformDispatcher.instance.locale.languageCode;
      await _firebaseMessaging.subscribeToTopic('all');
      await _firebaseMessaging.subscribeToTopic(lang);
      debugPrint('📡 Subscribed to topics: all, $lang');
    } catch (e) {
      debugPrint('❌ Error subscribing to topics: $e');
    }
  }

  Future<void> _updateLastActiveAt() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Ensure user.id is a valid UUID
        if (user.id.isNotEmpty && user.id.length >= 32) {
          await supabase
              .from('profiles')
              .update({'last_active_at': DateTime.now().toIso8601String()})
              .eq('id', user.id);
          debugPrint('🕒 Updated last_active_at for user');
        } else {
          debugPrint('❌ Invalid user ID format: ${user.id}');
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
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle initial message (app opened from notification)
  Future<void> _handleInitialMessage() async {
    try {
      final RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
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
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Foreground message received: ${message.data}');

    // Show local notification
    showLocalNotification(message);

    // Call callback if provided
    onNotificationReceived?.call(message.data);
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

  /// Show local notification
  Future<void> showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'gymai_pro_channel',
          'GymAI Pro Notifications',
          channelDescription: 'Notifications for GymAI Pro app',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFD4AF37), // Gold color
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
      message.hashCode,
      message.notification?.title ?? 'GymAI Pro',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }

  /// Show custom local notification
  Future<void> showCustomNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
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
      id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
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
    return _firebaseMessaging.getNotificationSettings();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  /// Trigger processing of broadcast queue (Edge Function)
  Future<bool> processBroadcastQueue() async {
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
    try {
      final supabase = Supabase.instance.client;
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
        token = await _firebaseMessaging.getToken();
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
    required String senderName,
    required String message,
    required String messageId,
    required String messageType,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.functions.invoke(
        'send-chat-notification',
        body: {
          'receiver_id': receiverId,
          'sender_name': senderName,
          'message': message,
          'message_id': messageId,
          'message_type': messageType,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ Chat notification sent successfully');
        return true;
      } else {
        debugPrint('❌ Chat notification failed: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending chat notification: $e');
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
