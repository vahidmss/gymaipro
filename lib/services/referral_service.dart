import 'package:flutter/foundation.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت سیستم دعوت و کد معرف
/// کد معرف همان username کاربر است
class ReferralService {
  factory ReferralService() => _instance;
  ReferralService._internal();
  static final ReferralService _instance = ReferralService._internal();
  final SupabaseClient _client = Supabase.instance.client;
  final ProfileRepository _profiles = ProfileRepository.instance;

  /// ثبت کد معرف هنگام ثبت‌نام
  /// [referrerUsername] نام کاربری شخصی که دعوت کرده است
  /// [newUserId] شناسه کاربر جدید که ثبت‌نام می‌کند
  Future<bool> registerReferral({
    required String referrerUsername,
    required String newUserId,
  }) async {
    try {
      final referrerProfile =
          await _profiles.fetchProfileByUsername(referrerUsername);

      if (referrerProfile == null) {
        debugPrint('⚠️ Referrer not found: $referrerUsername');
        return false;
      }

      final referrerId = referrerProfile['id'] as String;

      if (referrerId == newUserId) {
        debugPrint('⚠️ User cannot refer themselves');
        return false;
      }

      final newUserProfile = await _profiles.fetchProfile(newUserId);
      if (newUserProfile != null) {
        final existingReferrer = newUserProfile['referrer_username'] as String?;
        if (existingReferrer != null && existingReferrer.isNotEmpty) {
          debugPrint('⚠️ User already has a referrer: $existingReferrer');
          return false;
        }
      }

      await _client
          .from('profiles')
          .update({
            'referrer_username': referrerUsername,
            'referred_at': DateTime.now().toIso8601String(),
          })
          .eq('id', newUserId);

      await _incrementReferralCount(referrerId);

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
      try {
        await _client.rpc<dynamic>(
          'increment_referral_count',
          params: {'user_id': userId},
        );
      } catch (_) {
        throw Exception('RPC not available');
      }
    } catch (e) {
      try {
        final profile = await _profiles.fetchProfile(userId);
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

      final profile = await _profiles.fetchProfileByUsername(username);

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

      return _profiles.fetchProfilesByReferrerUsername(username);
    } catch (e) {
      debugPrint('❌ Error getting referred users: $e');
      return [];
    }
  }
}
