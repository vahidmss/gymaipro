import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_clear_service.dart';
import 'package:gymaipro/academy/services/article_service.dart';
import 'package:gymaipro/academy/services/article_stats_cache_service.dart';
import 'package:gymaipro/achievements/services/achievement_database_service.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/chat/services/chat_presence_service.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/core/foreground_resume_coordinator.dart';
import 'package:gymaipro/core/startup_bootstrap.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سرویس مرکزی برای پاک کردن تمام کش‌ها و داده‌های کاربر هنگام logout
/// این سرویس اطمینان می‌دهد که هیچ اطلاعاتی از کاربر قبلی باقی نماند
class LogoutCacheClearService {
  /// پاک کردن تمام کش‌ها و داده‌های کاربر
  static Future<void> clearAllUserData() async {
    if (kDebugMode) {
      print('=== LOGOUT: شروع پاک کردن تمام کش‌ها و داده‌های کاربر ===');
    }

    try {
      // 1. پاک کردن کش‌های اصلی
      await _clearMainCaches();

      // 2. پاک کردن کش‌های AI و چت
      await _clearAICaches();

      // 3. پاک کردن کش‌های دیگر
      await _clearOtherCaches();

      // 4. پاک کردن داده‌های meal log از SharedPreferences
      await _clearMealLogData();

      // 5. پاک کردن سایر داده‌های کاربر از SharedPreferences
      await _clearUserSpecificSharedPreferences();

      if (kDebugMode) {
        print('=== LOGOUT: تمام کش‌ها و داده‌های کاربر با موفقیت پاک شدند ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('=== LOGOUT: خطا در پاک کردن کش‌ها: $e ===');
      }
      // حتی اگر خطایی رخ داد، ادامه می‌دهیم تا بقیه کش‌ها پاک شوند
    }
  }

  /// پاک کردن کش‌های اصلی
  static Future<void> _clearMainCaches() async {
    try {
      DashboardCacheService().invalidateAll();
      FoodService().clearCache();
      ExerciseService().clearCache();
      SimpleProfileService.invalidateCache();

      // ریست حالت در حافظه دستاوردها و امتیاز تا کاربر بعدی داده قبلی نبیند
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

  /// پاک کردن کش‌های AI و چت
  static Future<void> _clearAICaches() async {
    try {
      await CoachPersistenceClearService.clearLocalCoachData();

      // پاک کردن داده‌های حضور در چت
      final chatPresenceService = ChatPresenceService();
      await chatPresenceService.clearAllPresence();
      await ChatService().clearAllCaches();

      if (kDebugMode) {
        print('✅ کش‌های AI و چت پاک شدند');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ خطا در پاک کردن کش‌های AI: $e');
      }
    }
  }

  /// پاک کردن کش‌های دیگر
  static Future<void> _clearOtherCaches() async {
    try {
      // پاک کردن کش دستاوردها (همه کش‌های achievement)
      await AchievementDatabaseService.clearAllAchievementCaches();

      // پاک کردن کش مقالات
      await ArticleService.clearCache();

      // پاک کردن کش آمار مقالات
      ArticleStatsCacheService.clearCache();

      // پاک کردن کش رتبه‌بندی مربیان
      await TrainerRankingService.clearCache();

      // توجه: کش ویدیو و موزیک پاک نمی‌شوند چون فایل‌های دانلود شده هستند
      // و باید برای همه کاربران در دسترس باشند

      // پاک کردن navigation pending (مستقیماً از SharedPreferences)
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

  /// پاک کردن داده‌های meal log از SharedPreferences
  static Future<void> _clearMealLogData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // پاک کردن تمام کلیدهای مربوط به food log
      final logKeys = keys.where((k) => 
        k.startsWith('food_log_ ') || 
        k.startsWith('food_log_last_session_ ') ||
        k.startsWith('food_log_last_plan_ ')
      ).toList();

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

  /// پاک کردن سایر داده‌های کاربر از SharedPreferences
  /// این متد تمام کلیدهایی که ممکن است مربوط به کاربر باشند را پاک می‌کند
  static Future<void> _clearUserSpecificSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // لیست پیشوندهای کلیدهایی که باید پاک شوند
      // coach + legacy ai keys are cleared in CoachPersistenceClearService
      final prefixesToRemove = [
        'achievements_cache',
        'achievements_last_sync',
        'pending_navigation',
        // coach + legacy ai keys are cleared in CoachPersistenceClearService
      ];

      int removedCount = 0;
      for (final key in keys) {
        // بررسی اینکه آیا کلید با یکی از پیشوندها شروع می‌شود
        final shouldRemove = prefixesToRemove.any(key.startsWith);
        
        if (shouldRemove) {
          await prefs.remove(key);
          removedCount++;
        }
      }

      if (kDebugMode) {
        print('✅ سایر داده‌های کاربر از SharedPreferences پاک شدند ($removedCount کلید)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ خطا در پاک کردن SharedPreferences: $e');
      }
    }
  }
}

