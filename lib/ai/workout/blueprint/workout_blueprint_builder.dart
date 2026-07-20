import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/profile_age_resolver.dart';
import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_snapshot.dart';
import 'package:gymaipro/ai/entitlement/subscription_capability_map.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/strategy/coach_strategy.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_type.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_reason.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_trace.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_validator.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_frequency_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_intensity_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_periodization_type.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_recovery_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_split_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_decision_step.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_exercise_complexity.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_exercise_replacement_policy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_training_style.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_volume_strategy.dart';
import 'package:gymaipro/ai/workout/models/workout_progression.dart';

/// Plans high-level workout strategy from Coach runtime artifacts.
///
/// All split, frequency, volume, intensity, and recovery decisions live here.
/// The workout generator only executes the resulting blueprint.
class WorkoutBlueprintBuilder {
  const WorkoutBlueprintBuilder({
    WorkoutBlueprintValidator validator = const WorkoutBlueprintValidator(),
  }) : _validator = validator;

  final WorkoutBlueprintValidator _validator;

  WorkoutBlueprintResult build({
    required CoachContext context,
    required String userId,
    CoachKnowledgeResult? knowledgeResult,
    CoachStrategy? strategy,
    CoachEntitlementSnapshot? entitlementSnapshot,
    CoachConversationState? conversationState,
    int? varietySeed,
  }) {
    final startedAt = DateTime.now();
    final steps = <String>['extract_context'];
    final reasons = <WorkoutBlueprintReason>[];

    final profile = context.profile;
    final preferences = context.preferences;
    final goals = List<String>.from(context.goals);
    final equipment = List<String>.from(context.equipment);
    final restrictions = List<String>.from(context.restrictions);
    final experience = _experience(profile, preferences, conversationState);
    final sessionMinutes = _sessionMinutes(profile, preferences);
    final daysPerWeek = _daysPerWeek(profile, preferences, conversationState);
    final avoidExercises = _avoidExerciseNames(context.memories, preferences);
    final preferredMuscles = _priorityMuscles(context);
    final recoveryScore = _recoveryScore(context);
    final medical = _medicalConditions(context.memories);
    final limitations = <String>[...restrictions, ...medical];
    final goal = WorkoutScience.goalFromProfile(goals, '$experience ${goals.join(' ')}');

    final entitlementAllowed = _entitlementAllowed(entitlementSnapshot);
    if (!entitlementAllowed) {
      return const WorkoutBlueprintResult(
        entitlementBlocked: true,
        reasons: <WorkoutBlueprintReason>[
          WorkoutBlueprintReason(
            code: 'entitlement.blocked',
            subject: 'Entitlement',
            because: <String>['generateWorkout capability denied'],
          ),
        ],
        message: 'Workout generation is not allowed for this plan.',
      );
    }

    final missing = _missingRequiredFields(
      profile: profile,
      goals: goals,
      equipment: equipment,
      experience: experience,
      daysPerWeek: daysPerWeek,
      sessionMinutes: sessionMinutes,
    );
    if (missing.isNotEmpty || (strategy?.requiresFollowUp ?? false)) {
      return WorkoutBlueprintResult(
        needsFollowUp: true,
        followUpFields: missing,
        reasons: <WorkoutBlueprintReason>[
          WorkoutBlueprintReason(
            code: 'input.incomplete',
            subject: 'Blueprint input',
            because: missing,
          ),
        ],
        message: 'Need follow-up: ${missing.join(', ')}',
      );
    }

    steps.add('select_frequency');
    final frequency = _frequencyFor(daysPerWeek);

    steps.add('select_split');
    final splitStrategy = _splitStrategy(
      goal: goal,
      experience: experience,
      frequency: frequency,
      recoveryScore: recoveryScore,
      knowledgeDescription: knowledgeResult?.selectedNode.description,
    );

    steps.add('select_volume_intensity');
    final recoveryStrategy = _recoveryStrategy(recoveryScore);
    final volume = _volumeStrategy(goal: goal, experience: experience, recoveryScore: recoveryScore);
    final intensity = _intensityStrategy(goal: goal, experience: experience, recoveryScore: recoveryScore);
    final periodization = _periodizationType(
      goal: goal,
      recoveryScore: recoveryScore,
      strategy: strategy,
    );

    final estimatedWeeklyVolume = _estimatedWeeklyVolume(
      goal: goal,
      experience: experience,
      volume: volume,
      frequency: frequency,
    );
    final exercisesPerSession = _exercisesPerSession(volume, sessionMinutes);
    final progressionStrategy = _progressionStrategy(
      goal: goal,
      periodization: periodization,
    );
    final trainingStyle = _trainingStyle(goal);
    final complexity = _exerciseComplexity(experience);
    final minRecoveryHours = _minRecoveryHours(recoveryStrategy);
    final deloadFrequencyWeeks = _deloadFrequencyWeeks(periodization);
    final memorySignals = _memorySignals(context.memories, avoidExercises);

    final confidence = _confidence(
      context: context,
      strategy: strategy,
      recoveryScore: recoveryScore,
    );

    reasons.addAll(<WorkoutBlueprintReason>[
      WorkoutBlueprintReason(
        code: 'goal.selected',
        subject: 'Goal',
        because: <String>[
          'Goal=${goal.name}',
          if (goals.isNotEmpty) 'Goals=${goals.join(', ')}',
        ],
      ),
      WorkoutBlueprintReason(
        code: 'experience.selected',
        subject: 'Experience',
        because: <String>['Experience=$experience'],
      ),
      WorkoutBlueprintReason(
        code: 'recovery.selected',
        subject: 'Recovery',
        because: <String>[
          'RecoveryScore=$recoveryScore',
          'RecoveryStrategy=${recoveryStrategy.name}',
        ],
      ),
      WorkoutBlueprintReason(
        code: 'equipment.selected',
        subject: 'Equipment',
        because: <String>['Equipment=${equipment.join(', ')}'],
      ),
      if (limitations.isNotEmpty)
        WorkoutBlueprintReason(
          code: 'limitations.selected',
          subject: 'Restrictions',
          because: <String>['Restrictions=${limitations.join(', ')}'],
        ),
      WorkoutBlueprintReason(
        code: 'frequency.selected',
        subject: 'Frequency',
        because: <String>['Frequency=${frequency.daysPerWeek}'],
      ),
      WorkoutBlueprintReason(
        code: 'split.selected',
        subject: 'Split',
        because: <String>[
          'SplitStrategy=${splitStrategy.name}',
          if (knowledgeResult != null)
            'Knowledge=${knowledgeResult.selectedNode.id}',
        ],
      ),
      WorkoutBlueprintReason(
        code: 'volume.selected',
        subject: 'Volume',
        because: <String>['Volume=${volume.name}'],
      ),
      WorkoutBlueprintReason(
        code: 'intensity.selected',
        subject: 'Intensity',
        because: <String>['Intensity=${intensity.name}'],
      ),
      if (preferredMuscles.isNotEmpty)
        WorkoutBlueprintReason(
          code: 'muscles.priority',
          subject: 'Preferred muscles',
          because: <String>['Heatmap=${preferredMuscles.join(', ')}'],
        ),
      if (avoidExercises.isNotEmpty)
        WorkoutBlueprintReason(
          code: 'exercises.avoid',
          subject: 'Avoid exercises',
          because: avoidExercises,
        ),
    ]);

    final decisions = <WorkoutBlueprintDecisionStep>[
      WorkoutBlueprintDecisionStep(
        decision: 'splitStrategy',
        outcome: splitStrategy.name,
        factors: <String>[
          'Goal=${goal.name}',
          'Experience=$experience',
          'RecoveryScore=$recoveryScore',
          'RecoveryStrategy=${recoveryStrategy.name}',
          'Frequency=${frequency.daysPerWeek}',
          if (knowledgeResult != null)
            'Knowledge=${knowledgeResult.selectedNode.id}',
          if (avoidExercises.isNotEmpty) 'MemoryAvoid=${avoidExercises.join(',')}',
        ],
      ),
      WorkoutBlueprintDecisionStep(
        decision: 'frequency',
        outcome: frequency.name,
        factors: <String>[
          'DaysPerWeek=${frequency.daysPerWeek}',
          'Goal=${goal.name}',
        ],
      ),
      WorkoutBlueprintDecisionStep(
        decision: 'volume',
        outcome: volume.name,
        factors: <String>[
          'Goal=${goal.name}',
          'Experience=$experience',
          'RecoveryScore=$recoveryScore',
        ],
      ),
      WorkoutBlueprintDecisionStep(
        decision: 'intensity',
        outcome: intensity.name,
        factors: <String>[
          'Goal=${goal.name}',
          'Experience=$experience',
          'RecoveryStrategy=${recoveryStrategy.name}',
        ],
      ),
      WorkoutBlueprintDecisionStep(
        decision: 'progressionStrategy',
        outcome: progressionStrategy.name,
        factors: <String>[
          'Goal=${goal.name}',
          'Periodization=${periodization.name}',
        ],
      ),
    ];

    final blueprint = WorkoutBlueprint(
      goal: goal,
      experience: experience,
      daysPerWeek: frequency.daysPerWeek,
      splitStrategy: splitStrategy,
      frequency: frequency,
      volume: volume,
      intensity: intensity,
      periodization: periodization,
      recoveryStrategy: recoveryStrategy,
      equipment: equipment,
      limitations: limitations,
      preferredMuscles: preferredMuscles,
      avoidExercises: avoidExercises,
      preferredExercises: const <String>[],
      weeklySetsTarget: estimatedWeeklyVolume,
      maxSessionMinutes: sessionMinutes,
      minRecoveryHours: minRecoveryHours,
      preferredExerciseComplexity: complexity,
      exerciseReplacementPolicy: WorkoutExerciseReplacementPolicy.substitute,
      deloadFrequencyWeeks: deloadFrequencyWeeks,
      progressionStrategy: progressionStrategy,
      trainingStyle: trainingStyle,
      exercisesPerSession: exercisesPerSession,
      confidence: confidence,
      reasons: reasons,
      trace: WorkoutBlueprintTrace(
        steps: steps,
        recoveryScore: recoveryScore,
        knowledgeNodeId: knowledgeResult?.selectedNode.id,
        memorySignals: memorySignals,
        decisions: decisions,
        buildDuration: DateTime.now().difference(startedAt),
      ),
      userId: userId,
      goals: goals,
      entitlementAllowed: entitlementAllowed,
      varietySeed: varietySeed,
    );

    final validation = _validator.validate(blueprint);
    if (!validation.isValid || validation.needsFollowUp) {
      return WorkoutBlueprintResult(
        needsFollowUp: true,
        followUpFields: validation.followUpFields,
        reasons: reasons,
        message: 'Blueprint validation failed: ${validation.issues.join('; ')}',
      );
    }

    return WorkoutBlueprintResult(
      blueprint: blueprint,
      reasons: reasons,
      message: 'Workout blueprint planned.',
    );
  }

