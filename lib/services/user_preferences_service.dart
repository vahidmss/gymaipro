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

    // Increment global likes
    await _client.rpc<void>(
      'increment_exercise_likes',
      params: {'exercise_id_param': exerciseId},
    );
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

    // Decrement global likes
    await _client.rpc<void>(
      'decrement_exercise_likes',
      params: {'exercise_id_param': exerciseId},
    );
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
}
