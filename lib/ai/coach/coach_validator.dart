import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/coach/coach_reason.dart';
import 'package:gymaipro/ai/coach/coach_rules.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_definitions.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Validates whether an intent has enough context to be routed.
///
/// The validator only returns decisions. It does not call OpenAI, mutate state,
/// or fetch missing data.
class CoachValidator {
  const CoachValidator();

  /// Returns a blocking decision when validation fails.
  CoachDecision? validate({
    required AIIntentDefinition intentDefinition,
    required AIContextProviderSelection providerSelection,
    required CoachContext context,
  }) {
    final missingProviders = providerSelection.missingRequiredProviders;
    if (missingProviders.isNotEmpty) {
      return CoachDecision(
        shouldCallAI: false,
        followUpQuestion: 'Required coach context providers are missing.',
        missingData: _missingProviderNames(missingProviders),
        requiredProviders: intentDefinition.requiredProviders,
        missingProviders: missingProviders,
        decisionReason: const <CoachReason>{
          CoachReason.validationFailed,
          CoachReason.missingProvider,
        },
        confidence: 0.95,
        notes: const <String>[
          'Provider selection could not satisfy all required context keys.',
        ],
      );
    }

    if (intentDefinition.intent == AIIntent.workoutGeneration) {
      return _validateWorkoutGeneration(intentDefinition, context);
    }

    if (_requiresCurrentQuestion(intentDefinition, context)) {
      return CoachDecision(
        shouldCallAI: false,
        followUpQuestion: 'What would you like GymAI Coach to help with?',
        missingData: const <String>['currentQuestion'],
        requiredProviders: intentDefinition.requiredProviders,
        missingProviders: const <AIContextProviderKey>{},
        decisionReason: const <CoachReason>{
          CoachReason.validationFailed,
          CoachReason.needCurrentQuestion,
        },
        confidence: 0.9,
        notes: const <String>[
          'The intent requires a current user question, but none was provided.',
        ],
      );
    }

    return null;
  }

  CoachDecision? _validateWorkoutGeneration(
    AIIntentDefinition intentDefinition,
    CoachContext context,
  ) {
    final missingData = CoachRules.missingWorkoutGenerationData(context);
    if (missingData.isEmpty) return null;

    return CoachDecision(
      shouldCallAI: false,
      followUpQuestion:
          'To generate a workout program, GymAI needs profile basics first.',
      missingData: missingData,
      requiredProviders: intentDefinition.requiredProviders,
      missingProviders: const <AIContextProviderKey>{},
      decisionReason: const <CoachReason>{
        CoachReason.validationFailed,
        CoachReason.needMoreProfile,
        CoachReason.needGoals,
      },
      confidence: 0.92,
      notes: const <String>[
        'Workout generation is blocked until age, height, weight, and goal are available.',
      ],
    );
  }

  bool _requiresCurrentQuestion(
    AIIntentDefinition intentDefinition,
    CoachContext context,
  ) {
    if (!intentDefinition.requiredProviders.contains(
      AIContextProviderKey.currentQuestion,
    )) {
      return false;
    }

    final question = context.currentQuestion;
    return question == null || question.trim().isEmpty;
  }

  List<String> _missingProviderNames(Set<AIContextProviderKey> providers) {
    return List<String>.unmodifiable(
      providers.map((provider) => provider.name),
    );
  }
}
