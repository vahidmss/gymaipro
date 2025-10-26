import 'package:flutter/foundation.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIExerciseReadService {
  final SupabaseClient _db = Supabase.instance.client;

  /// خواندن تمرین‌ها فقط از جدول ai_exercises (برای AI)
  Future<List<Exercise>> getExercisesForAI({int limit = 500}) async {
    try {
      // پیشنهاد: استفاده از RPC با SECURITY DEFINER برای عبور از RLS
      final rows = await _db.rpc<List<dynamic>>(
        'ai_exercises_list',
        params: {'limit_count': limit},
      );

      return rows.map<Exercise>(_mapRowToExercise).toList();
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('[AIExerciseRead] Error: $e');
      return [];
    }
  }

  Exercise _mapRowToExercise(dynamic row) {
    final Map<String, dynamic> r = Map<String, dynamic>.from(row as Map);
    return Exercise(
      id: (r['id'] as int?) ?? 0,
      title: (r['name'] as String?) ?? '',
      name: (r['name'] as String?) ?? '',
      mainMuscle: (r['main_muscle'] as String?) ?? '',
      secondaryMuscles: (r['secondary_muscles'] as String?) ?? '',
      tips:
          (r['tips'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
      videoUrl: (r['video_url'] as String?) ?? '',
      imageUrl: (r['image_url'] as String?) ?? '',
      otherNames:
          (r['other_names'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
      content: (r['content'] as String?) ?? '',
      difficulty: (r['difficulty'] as String?) ?? 'متوسط',
      equipment: (r['equipment'] as String?) ?? 'بدون تجهیزات',
      exerciseType: (r['exercise_type'] as String?) ?? 'قدرتی',
      estimatedDuration: (r['estimated_duration'] as int?) ?? 0,
      targetArea: (r['target_area'] as String?) ?? '',
    );
  }
}
