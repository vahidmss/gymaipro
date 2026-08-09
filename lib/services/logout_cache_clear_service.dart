import 'package:flutter/foundation.dart';
import 'package:gymaipro/academy/services/music_favorite_service.dart';
import 'package:gymaipro/academy/services/workout_music_service.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_clear_service.dart';
import 'package:gymaipro/academy/services/article_service.dart';
import 'package:gymaipro/academy/services/article_stats_cache_service.dart';
import 'package:gymaipro/achievements/services/achievement_database_service.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/ai/services/progress_analysis_storage_service.dart';
import 'package:gymaipro/chat/services/chat_cache_service.dart';
import 'package:gymaipro/chat/services/chat_presence_service.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/core/foreground_resume_coordinator.dart';
import 'package:gymaipro/core/startup_bootstrap.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/meal_log/services/meal_log_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/ranking/services/activity_tracking_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/presence_service.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/trainer_channel/services/trainer_channel_service.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مرکزی برای پاک کردن تمام کش‌ها و داده‌های کاربر هنگام logout / تعویض حساب
class LogoutCacheClearService {
  /// [previousUserId] را هنگام تعویض حساب پاس بده تا کش دیسک چت کاربر قبلی پاک شود
  /// (چون بعد از login، `currentUser` دیگر کاربر جدید است).
  static Future<void> clearAllUserData({String? previousUserId}) async {
    if (kDebugMode) {
      print('=== LOGOUT: شروع پاک کردن تمام کش‌ها و داده‌های کاربر ===');
    }

    final resolvedPreviousUserId = previousUserId ??
        Supabase.instance.client.auth.currentUser?.id;

    try {
      await _clearMainCaches();
      await _clearAICaches(previousUserId: resolvedPreviousUserId);
      await _clearOtherCaches();
      await _clearMealLogData();
      await _clearUserSpecificSharedPreferences();
      await _clearMemorySingletons();

      if (kDebugMode) {
        print('=== LOGOUT: تمام کش‌ها و داده‌های کاربر با موفقیت پاک شدند ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('=== LOGOUT: خطا در پاک کردن کش‌ها: $e ===');
      }
    }
  }

  static Future<void> _clearMainCaches() async {
    try {
      // Dispose realtime so next login rebinds weight channel to new user.
      await DashboardCacheService().dispose();
      FoodService().clearCache();
      await ExerciseService().clearCache();
      SimpleProfileService.invalidateCache();

      AchievementService.instance.resetForLogout();
      ScoreService().resetScore();
      StartupBootstrap.resetOnLogout();
      ForegroundResumeCoordinator.resetOnLogout();

      if (kDebugMode) {
        print('✅ کش‌های اصلی پاک شدند');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ خطا در پاک کردن کش‌های اصلی: $e');
      }
    }
  }

  static Future<void> _clearAICaches({String? previousUserId}) async {
    try {
      await CoachPersistenceClearService.clearLocalCoachData();

      final chatPresenceService = ChatPresenceService();
      await chatPresenceService.clearAllPresence();
      try {
        await PresenceService.instance.markBackground(source: 'logout');
      } catch (_) {}
      await ChatService().clearAllCaches(forUserId: previousUserId);
      ChatCacheService.clearAllMemory();

      if (kDebugMode) {
        print('✅ کش‌های AI و چت پاک شدند');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ خطا در پاک کردن کش‌های AI: $e');
      }
    }
  }

  static Future<void> _clearOtherCaches() async {
    try {
      await AchievementDatabaseService.clearAllAchievementCaches();
      await ArticleService.clearCache();
      ArticleStatsCacheService.clearCache();
      await TrainerRankingService.clearCache();

      // User-tainted music catalog (likes / private trainer tracks).
      await WorkoutMusicService.clearCache();
      await MusicFavoriteService().clearFavorites();

      await ProgressAnalysisStorageService().clearLocalAnalyses();

      // توجه: کش فایل ویدیو/موزیک روی دیسک عمداً نگه داشته می‌شود (اشتراکی).

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_navigation');

      if (kDebugMode) {
        print('✅ کش‌های دیگر پاک شدند');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ خطا در پاک کردن کش‌های دیگر: $e');
      }
    }
  }

  static Future<void> _clearMealLogData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final logKeys = keys
          .where(
            (k) =>
                k.startsWith('food_log_ ') ||
                k.startsWith('food_log_last_session_ ') ||
                k.startsWith('food_log_last_plan_ '),
          )
          .toList();

      for (final key in logKeys) {
        await prefs.remove(key);
      }

      if (kDebugMode) {
        print('✅ داده‌های meal log پاک شدند (${logKeys.length} کلید)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ خطا در پاک کردن داده‌های meal log: $e');
      }
    }
  }

  /// Prefs مربوط به هویت/اجتماع/ورزش کاربر — کاتالوگ عمومی WP عمداً نگه داشته می‌شود.
  static Future<void> _clearUserSpecificSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final prefixesToRemove = <String>[
        'achievements_cache',
        'achievements_last_sync',
        'pending_navigation',
        // Club / social
        'friends_screen_cache',
        'trainers_screen_cache',
        'club_stats_cache',
        'recent_activities_cache',
        // Chat (disk) — also cleared by ChatCacheService, belt-and-suspenders
        'chat_cache_',
        'avatar_url_',
        // Music (user-tainted)
        'academy_workout_music',
        'music_favorites',
        // Workout / health
        'workout_log_',
        'live_workout_draft_',
        'coach_workout_session_',
        'workout_program_',
        'workout_program_draft_',
        'workout_program_token_',
        'progress_analyses',
        'progress_analysis_current',
        'rule_based_recent_exercise_ids_v1',
        // AI context safety net (also cleared in CoachPersistenceClearService)
        'ai_user_context_cache',
      ];

      var removedCount = 0;
      for (final key in keys) {
        if (prefixesToRemove.any(key.startsWith)) {
          await prefs.remove(key);
          removedCount++;
        }
      }

      if (kDebugMode) {
        print(
          '✅ سایر داده‌های کاربر از SharedPreferences پاک شدند ($removedCount کلید)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ خطا در پاک کردن SharedPreferences: $e');
      }
    }
  }

  static Future<void> _clearMemorySingletons() async {
    try {
      WalletService().clearCacheForLogout();
      MealLogService().clearProfileIdCache();
      ActivityTrackingService().clearCachedUserId();
      TrainerChannelService.clearAllCaches();
      WorkoutProgramService().clearMemoryCache();

      if (kDebugMode) {
        print('✅ کش‌های حافظهٔ singleton پاک شدند');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ خطا در پاک کردن singletonها: $e');
      }
    }
  }
}
