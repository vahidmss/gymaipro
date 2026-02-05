import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Resolve a profile by either `profiles.id` (legacy) or `profiles.auth_user_id` (new linkage).
  static Future<Map<String, dynamic>?> fetchProfile(String userIdOrAuthId) async {
    // 1) Preferred/fast path: profiles.id
    final byId = await _client
        .from('profiles')
        .select()
        .eq('id', userIdOrAuthId)
        .maybeSingle();
    if (byId != null) return Map<String, dynamic>.from(byId);

    // 2) Fallback: auth_user_id (when profiles.id != auth.users.id)
    final byAuth = await _client
        .from('profiles')
        .select()
        .eq('auth_user_id', userIdOrAuthId)
        .maybeSingle();
    if (byAuth != null) return Map<String, dynamic>.from(byAuth);

    return null;
  }

  /// دریافت آمار کاربر (تعداد برنامه‌ها، مربیان، دوستان و...)
  static Future<Map<String, int>> getUserStats(String userIdOrAuthId) async {
    try {
      // Most tables use `profiles.id` as the user identifier.
      final profile = await fetchProfile(userIdOrAuthId);
      final userId = (profile?['id'] ?? userIdOrAuthId).toString();
      if (userId.isEmpty) {
        return {
          'active_programs': 0,
          'total_programs': 0,
          'active_trainers': 0,
          'friends': 0,
        };
      }

      // تعداد برنامه‌های تمرینی ارسال شده (فعال)
      List<dynamic> activeWorkoutPrograms;
      try {
        activeWorkoutPrograms = await _client
            .from('workout_programs')
            .select('id')
            .eq('user_id', userId)
            .eq('is_deleted', false)
            .not('sent_at', 'is', null);
      } catch (_) {
        activeWorkoutPrograms = await _client
            .from('workout_programs')
            .select('id')
            .eq('user_id', userId)
            .eq('is_deleted', false);
      }

      // تعداد کل برنامه‌های تمرینی (حذف نشده)
      List<dynamic> totalWorkoutPrograms;
      try {
        totalWorkoutPrograms = await _client
            .from('workout_programs')
            .select('id')
            .eq('user_id', userId)
            .eq('is_deleted', false);
      } catch (_) {
        totalWorkoutPrograms = [];
      }

      // تعداد برنامه‌های تغذیه ارسال شده (فعال)
      int activeNutritionPrograms = 0;
      int totalNutritionPrograms = 0;
      try {
        final nutritionStats = await _client
            .from('meal_plans')
            .select('id, sent_at')
            .eq('user_id', userId)
            .eq('is_deleted', false);
        totalNutritionPrograms = nutritionStats.length;
        activeNutritionPrograms = nutritionStats
            .where((p) => p['sent_at'] != null)
            .length;
      } catch (_) {
        // جدول وجود ندارد
      }

      // تعداد مربیان فعال
      final trainerStats = await _client
          .from('trainer_clients')
          .select('id')
          .eq('client_id', userId)
          .eq('status', 'active');

      // تعداد دوستان
      final friendStats = await _client
          .from('user_friends')
          .select('id')
          .or('user_id.eq.$userId,friend_id.eq.$userId');

      final activePrograms =
          activeWorkoutPrograms.length + activeNutritionPrograms;
      final totalPrograms =
          totalWorkoutPrograms.length + totalNutritionPrograms;

      return {
        'active_programs': activePrograms,
        'total_programs': totalPrograms,
        'active_trainers': trainerStats.length,
        'friends': friendStats.length,
      };
    } catch (e) {
      print('خطا در دریافت آمار کاربر: $e');
      return {
        'active_programs': 0,
        'total_programs': 0,
        'active_trainers': 0,
        'friends': 0,
      };
    }
  }
}
