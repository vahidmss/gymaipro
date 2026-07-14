import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/skills/coach_skill_type.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/ai/skills/skill_capability.dart';

/// Evaluation produced by a [CoachSkill] for one request.
class SkillEvaluation {
  const SkillEvaluation({
    required this.skillId,
    required this.skillType,
    required this.outcome,
    required this.confidence,
    required this.estimatedLatency,
    required this.requiresAIFallback,
    required this.missingContext,
    this.previewMessage,
    this.notes = const <String>[],
  });

  final String skillId;
  final CoachSkillType skillType;
  final SkillOutcome outcome;
  final double confidence;
  final Duration estimatedLatency;
  final bool requiresAIFallback;
  final List<AIContextProviderKey> missingContext;
  final String? previewMessage;
  final List<String> notes;

  bool get canHandleLocally => outcome == SkillOutcome.handledLocally;
  bool get canHandlePartially => outcome == SkillOutcome.partialLocal;
}

/// Contract for a local-capable coach skill.
///
/// Skills are descriptive only. They do not call OpenAI, APIs, navigation, or
/// prompt builders.
abstract class CoachSkill {
  const CoachSkill();

  /// Stable skill id.
  String get id;

  /// Skill family.
  CoachSkillType get type;

  /// Human-readable title.
  String get title;

  /// Intents this skill can attempt to satisfy locally.
  Set<AIIntent> get supportedIntents;

  /// Context providers required for a confident local answer.
  Set<AIContextProviderKey> get requiredContext;

  /// Context providers that improve local answer quality.
  Set<AIContextProviderKey> get optionalContext;

  /// Baseline confidence when required context is present.
  double get baseConfidence;

  /// Estimated local execution latency.
  Duration get estimatedLatency;

  /// Whether AI should still be considered after a partial local answer.
  bool get requiresAIFallback;

  /// Capability metadata for future executor integration.
  SkillCapability get capability;

  /// Evaluates whether this skill can answer locally for [intent].
  SkillEvaluation evaluate({
    required CoachContext context,
    required AIIntent intent,
  });
}

/// Contract for skills that can produce a local runtime response.
abstract class CoachRunnableSkill extends CoachSkill {
  const CoachRunnableSkill();

  /// Executes the skill and returns a local response or AI fallback signal.
  CoachSkillResponse execute({
    required CoachContext context,
    required AIIntent intent,
  });
}

/// Shared context checks for skill evaluation.
abstract class CoachSkillContextChecks {
  const CoachSkillContextChecks._();

  static bool hasProvider(CoachContext context, AIContextProviderKey provider) {
    switch (provider) {
      case AIContextProviderKey.profile:
        return context.profile.isNotEmpty;
      case AIContextProviderKey.goals:
        return context.goals.isNotEmpty ||
            _hasValue(context.profile['fitness_goals']) ||
            _hasValue(context.profile['goal']);
      case AIContextProviderKey.restrictions:
        return context.restrictions.isNotEmpty;
      case AIContextProviderKey.activeProgram:
        return context.activeProgram != null &&
            context.activeProgram!.isNotEmpty;
      case AIContextProviderKey.workoutHistory:
        return context.workoutHistory.isNotEmpty;
      case AIContextProviderKey.heatmap:
        return context.weeklyHeatmap != null;
      case AIContextProviderKey.equipment:
        return context.equipment.isNotEmpty;
      case AIContextProviderKey.memory:
        return context.memories.isNotEmpty;
      case AIContextProviderKey.currentQuestion:
        final question = context.currentQuestion;
        return question != null && question.trim().isNotEmpty;
      case AIContextProviderKey.apiUsage:
        return context.apiUsage.isNotEmpty;
      case AIContextProviderKey.recovery:
        return context.preferences.containsKey('recovery') ||
            context.preferences.containsKey('recovery_score');
      case AIContextProviderKey.preferences:
        return context.preferences.isNotEmpty;
      case AIContextProviderKey.chatHistory:
        return !context.conversationSummary.placeholder ||
            (context.conversationSummary.messageCount > 0);
      case AIContextProviderKey.nutrition:
      case AIContextProviderKey.supplements:
      case AIContextProviderKey.appHelp:
      case AIContextProviderKey.diagnostics:
        return context.preferences.containsKey(provider.name);
    }
  }

  static List<AIContextProviderKey> missingRequired(
    CoachContext context,
    Set<AIContextProviderKey> required,
  ) {
    return required
        .where((provider) => !hasProvider(context, provider))
        .toList(growable: false);
  }

  static double confidenceFromCoverage({
    required double baseConfidence,
    required Set<AIContextProviderKey> required,
    required Set<AIContextProviderKey> optional,
    required CoachContext context,
  }) {
    if (required.isEmpty) return baseConfidence;

    final requiredPresent = required
        .where((provider) => hasProvider(context, provider))
        .length;
    final requiredRatio = requiredPresent / required.length;
    if (requiredRatio < 1) {
      return (baseConfidence * requiredRatio).clamp(0, 1);
    }

    if (optional.isEmpty) return baseConfidence;

    final optionalPresent = optional
        .where((provider) => hasProvider(context, provider))
        .length;
    final optionalBonus = optional.isEmpty
        ? 0.0
        : (optionalPresent / optional.length) * 0.08;
    return (baseConfidence + optionalBonus).clamp(0, 1);
  }

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable<Object?>) return value.isNotEmpty;
    return true;
  }
}
