import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile_mapper.dart';
import 'package:gymaipro/ai/exercise/safety/exercise_safety_engine.dart';
import 'package:gymaipro/ai/workout/equipment/workout_equipment_tokens.dart';
import 'package:gymaipro/ai/workout/generator/llm_iran_gym_style.dart';
import 'package:gymaipro/models/exercise.dart';

/// Shrinks the exercise catalog for LLM prompts (token control + injury screen).
abstract final class LlmWorkoutCatalogCurator {
  const LlmWorkoutCatalogCurator._();

  static const int defaultMaxExercises = 110;

  /// Prefer equipment-compatible + familiar Iranian staples, then diversify.
  ///
  /// Injury/limitation strings are screened with [ExerciseSafetyEngine] so the
  /// paid generator never even sees high-risk movements (e.g. squat + knee).
  static List<Exercise> curate(
    List<Exercise> catalog, {
    required List<String> equipment,
    List<String> restrictions = const <String>[],
    int maxExercises = defaultMaxExercises,
    ExerciseSafetyEngine safetyEngine = const ExerciseSafetyEngine(),
    ExerciseProfileMapper profileMapper = const ExerciseProfileMapper(),
  }) {
    if (catalog.isEmpty) return const <Exercise>[];

    final tokens = WorkoutEquipmentTokens.expand(equipment);
    final avoid = restrictions
        .map((r) => r.trim().toLowerCase())
        .where((r) => r.isNotEmpty)
        .toList(growable: false);
    final safetyQuery = _safetyQuery(
      equipment: equipment,
      restrictions: restrictions,
    );

    final matched = <Exercise>[];
    final rest = <Exercise>[];

    for (final exercise in catalog) {
      if (_isAvoided(exercise, avoid)) continue;
      if (safetyQuery != null &&
          !_isSafe(
            exercise,
            query: safetyQuery,
            safetyEngine: safetyEngine,
            profileMapper: profileMapper,
          )) {
        continue;
      }
      if (_matchesEquipment(exercise.equipment, tokens)) {
        matched.add(exercise);
      } else {
        rest.add(exercise);
      }
    }

    final pool = List<Exercise>.from(matched.isNotEmpty ? matched : rest)
      ..sort((a, b) {
        final byScore = LlmIranGymPopularity.score(
          b,
        ).compareTo(LlmIranGymPopularity.score(a));
        if (byScore != 0) return byScore;
        return a.name.compareTo(b.name);
      });

    return _diversifyPreferringPopular(pool, maxExercises);
  }

  static ExerciseIntelligenceQuery? _safetyQuery({
    required List<String> equipment,
    required List<String> restrictions,
  }) {
    final meaningful = restrictions
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .where((r) {
          final lower = r.toLowerCase();
          return !lower.contains('ندارم') &&
              !lower.contains('ندارد') &&
              lower != 'none' &&
              lower != 'no' &&
              lower != 'هیچکدام' &&
              lower != 'هیچ کدام';
        })
        .toList(growable: false);
    if (meaningful.isEmpty) return null;
    return ExerciseIntelligenceQuery(
      availableEquipment: equipment,
      limitations: meaningful,
    );
  }

  static bool _isSafe(
    Exercise exercise, {
    required ExerciseIntelligenceQuery query,
    required ExerciseSafetyEngine safetyEngine,
    required ExerciseProfileMapper profileMapper,
  }) {
    final profile = profileMapper.fromExercise(exercise);
    return safetyEngine.evaluate(exercise: profile, query: query).isSafe;
  }

  static bool _isAvoided(Exercise exercise, List<String> avoid) {
    if (avoid.isEmpty) return false;
    final hay = '${exercise.name} ${exercise.mainMuscle}'.toLowerCase();
    for (final token in avoid) {
      if (token.contains('ندارد') || token == 'none') continue;
      if (hay.contains(token)) return true;
    }
    return false;
  }

  static bool _matchesEquipment(String rawEquipment, List<String> tokens) {
    if (tokens.isEmpty) return true;
    final equipment = rawEquipment.trim().toLowerCase();
    if (equipment.isEmpty) return true;

    final joined = tokens.join(' ').toLowerCase();
    final isFullGym =
        joined.contains('باشگاه کامل') ||
        (joined.contains('هالتر') && joined.contains('دمبل'));
    if (isFullGym) return true;

    for (final token in tokens) {
      final t = token.trim().toLowerCase();
      if (t.isEmpty) continue;
      if (equipment.contains(t)) return true;
      if (t.contains('بدون') &&
          (equipment.contains('بدون') ||
              equipment.contains('وزن بدن') ||
              equipment.contains('bodyweight'))) {
        return true;
      }
    }
    return false;
  }

  /// Round-robin by muscle, but each muscle list is already popularity-sorted.
  static List<Exercise> _diversifyPreferringPopular(
    List<Exercise> pool,
    int max,
  ) {
    if (pool.length <= max) {
      return List<Exercise>.unmodifiable(pool);
    }

    final byMuscle = <String, List<Exercise>>{};
    for (final exercise in pool) {
      final key = exercise.mainMuscle.trim().isEmpty
          ? 'other'
          : exercise.mainMuscle.trim();
      (byMuscle[key] ??= <Exercise>[]).add(exercise);
    }

    // Reserve ~55% slots for top global popular picks so staples always appear.
    final reserved = (max * 0.55).round().clamp(40, max);
    final out = <Exercise>[];
    final seen = <int>{};

    for (final exercise in pool) {
      if (out.length >= reserved) break;
      if (seen.add(exercise.id)) out.add(exercise);
    }

    var index = 0;
    while (out.length < max) {
      var added = false;
      for (final entries in byMuscle.values) {
        if (index < entries.length) {
          final exercise = entries[index];
          if (seen.add(exercise.id)) {
            out.add(exercise);
            added = true;
            if (out.length >= max) break;
          } else {
            added = true;
          }
        }
      }
      if (!added) break;
      index++;
    }

    return List<Exercise>.unmodifiable(out);
  }
}
