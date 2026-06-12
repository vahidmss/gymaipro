import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gymaipro/admin/services/exercise_v3_sync_mapper.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/network/wordpress_http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس sync تمرین‌ها از WordPress (+ ادغام gymai/v3.6) به Supabase
class ExerciseSyncService {
  final SupabaseClient _client = Supabase.instance.client;
  String get _wordpressApiUrl =>
      '${AppConfig.wordpressApiOrigin}/wp-json/wp/v2/exercises';

  /// متاهای وردپرس که ستون جدا ندارند — در `exercise_extended_json.wp_meta`.
  static const List<String> _wpExtendedMetaKeys = [
    'mechanics_type',
    'force_type',
    'plane_of_motion',
    'laterality',
    'posture',
    'grip_type',
    'resistance_profile',
    'joint_focus',
    'programming_goal',
    'recommended_sets',
    'rep_range_strength',
    'rep_range_hypertrophy',
    'rep_range_endurance',
    'rest_seconds',
    'tempo',
    'setup',
    'execution',
    'breathing',
    'common_mistakes',
    'contraindications',
    'secondary_muscle_keys',
    'equipment_keys',
  ];

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Sync همه تمرین‌ها از WordPress به Supabase
  Future<SyncResult> syncExercises({
    void Function(int current, int total, String exerciseName)? onProgress,
  }) async {
    try {
      _log('=== Starting exercise sync (WP + gymai/v3) ===');

      final v3ById = await ExerciseV3SyncMapper.fetchAllById();
      _log('=== V3 catalog: ${v3ById.length} exercises ===');

      final wordpressExercises = await _fetchExercisesFromWordPress();
      _log(
        '=== Fetched ${wordpressExercises.length} exercises from WordPress ===',
      );

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
      int v3MergedCount = 0;
      final List<String> errors = [];

      for (int i = 0; i < wordpressExercises.length; i++) {
        final wpRow = wordpressExercises[i];
        final exercise = wpRow.exercise;
        onProgress?.call(i + 1, wordpressExercises.length, exercise.title);

        try {
          final v3 = v3ById[exercise.id];
          if (v3 != null) v3MergedCount++;
          await _syncExerciseToSupabase(exercise, wpRow.raw, v3Item: v3);
          syncedCount++;
        } catch (e) {
          failedCount++;
          errors.add('${exercise.title}: $e');
          _log('Error syncing exercise ${exercise.title}: $e');
        }
      }

      onProgress?.call(
        wordpressExercises.length,
        wordpressExercises.length,
        'تمام',
      );

      final v3Note = v3ById.isEmpty
          ? ' (API v3 در دسترس نبود — فقط WP)'
          : ' — $v3MergedCount مورد با v3.6 ادغام شد';

      return SyncResult(
        success: failedCount == 0,
        message:
            'Sync کامل شد: $syncedCount موفق، $failedCount ناموفق$v3Note',
        syncedCount: syncedCount,
        failedCount: failedCount,
        v3MergedCount: v3MergedCount,
        errors: errors,
      );
    } catch (e, stackTrace) {
      _log('Error in syncExercises: $e');
      _log('Stack trace: $stackTrace');
      return SyncResult(
        success: false,
        message: 'خطا در sync: $e',
        syncedCount: 0,
        failedCount: 0,
      );
    }
  }

  /// دریافت تمرین‌ها از WordPress REST API
  Future<List<_WpExerciseRow>> _fetchExercisesFromWordPress() async {
    final List<_WpExerciseRow> exercises = [];
    int page = 1;

    while (true) {
      final url =
          '$_wordpressApiUrl?_embed=true&per_page=100&page=$page&_fields=id,title,content,modified,meta,_embedded,featured_image';

      try {
        final response = await wordpressGet(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          timeout: const Duration(seconds: 20),
        );

        if (response.statusCode == 200) {
          final List<dynamic> exercisesData =
              jsonDecode(response.body) as List<dynamic>;

          if (exercisesData.isEmpty) break;

          for (final exerciseData in exercisesData) {
            try {
              final raw = exerciseData as Map<String, dynamic>;
              final exercise = Exercise.fromJson(raw);
              exercises.add(_WpExerciseRow(exercise: exercise, raw: raw));
            } catch (e) {
              _log('Error parsing exercise: $e');
              continue;
            }
          }

          page++;
          if (page > 20) break;
        } else if (response.statusCode == 400 || response.statusCode == 404) {
          break;
        } else {
          _log('WordPress API error: ${response.statusCode}');
          break;
        }
      } catch (e) {
        _log('Error fetching page $page: $e');
        break;
      }
    }

    return exercises;
  }

  Future<void> _syncExerciseToSupabase(
    Exercise exercise,
    Map<String, dynamic> wpRaw, {
    Map<String, dynamic>? v3Item,
  }) async {
    final supabaseData = _exerciseToSupabaseData(exercise, wpRaw);
    if (v3Item != null) {
      ExerciseV3SyncMapper.applyToSupabaseRow(supabaseData, v3Item);
    }
    await _client.from('ai_exercises').upsert(supabaseData, onConflict: 'id');
  }

