import 'package:flutter/foundation.dart';
import 'package:gymaipro/ranking/models/user_activity.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس ردیابی فعالیت‌های خودکار کاربران
/// این سرویس فعالیت‌های واقعی کاربر را ردیابی می‌کند که قابل دستکاری نیستند
class ActivityTrackingService {
  factory ActivityTrackingService() => _instance;
  ActivityTrackingService._internal();
  static final ActivityTrackingService _instance =
      ActivityTrackingService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final String _tableName = 'user_activity_tracking';

  /// افزایش زمان خواندن مقاله
  Future<void> incrementArticleReadingTime(int minutes) async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId == null) return;

      final today = DateTime.now();
      final todayDate = today.toIso8601String().substring(0, 10);

      // دریافت یا ایجاد رکورد امروز
      final existing = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('activity_date', todayDate)
          .maybeSingle();

      if (existing != null) {
        // به‌روزرسانی
        await _client
            .from(_tableName)
            .update({
              'article_reading_minutes':
                  (existing['article_reading_minutes'] as num? ?? 0).toInt() +
                  minutes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('activity_date', todayDate);
      } else {
        // ایجاد جدید
        await _client.from(_tableName).insert({
          'user_id': userId,
          'activity_date': todayDate,
          'article_reading_minutes': minutes,
        });
      }
    } catch (e) {
      debugPrint('❌ Error incrementing article reading time: $e');
    }
  }

  /// افزایش زمان گوش دادن به موزیک
  Future<void> incrementMusicListeningTime(int minutes) async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId == null) return;

      final today = DateTime.now();
      final todayDate = today.toIso8601String().substring(0, 10);

      final existing = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('activity_date', todayDate)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from(_tableName)
            .update({
              'music_listening_minutes':
                  (existing['music_listening_minutes'] as num? ?? 0).toInt() +
                  minutes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('activity_date', todayDate);
      } else {
        await _client.from(_tableName).insert({
          'user_id': userId,
          'activity_date': todayDate,
          'music_listening_minutes': minutes,
        });
      }
    } catch (e) {
      debugPrint('❌ Error incrementing music listening time: $e');
    }
  }

  /// افزایش زمان تماشای ویدیو
  Future<void> incrementVideoWatchingTime(int minutes) async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId == null) return;

      final today = DateTime.now();
      final todayDate = today.toIso8601String().substring(0, 10);

      final existing = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('activity_date', todayDate)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from(_tableName)
            .update({
              'video_watching_minutes':
                  (existing['video_watching_minutes'] as num? ?? 0).toInt() +
                  minutes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('activity_date', todayDate);
      } else {
        await _client.from(_tableName).insert({
          'user_id': userId,
          'activity_date': todayDate,
          'video_watching_minutes': minutes,
        });
      }
    } catch (e) {
      debugPrint('❌ Error incrementing video watching time: $e');
    }
  }

  /// افزایش تعداد تمرینات ثبت شده
  Future<void> incrementWorkoutLogs() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId == null) return;

      final today = DateTime.now();
      final todayDate = today.toIso8601String().substring(0, 10);

      final existing = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('activity_date', todayDate)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from(_tableName)
            .update({
              'workout_logs_count':
                  (existing['workout_logs_count'] as num? ?? 0).toInt() + 1,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('activity_date', todayDate);
      } else {
        await _client.from(_tableName).insert({
          'user_id': userId,
          'activity_date': todayDate,
          'workout_logs_count': 1,
        });
      }
    } catch (e) {
      debugPrint('❌ Error incrementing workout logs: $e');
    }
  }

  /// افزایش تعداد وعده‌های ثبت شده
  Future<void> incrementMealLogs() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId == null) return;

      final today = DateTime.now();
      final todayDate = today.toIso8601String().substring(0, 10);

      final existing = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('activity_date', todayDate)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from(_tableName)
            .update({
              'meal_logs_count':
                  (existing['meal_logs_count'] as num? ?? 0).toInt() + 1,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('activity_date', todayDate);
      } else {
        await _client.from(_tableName).insert({
          'user_id': userId,
          'activity_date': todayDate,
          'meal_logs_count': 1,
        });
      }
    } catch (e) {
      debugPrint('❌ Error incrementing meal logs: $e');
    }
  }

  /// ثبت کالری‌شماری برای امروز
  Future<void> markCalorieCounting() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId == null) return;

      final today = DateTime.now();
      final todayDate = today.toIso8601String().substring(0, 10);

      final existing = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('activity_date', todayDate)
          .maybeSingle();

      if (existing != null) {
        // اگر قبلاً ثبت نشده بود، اضافه کن
        if ((existing['calorie_counting_days'] as num? ?? 0).toInt() == 0) {
          await _client
              .from(_tableName)
              .update({
                'calorie_counting_days': 1,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', userId)
              .eq('activity_date', todayDate);
        }
      } else {
        await _client.from(_tableName).insert({
          'user_id': userId,
          'activity_date': todayDate,
          'calorie_counting_days': 1,
        });
      }
    } catch (e) {
      debugPrint('❌ Error marking calorie counting: $e');
    }
  }

  /// دریافت فعالیت امروز
  Future<UserActivity?> getTodayActivity() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId == null) return null;

      final today = DateTime.now();
      final todayDate = today.toIso8601String().substring(0, 10);

      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('activity_date', todayDate)
          .maybeSingle();

      if (response == null) {
        return UserActivity(userId: userId, activityDate: today);
      }

      return UserActivity.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting today activity: $e');
      return null;
    }
  }

  /// دریافت فعالیت‌های کاربر در بازه زمانی
  Future<List<UserActivity>> getUserActivities({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId == null) return [];
      return getUserActivitiesForUser(
        userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('❌ Error getting user activities: $e');
      return [];
    }
  }

  /// دریافت فعالیت‌های یک کاربر مشخص در بازه زمانی (برای پروفایل دیگران / امتیازدهی)
  Future<List<UserActivity>> getUserActivitiesForUser(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final startDateString = startDate?.toIso8601String().substring(0, 10);
      final endDateString = endDate?.toIso8601String().substring(0, 10);

      var query = _client.from(_tableName).select().eq('user_id', userId);
      if (startDateString != null) {
        query = query.gte('activity_date', startDateString);
      }
      if (endDateString != null) {
        query = query.lte('activity_date', endDateString);
      }

      final response = await query.order('activity_date', ascending: false);
      return (response as List<dynamic>)
          .map<UserActivity>(
            (json) => UserActivity.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting user activities for user: $e');
      return [];
    }
  }
}
