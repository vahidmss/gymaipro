import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';

/// Static validation rules for GymAI Coach v2.
///
/// Rules are intentionally local and deterministic. They do not call OpenAI,
/// services, databases, or UI layers.
class CoachRules {
  const CoachRules._();

  /// Profile fields required before generating a personalized workout program.
  static const Set<String> workoutGenerationProfileFields = <String>{
    'age',
    'height',
    'weight',
  };

  /// Intents that can be routed to local handling when context is sufficient.
  static const Set<AIIntent> localCapableIntents = <AIIntent>{
    AIIntent.workoutToday,
    AIIntent.recovery,
    AIIntent.motivation,
    AIIntent.appHelp,
    AIIntent.bugReport,
    AIIntent.feedback,
  };

  /// Returns missing profile fields for workout generation.
  static List<String> missingWorkoutGenerationData(CoachContext context) {
    final profile = context.profile;
    final missing = <String>[];

    for (final field in workoutGenerationProfileFields) {
      if (!_hasValue(profile[field])) {
        missing.add(field);
      }
    }

    if (!_hasGoal(context, profile)) {
      missing.add('goal');
    }

    return List<String>.unmodifiable(missing);
  }

  static bool _hasGoal(CoachContext context, Map<String, Object?> profile) {
    if (context.goals.isNotEmpty) return true;

    return _hasValue(profile['fitness_goals']) || _hasValue(profile['goal']);
  }

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable<Object?>) return value.isNotEmpty;
    return true;
  }
}
