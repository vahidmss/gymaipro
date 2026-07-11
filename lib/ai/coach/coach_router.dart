import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/coach/coach_reason.dart';
import 'package:gymaipro/ai/coach/coach_rules.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_definitions.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Route selected by the coach brain.
enum CoachRoute { local, ai, followUp }

/// Decides whether an intent should be handled locally, by AI, or by follow-up.
///
/// The router only produces decisions. It never executes the selected route.
class CoachRouter {
  const CoachRouter();

  /// Returns the final route decision after validation.
  CoachDecision route({
    required AIIntentDefinition intentDefinition,
    required AIContextProviderSelection providerSelection,
    CoachDecision? validationDecision,
  }) {
    if (validationDecision != null) {
      return validationDecision;
    }

    if (_canUseLocalRoute(intentDefinition)) {
      return CoachDecision(
        shouldCallAI: false,
        localResponse: 'Local coach route selected.',
        missingData: const <String>[],
        requiredProviders: intentDefinition.requiredProviders,
        missingProviders: const <AIContextProviderKey>{},
        decisionReason: const <CoachReason>{
          CoachReason.localAnswer,
          CoachReason.enoughContext,
        },
        confidence: 0.86,
        notes: <String>[
          'Intent ${intentDefinition.id} supports local response.',
          'Selected providers: ${_providerIds(providerSelection.providers).join(', ')}.',
        ],
      );
    }

    if (intentDefinition.requiresAI) {
      return CoachDecision(
        shouldCallAI: true,
        missingData: const <String>[],
        requiredProviders: intentDefinition.requiredProviders,
        missingProviders: const <AIContextProviderKey>{},
        decisionReason: const <CoachReason>{
          CoachReason.openAIRequired,
          CoachReason.enoughContext,
        },
        confidence: 0.82,
        notes: <String>[
          'Intent ${intentDefinition.id} requires AI.',
          if (intentDefinition.localResponseSupported)
            'A local fallback may be added in a future phase.',
        ],
      );
    }

    return CoachDecision(
      shouldCallAI: false,
      followUpQuestion: 'GymAI needs one more detail before continuing.',
      missingData: const <String>['route'],
      requiredProviders: intentDefinition.requiredProviders,
      missingProviders: const <AIContextProviderKey>{},
      decisionReason: const <CoachReason>{
        CoachReason.lowConfidence,
        CoachReason.unsupportedLocalResponse,
      },
      confidence: 0.45,
      notes: <String>[
        'No confident local or AI route was selected for ${intentDefinition.id}.',
      ],
    );
  }

  bool _canUseLocalRoute(AIIntentDefinition intentDefinition) {
    return !intentDefinition.requiresAI &&
        intentDefinition.localResponseSupported &&
        CoachRules.localCapableIntents.contains(intentDefinition.intent);
  }

  List<String> _providerIds(List<AIContextProvider> providers) {
    return List<String>.unmodifiable(providers.map((provider) => provider.id));
  }
}
