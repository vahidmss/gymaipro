import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/skills/coach_skill.dart';
import 'package:gymaipro/ai/skills/coach_skill_type.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_reason.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_reason_type.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/ai/skills/skill_capability.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_program_policy.dart';
import 'package:gymaipro/models/exercise.dart';

/// Chat must not author programs — only redirect to dedicated product flows.
class WorkoutGenerationSkill extends CoachRunnableSkill {
  const WorkoutGenerationSkill({
    this.catalog = const <Exercise>[],
    this.userId = 'coach_user',
  });

  final List<Exercise> catalog;
  final String userId;

  @override
  String get id => 'workout_generation_skill';

  @override
  CoachSkillType get type => CoachSkillType.workoutGeneration;

  @override
  String get title => 'Workout Generation';

  @override
  Set<AIIntent> get supportedIntents =>
      const <AIIntent>{AIIntent.workoutGeneration};

  @override
  Set<AIContextProviderKey> get requiredContext =>
      const <AIContextProviderKey>{};

  @override
  Set<AIContextProviderKey> get optionalContext =>
      const <AIContextProviderKey>{};

  @override
  double get baseConfidence => 1;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 40);

  @override
  bool get requiresAIFallback => false;

  @override
  SkillCapability get capability => const SkillCapability(
    id: 'generate_workout_program',
    title: 'Generate Workout Program',
    description:
        'Redirect users out of chat to trainers or AI program request.',
    kind: SkillCapabilityKind.navigationHint,
    outputs: <String>['redirect'],
    navigationTargets: <String>[
      'workout_program_request',
      'trainer_ranking',
    ],
  );

  @override
  SkillEvaluation evaluate({
    required CoachContext context,
    required AIIntent intent,
  }) {
    return SkillEvaluation(
      skillId: id,
      skillType: type,
      outcome: SkillOutcome.handledLocally,
      confidence: baseConfidence,
      estimatedLatency: estimatedLatency,
      requiresAIFallback: false,
      missingContext: const <AIContextProviderKey>[],
      previewMessage: CoachChatProgramPolicy.redirectMessage,
      notes: const <String>['Chat program delivery blocked'],
    );
  }

  @override
  CoachSkillResponse execute({
    required CoachContext context,
    required AIIntent intent,
  }) {
    return CoachSkillResponse(
      confidence: 1,
      requiresAI: false,
      message: CoachChatProgramPolicy.redirectMessage,
      structuredData: const <String, Object?>{
        'navigateTo': 'workout_program_request',
        'navigationTargets': <String>[
          'workout_program_request',
          'trainer_ranking',
        ],
        'blockedInChat': true,
      },
      nextActions: const <String>[
        'open_workout_program_request',
        'open_trainer_ranking',
      ],
      reasons: const <SkillReason>[
        SkillReason(
          type: SkillReasonType.goalAlignment,
          message: 'Programs are not delivered inside chat.',
        ),
      ],
    );
  }
}
