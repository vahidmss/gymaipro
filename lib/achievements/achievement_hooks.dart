import 'package:flutter/foundation.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// هوک‌های سبک برای سیم‌کشی دستاوردها از سرویس‌های دامنه.
abstract final class AchievementHooks {
  static Future<void> setProgress(String achievementId, int value) async {
    try {
      await AchievementService.instance.updateProgress(achievementId, value);
    } catch (e) {
      debugPrint('⚠️ AchievementHooks.setProgress($achievementId): $e');
    }
  }

  static Future<void> unlockOnce(String achievementId) =>
      setProgress(achievementId, 1);

  /// اگر کاربر برنامه تمرین/رژیم دارد، دستاورد مربوط را باز کن.
  static Future<void> syncOwnedPrograms() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final profileId = profile?['id'] as String?;
      if (profileId == null || profileId.isEmpty) return;

      final client = Supabase.instance.client;
      final workout = await client
          .from('workout_programs')
          .select('id')
          .eq('user_id', profileId)
          .limit(1)
          .maybeSingle();
      if (workout != null) {
        await unlockOnce('get_exercise_program');
      }

      final meal = await client
          .from('meal_plans')
          .select('id')
          .eq('user_id', profileId)
          .limit(1)
          .maybeSingle();
      if (meal != null) {
        await unlockOnce('get_diet_program');
      }
    } catch (e) {
      debugPrint('⚠️ AchievementHooks.syncOwnedPrograms: $e');
    }
  }
}
