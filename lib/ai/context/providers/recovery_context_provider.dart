import 'package:gymaipro/ai/context/coach_context_patch.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads live recovery signals written after workouts into coach preferences.
///
/// Keys match [LiveWorkoutCompletionService]:
/// - `recovery_score_$userId`
/// - `last_workout_completed_at_$userId`
class RecoveryContextProvider implements AIContextProvider {
  RecoveryContextProvider({
    AIContextRepository? repository,
    SharedPreferences? preferences,
  }) : _preferences = preferences,
       _repository = repository;

  final SharedPreferences? _preferences;
  // Kept for AIContextBuilder.standard() wiring compatibility.
  // ignore: unused_field
  final AIContextRepository? _repository;

  static String recoveryScoreKey(String userId) => 'recovery_score_$userId';

  static String lastWorkoutCompletedAtKey(String userId) =>
      'last_workout_completed_at_$userId';

  @override
  String get id => 'recovery_context_provider';

  @override
  String get name => 'Recovery Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.recovery,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.recovery,
  };

  @override
  AIContextProviderMetadata get metadata => AIContextProviderMetadata(
    name: name,
    priority: priority,
    estimatedCost: estimatedCost,
    estimatedLatency: estimatedLatency,
    cacheable: cacheable,
    ttl: ttl,
  );

  @override
  ContextPriority get priority => ContextPriority.high;

  @override
  double get estimatedCost => 0;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 40);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 5);

  @override
  Future<CoachContextPatch> build(AIContextRequest request) async {
    final userId = request.userId.trim();
    if (userId.isEmpty) return CoachContextPatch.empty;

    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final rawScore = prefs.getString(recoveryScoreKey(userId));
    final rawCompletedAt = prefs.getString(lastWorkoutCompletedAtKey(userId));

    var score = int.tryParse(rawScore ?? '');
    final completedAt = DateTime.tryParse(rawCompletedAt ?? '');
    final now = DateTime.now();
    int? daysSince;

    if (completedAt != null) {
      daysSince = now.difference(completedAt).inDays;
      // Rest days restore readiness after a logged session.
      if (score != null && daysSince > 0) {
        score = (score + daysSince * 10).clamp(score, 100);
      } else if (score == null && daysSince >= 0) {
        score = (45 + daysSince * 12).clamp(35, 95);
      }
    }

    if (score == null && rawScore == null && rawCompletedAt == null) {
      return CoachContextPatch.empty;
    }

    return CoachContextPatch(
      preferences: <String, Object?>{
        if (score != null) 'recovery_score': score,
        if (completedAt != null)
          'last_workout_completed_at': completedAt.toIso8601String(),
        if (daysSince != null) 'days_since_last_workout': daysSince,
      },
    );
  }
}
