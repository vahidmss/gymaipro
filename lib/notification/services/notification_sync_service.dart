import 'package:flutter/foundation.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/notification/services/notification_settings_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSyncService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// همگام‌سازی تنظیمات اعلان‌ها از SharedPreferences به دیتابیس
  static Future<bool> syncSettingsToDatabase() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No user found for sync');
        return false;
      }

      // دریافت تنظیمات از SharedPreferences
      final settings = await NotificationSettingsService.getSettings();
      debugPrint(
        '📱 Local settings: chat_notifications=${settings.chatNotifications}',
      );

      // استفاده از upsert ساده
      final response = await _client
          .from('user_notification_settings')
          .upsert({
            'user_id': user.id,
            'chat_notifications': settings.chatNotifications,
            'workout_notifications': settings.workoutReminders,
            'friend_request_notifications': settings.achievementNotifications,
            'trainer_request_notifications': settings.mealReminders,
            'trainer_message_notifications': settings.weightReminders,
            'general_notifications': settings.generalNotifications,
            'sound_enabled': settings.soundEnabled,
            'vibration_enabled': settings.vibrationEnabled,
          }, onConflict: 'user_id')
          .timeout(const Duration(seconds: 5));

      if (response != null && response.error != null) {
        debugPrint('❌ Database sync error: ${response.error}');
        return false;
      }

      debugPrint('✅ Settings synced to database successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error syncing notification settings: $e');
      return false;
    }
  }

  /// همگام‌سازی تنظیمات اعلان‌ها از دیتابیس به SharedPreferences
  static Future<bool> syncSettingsFromDatabase() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      // دریافت تنظیمات از دیتابیس
      final response = await _client
          .from('user_notification_settings')
          .select()
          .eq('user_id', user.id)
          .single();

      // تبدیل به NotificationSettingsModel
      final settings = NotificationSettingsModel(
        chatNotifications: (response['chat_notifications'] as bool?) ?? true,
        workoutReminders: (response['workout_notifications'] as bool?) ?? true,
        achievementNotifications:
            (response['friend_request_notifications'] as bool?) ?? true,
        mealReminders:
            (response['trainer_request_notifications'] as bool?) ?? true,
        weightReminders:
            (response['trainer_message_notifications'] as bool?) ?? true,
        generalNotifications:
            (response['general_notifications'] as bool?) ?? true,
        soundEnabled: (response['sound_enabled'] as bool?) ?? true,
        vibrationEnabled: (response['vibration_enabled'] as bool?) ?? true,
      );

      // ذخیره در SharedPreferences
      await NotificationSettingsService.saveSettings(settings);
      return true;
    } catch (e) {
      debugPrint('Error syncing settings from database: $e');
    }
    return false;
  }

  /// چک کردن آیا تنظیمات در دیتابیس وجود دارد یا نه
  static Future<bool> hasDatabaseSettings() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('user_notification_settings')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking database settings: $e');
      return false;
    }
  }

  /// پاک کردن تنظیمات از دیتابیس
  static Future<bool> clearDatabaseSettings() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No user found for clear');
        return false;
      }

      // حذف تنظیمات از دیتابیس
      final response = await _client
          .from('user_notification_settings')
          .delete()
          .eq('user_id', user.id)
          .timeout(const Duration(seconds: 5));

      // delete در Supabase ممکن است null برگرداند
      if (response != null && response.error != null) {
        debugPrint('❌ Clear settings error: ${response.error}');
        return false;
      }

      debugPrint('✅ Settings cleared from database successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing settings: $e');
      return false;
    }
  }

  /// حذف تنظیمات قبلی و ایجاد جدید
  static Future<bool> forceSyncSettings() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No user found for force sync');
        return false;
      }

      // دریافت تنظیمات از SharedPreferences
      final settings = await NotificationSettingsService.getSettings();
      debugPrint(
        '📱 Force sync - Local settings: chat_notifications=${settings.chatNotifications}',
      );

      // استفاده از upsert ساده
      final response = await _client
          .from('user_notification_settings')
          .upsert({
            'user_id': user.id,
            'chat_notifications': settings.chatNotifications,
            'workout_notifications': settings.workoutReminders,
            'friend_request_notifications': settings.achievementNotifications,
            'trainer_request_notifications': settings.mealReminders,
            'trainer_message_notifications': settings.weightReminders,
            'general_notifications': settings.generalNotifications,
            'sound_enabled': settings.soundEnabled,
            'vibration_enabled': settings.vibrationEnabled,
          }, onConflict: 'user_id')
          .timeout(const Duration(seconds: 5));

      if (response != null && response.error != null) {
        debugPrint('❌ Force sync error: ${response.error}');
        return false;
      }

      debugPrint('✅ Force sync completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error in force sync: $e');
      return false;
    }
  }
}
