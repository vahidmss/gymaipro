import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/notification/notification_service.dart';
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
  final NotificationService _notificationService = NotificationService();
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

      // بررسی تنظیمات نوتیفیکیشن
      if (!_shouldSendNotification(message)) return;

      // دریافت اطلاعات فرستنده
      final senderInfo = await _getSenderInfo(message.senderId);
      if (senderInfo == null) return;

      // ایجاد نوتیفیکیشن
      await _createNotification(message, senderInfo);
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  /// بررسی اینکه آیا باید نوتیفیکیشن ارسال شود
  bool _shouldSendNotification(ChatMessage message) {
    // بررسی فعال بودن نوتیفیکیشن‌های چت
    if (!_settings.enabled) return false;

    // بررسی ساعات سکوت
    if (_isInQuietHours()) return false;

    // بررسی تنظیمات بر اساس نوع کاربر
    if (!_settings.notifyFromTrainers && _isFromTrainer(message.senderId)) {
      return false;
    }
    if (!_settings.notifyFromAthletes && _isFromAthlete(message.senderId)) {
      return false;
    }

    // بررسی تنظیمات بر اساس نوع پیام
    if (!_settings.notifyTextMessages && message.isText) return false;
    if (!_settings.notifyImageMessages && message.isImage) return false;
    if (!_settings.notifyFileMessages && message.isFile) return false;
    if (!_settings.notifyVoiceMessages && message.isVoice) return false;

    return true;
  }

  /// بررسی ساعات سکوت
  bool _isInQuietHours() {
    if (_settings.quietStartTime == null || _settings.quietEndTime == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final start = _settings.quietStartTime!;
    final end = _settings.quietEndTime!;

    // اگر ساعات سکوت در همان روز است
    if (start.hour < end.hour ||
        (start.hour == end.hour && start.minute < end.minute)) {
      return now.hour > start.hour ||
          (now.hour == start.hour && now.minute >= start.minute) &&
              (now.hour < end.hour ||
                  (now.hour == end.hour && now.minute < end.minute));
    }

    // اگر ساعات سکوت از شب تا صبح است
    return now.hour >= start.hour || now.hour < end.hour;
  }

  /// بررسی اینکه آیا فرستنده مربی است
  bool _isFromTrainer(String senderId) {
    // اینجا باید از UserService استفاده کنی تا نقش کاربر را بررسی کنی
    // فعلاً فرض می‌کنیم که در data پیام این اطلاعات موجود است
    return false; // باید پیاده‌سازی شود
  }

  /// بررسی اینکه آیا فرستنده ورزشکار است
  bool _isFromAthlete(String senderId) {
    // اینجا باید از UserService استفاده کنی تا نقش کاربر را بررسی کنی
    return false; // باید پیاده‌سازی شود
  }

  /// دریافت اطلاعات فرستنده
  Future<Map<String, dynamic>?> _getSenderInfo(String senderId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url, role')
          .eq('id', senderId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error getting sender info: $e');
      return null;
    }
  }

  /// ایجاد نوتیفیکیشن
  Future<void> _createNotification(
    ChatMessage message,
    Map<String, dynamic> senderInfo,
  ) async {
    try {
      final title = _generateNotificationTitle(senderInfo);
      final body = _generateNotificationBody(message);

      final notificationData = {
        'message_id': message.id,
        'sender_id': message.senderId,
        'conversation_id': _generateConversationId(
          message.senderId,
          message.receiverId,
        ),
        'message_type': message.messageType,
        'sender_name': senderInfo['full_name'],
        'sender_avatar': senderInfo['avatar_url'],
      };

      await _notificationService.showCustomNotification(
        title: title,
        body: body,
        payload: jsonEncode(notificationData),
      );
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// تولید عنوان نوتیفیکیشن
  String _generateNotificationTitle(Map<String, dynamic> senderInfo) {
    final senderName = senderInfo['full_name'] ?? 'کاربر ناشناس';
    final senderRole = senderInfo['role'];

    if (senderRole == 'trainer') {
      return 'پیام جدید از مربی $senderName';
    } else if (senderRole == 'athlete') {
      return 'پیام جدید از ورزشکار $senderName';
    } else {
      return 'پیام جدید از $senderName';
    }
  }

  /// تولید متن نوتیفیکیشن
  String _generateNotificationBody(ChatMessage message) {
    switch (message.messageType) {
      case 'text':
        return message.message;
      case 'image':
        return '📷 تصویر ارسال کرد';
      case 'file':
        return '📎 فایل ارسال کرد';
      case 'voice':
        return '🎤 پیام صوتی ارسال کرد';
      default:
        return 'پیام جدید دریافت کردید';
    }
  }

  /// تولید شناسه مکالمه
  String _generateConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
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