  bool _entitlementAllowed(CoachEntitlementSnapshot? snapshot) {
    if (snapshot == null) return true;
    final planCapabilities = SubscriptionCapabilityMap.forPlan(
      snapshot.entitlement.plan,
    );
    if (snapshot.entitlement.disabledCapabilities.contains(
      CoachCapability.generateWorkout,
    )) {
      return false;
    }
    return planCapabilities.contains(CoachCapability.generateWorkout) ||
        snapshot.entitlement.lifetimeCapabilities.contains(
          CoachCapability.generateWorkout,
        ) ||
        snapshot.entitlement.trialCapabilities.contains(
          CoachCapability.generateWorkout,
        );
  }

  List<String> _missingRequiredFields({
    required Map<String, Object?> profile,
    required List<String> goals,
    required List<String> equipment,
    required String experience,
    required int daysPerWeek,
    required int sessionMinutes,
  }) {
    final missing = <String>[];
    final age = _asInt(profile['age']) ?? ProfileAgeResolver.resolve(profile);
    final height = _asDouble(profile['height']);
    final weight = _asDouble(profile['weight']);
    if (age == null || age <= 0) missing.add('age');
    if (height == null || height <= 0) missing.add('height');
    if (weight == null || weight <= 0) missing.add('weight');
    if (goals.isEmpty) missing.add('goal');
    if (experience.trim().isEmpty) missing.add('experience');
    if (equipment.isEmpty) missing.add('equipment');
    if (daysPerWeek < 2 || daysPerWeek > 6) missing.add('workoutDays');
    if (sessionMinutes < 20) missing.add('workoutDuration');
    return missing;
  }

