import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس حرفه‌ای نوتیفیکیشن پیام‌های شخصی
/// قابلیت‌های پیشرفته:
/// - تنظیمات شخصی‌سازی شده برای هر کاربر
/// - فیلتر بر اساس نوع کاربر (مربی/ورزشکار)
/// - مدیریت ساعات سکوت
/// - گروه‌بندی نوتیفیکیشن‌ها
/// - پشتیبانی از پیام‌های مختلف (متن، تصویر، فایل)
class PrivateMessageNotificationService {
  factory PrivateMessageNotificationService() => _instance;
  PrivateMessageNotificationService._internal();
  static final PrivateMessageNotificationService _instance =
      PrivateMessageNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  RealtimeChannel? _messageChannel;
  RealtimeChannel? _conversationChannel;

  // تنظیمات نوتیفیکیشن پیام‌های شخصی
  PrivateMessageNotificationSettings _settings =
      const PrivateMessageNotificationSettings();

  /// تنظیمات نوتیفیکیشن پیام‌های شخصی
  PrivateMessageNotificationSettings get settings => _settings;

  /// مقداردهی اولیه سرویس
  Future<void> initialize() async {
    await _loadSettings();
    await _setupMessageSubscription();
  }

  /// بارگذاری تنظیمات از SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(
        'private_message_notification_settings',
      );

      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = PrivateMessageNotificationSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading private message notification settings: $e');
    }
  }

  /// ذخیره تنظیمات در SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'private_message_notification_settings',
        jsonEncode(_settings.toJson()),
      );
    } catch (e) {
      debugPrint('Error saving private message notification settings: $e');
    }
  }

  /// تنظیم اشتراک‌گذاری پیام‌های جدید
  Future<void> _setupMessageSubscription() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // اشتراک‌گذاری پیام‌های جدید
      _messageChannel = _supabase.channel(
        'private_message_notifications_${user.id}',
      );

      _messageChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'chat_messages',
            callback: (payload) async {
              await _handleNewMessage(payload.newRecord);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error setting up message subscription: $e');
    }
  }

  /// پردازش پیام جدید
  Future<void> _handleNewMessage(Map<String, dynamic> messageData) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final message = ChatMessage.fromJson(messageData);

      // فقط پیام‌هایی که برای کاربر فعلی ارسال شده‌اند
      if (message.receiverId != user.id) return;

      // ⚠️ غیرفعال کردن نوتیفیکیشن محلی برای پیام‌های چت
      // چون edge function خودش نوتیفیکیشن را ارسال می‌کند و بررسی حضور کاربر را انجام می‌دهد
      // این از تکرار نوتیفیکیشن جلوگیری می‌کند
      debugPrint('⚠️ Skipping local notification for chat message (handled by edge function)');
      // تمام نوتیفیکیشن‌های چت توسط edge function مدیریت می‌شوند
      return;
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  /// به‌روزرسانی تنظیمات
  Future<void> updateSettings(
    PrivateMessageNotificationSettings newSettings,
  ) async {
    _settings = newSettings;
    await _saveSettings();
  }

  /// دریافت تنظیمات فعلی
  PrivateMessageNotificationSettings getCurrentSettings() {
    return _settings;
  }

  /// فعال/غیرفعال کردن نوتیفیکیشن‌ها
  Future<void> setEnabled(bool enabled) async {
    _settings = _settings.copyWith(enabled: enabled);
    await _saveSettings();
  }

  /// تنظیم ساعات سکوت
  Future<void> setQuietHours(TimeOfDay? startTime, TimeOfDay? endTime) async {
    _settings = _settings.copyWith(
      quietStartTime: startTime,
      quietEndTime: endTime,
    );
    await _saveSettings();
  }

  /// تنظیم نوتیفیکیشن بر اساس نوع کاربر
  Future<void> setUserTypeNotifications({
    bool? fromTrainers,
    bool? fromAthletes,
  }) async {
    _settings = _settings.copyWith(
      notifyFromTrainers: fromTrainers,
      notifyFromAthletes: fromAthletes,
    );
    await _saveSettings();
  }

  /// تنظیم نوتیفیکیشن بر اساس نوع پیام
  Future<void> setMessageTypeNotifications({
    bool? textMessages,
    bool? imageMessages,
    bool? fileMessages,
    bool? voiceMessages,
  }) async {
    _settings = _settings.copyWith(
      notifyTextMessages: textMessages,
      notifyImageMessages: imageMessages,
      notifyFileMessages: fileMessages,
      notifyVoiceMessages: voiceMessages,
    );
    await _saveSettings();
  }

  /// پاک کردن تمام نوتیفیکیشن‌های چت
  Future<void> clearAllChatNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// دریافت تعداد نوتیفیکیشن‌های خوانده نشده
  Future<int> getUnreadNotificationCount() async {
    final pendingNotifications = await _localNotifications
        .pendingNotificationRequests();
    return pendingNotifications.length;
  }

  /// توقف سرویس
  Future<void> dispose() async {
    await _messageChannel?.unsubscribe();
    await _conversationChannel?.unsubscribe();
  }
}

