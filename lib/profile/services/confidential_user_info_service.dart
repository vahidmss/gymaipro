import 'package:supabase_flutter/supabase_flutter.dart';

class ConfidentialUserInfoService {
  static final SupabaseClient _client = Supabase.instance.client;

  static const String tableName = 'confidential_user_info';

  // Returns auth user id or throws
  static String _requireUserId() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      throw Exception('کاربر وارد نشده است');
    }
    return uid;
  }

  // Save consent = true with timestamp; creates row if missing
  static Future<bool> saveConsentAccepted() async {
    try {
      final userId = _requireUserId();
      // try to fetch username from profiles for snapshot
      String? username;
      try {
        final p = await _client
            .from('profiles')
            .select('username')
            .eq('id', userId)
            .maybeSingle();
        if (p != null && p['username'] != null) {
          username = p['username'].toString();
        }
      } catch (_) {}

      // Upsert by unique(profile_id)
      final data = {
        'profile_id': userId,
        'has_consented': true,
        'consented_at': DateTime.now().toIso8601String(),
        if (username != null && username.isNotEmpty)
          'username_snapshot': username,
      };

      await _client
          .from(tableName)
          .upsert(data, onConflict: 'profile_id')
          .select()
          .maybeSingle();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Fetch current consent status
  static Future<bool> getConsentStatus() async {
    try {
      final userId = _requireUserId();
      final row = await _client
          .from(tableName)
          .select('has_consented')
          .eq('profile_id', userId)
          .maybeSingle();
      if (row == null) return false;
      final value = row['has_consented'];
      if (value is bool) return value;
      if (value is int) return value != 0;
      return false;
    } catch (_) {
      return false;
    }
  }

  // Fetch consent status for a specific profile id (trainer-view use case)
  static Future<bool> getConsentStatusForProfile(String profileId) async {
    try {
      final row = await _client
          .from(tableName)
          .select('has_consented')
          .eq('profile_id', profileId)
          .maybeSingle();
      if (row == null) return false;
      final value = row['has_consented'];
      if (value is bool) return value;
      if (value is int) return value != 0;
      return false;
    } catch (_) {
      return false;
    }
  }

  // Ensure a row exists for current user
  static Future<void> _ensureRow() async {
    final userId = _requireUserId();
    final row = await _client
        .from(tableName)
        .select('profile_id')
        .eq('profile_id', userId)
        .maybeSingle();
    if (row == null) {
      await _client.from(tableName).insert({'profile_id': userId});
    }
  }

  // Update photos_visible_to_trainer flag
  static Future<bool> updatePhotosVisibility(bool isVisible) async {
    try {
      await _ensureRow();
      final userId = _requireUserId();
      await _client
          .from(tableName)
          .update({'photos_visible_to_trainer': isVisible})
          .eq('profile_id', userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Append a photo entry to photo_album JSON array and update last_photo_at
  static Future<bool> appendPhotoToAlbum({
    required String url,
    required String type, // front|back|side|progress
    required DateTime takenAt,
    String? notes,
    bool isVisibleToTrainer = false,
    String? blurLevel,
  }) async {
    try {
      await _ensureRow();
      final userId = _requireUserId();

      // Fetch current album
      final row = await _client
          .from(tableName)
          .select('photo_album')
          .eq('profile_id', userId)
          .maybeSingle();

      final List<dynamic> album = (row != null && row['photo_album'] is List)
          ? List.from(row['photo_album'] as Iterable<dynamic>)
          : <dynamic>[];

      final Map<String, dynamic> photo = {
        'url': url,
        'type': type,
        'taken_at': takenAt.toIso8601String(),
        'notes': notes,
        'is_visible_to_trainer': isVisibleToTrainer,
        'blur_level': blurLevel,
      };

      album.add(photo);

      await _client
          .from(tableName)
          .update({
            'photo_album': album,
            'last_photo_at': takenAt.toIso8601String(),
          })
          .eq('profile_id', userId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Update lifestyle/preferences JSON
  static Future<bool> updateLifestylePreferences(
    Map<String, dynamic> prefs,
  ) async {
    try {
      await _ensureRow();
      final userId = _requireUserId();
      await _client
          .from(tableName)
          .update({'lifestyle_preferences': prefs})
          .eq('profile_id', userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Load user's photo album and settings
  static Future<Map<String, dynamic>?> loadUserData() async {
    try {
      final userId = _requireUserId();
      final row = await _client
          .from(tableName)
          .select(
            'photos_visible_to_trainer, last_photo_at, photo_album, lifestyle_preferences',
          )
          .eq('profile_id', userId)
          .maybeSingle();

      if (row == null) return null;

      return {
        'photos_visible_to_trainer':
            (row['photos_visible_to_trainer'] as bool?) ?? false,
        'last_photo_at': row['last_photo_at'],
        'photo_album': (row['photo_album'] as List<dynamic>?) ?? <dynamic>[],
        'lifestyle_preferences':
            (row['lifestyle_preferences'] as Map<String, dynamic>?) ??
            <String, dynamic>{},
      };
    } catch (e) {
      print('Error loading user data: $e');
      return null;
    }
  }

  // Read-only: Load another user's data by profile id (for trainer view)
  static Future<Map<String, dynamic>?> loadUserDataForProfile(
    String profileId,
  ) async {
    try {
      final row = await _client
          .from(tableName)
          .select(
            'photos_visible_to_trainer, last_photo_at, photo_album, lifestyle_preferences',
          )
          .eq('profile_id', profileId)
          .maybeSingle();

      if (row == null) return null;

      return {
        'photos_visible_to_trainer':
            (row['photos_visible_to_trainer'] as bool?) ?? false,
        'last_photo_at': row['last_photo_at'],
        'photo_album': (row['photo_album'] as List<dynamic>?) ?? <dynamic>[],
        'lifestyle_preferences':
            (row['lifestyle_preferences'] as Map<String, dynamic>?) ??
            <String, dynamic>{},
      };
    } catch (_) {
      return null;
    }
  }
}
