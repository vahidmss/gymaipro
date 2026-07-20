import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/skills/coach_skill.dart';
import 'package:gymaipro/ai/skills/coach_skill_type.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_renderer.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/ai/skills/skill_capability.dart';
import 'package:gymaipro/ai/workout/runtime/workout_generation_skill.dart';

const CoachSkillRenderer _skillRenderer = CoachSkillRenderer();

/// Registry of local-capable coach skills.
///
/// This registry is infrastructure-only and is not connected to runtime yet.
class CoachSkillRegistry {
  const CoachSkillRegistry({this.skills = defaultSkills});

  static const List<CoachSkill> defaultSkills = <CoachSkill>[
    WorkoutTodaySkill(),
    HeatmapSkill(),
    RecoverySkill(),
    ProgressSummarySkill(),
    MotivationSkill(),
    AppHelpSkill(),
    // Offline generator: asks follow-ups when profile/goals/equipment missing;
    // falls back to AI when exercise catalog is not injected yet.
    WorkoutGenerationSkill(),
  ];

  final List<CoachSkill> skills;

  /// Returns skills that support [intent].
  List<CoachSkill> skillsForIntent(AIIntent intent) {
    return skills
        .where((skill) => skill.supportedIntents.contains(intent))
        .toList(growable: false);
  }

  /// Finds a skill by stable id.
  CoachSkill? skillById(String id) {
    for (final skill in skills) {
      if (skill.id == id) return skill;
    }
    return null;
  }
}

/// Shows today's workout from the active program without calling OpenAI.
class WorkoutTodaySkill extends CoachRunnableSkill {
  const WorkoutTodaySkill();

  @override
  String get id => 'workout_today_skill';

  @override
  CoachSkillType get type => CoachSkillType.workoutToday;

  @override
  String get title => 'Workout Today';

  @override
  Set<AIIntent> get supportedIntents => const <AIIntent>{AIIntent.workoutToday};

  @override
  Set<AIContextProviderKey> get requiredContext => const <AIContextProviderKey>{
    AIContextProviderKey.activeProgram,
  };

  @override
  Set<AIContextProviderKey> get optionalContext => const <AIContextProviderKey>{
    AIContextProviderKey.workoutHistory,
    AIContextProviderKey.heatmap,
    AIContextProviderKey.profile,
  };

  @override
  double get baseConfidence => 0.9;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 120);

  @override
  bool get requiresAIFallback => false;

  @override
  SkillCapability get capability => const SkillCapability(
    id: 'show_today_workout',
    title: 'Show Today Workout',
    description: 'Summarize the active program session for today.',
    kind: SkillCapabilityKind.readOnlyData,
    outputs: <String>['show_program', 'today_session_summary'],
    navigationTargets: <String>['active_program'],
  );

  @override
  SkillEvaluation evaluate({
    required CoachContext context,
    required AIIntent intent,
  }) {
    final missing = CoachSkillContextChecks.missingRequired(
      context,
      requiredContext,
    );
    if (missing.isNotEmpty) {
      return _insufficient(missing);
    }

    final confidence = CoachSkillContextChecks.confidenceFromCoverage(
      baseConfidence: baseConfidence,
      required: requiredContext,
      optional: optionalContext,
      context: context,
    );

    return SkillEvaluation(
      skillId: id,
      skillType: type,
      outcome: SkillOutcome.handledLocally,
      confidence: confidence,
      estimatedLatency: estimatedLatency,
      requiresAIFallback: false,
      missingContext: const <AIContextProviderKey>[],
      previewMessage: 'Local today-workout summary is available.',
      notes: const <String>['Active program context is present.'],
    );
  }

  @override
  CoachSkillResponse execute({
    required CoachContext context,
    required AIIntent intent,
  }) {
    return _skillRenderer.renderWorkoutToday(context);
  }

  SkillEvaluation _insufficient(List<AIContextProviderKey> missing) {
    return SkillEvaluation(
      skillId: id,
      skillType: type,
      outcome: SkillOutcome.insufficientContext,
      confidence: 0.2,
      estimatedLatency: estimatedLatency,
      requiresAIFallback: true,
      missingContext: missing,
      notes: const <String>[
        'Active program is required for WorkoutTodaySkill.',
      ],
    );
  }
}

/// Explains weekly muscle heatmap data locally.
class HeatmapSkill extends CoachRunnableSkill {
  const HeatmapSkill();