  WorkoutFrequencyStrategy _frequencyFor(int daysPerWeek) {
    return WorkoutFrequencyStrategy.values.firstWhere(
      (value) => value.daysPerWeek == daysPerWeek.clamp(2, 6),
      orElse: () => WorkoutFrequencyStrategy.three,
    );
  }

  WorkoutSplitStrategy _splitStrategy({
    required TrainingGoal goal,
    required String experience,
    required WorkoutFrequencyStrategy frequency,
    required double recoveryScore,
    String? knowledgeDescription,
  }) {
    final isAdvanced = WorkoutScience.isAdvancedExperience(experience);
    final isBeginner = WorkoutScience.isBeginnerExperience(experience);
    final knowledge = (knowledgeDescription ?? '').toLowerCase();

    if (knowledge.contains('phat') && isAdvanced && frequency.daysPerWeek >= 5) {
      return WorkoutSplitStrategy.phat;
    }
    if (knowledge.contains('phul') && frequency.daysPerWeek == 4) {
      return WorkoutSplitStrategy.phul;
    }

    switch (frequency) {
      case WorkoutFrequencyStrategy.two:
        return WorkoutSplitStrategy.fullBody;
      case WorkoutFrequencyStrategy.three:
        // 3-day programs use PPL so day labels (فشار/کشش/پا) match muscle focus.
        // Full-body remains for true beginners only.
        if (isBeginner) {
          return WorkoutSplitStrategy.fullBody;
        }
        return WorkoutSplitStrategy.pushPullLegs;
      case WorkoutFrequencyStrategy.four:
        return WorkoutSplitStrategy.upperLower;
      case WorkoutFrequencyStrategy.five:
        return isAdvanced ? WorkoutSplitStrategy.broSplit : WorkoutSplitStrategy.upperLower;
      case WorkoutFrequencyStrategy.six:
        if (isAdvanced && recoveryScore >= 0.65) {
          return WorkoutSplitStrategy.phat;
        }
        return WorkoutSplitStrategy.pushPullLegs;
    }
  }

