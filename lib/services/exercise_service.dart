import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/models/custom_exercise.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';
import 'package:gymaipro/models/exercise_rich_meta.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/models/exercise_comment.dart';
import 'package:gymaipro/network/wordpress_http.dart';
import 'package:gymaipro/services/custom_exercise_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/user_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Decode heavy JSON off the UI thread (returns sendable types only).
List<dynamic> _decodeJsonList(String jsonStr) {
  return jsonDecode(jsonStr) as List<dynamic>;
}

List<String> parseStoredMediaUrls(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) {
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  if (raw is String) {
    final t = raw.trim();
    if (t.isEmpty) return [];
    if (t.startsWith('[')) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } catch (_) {}
      return [];
    }
    return [t];
  }
  return [];
}

class ExerciseService {
  factory ExerciseService() {
    return _instance;
  }

  ExerciseService._internal();
  static final ExerciseService _instance = ExerciseService._internal();

  String get apiUrl =>
      '${AppConfig.wordpressApiOrigin}/wp-json/wp/v2/exercises';
  final SupabaseClient _client = Supabase.instance.client;
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final CustomExerciseService _customExerciseService = CustomExerciseService();
  List<Exercise>? _cachedExercises;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidity = Duration(
    hours: 24,
  ); // افزایش مدت اعتبار cache
  static const String _exercisesListCacheKey = 'exercises_list_cache';
  static const String _exercisesListCacheTimeKey = 'exercises_list_cache_time';
  static const String _exercisesListCacheVersionKey =
      'exercises_list_cache_version';
  static const int _cacheVersion = 6; // list without extended_json + lazy richMeta

  /// ستون‌های لیست (بدون exercise_extended_json سنگین).
  static const String _listSelectColumns = '''
id, name, content, main_muscle, secondary_muscles, tips, video_url, image_url,
other_names, difficulty, equipment, exercise_type, estimated_duration, target_area,
short_description, detailed_description, learn, movement_pattern, body_engagement,
muscle_targets_json, met, typical_rpe, movement_distance_cm, calories_per_1000kg,
exercise_difficulty_score, estimated_1rm_formula, views_count, likes_count, source
''';

  /// بازگرداندن فوری لیست از حافظه — بدون هیچ async/await/DB.
  /// اگر هنوز لود نشده باشد، لیست خالی برمی‌گرداند.
  /// این برای باز کردن فوری bottom sheet انتخاب تمرین مناسب است.
  List<Exercise> get cachedExercisesSync => _cachedExercises ?? const [];

  // Clear all cached data
  void clearCache() {
    _cachedExercises = null;
    _lastCacheTime = null;
    _clearPersistentCache();
  }