  @override
  String get id => 'heatmap_skill';

  @override
  CoachSkillType get type => CoachSkillType.heatmap;

  @override
  String get title => 'Heatmap Explanation';

  @override
  Set<AIIntent> get supportedIntents => const <AIIntent>{
    AIIntent.workoutToday,
    AIIntent.recovery,
    AIIntent.progressAnalysis,
    AIIntent.generalFitness,
  };

  @override
  Set<AIContextProviderKey> get requiredContext => const <AIContextProviderKey>{
    AIContextProviderKey.heatmap,
  };

  @override
  Set<AIContextProviderKey> get optionalContext => const <AIContextProviderKey>{
    AIContextProviderKey.workoutHistory,
    AIContextProviderKey.profile,
  };

  @override
  double get baseConfidence => 0.84;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 150);

  @override
  bool get requiresAIFallback => false;

  @override
  SkillCapability get capability => const SkillCapability(
    id: 'explain_heatmap',
    title: 'Explain Heatmap',
    description: 'Describe weekly muscle load from heatmap data.',
    kind: SkillCapabilityKind.diagnosticSummary,
    outputs: <String>['show_heatmap', 'heatmap_summary'],
    navigationTargets: <String>['weekly_heatmap'],
  );

  @override
  SkillEvaluation evaluate({
    required CoachContext context,
    required AIIntent intent,
  }) {
    final missing = CoachSkillContextChecks.missingRequired(
      context,
      requiredContext,
    );
    if (missing.isNotEmpty) {
      return SkillEvaluation(
        skillId: id,
        skillType: type,
        outcome: SkillOutcome.insufficientContext,
        confidence: 0.25,
        estimatedLatency: estimatedLatency,
        requiresAIFallback: true,
        missingContext: missing,
        notes: const <String>['Heatmap snapshot is missing.'],
      );
    }

    final confidence = CoachSkillContextChecks.confidenceFromCoverage(
      baseConfidence: baseConfidence,
      required: requiredContext,
      optional: optionalContext,
      context: context,
    );

    return SkillEvaluation(
      skillId: id,
      skillType: type,
      outcome: SkillOutcome.handledLocally,
      confidence: confidence,
      estimatedLatency: estimatedLatency,
      requiresAIFallback: false,
      missingContext: const <AIContextProviderKey>[],
      previewMessage: 'Local heatmap explanation is available.',
      notes: const <String>['Weekly heatmap context is present.'],
    );
  }

  @override
  CoachSkillResponse execute({
    required CoachContext context,
    required AIIntent intent,
  }) {
    return _skillRenderer.renderHeatmap(context);
  }
}

/// Provides recovery guidance from local training signals.
class RecoverySkill extends CoachRunnableSkill {
  const RecoverySkill();

  @override
  String get id => 'recovery_skill';

  @override
  CoachSkillType get type => CoachSkillType.recovery;

  @override
  String get title => 'Recovery Guidance';

  @override
  Set<AIIntent> get supportedIntents => const <AIIntent>{AIIntent.recovery};

  @override
  Set<AIContextProviderKey> get requiredContext => const <AIContextProviderKey>{
    AIContextProviderKey.currentQuestion,
  };

  @override
  Set<AIContextProviderKey> get optionalContext => const <AIContextProviderKey>{
    AIContextProviderKey.recovery,
    AIContextProviderKey.preferences,
    AIContextProviderKey.profile,
    AIContextProviderKey.heatmap,
    AIContextProviderKey.workoutHistory,
    AIContextProviderKey.memory,
  };