  Map<String, dynamic> _exerciseToSupabaseData(
    Exercise exercise,
    Map<String, dynamic> wpRaw,
  ) {
    final meta = wpRaw['meta'];
    final Map<String, dynamic> metaMap = meta is Map<String, dynamic>
        ? meta
        : <String, dynamic>{};

    String readMeta(String key) {
      final v = metaMap[key];
      if (v == null) return '';
      if (v is List) return v.whereType<String>().join(', ');
      return v.toString().trim();
    }

    final shortDesc = readMeta('short_description');
    final detailedDesc = readMeta('detailed_description');
    final learn = readMeta('learn');
    final seoContent = readMeta('seo_content');
    final movementPattern = readMeta('movement_pattern');
    final bodyEngagement = readMeta('body_engagement');
    final estimated1RmFormula = readMeta('estimated_1rm_formula');

    final muscleTargets = ExerciseV3SyncMapper.resolveMuscleTargetsJson(
      metaMap: metaMap,
      exerciseTargets: exercise.muscleTargets,
    );

    num? parseNum(String key) {
      final s = readMeta(key);
      if (s.isEmpty) return null;
      return num.tryParse(s);
    }

    int? parseInt(String key) {
      final n = parseNum(key);
      return n?.round();
    }

    var imageUrl = exercise.imageUrl;
    if (imageUrl.isEmpty) {
      final metaImg = readMeta('image_url');
      if (metaImg.isNotEmpty) {
        imageUrl = metaImg;
      } else {
        final thumb = readMeta('thumbnail_url');
        if (thumb.isNotEmpty) imageUrl = thumb;
      }
    }

    final modified = (wpRaw['modified'] ?? '').toString();
    final syncedAtIso = DateTime.now().toIso8601String();

    final data = <String, dynamic>{
      'id': exercise.id,
      'name': exercise.name,
      'content': exercise.content,
      'main_muscle': exercise.mainMuscle,
      'secondary_muscles': exercise.secondaryMuscles,
      'tips': exercise.tips,
      'video_url': exercise.videoUrl.isNotEmpty
          ? exercise.videoUrl
          : (readMeta('video_url').isNotEmpty ? readMeta('video_url') : null),
      'image_url': imageUrl.isNotEmpty ? imageUrl : null,
      'other_names': exercise.otherNames,
      'difficulty': exercise.difficulty,
      'equipment': exercise.equipment,
      'exercise_type': exercise.exerciseType,
      'estimated_duration': exercise.estimatedDuration,
      'target_area': exercise.targetArea.isNotEmpty
          ? exercise.targetArea
          : (readMeta('target_area').isNotEmpty
                ? readMeta('target_area')
                : exercise.mainMuscle),
      'short_description': shortDesc.isNotEmpty ? shortDesc : null,
      'detailed_description': detailedDesc.isNotEmpty
          ? detailedDesc
          : (exercise.detailedDescription.isNotEmpty
                ? exercise.detailedDescription
                : null),
      'learn': learn.isNotEmpty ? learn : null,
      'seo_content': seoContent.isEmpty ? null : seoContent,
      'movement_pattern': movementPattern.isEmpty ? null : movementPattern,
      'body_engagement': bodyEngagement.isEmpty ? null : bodyEngagement,
      'estimated_1rm_formula': estimated1RmFormula.isEmpty
          ? null
          : estimated1RmFormula,
      'muscle_targets_json': muscleTargets,
      'exercise_extended_json': _wpExtendedFromMeta(metaMap),
      'met': parseNum('met'),
      'movement_distance_cm': parseInt('movement_distance_cm'),
      'calories_per_1000kg': parseInt('calories_per_1000kg'),
      'exercise_difficulty_score': parseInt('exercise_difficulty_score'),
      'typical_rpe': parseNum('typical_rpe'),
      'views_count': parseInt('views_count') ?? 0,
      'likes_count': parseInt('likes_count') ?? 0,
      'wordpress_modified': modified.isNotEmpty
          ? DateTime.tryParse(modified)?.toIso8601String()
          : null,
      'synced_at': syncedAtIso,
      'source': jsonEncode({
        'tags': exercise.tags,
        'title': exercise.title,
        'detailedDescription': detailedDesc.isNotEmpty
            ? detailedDesc
            : exercise.detailedDescription,
      }),
    };

    return data..removeWhere((_, v) => v == null);
  }

  static Map<String, dynamic> _wpExtendedFromMeta(Map<String, dynamic> metaMap) {
    final wpMeta = <String, dynamic>{};
    for (final key in _wpExtendedMetaKeys) {
      final v = metaMap[key];
      if (v == null) continue;
      final s = v is List
          ? v.map((e) => e.toString()).join('\n')
          : v.toString().trim();
      if (s.isNotEmpty) wpMeta[key] = s;
    }
    if (wpMeta.isEmpty) return {};
    return {'wp_meta': wpMeta};
  }

  Future<int> getSupabaseExerciseCount() async {
    try {
      final res = await _client
          .from('ai_exercises')
          .select('id')
          .count();
      return res.count;
    } catch (e) {
      _log('Error getting Supabase count: $e');
      return 0;
    }
  }

  Future<int> getWordPressExerciseCount() async {
    try {
      final response = await wordpressGet(
        Uri.parse('$_wordpressApiUrl?per_page=1'),
        headers: {'Content-Type': 'application/json'},
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final totalHeader = response.headers['x-wp-total'];
        if (totalHeader != null) {
          return int.tryParse(totalHeader) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      _log('Error getting WordPress count: $e');
      return 0;
    }
  }
}

class _WpExerciseRow {
  const _WpExerciseRow({required this.exercise, required this.raw});

  final Exercise exercise;
  final Map<String, dynamic> raw;
}

class SyncResult {
  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
    this.v3MergedCount = 0,
    this.errors,
  });
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final int v3MergedCount;
  final List<String>? errors;
}