  WorkoutRecoveryStrategy _recoveryStrategy(double recoveryScore) {
    if (recoveryScore < 0.5) return WorkoutRecoveryStrategy.conservative;
    if (recoveryScore >= 0.8) return WorkoutRecoveryStrategy.aggressive;
    return WorkoutRecoveryStrategy.normal;
  }

  WorkoutVolumeStrategy _volumeStrategy({
    required TrainingGoal goal,
    required String experience,
    required double recoveryScore,
  }) {
    if (recoveryScore < 0.5) return WorkoutVolumeStrategy.low;
    final isBeginner = WorkoutScience.isBeginnerExperience(experience);
    final isAdvanced = WorkoutScience.isAdvancedExperience(experience);
    switch (goal) {
      case TrainingGoal.strength:
        return isAdvanced ? WorkoutVolumeStrategy.high : WorkoutVolumeStrategy.medium;
      case TrainingGoal.hypertrophy:
        if (isBeginner) return WorkoutVolumeStrategy.medium;
        if (isAdvanced) return WorkoutVolumeStrategy.veryHigh;
        return WorkoutVolumeStrategy.high;
      case TrainingGoal.fatLoss:
        return WorkoutVolumeStrategy.medium;
      case TrainingGoal.endurance:
        return WorkoutVolumeStrategy.low;
      case TrainingGoal.general:
        return isBeginner ? WorkoutVolumeStrategy.low : WorkoutVolumeStrategy.medium;
    }
  }

  WorkoutIntensityStrategy _intensityStrategy({
    required TrainingGoal goal,
    required String experience,
    required double recoveryScore,
  }) {
    if (recoveryScore < 0.5) return WorkoutIntensityStrategy.light;
    final isBeginner = WorkoutScience.isBeginnerExperience(experience);
    final isAdvanced = WorkoutScience.isAdvancedExperience(experience);
    switch (goal) {
      case TrainingGoal.strength:
        return isAdvanced ? WorkoutIntensityStrategy.maximum : WorkoutIntensityStrategy.hard;
      case TrainingGoal.hypertrophy:
        return isBeginner
            ? WorkoutIntensityStrategy.moderate
            : WorkoutIntensityStrategy.hard;
      case TrainingGoal.fatLoss:
        return WorkoutIntensityStrategy.moderate;
      case TrainingGoal.endurance:
        return WorkoutIntensityStrategy.light;
      case TrainingGoal.general:
        return WorkoutIntensityStrategy.moderate;
    }
  }

  WorkoutPeriodizationType _periodizationType({
    required TrainingGoal goal,
    required double recoveryScore,
    CoachStrategy? strategy,
  }) {
    if (recoveryScore < 0.5) return WorkoutPeriodizationType.deload;
    if (strategy?.strategyType == CoachStrategyType.safetyGate) {
      return WorkoutPeriodizationType.maintenance;
    }
    switch (goal) {
      case TrainingGoal.strength:
        return WorkoutPeriodizationType.linear;
      case TrainingGoal.fatLoss:
        return WorkoutPeriodizationType.undulating;
      case TrainingGoal.hypertrophy:
        return WorkoutPeriodizationType.block;
      case TrainingGoal.endurance:
        return WorkoutPeriodizationType.undulating;
      case TrainingGoal.general:
        return WorkoutPeriodizationType.linear;
    }
  }

