import 'package:flutter/foundation.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت سیستم دعوت و کد معرف
/// کد معرف همان username کاربر است
class ReferralService {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal();
  final SupabaseClient _client = Supabase.instance.client;

  /// ثبت کد معرف هنگام ثبت‌نام
  /// [referrerUsername] نام کاربری شخصی که دعوت کرده است
  /// [newUserId] شناسه کاربر جدید که ثبت‌نام می‌کند
  Future<bool> registerReferral({
    required String referrerUsername,
    required String newUserId,
  }) async {
    try {
      // بررسی اینکه referrer وجود دارد
      final referrerProfile = await _client
          .from('profiles')
          .select('id, username')
          .eq('username', referrerUsername)
          .maybeSingle();

      if (referrerProfile == null) {
        debugPrint('⚠️ Referrer not found: $referrerUsername');
        return false;
      }

      final referrerId = referrerProfile['id'] as String;

      // بررسی اینکه کاربر خودش را دعوت نکرده باشد
      if (referrerId == newUserId) {
        debugPrint('⚠️ User cannot refer themselves');
        return false;
      }

      // بررسی اینکه کاربر قبلاً کد معرف نداشته باشد
      final newUserProfile = await _client
          .from('profiles')
          .select('referrer_username')
          .eq('id', newUserId)
          .maybeSingle();

      if (newUserProfile != null) {
        final existingReferrer = newUserProfile['referrer_username'] as String?;
        if (existingReferrer != null && existingReferrer.isNotEmpty) {
          debugPrint('⚠️ User already has a referrer: $existingReferrer');
          return false;
        }
      }

      // ثبت referral در پروفایل کاربر جدید
      await _client
          .from('profiles')
          .update({
            'referrer_username': referrerUsername,
            'referred_at': DateTime.now().toIso8601String(),
          })
          .eq('id', newUserId);

      // افزایش تعداد referrals کاربر دعوت‌کننده
      await _incrementReferralCount(referrerId);

      // به‌روزرسانی دستاوردهای invite
      await _updateInviteAchievements(referrerId);

      debugPrint('✅ Referral registered: $referrerUsername -> $newUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error registering referral: $e');
      return false;
    }
  }

  /// افزایش تعداد referrals کاربر
  Future<void> _incrementReferralCount(String userId) async {
    try {
      // استفاده از RPC یا update با increment
      try {
        await _client.rpc<dynamic>(
          'increment_referral_count',
          params: {'user_id': userId},
        );
      } catch (_) {
        // اگر RPC وجود نداشت، از روش fallback استفاده می‌کنیم
        throw Exception('RPC not available');
      }
    } catch (e) {
      // Fallback: استفاده از select + update
      try {
        final profile = await _client
            .from('profiles')
            .select('total_referrals')
            .eq('id', userId)
            .maybeSingle();

        if (profile != null) {
          final currentCount = (profile['total_referrals'] as int?) ?? 0;
          await _client
              .from('profiles')
              .update({'total_referrals': currentCount + 1})
              .eq('id', userId);
        }
      } catch (e2) {
        debugPrint('❌ Error incrementing referral count: $e2');
      }
    }
  }

  /// به‌روزرسانی دستاوردهای invite
  Future<void> _updateInviteAchievements(String userId) async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) return;

      final totalReferrals = (profile['total_referrals'] as int?) ?? 0;

      final achievementService = AchievementService.instance;

      // به‌روزرسانی دستاوردهای invite
      await achievementService.updateProgress('invite_1', totalReferrals);
      await achievementService.updateProgress('invite_3', totalReferrals);
      await achievementService.updateProgress('invite_10', totalReferrals);
      await achievementService.updateProgress('invite_30', totalReferrals);

      debugPrint('✅ Invite achievements updated: $totalReferrals referrals');
    } catch (e) {
      debugPrint('❌ Error updating invite achievements: $e');
    }
  }

  /// دریافت تعداد referrals کاربر فعلی
  Future<int> getTotalReferrals() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) return 0;

      return (profile['total_referrals'] as int?) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting total referrals: $e');
      return 0;
    }
  }

  /// دریافت username کاربری که این کاربر را دعوت کرده است
  Future<String?> getReferrerUsername() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) return null;

      return profile['referrer_username'] as String?;
    } catch (e) {
      debugPrint('❌ Error getting referrer username: $e');
      return null;
    }
  }

  /// بررسی اینکه آیا username معتبر است (برای کد معرف)
  Future<bool> isValidReferrerUsername(String username) async {
    try {
      if (username.isEmpty) return false;

      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      // بررسی اینکه کاربر خودش را دعوت نکند
      final currentUser = _client.auth.currentUser;
      if (currentUser != null && profile != null) {
        final profileId = profile['id'] as String;
        if (profileId == currentUser.id) {
          return false;
        }
      }

      return profile != null;
    } catch (e) {
      debugPrint('❌ Error validating referrer username: $e');
      return false;
    }
  }

  /// دریافت لیست کاربرانی که این کاربر دعوت کرده است
  Future<List<Map<String, dynamic>>> getReferredUsers() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return [];

      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) return [];

      final username = profile['username'] as String?;
      if (username == null || username.isEmpty) return [];

      final response = await _client
          .from('profiles')
          .select(
            'id, username, first_name, last_name, avatar_url, referred_at',
          )
          .eq('referrer_username', username)
          .order('referred_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting referred users: $e');
      return [];
    }
  }
}