/// تنظیمات نوتیفیکیشن پیام‌های شخصی
class PrivateMessageNotificationSettings {
  const PrivateMessageNotificationSettings({
    this.enabled = true,
    this.notifyFromTrainers = true,
    this.notifyFromAthletes = true,
    this.notifyTextMessages = true,
    this.notifyImageMessages = true,
    this.notifyFileMessages = true,
    this.notifyVoiceMessages = true,
    this.groupNotifications = true,
    this.showPreview = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietStartTime,
    this.quietEndTime,
    this.maxNotificationsPerConversation = 5,
  });

  factory PrivateMessageNotificationSettings.fromJson(
    Map<String, dynamic> json,
  ) {
    return PrivateMessageNotificationSettings(
      enabled: (json['enabled'] as bool?) ?? true,
      notifyFromTrainers: (json['notify_from_trainers'] as bool?) ?? true,
      notifyFromAthletes: (json['notify_from_athletes'] as bool?) ?? true,
      notifyTextMessages: (json['notify_text_messages'] as bool?) ?? true,
      notifyImageMessages: (json['notify_image_messages'] as bool?) ?? true,
      notifyFileMessages: (json['notify_file_messages'] as bool?) ?? true,
      notifyVoiceMessages: (json['notify_voice_messages'] as bool?) ?? true,
      groupNotifications: (json['group_notifications'] as bool?) ?? true,
      showPreview: (json['show_preview'] as bool?) ?? true,
      soundEnabled: (json['sound_enabled'] as bool?) ?? true,
      vibrationEnabled: (json['vibration_enabled'] as bool?) ?? true,
      quietStartTime: json['quiet_start_time'] != null
          ? _parseTimeOfDay(json['quiet_start_time'] as String)
          : null,
      quietEndTime: json['quiet_end_time'] != null
          ? _parseTimeOfDay(json['quiet_end_time'] as String)
          : null,
      maxNotificationsPerConversation:
          (json['max_notifications_per_conversation'] as int?) ?? 5,
    );
  }
  final bool enabled;
  final bool notifyFromTrainers;
  final bool notifyFromAthletes;
  final bool notifyTextMessages;
  final bool notifyImageMessages;
  final bool notifyFileMessages;
  final bool notifyVoiceMessages;
  final bool groupNotifications;
  final bool showPreview;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final TimeOfDay? quietStartTime;
  final TimeOfDay? quietEndTime;
  final int maxNotificationsPerConversation;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'notify_from_trainers': notifyFromTrainers,
      'notify_from_athletes': notifyFromAthletes,
      'notify_text_messages': notifyTextMessages,
      'notify_image_messages': notifyImageMessages,
      'notify_file_messages': notifyFileMessages,
      'notify_voice_messages': notifyVoiceMessages,
      'group_notifications': groupNotifications,
      'show_preview': showPreview,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'quiet_start_time': quietStartTime != null
          ? '${quietStartTime!.hour.toString().padLeft(2, '0')}:${quietStartTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'quiet_end_time': quietEndTime != null
          ? '${quietEndTime!.hour.toString().padLeft(2, '0')}:${quietEndTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'max_notifications_per_conversation': maxNotificationsPerConversation,
    };
  }

  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  PrivateMessageNotificationSettings copyWith({
    bool? enabled,
    bool? notifyFromTrainers,
    bool? notifyFromAthletes,
    bool? notifyTextMessages,
    bool? notifyImageMessages,
    bool? notifyFileMessages,
    bool? notifyVoiceMessages,
    bool? groupNotifications,
    bool? showPreview,
    bool? soundEnabled,
    bool? vibrationEnabled,
    TimeOfDay? quietStartTime,
    TimeOfDay? quietEndTime,
    int? maxNotificationsPerConversation,
  }) {
    return PrivateMessageNotificationSettings(
      enabled: enabled ?? this.enabled,
      notifyFromTrainers: notifyFromTrainers ?? this.notifyFromTrainers,
      notifyFromAthletes: notifyFromAthletes ?? this.notifyFromAthletes,
      notifyTextMessages: notifyTextMessages ?? this.notifyTextMessages,
      notifyImageMessages: notifyImageMessages ?? this.notifyImageMessages,
      notifyFileMessages: notifyFileMessages ?? this.notifyFileMessages,
      notifyVoiceMessages: notifyVoiceMessages ?? this.notifyVoiceMessages,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      showPreview: showPreview ?? this.showPreview,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietStartTime: quietStartTime ?? this.quietStartTime,
      quietEndTime: quietEndTime ?? this.quietEndTime,
      maxNotificationsPerConversation:
          maxNotificationsPerConversation ??
          this.maxNotificationsPerConversation,
    );
  }
}