  int _estimatedWeeklyVolume({
    required TrainingGoal goal,
    required String experience,
    required WorkoutVolumeStrategy volume,
    required WorkoutFrequencyStrategy frequency,
  }) {
    var base = WorkoutScience.weeklySetsForGoal(goal, experience);
    switch (volume) {
      case WorkoutVolumeStrategy.low:
        base = (base * 0.8).round();
      case WorkoutVolumeStrategy.medium:
        break;
      case WorkoutVolumeStrategy.high:
        base = (base * 1.15).round();
      case WorkoutVolumeStrategy.veryHigh:
        base = (base * 1.3).round();
    }
    return base * frequency.daysPerWeek.clamp(2, 6) ~/ 3;
  }

  int _exercisesPerSession(WorkoutVolumeStrategy volume, int sessionMinutes) {
    final base = sessionMinutes >= 75
        ? 6
        : sessionMinutes >= 55
        ? 5
        : 4;
    return switch (volume) {
      WorkoutVolumeStrategy.low => (base - 1).clamp(3, 6),
      WorkoutVolumeStrategy.medium => base,
      WorkoutVolumeStrategy.high => (base + 1).clamp(4, 7),
      WorkoutVolumeStrategy.veryHigh => (base + 2).clamp(5, 8),
    };
  }

  WorkoutProgressionStrategy _progressionStrategy({
    required TrainingGoal goal,
    required WorkoutPeriodizationType periodization,
  }) {
    if (periodization == WorkoutPeriodizationType.deload) {
      return WorkoutProgressionStrategy.deload;
    }
    if (periodization == WorkoutPeriodizationType.maintenance) {
      return WorkoutProgressionStrategy.maintenance;
    }
    return switch (goal) {
      TrainingGoal.strength => WorkoutProgressionStrategy.increaseWeight,
      TrainingGoal.hypertrophy => WorkoutProgressionStrategy.increaseReps,
      TrainingGoal.fatLoss => WorkoutProgressionStrategy.increaseVolume,
      TrainingGoal.endurance => WorkoutProgressionStrategy.increaseVolume,
      TrainingGoal.general => WorkoutProgressionStrategy.maintenance,
    };
  }

  WorkoutTrainingStyle _trainingStyle(TrainingGoal goal) {
    return switch (goal) {
      TrainingGoal.strength => WorkoutTrainingStyle.strength,
      TrainingGoal.hypertrophy => WorkoutTrainingStyle.hypertrophy,
      TrainingGoal.fatLoss => WorkoutTrainingStyle.fatLoss,
      TrainingGoal.endurance => WorkoutTrainingStyle.endurance,
      TrainingGoal.general => WorkoutTrainingStyle.generalFitness,
    };
  }

  WorkoutExerciseComplexity _exerciseComplexity(String experience) {
    if (WorkoutScience.isBeginnerExperience(experience)) {
      return WorkoutExerciseComplexity.basic;
    }
    if (WorkoutScience.isAdvancedExperience(experience)) {
      return WorkoutExerciseComplexity.advanced;
    }
    return WorkoutExerciseComplexity.moderate;
  }

  int _minRecoveryHours(WorkoutRecoveryStrategy recoveryStrategy) {
    return switch (recoveryStrategy) {
      WorkoutRecoveryStrategy.conservative => 48,
      WorkoutRecoveryStrategy.normal => 24,
      WorkoutRecoveryStrategy.aggressive => 18,
    };
  }

  int _deloadFrequencyWeeks(WorkoutPeriodizationType periodization) {
    return switch (periodization) {
      WorkoutPeriodizationType.deload => 1,
      WorkoutPeriodizationType.maintenance => 6,
      WorkoutPeriodizationType.block => 4,
      WorkoutPeriodizationType.undulating => 3,
      WorkoutPeriodizationType.linear => 4,
    };
  }

  List<String> _memorySignals(
    List<CoachMemory> memories,
    List<String> avoidExercises,
  ) {
    final signals = <String>[];
    for (final memory in memories) {
      signals.add('${memory.key}=${memory.value}');
    }
    if (avoidExercises.isNotEmpty) {
      signals.add('avoid=${avoidExercises.join(',')}');
    }
    return signals;
  }