  @override
  double get baseConfidence => 0.86;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 120);

  @override
  bool get requiresAIFallback => false;

  @override
  SkillCapability get capability => const SkillCapability(
    id: 'recovery_guidance',
    title: 'Recovery Guidance',
    description: 'Offer readiness and rest guidance from local signals.',
    kind: SkillCapabilityKind.templatedText,
    outputs: <String>['show_recovery', 'recovery_summary'],
    navigationTargets: <String>['recovery'],
  );

  @override
  SkillEvaluation evaluate({
    required CoachContext context,
    required AIIntent intent,
  }) {
    final missing = CoachSkillContextChecks.missingRequired(
      context,
      requiredContext,
    );
    if (missing.isNotEmpty) {
      return SkillEvaluation(
        skillId: id,
        skillType: type,
        outcome: SkillOutcome.insufficientContext,
        confidence: 0.3,
        estimatedLatency: estimatedLatency,
        requiresAIFallback: true,
        missingContext: missing,
        notes: const <String>['Recovery skill missing required context.'],
      );
    }

    final confidence = CoachSkillContextChecks.confidenceFromCoverage(
      baseConfidence: baseConfidence,
      required: requiredContext,
      optional: optionalContext,
      context: context,
    );

    return SkillEvaluation(
      skillId: id,
      skillType: type,
      outcome: SkillOutcome.handledLocally,
      confidence: confidence,
      estimatedLatency: estimatedLatency,
      requiresAIFallback: false,
      missingContext: const <AIContextProviderKey>[],
      previewMessage: 'Local recovery summary is available.',
    );
  }

  @override
  CoachSkillResponse execute({
    required CoachContext context,
    required AIIntent intent,
  }) {
    return _skillRenderer.renderRecovery(context);
  }
}

/// Summarizes progress trends locally before deeper AI analysis.
class ProgressSummarySkill extends CoachSkill {
  const ProgressSummarySkill();

  @override
  String get id => 'progress_summary_skill';

  @override
  CoachSkillType get type => CoachSkillType.progressSummary;

  @override
  String get title => 'Progress Summary';

  @override
  Set<AIIntent> get supportedIntents => const <AIIntent>{
    AIIntent.progressAnalysis,
  };

  @override
  Set<AIContextProviderKey> get requiredContext => const <AIContextProviderKey>{
    AIContextProviderKey.workoutHistory,
    AIContextProviderKey.profile,
  };

  @override
  Set<AIContextProviderKey> get optionalContext => const <AIContextProviderKey>{
    AIContextProviderKey.heatmap,
    AIContextProviderKey.goals,
    AIContextProviderKey.memory,
  };

  @override
  double get baseConfidence => 0.76;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 200);

  @override
  bool get requiresAIFallback => true;

  @override
  SkillCapability get capability => const SkillCapability(
    id: 'progress_summary',
    title: 'Progress Summary',
    description: 'Provide a lightweight local progress snapshot.',
    kind: SkillCapabilityKind.diagnosticSummary,
    outputs: <String>['show_progress', 'progress_snapshot'],
    navigationTargets: <String>['progress_analysis'],
  );

  @override
  SkillEvaluation evaluate({
    required CoachContext context,
    required AIIntent intent,
  }) {
    final missing = CoachSkillContextChecks.missingRequired(
      context,
      requiredContext,
    );
    if (missing.isNotEmpty) {
      return SkillEvaluation(
        skillId: id,
        skillType: type,
        outcome: SkillOutcome.insufficientContext,
        confidence: 0.22,
        estimatedLatency: estimatedLatency,
        requiresAIFallback: true,
        missingContext: missing,
        notes: const <String>['Progress summary needs history and profile.'],
      );
    }

    final confidence = CoachSkillContextChecks.confidenceFromCoverage(
      baseConfidence: baseConfidence,
      required: requiredContext,
      optional: optionalContext,
      context: context,
    );

    return SkillEvaluation(
      skillId: id,
      skillType: type,
      outcome: SkillOutcome.partialLocal,
      confidence: confidence,
      estimatedLatency: estimatedLatency,
      requiresAIFallback: true,
      missingContext: const <AIContextProviderKey>[],
      previewMessage:
          'Local progress snapshot is available before AI analysis.',
      notes: const <String>[
        'ProgressSummarySkill always keeps AI fallback enabled.',
      ],
    );
  }
}

/// Returns motivational local responses without OpenAI.
class MotivationSkill extends CoachRunnableSkill {
  const MotivationSkill();

  @override
  String get id => 'motivation_skill';

  @override
  CoachSkillType get type => CoachSkillType.motivation;

  @override
  String get title => 'Motivation';

  @override
  Set<AIIntent> get supportedIntents => const <AIIntent>{AIIntent.motivation};

  @override
  Set<AIContextProviderKey> get requiredContext => const <AIContextProviderKey>{
    AIContextProviderKey.currentQuestion,
  };

  @override
  Set<AIContextProviderKey> get optionalContext => const <AIContextProviderKey>{
    AIContextProviderKey.profile,
    AIContextProviderKey.goals,
    AIContextProviderKey.preferences,
  };

