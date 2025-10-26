import 'dart:convert';

import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/exercise_comment.dart';
import 'package:gymaipro/services/user_preferences_service.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseService {
  factory ExerciseService() {
    return _instance;
  }

  ExerciseService._internal();
  static final ExerciseService _instance = ExerciseService._internal();

  final String apiUrl = 'https://gymaipro.ir/wp-json/wp/v2/exercises';
  final SupabaseClient _client = Supabase.instance.client;
  final UserPreferencesService _preferencesService = UserPreferencesService();
  List<Exercise>? _cachedExercises;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidity = Duration(minutes: 5);

  // Clear all cached data
  void clearCache() {
    _cachedExercises = null;
    _lastCacheTime = null;
  }

  // اولیه‌سازی کل سرویس
  static Future<void> initAll() async {
    await _instance.init();
  }

  // Initialize and load favorites & likes
  Future<void> init() async {
    // Load will be done when needed
  }

  // Get all exercises with caching
  Future<List<Exercise>> getExercises() async {
    // Return cached exercises if still valid
    if (_cachedExercises != null && _lastCacheTime != null) {
      final timeSinceLastCache = DateTime.now().difference(_lastCacheTime!);
      if (timeSinceLastCache < _cacheValidity) {
        return _applyUserDataToExercises(_cachedExercises!);
      }
    }

    try {
      // Fetch all pages from WP REST (per_page max 100)
      int page = 1;
      final List<Exercise> exercises = [];
      while (true) {
        final url =
            '$apiUrl?_embed=true&per_page=100&page=$page&_fields=id,title,content,modified,meta,_embedded,featured_image';
        final response = await http
            .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> exercisesData =
              jsonDecode(response.body) as List<dynamic>;
          if (exercisesData.isEmpty) break;

          if (page == 1 && exercisesData.isNotEmpty) {}

          for (final exerciseData in exercisesData) {
            try {
              // استفاده از متد fromJson مدل Exercise
              final exercise = Exercise.fromJson(
                exerciseData as Map<String, dynamic>,
              );
              exercises.add(exercise);
            } catch (e) {
              continue;
            }
          }

          // next page
          page++;
        } else if (response.statusCode == 400 || response.statusCode == 404) {
          // probably page out of range
          break;
        } else {
          break;
        }
      }

      // Update cache
      _cachedExercises = exercises;
      _lastCacheTime = DateTime.now();
      return await _applyUserDataToExercises(exercises);
    } catch (e) {
      return [];
    }
  }

  /// فیلتر پیشرفته تمرینات
  Future<List<Exercise>> getFilteredExercises({
    String? difficulty,
    String? equipment,
    String? exerciseType,
    String? targetArea,
    int? minDuration,
    int? maxDuration,
    List<String>? muscleGroups,
    String? searchQuery,
  }) async {
    final exercises = await getExercises();

    return exercises.where((exercise) {
      // فیلتر سطح دشواری
      if (difficulty != null &&
          difficulty.isNotEmpty &&
          exercise.difficulty != difficulty) {
        return false;
      }

      // فیلتر تجهیزات
      if (equipment != null &&
          equipment.isNotEmpty &&
          exercise.equipment != equipment) {
        return false;
      }

      // فیلتر نوع تمرین
      if (exerciseType != null &&
          exerciseType.isNotEmpty &&
          exercise.exerciseType != exerciseType) {
        return false;
      }

      // فیلتر ناحیه هدف
      if (targetArea != null &&
          targetArea.isNotEmpty &&
          !exercise.targetArea.toLowerCase().contains(
            targetArea.toLowerCase(),
          )) {
        return false;
      }

      // فیلتر مدت زمان
      if (minDuration != null && exercise.estimatedDuration < minDuration) {
        return false;
      }
      if (maxDuration != null && exercise.estimatedDuration > maxDuration) {
        return false;
      }

      // فیلتر گروه عضلات
      if (muscleGroups != null && muscleGroups.isNotEmpty) {
        bool hasMatchingMuscle = false;
        for (final muscle in muscleGroups) {
          if (exercise.mainMuscle.toLowerCase().contains(
                muscle.toLowerCase(),
              ) ||
              exercise.secondaryMuscles.toLowerCase().contains(
                muscle.toLowerCase(),
              )) {
            hasMatchingMuscle = true;
            break;
          }
        }
        if (!hasMatchingMuscle) return false;
      }

      // فیلتر جستجو
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!exercise.name.toLowerCase().contains(query) &&
            !exercise.mainMuscle.toLowerCase().contains(query) &&
            !exercise.secondaryMuscles.toLowerCase().contains(query) &&
            !exercise.content.toLowerCase().contains(query) &&
            !exercise.tags.any((tag) => tag.toLowerCase().contains(query)) &&
            !exercise.otherNames.any(
              (name) => name.toLowerCase().contains(query),
            )) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// جستجوی هوشمند تمرینات
  Future<List<Exercise>> searchExercises(String query) async {
    if (query.trim().isEmpty) return getExercises();

    final exercises = await getExercises();
    final searchTerms = query
        .toLowerCase()
        .split(' ')
        .where((term) => term.isNotEmpty)
        .toList();

    return exercises.where((exercise) {
      // امتیازدهی بر اساس تطابق
      int score = 0;

      for (final term in searchTerms) {
        // تطابق نام تمرین (بالاترین امتیاز)
        if (exercise.name.toLowerCase().contains(term)) {
          score += 10;
        }

        // تطابق عضله اصلی
        if (exercise.mainMuscle.toLowerCase().contains(term)) {
          score += 8;
        }

        // تطابق عضلات فرعی
        if (exercise.secondaryMuscles.toLowerCase().contains(term)) {
          score += 6;
        }

        // تطابق تگ‌ها
        if (exercise.tags.any((tag) => tag.toLowerCase().contains(term))) {
          score += 5;
        }

        // تطابق نام‌های دیگر
        if (exercise.otherNames.any(
          (name) => name.toLowerCase().contains(term),
        )) {
          score += 4;
        }

        // تطابق محتوا
        if (exercise.content.toLowerCase().contains(term)) {
          score += 2;
        }

        // تطابق تجهیزات
        if (exercise.equipment.toLowerCase().contains(term)) {
          score += 3;
        }

        // تطابق نوع تمرین
        if (exercise.exerciseType.toLowerCase().contains(term)) {
          score += 3;
        }
      }

      return score > 0;
    }).toList()..sort((a, b) {
      // مرتب‌سازی بر اساس امتیاز
      int scoreA = 0, scoreB = 0;
      for (final term in searchTerms) {
        if (a.name.toLowerCase().contains(term)) scoreA += 10;
        if (b.name.toLowerCase().contains(term)) scoreB += 10;
      }
      return scoreB.compareTo(scoreA);
    });
  }

  /// ترتیب‌بندی پیشرفته تمرینات
  Future<List<Exercise>> getSortedExercises({
    required String sortBy,
    bool ascending = false,
  }) async {
    final exercises = await getExercises();

    switch (sortBy.toLowerCase()) {
      case 'name':
        exercises.sort(
          (a, b) =>
              ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
        );

      case 'difficulty':
        final difficultyOrder = {'مبتدی': 1, 'متوسط': 2, 'پیشرفته': 3};
        exercises.sort((a, b) {
          final aOrder = difficultyOrder[a.difficulty] ?? 2;
          final bOrder = difficultyOrder[b.difficulty] ?? 2;
          return ascending
              ? aOrder.compareTo(bOrder)
              : bOrder.compareTo(aOrder);
        });

      case 'duration':
        exercises.sort(
          (a, b) => ascending
              ? a.estimatedDuration.compareTo(b.estimatedDuration)
              : b.estimatedDuration.compareTo(a.estimatedDuration),
        );

      case 'popularity':
        exercises.sort(
          (a, b) => ascending
              ? a.likes.compareTo(b.likes)
              : b.likes.compareTo(a.likes),
        );

      case 'equipment':
        exercises.sort(
          (a, b) => ascending
              ? a.equipment.compareTo(b.equipment)
              : b.equipment.compareTo(a.equipment),
        );

      case 'type':
        exercises.sort(
          (a, b) => ascending
              ? a.exerciseType.compareTo(b.exerciseType)
              : b.exerciseType.compareTo(a.exerciseType),
        );

      default:
        // پیش‌فرض: مرتب‌سازی بر اساس نام
        exercises.sort((a, b) => a.name.compareTo(b.name));
    }

    return exercises;
  }

  /// دریافت فیلترهای موجود
  Future<Map<String, List<String>>> getAvailableFilters() async {
    final exercises = await getExercises();

    final difficulties = <String>{};
    final equipments = <String>{};
    final exerciseTypes = <String>{};
    final targetAreas = <String>{};
    final muscleGroups = <String>{};

    for (final exercise in exercises) {
      difficulties.add(exercise.difficulty);
      equipments.add(exercise.equipment);
      exerciseTypes.add(exercise.exerciseType);
      targetAreas.add(exercise.targetArea);

      if (exercise.mainMuscle.isNotEmpty) {
        muscleGroups.add(exercise.mainMuscle);
      }
      if (exercise.secondaryMuscles.isNotEmpty) {
        muscleGroups.addAll(exercise.secondaryMuscles.split(', '));
      }
    }

    return {
      'difficulties': difficulties.toList()..sort(),
      'equipments': equipments.toList()..sort(),
      'exerciseTypes': exerciseTypes.toList()..sort(),
      'targetAreas': targetAreas.toList()..sort(),
      'muscleGroups': muscleGroups.toList()..sort(),
    };
  }

  // Apply user-specific data to exercises (favorites, likes, etc.)
  Future<List<Exercise>> _applyUserDataToExercises(
    List<Exercise> exercises,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) return exercises;

    try {
      // Get user preferences for all exercises
      final exerciseIds = exercises.map((e) => e.id).toList();
      final preferences = await _preferencesService.getExercisePreferences(
        exerciseIds,
      );

      final favoriteIds = Set<int>.from(preferences['favorites'] as List);
      final likedIds = Set<int>.from(preferences['likes'] as List);
      final globalLikes = Map<int, int>.from(
        preferences['global_likes'] as Map,
      );

      // Apply preferences to exercises
      for (final exercise in exercises) {
        exercise.isFavorite = favoriteIds.contains(exercise.id);
        exercise.isLikedByUser = likedIds.contains(exercise.id);
        exercise.likes = globalLikes[exercise.id] ?? 0; // Use global like count
      }

      return exercises;
    } catch (e) {
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

  // Filter exercises by muscle group
  Future<List<Exercise>> filterByMuscleGroup(String muscleGroup) async {
    if (muscleGroup.isEmpty) return getExercises();

    final exercises = await getExercises();
    final lowerCaseMuscleGroup = muscleGroup.toLowerCase();

    return exercises.where((exercise) {
      return exercise.mainMuscle.toLowerCase().contains(lowerCaseMuscleGroup) ||
          exercise.secondaryMuscles.toLowerCase().contains(
            lowerCaseMuscleGroup,
          );
    }).toList();
  }

  // Get muscle groups list
  Future<List<String>> getMuscleGroups() async {
    final exercises = await getExercises();
    final Set<String> muscleGroups = {};

    for (final exercise in exercises) {
      // Extract main muscle groups and add them to the set
      if (exercise.mainMuscle.isNotEmpty) {
        final mainParts = exercise.mainMuscle.split('(')[0].trim();
        final muscles = mainParts.split(' ');
        for (final muscle in muscles) {
          if (muscle.trim().length > 3) muscleGroups.add(muscle.trim());
        }
      }
    }

    return muscleGroups.toList()..sort();
  }

  // Toggle favorite status
  Future<void> toggleFavorite(int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Find the exercise in cache to get its details
      if (_cachedExercises != null) {
        final exercise = _cachedExercises!.firstWhere(
          (e) => e.id == exerciseId,
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
          ),
        );
        if (exercise.id == exerciseId) {
          // Toggle favorite in database
          if (exercise.isFavorite) {
            await _preferencesService.removeExerciseFromFavorites(exerciseId);
            exercise.isFavorite = false;
          } else {
            await _preferencesService.addExerciseToFavorites(
              exerciseId,
              exercise.name,
              exercise.imageUrl,
            );
            exercise.isFavorite = true;
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite status');
    }
  }

  // Toggle like status
  Future<void> toggleLike(int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Find the exercise in cache
      if (_cachedExercises != null) {
        final exercise = _cachedExercises!.firstWhere(
          (e) => e.id == exerciseId,
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
          ),
        );
        if (exercise.id == exerciseId) {
          // Toggle like in database
          if (exercise.isLikedByUser) {
            await _preferencesService.removeExerciseLike(exerciseId);
            exercise.isLikedByUser = false;
            // Global likes will be updated by the service
            exercise.likes = (exercise.likes - 1)
                .clamp(0, double.infinity)
                .toInt();
          } else {
            await _preferencesService.addExerciseLike(exerciseId);
            exercise.isLikedByUser = true;
            // Global likes will be updated by the service
            exercise.likes = exercise.likes + 1;
          }
        }
      }
    } catch (e) {
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
      return [];
    }
  }

  // Get comments for an exercise
  Future<List<ExerciseComment>> getExerciseComments(int exerciseId) async {
    // کامنت‌ها فعلاً غیرفعال هستند چون جدول exercise_comments در Supabase وجود ندارد
    // و تمرینات از WordPress API دریافت می‌شود
    print('کامنت‌ها فعلاً غیرفعال هستند');
    return [];
  }

  // Add a comment to an exercise
  Future<ExerciseComment?> addExerciseComment(
    int exerciseId,
    String comment,
  ) async {
    // کامنت‌ها فعلاً غیرفعال هستند چون جدول exercise_comments در Supabase وجود ندارد
    // و تمرینات از WordPress API دریافت می‌شود
    print('کامنت‌ها فعلاً غیرفعال هستند');
    return null;
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId, int exerciseId) async {
    // کامنت‌ها فعلاً غیرفعال هستند چون جدول exercise_comments در Supabase وجود ندارد
    // و تمرینات از WordPress API دریافت می‌شود
    print('کامنت‌ها فعلاً غیرفعال هستند');
    return false;
  }
}
