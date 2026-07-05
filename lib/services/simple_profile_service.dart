import 'package:flutter/foundation.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/dashboard/services/dashboard_profile_mapper.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Removed dependency on ProfileService to keep a single source if we deprecate it

class SimpleProfileService {
  static SupabaseClient get client => Supabase.instance.client;

  // In-memory cache to prevent repeated Supabase queries/rebuild churn
  static Map<String, dynamic>? _cachedProfile;
  static DateTime? _cachedProfileAt;
  static Future<Map<String, dynamic>?>? _inFlightProfile;
  static const Duration _profileCacheTtl = Duration(seconds: 45);

  static void _log(String msg) {
    if (kDebugMode) {
      // Using print for consistency with existing logs
      // ignore: avoid_print
      debugPrint(msg);
    }
  }

  static void invalidateCache() {
    _cachedProfile = null;
    _cachedProfileAt = null;
    _inFlightProfile = null;
  }

  static void _warmDashboardProfileCache(Map<String, dynamic> profile) {
    try {
      final userId = profile['id']?.toString();
      final currentUserId = client.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) return;
      if (currentUserId != null &&
          userId != currentUserId &&
          profile['auth_user_id']?.toString() != currentUserId) {
        return;
      }
      DashboardCacheService().setProfileData(
        DashboardProfileMapper.fromRaw(profile),
      );
    } catch (_) {}
  }

  static const Set<String> _presenceOnlyKeys = {
    'last_active_at',
    'last_seen_at',
    'is_online',
    'updated_at',
  };

  static bool _isPresenceOnlyUpdate(Map<String, dynamic> updates) {
    if (updates.isEmpty) return false;
    return updates.keys.every(_presenceOnlyKeys.contains);
  }

  static void _patchCachedProfile(Map<String, dynamic> updates) {
    if (_cachedProfile == null) return;
    _cachedProfile!.addAll(updates);
    _cachedProfileAt = DateTime.now();
  }

  static List<String> _phoneVariants(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const [];

    // Keep digits-only for normalization
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const [];

    // Try common Iran formats: 09xxxxxxxxx, 9xxxxxxxxx, +989xxxxxxxxx, 989xxxxxxxxx
    String to09(String d) {
      var v = d;
      if (v.startsWith('0098')) v = v.substring(4);
      if (v.startsWith('98')) v = v.substring(2);
      if (v.startsWith('0')) v = v.substring(1);
      return '0$v';
    }

    String to9(String d) {
      var v = d;
      if (v.startsWith('0098')) v = v.substring(4);
      if (v.startsWith('98')) v = v.substring(2);
      if (v.startsWith('0')) v = v.substring(1);
      return v;
    }

    final v09 = to09(digits);
    final v9 = to9(digits);
    final v989 = '98$v9';
    final vPlus989 = '+98$v9';
    final v00989 = '0098$v9';

    return <String>{
      trimmed,
      digits,
      v09,
      v9,
      v989,
      vPlus989,
      v00989,
    }.where((v) => v.trim().isNotEmpty).toList();
  }

  static Future<void> _bestEffortLinkAuthUser({
    required Map<String, dynamic> profile,
    required String authUserId,
  }) async {
    try {
      final profileId = (profile['id'] as String?)?.trim();
      if (profileId == null || profileId.isEmpty) return;

      final existing = (profile['auth_user_id'] as String?)?.trim();
      if (existing == authUserId) return;

      await client
          .from('profiles')
          .update({'auth_user_id': authUserId})
          .eq('id', profileId);

      // Update in-memory map to keep it consistent for the current session
      profile['auth_user_id'] = authUserId;
      _log(
        '=== SIMPLE PROFILE SERVICE: Linked auth_user_id for profile $profileId ===',
      );
    } catch (e) {
      // Best-effort: do not fail profile load if policy blocks the update
      _log('=== SIMPLE PROFILE SERVICE: Failed to link auth_user_id: $e ===');
    }
  }

  // تست کاربر فعلی
  static Future<void> testCurrentUser() async {
    _log('=== TESTING CURRENT USER ===');

    final authUser = client.auth.currentUser;
    _log('Auth user: ${authUser?.id}');

    // mock removed

    final profile = await getCurrentProfile();
    _log('Profile found: ${profile != null}');
    if (profile != null) {
      _log('Profile username: ${profile['username']}');
      _log('Profile phone: ${profile['phone_number']}');
    }

    _log('=== END TEST ===');
  }

  /// نقش کاربر از کش در حافظه (بدون درخواست شبکه).
  static String? get cachedRole {
    if (_cachedProfile == null || _cachedProfileAt == null) return null;
    if (DateTime.now().difference(_cachedProfileAt!) >= _profileCacheTtl) {
      return null;
    }
    return (_cachedProfile!['role'] as String?) ?? 'athlete';
  }

  /// شناسهٔ پروفایل از کش در حافظه (بدون درخواست شبکه).
  static String? get cachedProfileId {
    if (_cachedProfile == null || _cachedProfileAt == null) return null;
    if (DateTime.now().difference(_cachedProfileAt!) >= _profileCacheTtl) {
      return null;
    }
    final id = _cachedProfile!['id'];
    if (id is String && id.isNotEmpty) return id;
    return null;
  }

  // دریافت پروفایل کاربر فعلی
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      // Serve from cache if still valid
      if (_cachedProfile != null && _cachedProfileAt != null) {
        final age = DateTime.now().difference(_cachedProfileAt!);
        if (age < _profileCacheTtl) return _cachedProfile;
      }

      // Deduplicate concurrent calls (many screens/services call this together)
      if (_inFlightProfile != null) return await _inFlightProfile;

      _inFlightProfile = () async {
        _log('=== SIMPLE PROFILE SERVICE: Getting current profile ===');

        // دریافت شناسه کاربر واقعی
        final userId = await AuthHelper.getCurrentUserId();
        if (userId == null) {
          _log(
            '=== SIMPLE PROFILE SERVICE: No authenticated user found anywhere ===',
          );
          return null;
        }

        _log(
          '=== SIMPLE PROFILE SERVICE: Getting profile for user: $userId ===',
        );
        // 1) Preferred: match by auth_user_id (new professional linkage)
        var response = await client
            .from('profiles')
            .select()
            .eq('auth_user_id', userId)
            .maybeSingle();

        // 2) Fallback: legacy schema where profiles.id == auth.users.id
        response ??= await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (response != null) {
          // Self-heal linkage if needed (best effort)
          await _bestEffortLinkAuthUser(profile: response, authUserId: userId);
          _log(
            '=== SIMPLE PROFILE SERVICE: Profile found: ${response['username']} ===',
          );
          _log(
            '=== SIMPLE PROFILE SERVICE: Profile phone: ${response['phone_number']} ===',
          );
          _log(
            '=== SIMPLE PROFILE SERVICE: Profile role: ${response['role']} ===',
          );
          _cachedProfile = response;
          _cachedProfileAt = DateTime.now();
          _warmDashboardProfileCache(response);
          return response;
        }
        _log(
          '=== SIMPLE PROFILE SERVICE: No profile found for user: $userId ===',
        );

        // fallback امن: تلاش برای پیدا کردن پروفایل با شماره‌ای که هنگام لاگین ذخیره کردیم
        try {
          final prefs = await SharedPreferences.getInstance();
          final phoneFromPrefs = prefs.getString('last_logged_in_phone_number');
          final authPhone = client.auth.currentUser?.phone;
          final candidates = <String>{
            ..._phoneVariants(phoneFromPrefs ?? ''),
            ..._phoneVariants(authPhone ?? ''),
          }.toList();

          if (candidates.isNotEmpty) {
            final profileByPhone = await client
                .from('profiles')
                .select()
                .inFilter('phone_number', candidates)
                .maybeSingle();
            if (profileByPhone != null) {
              _log(
                '=== SIMPLE PROFILE SERVICE: Profile found by phone fallback ===',
              );
              // Self-heal linkage if needed (best effort)
              await _bestEffortLinkAuthUser(
                profile: profileByPhone,
                authUserId: userId,
              );
              _cachedProfile = profileByPhone;
              _cachedProfileAt = DateTime.now();
              _warmDashboardProfileCache(profileByPhone);
              return profileByPhone;
            }
          }
        } catch (e) {
          _log('=== SIMPLE PROFILE SERVICE: phone fallback failed: $e ===');
        }

        // هیچ پروفایلی پیدا نشد
        return null;
      }();

      final result = await _inFlightProfile;
      return result;
    } catch (e) {
      _log('=== SIMPLE PROFILE SERVICE: Error getting profile: $e ===');
      return null;
    } finally {
      _inFlightProfile = null;
    }
  }

  /// Helper function برای query کردن profile کاربر فعلی با select خاص
  /// از همان منطق SimpleProfileService استفاده می‌کند (auth_user_id اول، سپس id)
  static Future<Map<String, dynamic>?> queryCurrentUserProfile({
    String select = '*',
  }) async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return null;

      // 1) Preferred: match by auth_user_id
      var response = await client
          .from('profiles')
          .select(select)
          .eq('auth_user_id', userId)
          .maybeSingle();

      // 2) Fallback: legacy schema where profiles.id == auth.users.id
      response ??= await client
          .from('profiles')
          .select(select)
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      _log('Error querying current user profile: $e');
      return null;
    }
  }

  // به‌روزرسانی پروفایل
  static Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      // IMPORTANT:
      // In this project, `profiles.id` can be different from `auth.users.id` for legacy data.
      // Always update the effective profile id we actually loaded (includes phone fallback).
      final currentProfile = await getCurrentProfile();
      final profileId = currentProfile?['id'] as String?;
      if (profileId == null || profileId.isEmpty) {
        debugPrint('No profile found to update');
        return false;
      }

      // حذف فیلدهای غیرضروری از updates
      final cleanUpdates = Map<String, dynamic>.from(updates);
      cleanUpdates.remove('id'); // حذف id از updates
      cleanUpdates.remove('created_at'); // حذف created_at از updates
      // نقش فقط از طریق AdminService قابل تغییر است؛ جلوگیری از بازنویسی تصادفی
      cleanUpdates.remove('role');
      // username را تنها در صورتی حذف می‌کنیم که مقدار آن رشته خالی باشد
      if (cleanUpdates['username'] == null ||
          (cleanUpdates['username'] is String &&
              (cleanUpdates['username'] as String).isEmpty)) {
        cleanUpdates.remove('username');
      }

      // تبدیل فیلدهای numeric از string به double
      for (final key in [
        'weight',
        'height',
        'arm_circumference',
        'chest_circumference',
        'waist_circumference',
        'hip_circumference',
      ]) {
        if (cleanUpdates.containsKey(key) && cleanUpdates[key] != null) {
          final value = cleanUpdates[key];
          if (value is String && value.isNotEmpty) {
            try {
              cleanUpdates[key] = double.parse(value);
            } catch (e) {
              debugPrint('Error parsing $key as double: $e');
              cleanUpdates.remove(key);
            }
          } else if (value == '' || value == null) {
            cleanUpdates.remove(key);
          }
        }
      }

      cleanUpdates['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final presenceOnly = _isPresenceOnlyUpdate(cleanUpdates);
      if (!presenceOnly) {
        debugPrint('Updating profile for profileId: $profileId');
        debugPrint('Updates: $updates');
        debugPrint('Clean updates: $cleanUpdates');
      }

      if (!presenceOnly) {
        final checkResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name')
            .eq('id', profileId)
            .maybeSingle();

        debugPrint('User check response: $checkResponse');

        if (checkResponse == null) {
          debugPrint('User not found in database!');
          return false;
        }
      }

      final response = await client
          .from('profiles')
          .update(cleanUpdates)
          .eq('id', profileId)
          .select();

      if (!presenceOnly) {
        debugPrint('Profile update response: $response');
      }

      if (response.isNotEmpty) {
        if (presenceOnly) {
          _patchCachedProfile(cleanUpdates);
        } else {
          _log('Profile updated successfully');
          try {
            DashboardCacheService().invalidateDashboard();
          } catch (_) {}
          invalidateCache();
        }
        return true;
      } else {
        if (!presenceOnly) {
          _log('Profile update failed - no response');
        }
        return false;
      }
    } catch (e) {
      _log('Error updating profile: $e');
      return false;
    }
  }

  /// به‌روزرسانی زمان آخرین فعالیت کاربر جاری.
  static Future<void> updateLastActiveAt() async {
    await updateProfile({
      'last_active_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ذخیره نام و نام خانوادگی
  static Future<bool> updateName(String firstName, String lastName) async {
    try {
      final updates = {'first_name': firstName, 'last_name': lastName};

      return await updateProfile(updates);
    } catch (e) {
      debugPrint('Error updating name: $e');
      return false;
    }
  }

  // ذخیره اطلاعات شخصی
  static Future<bool> updatePersonalInfo({
    String? bio,
    DateTime? birthDate,
    double? height,
    double? weight,
    String? gender,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (bio != null) updates['bio'] = bio;
      if (birthDate != null) {
        updates['birth_date'] = birthDate.toIso8601String().split('T')[0];
      }
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (gender != null) updates['gender'] = gender;

      return await updateProfile(updates);
    } catch (e) {
      debugPrint('Error updating personal info: $e');
      return false;
    }
  }

  // ذخیره اطلاعات فیزیکی
  static Future<bool> updatePhysicalInfo({
    double? armCircumference,
    double? chestCircumference,
    double? waistCircumference,
    double? hipCircumference,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (armCircumference != null) {
        updates['arm_circumference'] = armCircumference;
      }
      if (chestCircumference != null) {
        updates['chest_circumference'] = chestCircumference;
      }
      if (waistCircumference != null) {
        updates['waist_circumference'] = waistCircumference;
      }
      if (hipCircumference != null) {
        updates['hip_circumference'] = hipCircumference;
      }

      return await updateProfile(updates);
    } catch (e) {
      debugPrint('Error updating physical info: $e');
      return false;
    }
  }

  // ذخیره اهداف تناسب اندام
  static Future<bool> updateFitnessGoals(List<String> goals) async {
    try {
      return await updateProfile({'fitness_goals': goals});
    } catch (e) {
      debugPrint('Error updating fitness goals: $e');
      return false;
    }
  }

  // ذخیره شرایط پزشکی
  static Future<bool> updateMedicalConditions(List<String> conditions) async {
    try {
      return await updateProfile({'medical_conditions': conditions});
    } catch (e) {
      debugPrint('Error updating medical conditions: $e');
      return false;
    }
  }

  // ذخیره ترجیحات غذایی
  static Future<bool> updateDietaryPreferences(List<String> preferences) async {
    try {
      return await updateProfile({'dietary_preferences': preferences});
    } catch (e) {
      debugPrint('Error updating dietary preferences: $e');
      return false;
    }
  }

  // ذخیره سطح تجربه
  static Future<bool> updateExperienceLevel(String level) async {
    try {
      return await updateProfile({'experience_level': level});
    } catch (e) {
      debugPrint('Error updating experience level: $e');
      return false;
    }
  }

  // ذخیره روزهای تمرین ترجیحی
  static Future<bool> updatePreferredTrainingDays(List<String> days) async {
    try {
      return await updateProfile({'preferred_training_days': days});
    } catch (e) {
      debugPrint('Error updating preferred training days: $e');
      return false;
    }
  }

  // ذخیره زمان تمرین ترجیحی
  static Future<bool> updatePreferredTrainingTime(String time) async {
    try {
      return await updateProfile({'preferred_training_time': time});
    } catch (e) {
      debugPrint('Error updating preferred training time: $e');
      return false;
    }
  }
}
