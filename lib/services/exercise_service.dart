import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise.dart';
import '../models/exercise_comment.dart';

class ExerciseService {
  static final ExerciseService _instance = ExerciseService._internal();

  factory ExerciseService() {
    return _instance;
  }

  ExerciseService._internal();

  final String apiUrl = "https://gymaipro.ir/wp-json/wp/v2/exercises";
  final SupabaseClient _client = Supabase.instance.client;

  // Cached exercises list
  List<Exercise>? _cachedExercises;
  // Map to store comments for each exercise (cache)
  final Map<int, List<ExerciseComment>> _commentsCache = {};

  // Clear all cached data
  void clearCache() {
    _cachedExercises = null;
    _commentsCache.clear();
    print('Exercise cache cleared');
  }

  // اولیه‌سازی کل سرویس
  static Future<void> initAll() async {
    await _instance.init();
  }

  // Initialize and load favorites & likes
  Future<void> init() async {
    // Load will be done when needed
  }

  // Get all exercises from API with parameters for proper meta data
  Future<List<Exercise>> getExercises() async {
    // Return cached exercises if available
    if (_cachedExercises != null) {
      return await _applyUserData(_cachedExercises!);
    }

    try {
      // Add _embed=true to get meta fields
      final response = await http
          .get(Uri.parse('$apiUrl?_embed=true&per_page=100'), headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final exercises = data.map((json) => Exercise.fromJson(json)).toList();

        // Cache the results
        _cachedExercises = exercises;

        // Apply user specific data (favorites and likes)
        return await _applyUserData(exercises);
      } else {
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching exercises: $e');
    }
  }

  // Apply user data (favorites & likes) to exercises
  Future<List<Exercise>> _applyUserData(List<Exercise> exercises) async {
    // Only proceed if user is logged in
    final user = _client.auth.currentUser;
    if (user == null) {
      return exercises;
    }

    try {
      // Get user bookmarks from Supabase
      final bookmarksResponse = await _client
          .from('exercise_bookmarks')
          .select('exercise_id')
          .eq('user_id', user.id);

      final Set<int> favoriteIds = Set<int>.from(
          (bookmarksResponse as List<dynamic>)
              .map((item) => item['exercise_id'] as int));

      // Get user likes from Supabase
      final likesResponse = await _client
          .from('exercise_likes')
          .select('exercise_id')
          .eq('user_id', user.id);

      final Set<int> likedIds = Set<int>.from((likesResponse as List<dynamic>)
          .map((item) => item['exercise_id'] as int));

      // Get like counts for each exercise
      Map<int, int> likesCount = {};
      for (var exercise in exercises) {
        final countResponse = await _client.rpc(
          'get_exercise_likes_count',
          params: {'exercise_id_param': exercise.id},
        );
        likesCount[exercise.id] = countResponse ?? 0;
      }

      // Apply data to exercises
      for (var exercise in exercises) {
        exercise.isFavorite = favoriteIds.contains(exercise.id);
        exercise.isLikedByUser = likedIds.contains(exercise.id);
        exercise.likes = likesCount[exercise.id] ?? 0;
      }

      return exercises;
    } catch (e) {
      print('Error applying user data from database: $e');
      // Return original exercises if there's an error
      return exercises;
    }
  }

  // Get exercise by ID
  Future<Exercise?> getExerciseById(int id) async {
    final exercises = await getExercises();
    try {
      return exercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search exercises by query
  Future<List<Exercise>> searchExercises(String query) async {
    if (query.isEmpty) return getExercises();

    final exercises = await getExercises();
    final lowerCaseQuery = query.toLowerCase();

    return exercises.where((exercise) {
      return exercise.name.toLowerCase().contains(lowerCaseQuery) ||
          exercise.mainMuscle.toLowerCase().contains(lowerCaseQuery) ||
          exercise.secondaryMuscles.toLowerCase().contains(lowerCaseQuery) ||
          exercise.otherNames
              .any((name) => name.toLowerCase().contains(lowerCaseQuery));
    }).toList();
  }

  // Filter exercises by muscle group
  Future<List<Exercise>> filterByMuscleGroup(String muscleGroup) async {
    if (muscleGroup.isEmpty) return getExercises();

    final exercises = await getExercises();
    final lowerCaseMuscleGroup = muscleGroup.toLowerCase();

    return exercises.where((exercise) {
      return exercise.mainMuscle.toLowerCase().contains(lowerCaseMuscleGroup) ||
          exercise.secondaryMuscles
              .toLowerCase()
              .contains(lowerCaseMuscleGroup);
    }).toList();
  }

  // Get muscle groups list
  Future<List<String>> getMuscleGroups() async {
    final exercises = await getExercises();
    final Set<String> muscleGroups = {};

    for (var exercise in exercises) {
      // Extract main muscle groups and add them to the set
      if (exercise.mainMuscle.isNotEmpty) {
        final mainParts = exercise.mainMuscle.split('(')[0].trim();
        final muscles = mainParts.split(' ');
        for (var muscle in muscles) {
          if (muscle.trim().length > 3) muscleGroups.add(muscle.trim());
        }
      }
    }

    return muscleGroups.toList()..sort();
  }

  // Toggle favorite status using Supabase
  Future<void> toggleFavorite(int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Check if already in favorites
      final existingResponse = await _client
          .from('exercise_bookmarks')
          .select()
          .eq('user_id', user.id)
          .eq('exercise_id', exerciseId)
          .maybeSingle();

      if (existingResponse != null) {
        // Remove from favorites
        await _client
            .from('exercise_bookmarks')
            .delete()
            .eq('user_id', user.id)
            .eq('exercise_id', exerciseId);

        // Update cached exercises
        if (_cachedExercises != null) {
          final exercise =
              _cachedExercises!.firstWhere((e) => e.id == exerciseId,
                  orElse: () => Exercise(
                        id: 0,
                        title: '',
                        name: '',
                        mainMuscle: '',
                        secondaryMuscles: '',
                        tips: [],
                        videoUrl: '',
                        imageUrl: '',
                        otherNames: [],
                        content: '',
                      ));
          if (exercise.id == exerciseId) {
            exercise.isFavorite = false;
          }
        }
      } else {
        // Add to favorites
        await _client.from('exercise_bookmarks').insert({
          'user_id': user.id,
          'exercise_id': exerciseId,
        });

        // Update cached exercises
        if (_cachedExercises != null) {
          final exercise =
              _cachedExercises!.firstWhere((e) => e.id == exerciseId,
                  orElse: () => Exercise(
                        id: 0,
                        title: '',
                        name: '',
                        mainMuscle: '',
                        secondaryMuscles: '',
                        tips: [],
                        videoUrl: '',
                        imageUrl: '',
                        otherNames: [],
                        content: '',
                      ));
          if (exercise.id == exerciseId) {
            exercise.isFavorite = true;
          }
        }
      }
    } catch (e) {
      print('Error toggling favorite in database: $e');
      throw Exception('Failed to toggle favorite status');
    }
  }

  // Toggle like status using Supabase
  Future<void> toggleLike(int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Check if already liked
      final existingResponse = await _client
          .from('exercise_likes')
          .select()
          .eq('user_id', user.id)
          .eq('exercise_id', exerciseId)
          .maybeSingle();

      if (existingResponse != null) {
        // Remove like
        await _client
            .from('exercise_likes')
            .delete()
            .eq('user_id', user.id)
            .eq('exercise_id', exerciseId);

        // Update cached exercises
        if (_cachedExercises != null) {
          final exercise =
              _cachedExercises!.firstWhere((e) => e.id == exerciseId,
                  orElse: () => Exercise(
                        id: 0,
                        title: '',
                        name: '',
                        mainMuscle: '',
                        secondaryMuscles: '',
                        tips: [],
                        videoUrl: '',
                        imageUrl: '',
                        otherNames: [],
                        content: '',
                      ));
          if (exercise.id == exerciseId) {
            exercise.isLikedByUser = false;
            exercise.likes = (exercise.likes > 0) ? exercise.likes - 1 : 0;
          }
        }
      } else {
        // Add like
        await _client.from('exercise_likes').insert({
          'user_id': user.id,
          'exercise_id': exerciseId,
        });

        // Update cached exercises
        if (_cachedExercises != null) {
          final exercise =
              _cachedExercises!.firstWhere((e) => e.id == exerciseId,
                  orElse: () => Exercise(
                        id: 0,
                        title: '',
                        name: '',
                        mainMuscle: '',
                        secondaryMuscles: '',
                        tips: [],
                        videoUrl: '',
                        imageUrl: '',
                        otherNames: [],
                        content: '',
                      ));
          if (exercise.id == exerciseId) {
            exercise.isLikedByUser = true;
            exercise.likes += 1;
          }
        }
      }
    } catch (e) {
      print('Error toggling like in database: $e');
      throw Exception('Failed to toggle like status');
    }
  }

  // Get favorite exercises
  Future<List<Exercise>> getFavoriteExercises() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // Get all exercises
      final allExercises = await getExercises();

      // Filter favorites
      return allExercises.where((exercise) => exercise.isFavorite).toList();
    } catch (e) {
      print('Error getting favorite exercises: $e');
      return [];
    }
  }

  // Get popular exercises (most liked)
  Future<List<Exercise>> getPopularExercises() async {
    try {
      // Get all exercises
      final allExercises = await getExercises();

      // Sort by likes
      final sortedExercises = List<Exercise>.from(allExercises);
      sortedExercises.sort((a, b) => b.likes.compareTo(a.likes));

      // Return top 10 or less
      return sortedExercises.take(10).toList();
    } catch (e) {
      print('Error getting popular exercises: $e');
      return [];
    }
  }

  // Get comments for an exercise
  Future<List<ExerciseComment>> getExerciseComments(int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return [];
    }

    // Return cached comments if available
    if (_commentsCache.containsKey(exerciseId)) {
      return List.from(_commentsCache[exerciseId]!);
    }

    try {
      // Get comments from database
      final commentsResponse = await _client
          .from('exercise_comments')
          .select('*')
          .eq('exercise_id', exerciseId)
          .order('created_at', ascending: false);

      // Get user profiles for the comments
      final List<ExerciseComment> comments = [];
      for (final comment in commentsResponse) {
        try {
          // Get profile info for this comment
          final profileResponse = await _client
              .from('profiles')
              .select('username, avatar_url')
              .eq('id', comment['user_id'])
              .single();

          comments.add(ExerciseComment(
            id: comment['id'] as String,
            userId: comment['user_id'] as String,
            exerciseId: comment['exercise_id'] as int,
            comment: comment['comment'] as String,
            profileName: profileResponse['username'] ?? 'کاربر',
            profileAvatar: profileResponse['avatar_url'],
            createdAt: DateTime.parse(comment['created_at']),
            updatedAt: DateTime.parse(comment['updated_at']),
          ));
        } catch (e) {
          // If profile fetch fails, still add the comment with default profile info
          comments.add(ExerciseComment(
            id: comment['id'] as String,
            userId: comment['user_id'] as String,
            exerciseId: comment['exercise_id'] as int,
            comment: comment['comment'] as String,
            profileName: 'کاربر',
            profileAvatar: null,
            createdAt: DateTime.parse(comment['created_at']),
            updatedAt: DateTime.parse(comment['updated_at']),
          ));
          print('Error getting profile for comment: $e');
        }
      }

      // Update cache
      _commentsCache[exerciseId] = comments;
      return comments;
    } catch (e) {
      print('Error getting comments from database: $e');

      // If error, return empty list
      _commentsCache[exerciseId] = [];
      return [];
    }
  }

  // Add a comment to an exercise
  Future<ExerciseComment?> addExerciseComment(
      int exerciseId, String comment) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Get user profile information
      final profileResponse = await _client
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      final profileName = profileResponse['username'] ?? 'کاربر';
      final profileAvatar = profileResponse['avatar_url'];

      // Add comment to database
      final response = await _client.from('exercise_comments').insert({
        'user_id': user.id,
        'exercise_id': exerciseId,
        'comment': comment,
      }).select('*');

      // Get the first result from the array
      final commentData = response[0];

      // Create comment object from response
      final newComment = ExerciseComment(
        id: commentData['id'] as String,
        userId: commentData['user_id'] as String,
        exerciseId: commentData['exercise_id'] as int,
        comment: commentData['comment'] as String,
        profileName: profileName,
        profileAvatar: profileAvatar,
        createdAt: DateTime.parse(commentData['created_at']),
        updatedAt: DateTime.parse(commentData['updated_at']),
      );

      // Add to cache
      if (!_commentsCache.containsKey(exerciseId)) {
        _commentsCache[exerciseId] = [];
      }

      _commentsCache[exerciseId]!.insert(0, newComment);
      return newComment;
    } catch (e) {
      print('Error adding comment to database: $e');
      return null;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId, int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Delete from database
      await _client
          .from('exercise_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', user.id);

      // Update cache
      if (_commentsCache.containsKey(exerciseId)) {
        _commentsCache[exerciseId]!.removeWhere((c) => c.id == commentId);
      }

      return true;
    } catch (e) {
      print('Error deleting comment from database: $e');
      return false;
    }
  }
}
