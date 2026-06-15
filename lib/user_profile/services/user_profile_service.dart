import 'package:flutter/foundation.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
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

  /// Build a display label from a raw profile row (no extra query).
  static String displayNameFromMap(
    Map<String, dynamic>? profile, {
    String fallback = 'کاربر ناشناس',
  }) {
    if (profile == null) return fallback;

    final firstName = (profile['first_name'] as String? ?? '').trim();
    final lastName = (profile['last_name'] as String? ?? '').trim();
    final username = (profile['username'] as String? ?? '').trim();
    final phone = (profile['phone_number'] as String? ?? '').trim();

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    if (firstName.isNotEmpty) return firstName;
    if (lastName.isNotEmpty) return lastName;
    if (username.isNotEmpty) return username;
    if (phone.isNotEmpty) {
      return phone.length > 7 ? phone.replaceRange(0, 7, '***') : phone;
    }
    return fallback;
  }

  /// Batch load profiles keyed by auth user id (chat lists, notifications).
  static Future<List<Map<String, dynamic>>> fetchProfilesByAuthUserIds(
    List<String> authUserIds, {
    String columns =
        'auth_user_id, id, first_name, last_name, username, phone_number, role, avatar_url',
  }) async {
    if (authUserIds.isEmpty) return [];
    try {
      final rows = await _client
          .from('profiles')
          .select(columns)
          .inFilter('auth_user_id', authUserIds);
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('fetchProfilesByAuthUserIds: $e');
      return [];
    }
  }

  static const _friendListColumns =
      'id, auth_user_id, username, first_name, last_name, avatar_url, is_online';

  /// Convert profile id to auth.users id when friendship tables expect auth id.
  static Future<String> resolveAuthUserId(String profileOrAuthId) async {
    if (profileOrAuthId.isEmpty) return profileOrAuthId;
    try {
      final byAuth = await _client
          .from('profiles')
          .select('auth_user_id')
          .eq('auth_user_id', profileOrAuthId)
          .maybeSingle();
      if (byAuth != null) return profileOrAuthId;

      final row = await _client
          .from('profiles')
          .select('auth_user_id, id')
          .eq('id', profileOrAuthId)
          .maybeSingle();
      if (row == null) return profileOrAuthId;
      final authId = (row['auth_user_id'] as String?)?.trim();
      if (authId != null && authId.isNotEmpty) return authId;
      return (row['id'] as String?) ?? profileOrAuthId;
    } catch (_) {
      return profileOrAuthId;
    }
  }

  /// Batch load by profiles.id.
  static Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> profileIds, {
    String columns =
        'id, auth_user_id, username, first_name, last_name, avatar_url, role',
  }) async {
    if (profileIds.isEmpty) return [];
    try {
      final rows = await _client
          .from('profiles')
          .select(columns)
          .inFilter('id', profileIds);
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('fetchProfilesByIds: $e');
      return [];
    }
  }

  /// Map keyed by profiles.id — useful for admin lists and program screens.
  static Future<Map<String, Map<String, dynamic>>> fetchProfilesByIdsMap(
    List<String> profileIds, {
    String columns = 'id, username, first_name, last_name, avatar_url',
  }) async {
    final rows = await fetchProfilesByIds(profileIds, columns: columns);
    final map = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = (row['id'] as String?)?.trim();
      if (id != null && id.isNotEmpty) {
        map[id] = row;
      }
    }
    return map;
  }

  /// Identifiers may be auth_user_id or profiles.id (blocked users, mixed lists).
  static Future<List<Map<String, dynamic>>> fetchProfilesByIdentifiers(
    List<String> identifiers, {
    String columns = _friendListColumns,
  }) async {
    if (identifiers.isEmpty) return [];

    final byAuth =
        await fetchProfilesByAuthUserIds(identifiers, columns: columns);
    final seen = <String>{};
    final results = <Map<String, dynamic>>[];
    for (final row in byAuth) {
      final key = _profileIdentifierKey(row);
      if (key == null || seen.contains(key)) continue;
      seen.add(key);
      results.add(row);
    }

    final missing = identifiers.where((id) => !seen.contains(id)).toList();
    if (missing.isEmpty) return results;

    final byId = await fetchProfilesByIds(missing, columns: columns);
    for (final row in byId) {
      final key = _profileIdentifierKey(row);
      if (key == null || seen.contains(key)) continue;
      seen.add(key);
      results.add(row);
    }
    return results;
  }

  static String? _profileIdentifierKey(Map<String, dynamic> row) {
    final authId = (row['auth_user_id'] as String?)?.trim();
    if (authId != null && authId.isNotEmpty) return authId;
    return (row['id'] as String?)?.trim();
  }

  static Future<List<Map<String, dynamic>>> searchByUsername(
    String query, {
    int limit = 25,
  }) async {
    try {
      final rows = await _client
          .from('profiles')
          .select(_friendListColumns)
          .ilike('username', '%$query%')
          .limit(limit);
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('searchByUsername: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchByUsernameAndRole(
    String query, {
    required String role,
    String columns =
        'id, username, full_name, bio, height, weight, fitness_goals',
    int limit = 25,
  }) async {
    try {
      final rows = await _client
          .from('profiles')
          .select(columns)
          .eq('role', role)
          .ilike('username', '%$query%')
          .order('username')
          .limit(limit);
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('searchByUsernameAndRole: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchProfileByUsername(
    String username,
  ) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle();
      return row != null ? Map<String, dynamic>.from(row) : null;
    } catch (e) {
      debugPrint('fetchProfileByUsername: $e');
      return null;
    }
  }

  /// Trainer rows that have at least one specialization (for filter UI).
  static Future<List<Map<String, dynamic>>> fetchTrainerSpecializationRows() async {
    try {
      final rows = await _client
          .from('profiles')
          .select('specializations')
          .eq('role', 'trainer')
          .not('specializations', 'is', null);
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('fetchTrainerSpecializationRows: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchProfilesByRole(
    String role, {
    String columns = 'id',
    int? limit,
  }) async {
    try {
      final List<dynamic> rows;
      if (limit != null) {
        rows = await _client
            .from('profiles')
            .select(columns)
            .eq('role', role)
            .limit(limit);
      } else {
        rows = await _client.from('profiles').select(columns).eq('role', role);
      }
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('fetchProfilesByRole: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchProfilesByReferrerUsername(
    String referrerUsername, {
    String columns =
        'id, username, first_name, last_name, avatar_url, referred_at',
  }) async {
    try {
      final rows = await _client
          .from('profiles')
          .select(columns)
          .eq('referrer_username', referrerUsername)
          .order('referred_at', ascending: false);
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('fetchProfilesByReferrerUsername: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTrainers({
    int? limit = 10,
    bool orderByCreatedAtDesc = false,
  }) async {
    try {
      List<dynamic> rows;
      if (orderByCreatedAtDesc && limit != null) {
        rows = await _client
            .from('profiles')
            .select()
            .eq('role', 'trainer')
            .order('created_at', ascending: false)
            .limit(limit);
      } else if (orderByCreatedAtDesc) {
        rows = await _client
            .from('profiles')
            .select()
            .eq('role', 'trainer')
            .order('created_at', ascending: false);
      } else if (limit != null) {
        rows = await _client
            .from('profiles')
            .select()
            .eq('role', 'trainer')
            .limit(limit);
      } else {
        rows = await _client.from('profiles').select().eq('role', 'trainer');
      }
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('fetchTrainers: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTrainersByRanking() async {
    try {
      final rows = await _client
          .from('profiles')
          .select()
          .eq('role', 'trainer')
          .order('ranking', ascending: true);
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('fetchTrainersByRanking: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchTrainers(String query) async {
    try {
      final rows = await _client
          .from('profiles')
          .select()
          .eq('role', 'trainer')
          .or(
            'username.ilike.%$query%,first_name.ilike.%$query%,last_name.ilike.%$query%,bio.ilike.%$query%',
          )
          .order('ranking', ascending: true);
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('searchTrainers: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchOnlineTrainers() async {
    try {
      final rows = await _client
          .from('profiles')
          .select()
          .eq('role', 'trainer')
          .eq('is_online', true)
          .order('ranking', ascending: true);
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('fetchOnlineTrainers: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTopTrainers({
    int limit = 10,
  }) async {
    try {
      final rows = await _client
          .from('profiles')
          .select()
          .eq('role', 'trainer')
          .order('rating', ascending: false)
          .limit(limit);
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('fetchTopTrainers: $e');
      return [];
    }
  }

  static Future<List<String>> fetchActiveProfileIds({
    Duration within = const Duration(days: 30),
  }) async {
    try {
      final since = DateTime.now().subtract(within);
      final rows = await _client
          .from('profiles')
          .select('id')
          .gte('last_active_at', since.toIso8601String());
      return rows
          .map((row) => (row as Map)['id'] as String?)
          .whereType<String>()
          .toList();
    } catch (e) {
      debugPrint('fetchActiveProfileIds: $e');
      return [];
    }
  }

  /// Typed profile lookup (id or auth_user_id).
  static Future<UserProfile?> getUserProfile(String userIdOrAuthId) async {
    final data = await fetchProfile(userIdOrAuthId);
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  /// Display name for chat, lists, and public surfaces.
  static Future<String> getDisplayName(String userIdOrAuthId) async {
    try {
      final profile = await fetchProfile(userIdOrAuthId);
      if (profile != null) {
        return displayNameFromMap(profile);
      }
      debugPrint('⚠️ Profile not found for user: $userIdOrAuthId');
      return 'کاربر ناشناس';
    } catch (e) {
      debugPrint('⚠️ Error getting display name for $userIdOrAuthId: $e');
      return 'کاربر ناشناس';
    }
  }

  static Future<String?> getUserAvatar(String userIdOrAuthId) async {
    try {
      final profile = await fetchProfile(userIdOrAuthId);
      return profile?['avatar_url'] as String?;
    } catch (e) {
      return null;
    }
  }

  static Future<String> getUserRole(String userIdOrAuthId) async {
    try {
      final profile = await fetchProfile(userIdOrAuthId);
      return (profile?['role'] as String?)?.trim() ?? 'athlete';
    } catch (e) {
      return 'athlete';
    }
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
      debugPrint('خطا در دریافت آمار کاربر: $e');
      return {
        'active_programs': 0,
        'total_programs': 0,
        'active_trainers': 0,
        'friends': 0,
      };
    }
  }
}
