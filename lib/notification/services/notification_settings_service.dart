import 'dart:convert';

import 'package:gymaipro/notification/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static const String _settingsKey = 'notification_settings';

  /// دریافت تنظیمات اعلان‌ها
  static Future<NotificationSettingsModel> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        return NotificationSettingsModel(
          workoutReminders: (settingsMap['workout_reminders'] as bool?) ?? true,
          mealReminders: (settingsMap['meal_reminders'] as bool?) ?? true,
          weightReminders: (settingsMap['weight_reminders'] as bool?) ?? true,
          chatNotifications:
              (settingsMap['chat_notifications'] as bool?) ?? true,
          achievementNotifications:
              (settingsMap['achievement_notifications'] as bool?) ?? true,
          generalNotifications:
              (settingsMap['general_notifications'] as bool?) ?? true,
          soundEnabled: (settingsMap['sound_enabled'] as bool?) ?? true,
          vibrationEnabled: (settingsMap['vibration_enabled'] as bool?) ?? true,
        );
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    }

    // Return default settings if loading fails
    return NotificationSettingsModel();
  }

  /// ذخیره تنظیمات اعلان‌ها
  static Future<bool> saveSettings(NotificationSettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _settingsKey,
        json.encode({
          'workout_reminders': settings.workoutReminders,
          'meal_reminders': settings.mealReminders,
          'weight_reminders': settings.weightReminders,
          'chat_notifications': settings.chatNotifications,
          'achievement_notifications': settings.achievementNotifications,
          'general_notifications': settings.generalNotifications,
          'sound_enabled': settings.soundEnabled,
          'vibration_enabled': settings.vibrationEnabled,
        }),
      );
      return true;
    } catch (e) {
      print('Error saving notification settings: $e');
      return false;
    }
  }

  /// چک کردن آیا اعلان‌های چت فعال هستند یا نه
  static Future<bool> isChatNotificationEnabled() async {
    final settings = await getSettings();
    return settings.chatNotifications;
  }

  /// چک کردن آیا اعلان‌های برنامه‌های مربی فعال هستند یا نه
  static Future<bool> isWorkoutNotificationEnabled() async {
    final settings = await getSettings();
    return settings.workoutReminders;
  }

  /// چک کردن آیا اعلان‌های درخواست دوستی فعال هستند یا نه
  static Future<bool> isFriendRequestNotificationEnabled() async {
    final settings = await getSettings();
    return settings
        .achievementNotifications; // Using this field for friend requests
  }

  /// چک کردن آیا اعلان‌های درخواست مربی فعال هستند یا نه
  static Future<bool> isTrainerRequestNotificationEnabled() async {
    final settings = await getSettings();
    return settings.mealReminders; // Using this field for trainer requests
  }

  /// چک کردن آیا اعلان‌های پیام مربی فعال هستند یا نه
  static Future<bool> isTrainerMessageNotificationEnabled() async {
    final settings = await getSettings();
    return settings.weightReminders; // Using this field for trainer messages
  }

  /// چک کردن آیا اعلان‌های عمومی فعال هستند یا نه
  static Future<bool> isGeneralNotificationEnabled() async {
    final settings = await getSettings();
    return settings.generalNotifications;
  }

  /// چک کردن آیا صدا فعال است یا نه
  static Future<bool> isSoundEnabled() async {
    final settings = await getSettings();
    return settings.soundEnabled;
  }

  /// چک کردن آیا لرزش فعال است یا نه
  static Future<bool> isVibrationEnabled() async {
    final settings = await getSettings();
    return settings.vibrationEnabled;
  }
}