  /// پاک کردن cache پایدار
  Future<void> _clearPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_exercisesListCacheKey);
      await prefs.remove(_exercisesListCacheTimeKey);
      await prefs.remove(_exercisesListCacheVersionKey);
    } catch (e) {
      debugPrint('Error clearing persistent cache: $e');
    }
  }

  // اولیه‌سازی کل سرویس
  static Future<void> initAll() async {
    await _instance.init();
  }

  // Initialize and load favorites & likes
  Future<void> init() async {
    // Load will be done when needed
  }

  /// دریافت فوری از cache (بدون await)
  Future<List<Exercise>?> getExercisesFromCache() async {
    // اول از memory cache
    if (_cachedExercises != null && _lastCacheTime != null) {
      final timeSinceLastCache = DateTime.now().difference(_lastCacheTime!);
      if (timeSinceLastCache < _cacheValidity) {
        return _cachedExercises;
      }
    }

    // سپس از persistent cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimeStr = prefs.getString(_exercisesListCacheTimeKey);
      final cacheVersion = prefs.getInt(_exercisesListCacheVersionKey) ?? 0;

      if (cacheTimeStr != null && cacheVersion == _cacheVersion) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        final timeSinceCache = DateTime.now().difference(cacheTime);

        if (timeSinceCache < _cacheValidity) {
          final exercisesJson = prefs.getString(_exercisesListCacheKey);
          if (exercisesJson != null) {
            final List<dynamic> exercisesData =
                await compute(_decodeJsonList, exercisesJson);
            final exercises = exercisesData
                .map(
                  (e) => Exercise.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();

            // Update memory cache
            _cachedExercises = exercises;
            _lastCacheTime = cacheTime;

            return exercises;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading from persistent cache: $e');
    }

    return null;
  }

  // Get all exercises with caching - از Supabase استفاده می‌کند
  Future<List<Exercise>> getExercises({bool forceRefresh = false}) async {
    // Return cached exercises if still valid (unless force refresh)
    if (!forceRefresh) {
      if (_cachedExercises != null && _lastCacheTime != null) {
        final timeSinceLastCache = DateTime.now().difference(_lastCacheTime!);
        if (timeSinceLastCache < _cacheValidity) {
          return _applyUserDataToExercises(_cachedExercises!);
        }
      }

      // Try persistent cache
      try {
        final cachedExercises = await getExercisesFromCache();
        if (cachedExercises != null) {
          return await _applyUserDataToExercises(cachedExercises);
        }
      } catch (e) {
        debugPrint('Error loading from cache: $e');
      }
    }

    try {
      // اول از Supabase تلاش می‌کنیم (سریع‌تر)
      try {
        debugPrint('=== ExerciseService: Loading from Supabase (ai_exercises table) ===');
        final supabaseExercises = await _getExercisesFromSupabase();
        debugPrint('=== ExerciseService: Loaded ${supabaseExercises.length} exercises from ai_exercises ===');

        // اضافه کردن تمرینات اختصاصی مربی (اگر کاربر مربی باشد)
        final allExercises = <Exercise>[...supabaseExercises];
        final trainerCustomExercises = await _getTrainerCustomExercises();
        if (trainerCustomExercises.isNotEmpty) {
          debugPrint('=== ExerciseService: Adding ${trainerCustomExercises.length} trainer custom exercises ===');
          allExercises.addAll(trainerCustomExercises);
        }

        if (allExercises.isNotEmpty) {
          await _saveExercisesToCache(allExercises);
          _cachedExercises = allExercises;
          _lastCacheTime = DateTime.now();
          return await _applyUserDataToExercises(allExercises);
        }
        
        // اگر Supabase خالی بود، لیست خالی برمی‌گردونیم
        return [];
      } catch (e) {
        debugPrint('Error loading from Supabase: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      // در صورت خطا، cache قبلی را برمی‌گردانیم
      if (_cachedExercises != null) {
        return _applyUserDataToExercises(_cachedExercises!);
      }

      // Try persistent cache as fallback
      try {
        final cachedExercises = await getExercisesFromCache();
        if (cachedExercises != null && cachedExercises.isNotEmpty) {
          return await _applyUserDataToExercises(cachedExercises);
        }
      } catch (_) {
        // Ignore cache errors
      }

      return [];
    }
  }

  /// ذخیره لیست تمرین‌ها در cache پایدار
  Future<void> _saveExercisesToCache(List<Exercise> exercises) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exercisesJson = jsonEncode(
        exercises.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_exercisesListCacheKey, exercisesJson);
      await prefs.setString(
        _exercisesListCacheTimeKey,
        DateTime.now().toIso8601String(),
      );
      await prefs.setInt(_exercisesListCacheVersionKey, _cacheVersion);
    } catch (e) {
      debugPrint('Error saving exercises to cache: $e');
    }
  }

  /// دریافت تمرینات اختصاصی مربی (اگر کاربر مربی باشد)
  Future<List<Exercise>> _getTrainerCustomExercises() async {
    try {
      // IMPORTANT:
      // In this project, `profiles.id` may not equal `auth.users.id` for legacy data,
      // so we must use SimpleProfileService (which has a phone fallback).
      final profileResponse = await SimpleProfileService.getCurrentProfile();
      if (profileResponse == null) return [];

      final role = profileResponse['role'] as String?;
      if (role != 'trainer') return [];

      // دریافت تمرینات اختصاصی مربی
      final customExercises = await _customExerciseService.getMyExercises();
      
      // تبدیل CustomExercise به Exercise با author
      return await _customExerciseService.customExercisesToExercises(customExercises);
    } catch (e) {
      debugPrint('Error fetching trainer custom exercises: $e');
      return [];
    }
  }

  /// دریافت تمرینات از Supabase (سریع‌تر)
  Future<List<Exercise>> _getExercisesFromSupabase() async {
    try {
      debugPrint('=== _getExercisesFromSupabase: Starting query ===');
      debugPrint('=== Table: ai_exercises ===');
      
      final response = await _client
          .from('ai_exercises')
          .select(_listSelectColumns)
          .order('name')
          .limit(1000);

      debugPrint('=== _getExercisesFromSupabase: Query executed, response type: ${response.runtimeType} ===');
      debugPrint('=== _getExercisesFromSupabase: Response length: ${(response as List).length} ===');

      final exercises = <Exercise>[];
      for (final row in response) {
        try {
          final exercise = _mapSupabaseRowToExercise(row, includeRichMeta: false);
          exercises.add(exercise);
        } catch (e, stackTrace) {
          debugPrint('Error mapping exercise: $e');
          debugPrint('Stack trace: $stackTrace');
          continue;
        }
      }

      debugPrint('=== _getExercisesFromSupabase: Mapped ${exercises.length} exercises ===');
      return exercises;
    } catch (e, stackTrace) {
      debugPrint('=== Error fetching from Supabase: $e ===');
      debugPrint('=== Stack trace: $stackTrace ===');
      rethrow;
    }
  }

  /// استخراج detailed_description از source یا ستون مستقیم
  String _extractDetailedDescription(Map<String, dynamic> row) {
    // اول بررسی می‌کنیم که آیا ستون detailed_description وجود داره
    if (row['detailed_description'] != null && 
        (row['detailed_description'] as String).isNotEmpty) {
      return row['detailed_description'] as String;
    }
    
    // اگر نبود، از source استخراج می‌کنیم
    if (row['source'] != null) {
      try {
        Map<String, dynamic>? sourceJson;
        
        // بررسی نوع source: می‌تونه String (JSON) یا Map باشه
        if (row['source'] is Map) {
          sourceJson = row['source'] as Map<String, dynamic>;
        } else if (row['source'] is String) {
          final sourceStr = row['source'] as String;
          if (sourceStr.isNotEmpty) {
            sourceJson = jsonDecode(sourceStr) as Map<String, dynamic>;
          }
        }
        
        if (sourceJson != null) {
          final detailedDesc = sourceJson['detailedDescription'] as String?;
          if (detailedDesc != null && detailedDesc.isNotEmpty) {
            return detailedDesc;
          }
        }
      } catch (e) {
        debugPrint('Error parsing source JSON: $e');
      }
    }
    
    return '';
  }

  static int _parseExerciseId(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// تبدیل ردیف Supabase به Exercise
  Exercise _mapSupabaseRowToExercise(
    Map<String, dynamic> row, {
    bool includeRichMeta = true,
  }) {
    // تبدیل tips از array یا string
    List<String> tipsList = [];
    if (row['tips'] != null) {
      if (row['tips'] is List) {
        tipsList = (row['tips'] as List).whereType<String>().toList();
      } else if (row['tips'] is String) {
        final tipsStr = row['tips'] as String;
        if (tipsStr.isNotEmpty) {
          try {
            final decoded = jsonDecode(tipsStr);
            if (decoded is List) {
              tipsList = decoded.whereType<String>().toList();
            }
          } catch (_) {
            // اگر JSON نیست، به عنوان string استفاده می‌کنیم
            tipsList = [tipsStr];
          }
        }
      }
    }

    // تبدیل other_names
    List<String> otherNamesList = [];
    if (row['other_names'] != null) {
      if (row['other_names'] is List) {
        otherNamesList = (row['other_names'] as List)
            .whereType<String>()
            .toList();
      } else if (row['other_names'] is String) {
        final otherNamesStr = row['other_names'] as String;
        if (otherNamesStr.isNotEmpty) {
          try {
            final decoded = jsonDecode(otherNamesStr);
            if (decoded is List) {
              otherNamesList = decoded.whereType<String>().toList();
            }
          } catch (_) {
            otherNamesList = otherNamesStr
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        }
      }
    }

    final imageUrls = parseStoredMediaUrls(row['image_url']);
    final videoUrls = parseStoredMediaUrls(row['video_url']);
    final shortDesc = (row['short_description'] as String?)?.trim() ?? '';
    final learn = (row['learn'] as String?)?.trim() ?? '';
    final rawContent =
        (row['content'] as String?) ?? (row['description'] as String?) ?? '';

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return Exercise(
      id: _parseExerciseId(row['id']),
      title: (row['name'] as String?) ?? '',
      name: (row['name'] as String?) ?? '',
      mainMuscle: (row['main_muscle'] as String?) ?? '',
      secondaryMuscles: (row['secondary_muscles'] as String?) ?? '',
      tips: tipsList,
      videoUrl: videoUrls.isNotEmpty ? videoUrls.first : '',
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
      additionalVideoUrls:
          videoUrls.length > 1 ? videoUrls.sublist(1) : const <String>[],
      additionalImageUrls:
          imageUrls.length > 1 ? imageUrls.sublist(1) : const <String>[],
      otherNames: otherNamesList,
      content: learn.isNotEmpty ? learn : rawContent,
      difficulty: (row['difficulty'] as String?) ?? 'متوسط',
      equipment: (row['equipment'] as String?) ?? 'بدون تجهیزات',
      exerciseType: (row['exercise_type'] as String?) ?? 'قدرتی',
      estimatedDuration: (row['estimated_duration'] as int?) ?? 0,
      targetArea:
          (row['target_area'] as String?) ??
          (row['main_muscle'] as String?) ??
          '',
      tags: [],
      shortDescription: shortDesc,
      detailedDescription: _extractDetailedDescription(row),
      movementPattern: (row['movement_pattern'] as String?) ?? '',
      bodyEngagement: (row['body_engagement'] as String?) ?? '',
      typicalRpe: parseDouble(row['typical_rpe']),
      met: parseDouble(row['met']),
      author: 'جیم اِی آی',
      muscleTargets: MuscleTargets.parse(row['muscle_targets_json']),
      richMeta: includeRichMeta
          ? ExerciseRichMeta.fromSupabaseRow(row)
          : const ExerciseRichMeta(),
    );
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
      difficulties.add(
        ExerciseDisplayLabels.difficultyLabel(exercise.difficulty),
      );
      equipments.add(
        ExerciseDisplayLabels.equipmentLabel(exercise.equipment),
      );
      exerciseTypes.add(ExerciseDisplayLabels.type(exercise.exerciseType));
      if (exercise.targetArea.isNotEmpty) {
        targetAreas.add(exercise.targetArea);
      }
      if (exercise.mainMuscle.isNotEmpty) {
        muscleGroups.add(exercise.mainMuscle);
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

  /// تمرین با همه فیلدهای متا — اول Supabase، بعد کش/لیست.
  Future<Exercise?> getExerciseById(int id) async {
    if (id <= 0) return null;

    try {
      final row = await _client
          .from('ai_exercises')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row != null) {
        final exercise = _mapSupabaseRowToExercise(
          Map<String, dynamic>.from(row),
        );
        await _saveExerciseToCache(exercise);
        return exercise;
      }
    } catch (e) {
      debugPrint('getExerciseById supabase($id): $e');
    }

    final cachedExercise = await _loadExerciseFromCache(id);
    if (cachedExercise != null) {
      unawaited(_refreshExerciseDetailFromSupabase(id, cachedExercise));
      return cachedExercise;
    }

    final exercises = await getExercises(forceRefresh: true);
    try {
      final exercise = exercises.firstWhere((e) => e.id == id);
      await _saveExerciseToCache(exercise);
      return exercise;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshExerciseDetailFromSupabase(
    int id,
    Exercise cached,
  ) async {
    try {
      final row = await _client
          .from('ai_exercises')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return;
      final fresh = _mapSupabaseRowToExercise(
        Map<String, dynamic>.from(row),
      );
      fresh.isFavorite = cached.isFavorite;
      fresh.isLikedByUser = cached.isLikedByUser;
      fresh.likes = cached.likes;
      await _saveExerciseToCache(fresh);
    } catch (_) {}
  }

  /// Load exercise from SharedPreferences cache
  Future<Exercise?> _loadExerciseFromCache(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'exercise_$id';
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return null;
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Exercise.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error loading exercise from cache: $e');
      return null;
    }
  }

  /// Save exercise to SharedPreferences cache
  Future<void> _saveExerciseToCache(Exercise exercise) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'exercise_${exercise.id}';
      await prefs.setString(key, jsonEncode(exercise.toJson()));
    } catch (e) {
      debugPrint('Error saving exercise to cache: $e');
    }
  }

  /// Update exercise from API in background (non-blocking)
  Future<void> _updateExerciseFromApiInBackground(
    int id,
    Exercise cachedExercise,
  ) async {
    try {
      final url =
          '$apiUrl/$id?_embed=true&_fields=id,title,content,modified,meta,_embedded,featured_image';
      final response = await wordpressGet(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final exerciseData = jsonDecode(response.body) as Map<String, dynamic>;
        final exercise = Exercise.fromJson(exerciseData);

        // Always update cache (exercises don't change often)
        await _saveExerciseToCache(exercise);
        // Update in-memory cache if exists
        if (_cachedExercises != null) {
          final index = _cachedExercises!.indexWhere((e) => e.id == id);
          if (index != -1) {
            _cachedExercises![index] = exercise;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating exercise from API in background: $e');
      }
      // Silently fail - cache is still valid
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
    return ExerciseDisplayLabels.uniqueMuscleCategories(
      exercises.map((e) => e.mainMuscle).where((m) => m.isNotEmpty),
    );
  }

  // Toggle favorite status
  Future<void> toggleFavorite(int exerciseId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final exercises = _cachedExercises;
    if (exercises == null || exercises.isEmpty) {
      throw Exception('لیست تمرین‌ها هنوز بارگذاری نشده است');
    }

    final index = exercises.indexWhere((e) => e.id == exerciseId);
    if (index == -1) {
      throw Exception('تمرین یافت نشد');
    }

    final exercise = exercises[index];
    try {
      if (exercise.isFavorite) {
        await _preferencesService.removeExerciseFromFavorites(exerciseId);
        exercise.isFavorite = false;
      } else {
        await _preferencesService.addExerciseToFavorites(
          exerciseId,
          exercise.name,
          exercise.coverImageUrl,
        );
        exercise.isFavorite = true;
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

    final exercises = _cachedExercises;
    if (exercises == null || exercises.isEmpty) {
      throw Exception('لیست تمرین‌ها هنوز بارگذاری نشده است');
    }

    final index = exercises.indexWhere((e) => e.id == exerciseId);
    if (index == -1) {
      throw Exception('تمرین یافت نشد');
    }

    final exercise = exercises[index];
    try {
      if (exercise.isLikedByUser) {
        await _preferencesService.removeExerciseLike(exerciseId);
        exercise.isLikedByUser = false;
        exercise.likes =
            (exercise.likes - 1).clamp(0, double.infinity).toInt();
      } else {
        await _preferencesService.addExerciseLike(exerciseId);
        exercise.isLikedByUser = true;
        exercise.likes = exercise.likes + 1;
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

      // Filter exercises with likes > 0 (only show exercises that have been liked)
      final exercisesWithLikes = allExercises
          .where((e) => e.likes > 0)
          .toList();

      // Sort by likes (descending)
      exercisesWithLikes.sort((a, b) => b.likes.compareTo(a.likes));

      // Return top 20 (increased from 10 for better UX)
      return exercisesWithLikes.take(20).toList();
    } catch (e) {
      debugPrint('Error getting popular exercises: $e');
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