  @override
  double get baseConfidence => 0.88;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 80);

  @override
  bool get requiresAIFallback => false;

  @override
  SkillCapability get capability => const SkillCapability(
    id: 'motivation_message',
    title: 'Motivation Message',
    description: 'Generate a short motivational response locally.',
    kind: SkillCapabilityKind.templatedText,
    outputs: <String>['motivation_message'],
  );

  @override
  SkillEvaluation evaluate({
    required CoachContext context,
    required AIIntent intent,
  }) {
    final missing = CoachSkillContextChecks.missingRequired(
      context,
      requiredContext,
    );
    if (missing.isNotEmpty) {
      return SkillEvaluation(
        skillId: id,
        skillType: type,
        outcome: SkillOutcome.insufficientContext,
        confidence: 0.35,
        estimatedLatency: estimatedLatency,
        requiresAIFallback: true,
        missingContext: missing,
      );
    }

    final confidence = CoachSkillContextChecks.confidenceFromCoverage(
      baseConfidence: baseConfidence,
      required: requiredContext,
      optional: optionalContext,
      context: context,
    );

    return SkillEvaluation(
      skillId: id,
      skillType: type,
      outcome: SkillOutcome.handledLocally,
      confidence: confidence,
      estimatedLatency: estimatedLatency,
      requiresAIFallback: false,
      missingContext: const <AIContextProviderKey>[],
      previewMessage: 'Local motivation response is available.',
    );
  }

  @override
  CoachSkillResponse execute({
    required CoachContext context,
    required AIIntent intent,
  }) {
    return _skillRenderer.renderMotivation(context);
  }
}

/// Answers app-help questions with local guidance.
class AppHelpSkill extends CoachRunnableSkill {
  const AppHelpSkill();

  @override
  String get id => 'app_help_skill';

  @override
  String get title => 'App Help';

  @override
  CoachSkillType get type => CoachSkillType.appHelp;

  @override
  Set<AIIntent> get supportedIntents => const <AIIntent>{
    AIIntent.appHelp,
    AIIntent.bugReport,
    AIIntent.feedback,
  };

  @override
  Set<AIContextProviderKey> get requiredContext => const <AIContextProviderKey>{
    AIContextProviderKey.currentQuestion,
  };

  @override
  Set<AIContextProviderKey> get optionalContext => const <AIContextProviderKey>{
    AIContextProviderKey.preferences,
    AIContextProviderKey.diagnostics,
    AIContextProviderKey.profile,
  };

  @override
  double get baseConfidence => 0.86;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 90);

  @override
  bool get requiresAIFallback => false;

  @override
  SkillCapability get capability => const SkillCapability(
    id: 'app_help_response',
    title: 'App Help Response',
    description: 'Provide local help guidance for GymAI features.',
    kind: SkillCapabilityKind.navigationHint,
    outputs: <String>['app_help_message', 'support_hint'],
    navigationTargets: <String>['app_help', 'support'],
  );

  @override
  SkillEvaluation evaluate({
    required CoachContext context,
    required AIIntent intent,
  }) {
    final missing = CoachSkillContextChecks.missingRequired(
      context,
      requiredContext,
    );
    if (missing.isNotEmpty) {
      return SkillEvaluation(
        skillId: id,
        skillType: type,
        outcome: SkillOutcome.insufficientContext,
        confidence: 0.3,
        estimatedLatency: estimatedLatency,
        requiresAIFallback: true,
        missingContext: missing,
      );
    }

    final confidence = CoachSkillContextChecks.confidenceFromCoverage(
      baseConfidence: baseConfidence,
      required: requiredContext,
      optional: optionalContext,
      context: context,
    );

    return SkillEvaluation(
      skillId: id,
      skillType: type,
      outcome: SkillOutcome.handledLocally,
      confidence: confidence,
      estimatedLatency: estimatedLatency,
      requiresAIFallback: intent != AIIntent.appHelp,
      missingContext: const <AIContextProviderKey>[],
      previewMessage: 'Local app-help response is available.',
      notes: <String>[
        if (intent == AIIntent.bugReport) 'Bug reports may still escalate.',
        if (intent == AIIntent.feedback)
          'Feedback may still request AI polish.',
      ],
    );
  }

  @override
  CoachSkillResponse execute({
    required CoachContext context,
    required AIIntent intent,
  }) {
    return _skillRenderer.renderAppHelp(context: context, intent: intent);
  }
}
