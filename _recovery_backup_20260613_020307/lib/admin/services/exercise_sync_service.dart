import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس sync تمرین‌ها از WordPress به Supabase
class ExerciseSyncService {
  final SupabaseClient _client = Supabase.instance.client;
  final String _wordpressApiUrl = 'https://gymaipro.ir/wp-json/wp/v2/exercises';

  /// Sync همه تمرین‌ها از WordPress به Supabase
  Future<SyncResult> syncExercises({
    void Function(int current, int total, String exerciseName)? onProgress,
  }) async {
    try {
      debugPrint('=== Starting exercise sync from WordPress ===');
      
      // دریافت تمرین‌ها از WordPress
      final wordpressExercises = await _fetchExercisesFromWordPress();
      debugPrint('=== Fetched ${wordpressExercises.length} exercises from WordPress ===');
      
      if (wordpressExercises.isEmpty) {
        return SyncResult(
          success: false,
          message: 'هیچ تمرینی از WordPress دریافت نشد',
          syncedCount: 0,
          failedCount: 0,
        );
      }

      int syncedCount = 0;
      int failedCount = 0;
      final List<String> errors = [];

      // Sync هر تمرین به Supabase
      for (int i = 0; i < wordpressExercises.length; i++) {
        final exercise = wordpressExercises[i];
        onProgress?.call(i + 1, wordpressExercises.length, exercise.title);
        
        try {
          await _syncExerciseToSupabase(exercise);
          syncedCount++;
        } catch (e) {
          failedCount++;
          errors.add('${exercise.title}: $e');
          debugPrint('Error syncing exercise ${exercise.title}: $e');
        }
      }

      onProgress?.call(wordpressExercises.length, wordpressExercises.length, 'تمام');

      return SyncResult(
        success: failedCount == 0,
        message: 'Sync کامل شد: $syncedCount موفق، $failedCount ناموفق',
        syncedCount: syncedCount,
        failedCount: failedCount,
        errors: errors,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in syncExercises: $e');
      debugPrint('Stack trace: $stackTrace');
      return SyncResult(
        success: false,
        message: 'خطا در sync: $e',
        syncedCount: 0,
        failedCount: 0,
      );
    }
  }

  /// دریافت تمرین‌ها از WordPress API
  Future<List<Exercise>> _fetchExercisesFromWordPress() async {
    final List<Exercise> exercises = [];
    int page = 1;
    
    while (true) {
      final url =
          '$_wordpressApiUrl?_embed=true&per_page=100&page=$page&_fields=id,title,content,modified,meta,_embedded,featured_image';
      
      try {
        final response = await http
            .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> exercisesData =
              jsonDecode(response.body) as List<dynamic>;
          
          if (exercisesData.isEmpty) break;

          for (final exerciseData in exercisesData) {
            try {
              final exercise = Exercise.fromJson(
                exerciseData as Map<String, dynamic>,
              );
              exercises.add(exercise);
            } catch (e) {
              debugPrint('Error parsing exercise: $e');
              continue;
            }
          }

          page++;
          // محدود کردن تعداد صفحات
          if (page > 20) break; // حداکثر 2000 تمرین
        } else if (response.statusCode == 400 || response.statusCode == 404) {
          break;
        } else {
          debugPrint('WordPress API error: ${response.statusCode}');
          break;
        }
      } catch (e) {
        debugPrint('Error fetching page $page: $e');
        break;
      }
    }

    return exercises;
  }

  /// Sync یک تمرین به Supabase
  Future<void> _syncExerciseToSupabase(Exercise exercise) async {
    // تبدیل Exercise به فرمت Supabase
    final supabaseData = _exerciseToSupabaseData(exercise);

    // استفاده از upsert برای insert یا update
    await _client.from('ai_exercises').upsert(
      supabaseData,
      onConflict: 'id',
    );
  }

  /// تبدیل Exercise به فرمت Supabase
  Map<String, dynamic> _exerciseToSupabaseData(Exercise exercise) {
    final data = <String, dynamic>{
      'id': exercise.id,
      'name': exercise.name,
      // 'title' column doesn't exist in ai_exercises table, using 'name' instead
      'content': exercise.content,
      'main_muscle': exercise.mainMuscle,
      'secondary_muscles': exercise.secondaryMuscles,
      'tips': exercise.tips,
      'video_url': exercise.videoUrl,
      'image_url': exercise.imageUrl,
      'other_names': exercise.otherNames,
      'difficulty': exercise.difficulty,
      'equipment': exercise.equipment,
      'exercise_type': exercise.exerciseType,
      'estimated_duration': exercise.estimatedDuration,
      'target_area': exercise.targetArea.isNotEmpty 
          ? exercise.targetArea 
          : exercise.mainMuscle,
      // 'description' and 'detailed_description' columns don't exist in ai_exercises table
      // detailed_description is stored in 'source' JSON field and extracted during read
    };
    
    return data;
  }

  /// دریافت تعداد تمرین‌های موجود در Supabase
  Future<int> getSupabaseExerciseCount() async {
    try {
      final response = await _client
          .from('ai_exercises')
          .select('id');
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting Supabase count: $e');
      return 0;
    }
  }

  /// دریافت تعداد تمرین‌های موجود در WordPress
  Future<int> getWordPressExerciseCount() async {
    try {
      final response = await http.get(
        Uri.parse('$_wordpressApiUrl?per_page=1'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // از header X-WP-Total استفاده می‌کنیم
        final totalHeader = response.headers['x-wp-total'];
        if (totalHeader != null) {
          return int.tryParse(totalHeader) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting WordPress count: $e');
      return 0;
    }
  }
}

/// نتیجه sync
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final List<String>? errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
    this.errors,
  });
}