  double _confidence({
    required CoachContext context,
    required CoachStrategy? strategy,
    required double recoveryScore,
  }) {
    var score = context.metadata.confidence;
    if (context.equipment.isNotEmpty) score += 0.05;
    if (context.goals.isNotEmpty) score += 0.05;
    if (context.restrictions.isNotEmpty) score += 0.02;
    if (recoveryScore < 0.5) score -= 0.08;
    if (strategy != null) {
      score = (score + strategy.confidence) / 2;
    }
    return score.clamp(0, 1);
  }

  List<String> _avoidExerciseNames(
    List<CoachMemory> memories,
    Map<String, Object?> preferences,
  ) {
    final avoid = <String>[];
    for (final memory in memories) {
      final key = memory.key.toLowerCase();
      final value = memory.value.toLowerCase();
      if (key.contains('avoid') ||
          key.contains('dislike') ||
          key.contains('hate') ||
          value.contains('نمید') ||
          value.contains('دوست ندار')) {
        avoid.add(memory.value);
      }
      if (key.contains('squat') || value.contains('اسکوات')) {
        avoid.add('اسکوات');
      }
    }
    for (final entry in preferences.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('avoid') || key.contains('dislike')) {
        avoid.add(entry.value.toString());
      }
    }
    return _unique(avoid);
  }

  List<String> _priorityMuscles(CoachContext context) {
    final heatmap = context.weeklyHeatmap;
    if (heatmap == null || !heatmap.hasHeatmapData) {
      return const <String>[];
    }
    final entries = heatmap.targets.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.take(2).map((entry) => entry.key).toList();
  }

  double _recoveryScore(CoachContext context) {
    final heatmap = context.weeklyHeatmap;
    if (heatmap == null || !heatmap.hasHeatmapData) return 0.85;
    final highLoad = heatmap.targets.values.where((value) => value >= 5).length;
    if (highLoad >= 3) return 0.45;
    if (highLoad >= 2) return 0.6;
    return 0.85;
  }

  List<String> _medicalConditions(List<CoachMemory> memories) {
    return memories
        .where((memory) => memory.key.startsWith('medical.'))
        .map((memory) => memory.value)
        .toList();
  }

  int _daysPerWeek(
    Map<String, Object?> profile,
    Map<String, Object?> preferences,
    CoachConversationState? state,
  ) {
    final fromProfile = _asInt(
      profile['bb_days_per_week'] ?? profile['days_per_week'],
    );
    if (fromProfile != null && fromProfile >= 2) return fromProfile.clamp(2, 6);
    final fromPrefs = _asInt(preferences['workout_days']);
    if (fromPrefs != null && fromPrefs >= 2) return fromPrefs.clamp(2, 6);
    final fromState = state?.collectedFields['workout_days'];
    final parsed = _asInt(fromState);
    if (parsed != null && parsed >= 2) return parsed.clamp(2, 6);
    return 3;
  }

  int _sessionMinutes(
    Map<String, Object?> profile,
    Map<String, Object?> preferences,
  ) {
    final fromProfile = _asInt(
      profile['bb_session_minutes'] ?? profile['session_minutes'],
    );
    if (fromProfile != null && fromProfile > 0) return fromProfile;
    final fromPrefs = _asInt(preferences['session_minutes']);
    if (fromPrefs != null && fromPrefs > 0) return fromPrefs;
    return 60;
  }

  String _experience(
    Map<String, Object?> profile,
    Map<String, Object?> preferences,
    CoachConversationState? state,
  ) {
    final fromProfile =
        profile['experience_level'] ?? profile['bb_experience_level'];
    if (fromProfile != null && fromProfile.toString().trim().isNotEmpty) {
      return fromProfile.toString();
    }
    final fromPrefs = preferences['experience_level'];
    if (fromPrefs != null && fromPrefs.toString().trim().isNotEmpty) {
      return fromPrefs.toString();
    }
    final fromState = state?.collectedFields['experience_level'];
    if (fromState != null && fromState.toString().trim().isNotEmpty) {
      return fromState.toString();
    }
    return 'متوسط';
  }

  int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString().trim());
  }

  double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  List<String> _unique(List<String> values) {
    final seen = <String>{};
    final unique = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed.toLowerCase())) unique.add(trimmed);
    }
    return unique;
  }
}
