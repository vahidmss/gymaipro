import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserPreferencesService {
  factory UserPreferencesService() => _instance;
  UserPreferencesService._internal();
  static final UserPreferencesService _instance =
      UserPreferencesService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ===== FOOD FAVORITES =====

  /// Add food to user favorites
  Future<void> addFoodToFavorites(
    int foodId,
    String foodTitle,
    String? foodImageUrl,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.from('user_food_favorites').insert({
      'user_id': user.id,
      'food_id': foodId,
      'food_title': foodTitle,
      'food_image_url': foodImageUrl,
    });
  }

  /// Remove food from user favorites
  Future<void> removeFoodFromFavorites(int foodId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client
        .from('user_food_favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('food_id', foodId);
  }

  /// Get user's favorite foods
  Future<List<Map<String, dynamic>>> getFavoriteFoods() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('user_food_favorites')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Check if food is in user's favorites
  Future<bool> isFoodFavorite(int foodId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('user_food_favorites')
        .select('id')
        .eq('user_id', user.id)
        .eq('food_id', foodId)
        .maybeSingle();

    return response != null;
  }

  // ===== FOOD LIKES =====

  /// Add food like
  Future<void> addFoodLike(int foodId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Add to user likes
    await _client.from('user_food_likes').insert({
      'user_id': user.id,
      'food_id': foodId,
    });

    // Increment global likes
    await _client.rpc<void>(
      'increment_food_likes',
      params: {'food_id_param': foodId},
    );
  }

  /// Remove food like
  Future<void> removeFoodLike(int foodId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Remove from user likes
    await _client
        .from('user_food_likes')
        .delete()
        .eq('user_id', user.id)
        .eq('food_id', foodId);

    // Decrement global likes
    await _client.rpc<void>(
      'decrement_food_likes',
      params: {'food_id_param': foodId},
    );
  }

  /// Check if user liked a food
  Future<bool> isFoodLiked(int foodId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('user_food_likes')
        .select('id')
        .eq('user_id', user.id)
        .eq('food_id', foodId)
        .maybeSingle();

    return response != null;
  }

  // ===== EXERCISE FAVORITES =====

  /// Add exercise to user favorites
  Future<void> addExerciseToFavorites(
    int exerciseId,
    String exerciseName,
    String? exerciseImageUrl,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.from('user_exercise_favorites').insert({
      'user_id': user.id,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'exercise_image_url': exerciseImageUrl,
    });
  }

  /// Remove exercise from user favorites
  Future<void> removeExerciseFromFavorites(int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client
        .from('user_exercise_favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('exercise_id', exerciseId);
  }

  /// Get user's favorite exercises
  Future<List<Map<String, dynamic>>> getFavoriteExercises() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('user_exercise_favorites')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Check if exercise is in user's favorites
  Future<bool> isExerciseFavorite(int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('user_exercise_favorites')
        .select('id')
        .eq('user_id', user.id)
        .eq('exercise_id', exerciseId)
        .maybeSingle();

    return response != null;
  }

  // ===== EXERCISE LIKES =====

  /// Add exercise like
  Future<void> addExerciseLike(int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Add to user likes
    await _client.from('user_exercise_likes').insert({
      'user_id': user.id,
      'exercise_id': exerciseId,
    });

    // Increment global likes - try RPC first, fallback to direct update
    try {
      await _client.rpc<void>(
        'increment_exercise_likes',
        params: {'exercise_id_param': exerciseId},
      );
    } catch (e) {
      // Fallback: directly update global_exercise_likes table
      try {
        // Check if record exists
        final existing = await _client
            .from('global_exercise_likes')
            .select('exercise_id, total_likes')
            .eq('exercise_id', exerciseId)
            .maybeSingle();

        if (existing != null) {
          // Update existing record
          await _client
              .from('global_exercise_likes')
              .update({
                'total_likes': (existing['total_likes'] as int? ?? 0) + 1,
              })
              .eq('exercise_id', exerciseId);
        } else {
          // Insert new record
          await _client.from('global_exercise_likes').insert({
            'exercise_id': exerciseId,
            'total_likes': 1,
          });
        }
      } catch (fallbackError) {
        debugPrint('Error updating global_exercise_likes: $fallbackError');
        // Silently fail - user like is still recorded
      }
    }
  }

  /// Remove exercise like
  Future<void> removeExerciseLike(int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Remove from user likes
    await _client
        .from('user_exercise_likes')
        .delete()
        .eq('user_id', user.id)
        .eq('exercise_id', exerciseId);

    // Decrement global likes - try RPC first, fallback to direct update
    try {
      await _client.rpc<void>(
        'decrement_exercise_likes',
        params: {'exercise_id_param': exerciseId},
      );
    } catch (e) {
      // Fallback: directly update global_exercise_likes table
      try {
        // Check if record exists
        final existing = await _client
            .from('global_exercise_likes')
            .select('exercise_id, total_likes')
            .eq('exercise_id', exerciseId)
            .maybeSingle();

        if (existing != null) {
          final currentLikes = existing['total_likes'] as int? ?? 0;
          final newLikes = (currentLikes - 1).clamp(0, double.infinity).toInt();

          if (newLikes > 0) {
            // Update existing record
            await _client
                .from('global_exercise_likes')
                .update({'total_likes': newLikes})
                .eq('exercise_id', exerciseId);
          } else {
            // Remove record if likes reach zero (optional - you can keep it)
            await _client
                .from('global_exercise_likes')
                .delete()
                .eq('exercise_id', exerciseId);
          }
        }
      } catch (fallbackError) {
        debugPrint('Error updating global_exercise_likes: $fallbackError');
        // Silently fail - user unlike is still recorded
      }
    }
  }

  /// Check if user liked an exercise
  Future<bool> isExerciseLiked(int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('user_exercise_likes')
        .select('id')
        .eq('user_id', user.id)
        .eq('exercise_id', exerciseId)
        .maybeSingle();

    return response != null;
  }

  // ===== BATCH OPERATIONS =====

  /// Get all user preferences for foods (favorites and likes)
  Future<Map<String, dynamic>> getFoodPreferences(List<int> foodIds) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return {
        'favorites': <int>[],
        'likes': <int>[],
        'global_likes': <int, int>{},
      };
    }

    final futures = await Future.wait([
      _client
          .from('user_food_favorites')
          .select('food_id')
          .eq('user_id', user.id)
          .inFilter('food_id', foodIds),
      _client
          .from('user_food_likes')
          .select('food_id')
          .eq('user_id', user.id)
          .inFilter('food_id', foodIds),
      _client
          .from('global_food_likes')
          .select('food_id, total_likes')
          .inFilter('food_id', foodIds),
    ]);

    final favorites = (futures[0] as List)
        .map((item) => item['food_id'] as int)
        .toList();
    final likes = (futures[1] as List)
        .map((item) => item['food_id'] as int)
        .toList();

    // Create map of food_id to total_likes
    final globalLikes = <int, int>{};
    for (final item in futures[2] as List) {
      globalLikes[item['food_id'] as int] = item['total_likes'] as int;
    }

    return {
      'favorites': favorites,
      'likes': likes,
      'global_likes': globalLikes,
    };
  }

  /// Get all user preferences for exercises (favorites and likes)
  Future<Map<String, dynamic>> getExercisePreferences(
    List<int> exerciseIds,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return {
        'favorites': <int>[],
        'likes': <int>[],
        'global_likes': <int, int>{},
      };
    }

    final futures = await Future.wait([
      _client
          .from('user_exercise_favorites')
          .select('exercise_id')
          .eq('user_id', user.id)
          .inFilter('exercise_id', exerciseIds),
      _client
          .from('user_exercise_likes')
          .select('exercise_id')
          .eq('user_id', user.id)
          .inFilter('exercise_id', exerciseIds),
      _client
          .from('global_exercise_likes')
          .select('exercise_id, total_likes')
          .inFilter('exercise_id', exerciseIds),
    ]);

    final favorites = (futures[0] as List)
        .map((item) => item['exercise_id'] as int)
        .toList();
    final likes = (futures[1] as List)
        .map((item) => item['exercise_id'] as int)
        .toList();

    // Create map of exercise_id to total_likes
    final globalLikes = <int, int>{};
    for (final item in futures[2] as List) {
      globalLikes[item['exercise_id'] as int] = item['total_likes'] as int;
    }

    return {
      'favorites': favorites,
      'likes': likes,
      'global_likes': globalLikes,
    };
  }

  // ===== MUSIC LIKES =====

  /// Add music like
  /// musicId: INTEGER hash از UUID
  /// audioUrl: برای پیدا کردن موزیک در custom_music
  Future<void> addMusicLike(int musicId, {String? audioUrl}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Add to user likes
    await _client.from('user_music_likes').insert({
      'user_id': user.id,
      'music_id': musicId,
    });

    // Update likes_count در custom_music
    if (audioUrl != null) {
      try {
        // پیدا کردن موزیک با audio_url
        final music = await _client
            .from('custom_music')
            .select('id, likes_count')
            .eq('audio_url', audioUrl)
            .maybeSingle();

        if (music != null) {
          // به‌روزرسانی likes_count
          await _client
              .from('custom_music')
              .update({'likes_count': (music['likes_count'] as int? ?? 0) + 1})
              .eq('id', music['id'] as String);
        }
      } catch (e) {
        debugPrint('Error updating custom_music likes_count: $e');
        // Silently fail - user like is still recorded
      }
    }
  }

  /// Remove music like
  /// musicId: INTEGER hash از UUID
  /// audioUrl: برای پیدا کردن موزیک در custom_music
  Future<void> removeMusicLike(int musicId, {String? audioUrl}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Remove from user likes
    await _client
        .from('user_music_likes')
        .delete()
        .eq('user_id', user.id)
        .eq('music_id', musicId);

    // Update likes_count در custom_music
    if (audioUrl != null) {
      try {
        // پیدا کردن موزیک با audio_url
        final music = await _client
            .from('custom_music')
            .select('id, likes_count')
            .eq('audio_url', audioUrl)
            .maybeSingle();

        if (music != null) {
          final currentLikes = music['likes_count'] as int? ?? 0;
          final newLikes = (currentLikes - 1).clamp(0, double.infinity).toInt();

          // به‌روزرسانی likes_count
          await _client
              .from('custom_music')
              .update({'likes_count': newLikes})
              .eq('id', music['id'] as String);
        }
      } catch (e) {
        debugPrint('Error updating custom_music likes_count: $e');
        // Silently fail - user unlike is still recorded
      }
    }
  }

  /// Check if user liked a music
  Future<bool> isMusicLiked(int musicId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('user_music_likes')
        .select('id')
        .eq('user_id', user.id)
        .eq('music_id', musicId)
        .maybeSingle();

    return response != null;
  }

  /// Get all user preferences for musics (likes only - favorites stored locally)
  /// audioUrls: لیست audio_url ها برای پیدا کردن موزیک‌ها در custom_music
  Future<Map<String, dynamic>> getMusicPreferences(
    List<int> musicIds, {
    List<String>? audioUrls,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return {'likes': <int>[], 'global_likes': <int, int>{}};
    }

    try {
      final futures = await Future.wait([
        _client
            .from('user_music_likes')
            .select('music_id')
            .eq('user_id', user.id)
            .inFilter('music_id', musicIds),
        // دریافت likes_count از custom_music
        if (audioUrls != null && audioUrls.isNotEmpty) _client
                  .from('custom_music')
                  .select('audio_url, likes_count')
                  .inFilter('audio_url', audioUrls) else Future.value([]),
      ]);

      final likes = futures[0].map((item) => item['music_id'] as int).toList();

      // Create map of music_id to total_likes
      final globalLikes = <int, int>{};
      if (audioUrls != null &&
          audioUrls.isNotEmpty &&
          musicIds.length == audioUrls.length) {
        final customMusics = futures[1];
        // ساخت map از audio_url به likes_count
        final audioUrlToLikes = <String, int>{};
        for (final item in customMusics) {
          final audioUrl = item['audio_url'] as String;
          final likesCount = item['likes_count'] as int? ?? 0;
          audioUrlToLikes[audioUrl] = likesCount;
        }

        // Map کردن music_id به likes_count از طریق audio_url
        for (int i = 0; i < musicIds.length && i < audioUrls.length; i++) {
          final audioUrl = audioUrls[i];
          final likesCount = audioUrlToLikes[audioUrl] ?? 0;
          globalLikes[musicIds[i]] = likesCount;
        }
      }

      return {'likes': likes, 'global_likes': globalLikes};
    } catch (e) {
      debugPrint('Error getting music preferences: $e');
      return {'likes': <int>[], 'global_likes': <int, int>{}};
    }
  }
}
