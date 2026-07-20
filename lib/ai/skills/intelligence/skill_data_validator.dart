import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';

/// Coverage assessment for skill intelligence inputs.
class SkillDataCoverage {
  const SkillDataCoverage({
    required this.confidence,
    required this.requiresAI,
    required this.presentSignals,
    required this.missingSignals,
  });

  /// Computed confidence from available context signals.
  final double confidence;

  /// Whether the skill should fall back to AI.
  final bool requiresAI;

  /// Context signals that were present.
  final List<String> presentSignals;

  /// Context signals that were missing.
  final List<String> missingSignals;
}

/// Validates available [CoachContext] data and computes confidence.
class SkillDataValidator {
  const SkillDataValidator();

  /// Minimum confidence required for a local skill response.
  static const double localConfidenceThreshold = 0.55;

  /// Assesses data for workout-today skill intelligence.
  SkillDataCoverage workoutToday(CoachContext context) {
    return _assess(
      weights: <String, double>{
        'activeProgram': 0.25,
        'history': 0.2,
        'heatmap': 0.2,
        'goal': 0.15,
        'equipment': 0.1,
        'recovery': 0.1,
      },
      present: <String, bool>{
        'activeProgram': _hasActiveProgram(context),
        'history': context.workoutHistory.isNotEmpty,
        'heatmap': context.weeklyHeatmap?.hasHeatmapData ?? false,
        'goal': context.goals.isNotEmpty || _hasProfileGoal(context),
        'equipment': context.equipment.isNotEmpty,
        'recovery': _hasRecoverySignal(context),
      },
    );
  }

  /// Assesses data for heatmap skill intelligence.
  SkillDataCoverage heatmap(CoachContext context) {
    final heatmap = context.weeklyHeatmap;
    return _assess(
      weights: <String, double>{
        'heatmap': 0.55,
        'history': 0.2,
        'goal': 0.15,
        'program': 0.1,
      },
      present: <String, bool>{
        'heatmap': heatmap?.hasHeatmapData ?? false,
        'history': context.workoutHistory.isNotEmpty,
        'goal': context.goals.isNotEmpty || _hasProfileGoal(context),
        'program': _hasActiveProgram(context),
      },
    );
  }

  /// Assesses data for motivation skill intelligence.
  SkillDataCoverage motivation(CoachContext context) {
    return _assess(
      weights: <String, double>{
        'question': 0.35,
        'goal': 0.2,
        'history': 0.15,
        'heatmap': 0.15,
        'progressTrend': 0.15,
      },
      present: <String, bool>{
        'question': _hasCurrentQuestion(context),
        'goal': context.goals.isNotEmpty || _hasProfileGoal(context),
        'history': context.workoutHistory.isNotEmpty,
        'heatmap': context.weeklyHeatmap?.hasHeatmapData ?? false,
        'progressTrend': context.weeklyHeatmap?.weekTrendLine != null,
      },
    );
  }

  /// Assesses data for recovery / readiness skill intelligence.
  SkillDataCoverage recovery(CoachContext context) {
    return _assess(
      weights: <String, double>{
        'recovery': 0.4,
        'question': 0.2,
        'history': 0.2,
        'heatmap': 0.2,
      },
      present: <String, bool>{
        'recovery': _hasRecoverySignal(context) || _hasProfileRecovery(context),
        'question': _hasCurrentQuestion(context),
        'history': context.workoutHistory.isNotEmpty,
        'heatmap': context.weeklyHeatmap?.hasHeatmapData ?? false,
      },
    );
  }

  /// Assesses data for app-help skill intelligence.
  SkillDataCoverage appHelp({
    required CoachContext context,
    required AIIntent intent,
  }) {
    if (intent == AIIntent.bugReport || intent == AIIntent.feedback) {
      return const SkillDataCoverage(
        confidence: 0.5,
        requiresAI: true,
        presentSignals: <String>['question'],
        missingSignals: <String>['aiEscalation'],
      );
    }

    return _assess(
      weights: <String, double>{
        'question': 0.4,
        'apiUsage': 0.2,
        'program': 0.2,
        'history': 0.2,
      },
      present: <String, bool>{
        'question': _hasCurrentQuestion(context),
        'apiUsage': context.apiUsage.isNotEmpty,
        'program': _hasActiveProgram(context),
        'history': context.workoutHistory.isNotEmpty,
      },
    );
  }

  SkillDataCoverage _assess({
    required Map<String, double> weights,
    required Map<String, bool> present,
  }) {
    var confidence = 0.0;
    final presentSignals = <String>[];
    final missingSignals = <String>[];

    for (final entry in weights.entries) {
      if (present[entry.key] ?? false) {
        confidence += entry.value;
        presentSignals.add(entry.key);
      } else {
        missingSignals.add(entry.key);
      }
    }

    confidence = confidence.clamp(0.0, 1.0);
    return SkillDataCoverage(
      confidence: confidence,
      requiresAI: confidence < localConfidenceThreshold,
      presentSignals: List<String>.unmodifiable(presentSignals),
      missingSignals: List<String>.unmodifiable(missingSignals),
    );
  }

  bool _hasActiveProgram(CoachContext context) {
    final program = context.activeProgram;
    return program != null && program.isNotEmpty;
  }

  bool _hasCurrentQuestion(CoachContext context) {
    final question = context.currentQuestion;
    return question != null && question.trim().isNotEmpty;
  }

  bool _hasProfileGoal(CoachContext context) {
    final goal = context.profile['goal'] ?? context.profile['fitness_goals'];
    if (goal is String) return goal.trim().isNotEmpty;
    if (goal is Iterable<Object?>) return goal.isNotEmpty;
    return false;
  }

  bool _hasRecoverySignal(CoachContext context) {
    final recovery = context.preferences['recovery'];
    final recoveryScore = context.preferences['recovery_score'];
    final sleepHours = context.preferences['bb_sleep_hours'];
    final days = context.preferences['days_since_last_workout'];
    return recovery != null ||
        recoveryScore != null ||
        sleepHours != null ||
        days != null;
  }

  bool _hasProfileRecovery(CoachContext context) {
    return context.profile['recovery'] != null ||
        context.profile['readiness'] != null ||
        context.profile['fatigue'] != null ||
        context.profile['sleep'] != null;
  }
}
