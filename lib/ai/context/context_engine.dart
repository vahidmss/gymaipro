import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_assembler.dart';
import 'package:gymaipro/ai/context/context_builder.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/intent_definitions.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Facade for GymAI Coach v2 context selection and CoachContext assembly.
///
/// The engine produces immutable [CoachContext] packages only. It does not call
/// OpenAI, assemble existing prompts, or change current app behavior.
class AIContextEngine {
  AIContextEngine({
    AIIntentDetector intentDetector = const AIIntentDetector(),
    AIContextBuilder? contextBuilder,
    CoachContextAssembler? coachContextAssembler,
  }) : _intentDetector = intentDetector,
       _contextBuilder = contextBuilder ?? AIContextBuilder.standard(),
       _coachContextAssembler =
           coachContextAssembler ??
           CoachContextAssembler(
             contextBuilder: contextBuilder ?? AIContextBuilder.standard(),
           );

  final AIIntentDetector _intentDetector;
  final AIContextBuilder _contextBuilder;
  final CoachContextAssembler _coachContextAssembler;

  /// Selects providers for a known intent.
  AIContextProviderSelection selectProviders(AIIntent intent) {
    final definition = AIIntentDefinitions.forIntent(intent);
    final requiredProviders = _providersFor(definition.requiredProviders);
    final optionalProviders = _providersFor(definition.optionalProviders);

    return AIContextProviderSelection(
      intentDefinition: definition,
      requiredProviders: requiredProviders,
      optionalProviders: optionalProviders,
      missingRequiredProviders: _missingKeys(
        definition.requiredProviders,
        requiredProviders,
      ),
      missingOptionalProviders: _missingKeys(
        definition.optionalProviders,
        optionalProviders,
      ),
    );
  }

  /// Detects an intent from the current question and selects its providers.
  AIContextProviderSelection selectProvidersForQuestion({
    AIIntent? intent,
    String? currentQuestion,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final resolvedIntent = intent ?? _detectIntent(currentQuestion, metadata);
    return selectProviders(resolvedIntent);
  }

  /// Builds a unified [CoachContext] for a known intent.
  Future<CoachContext> buildCoachContext({
    required AIContextRequest request,
    required AIIntent intent,
    DateTime? buildTime,
  }) async {
    final selection = selectProviders(intent);
    return _coachContextAssembler.assemble(
      request: request,
      intent: intent,
      selection: selection,
      buildTime: buildTime,
    );
  }

  /// Detects intent and builds a unified [CoachContext].
  Future<CoachContext> buildCoachContextForQuestion({
    required AIContextRequest request,
    AIIntent? intent,
    DateTime? buildTime,
  }) async {
    final selection = selectProvidersForQuestion(
      intent: intent ?? request.intent,
      currentQuestion: request.currentQuestion,
      metadata: request.metadata,
    );
    return _coachContextAssembler.assemble(
      request: request,
      intent: selection.intentDefinition.intent,
      selection: selection,
      buildTime: buildTime,
    );
  }

  List<AIContextProvider> _providersFor(Set<AIContextProviderKey> keys) {
    final selected = <String, AIContextProvider>{};

    for (final provider in _contextBuilder.providers) {
      if (provider.providedKeys.intersection(keys).isNotEmpty) {
        selected[provider.id] = provider;
      }
    }

    return List<AIContextProvider>.unmodifiable(selected.values);
  }

  Set<AIContextProviderKey> _missingKeys(
    Set<AIContextProviderKey> requestedKeys,
    List<AIContextProvider> selectedProviders,
  ) {
    final providedKeys = <AIContextProviderKey>{
      for (final provider in selectedProviders) ...provider.providedKeys,
    };
    return Set<AIContextProviderKey>.unmodifiable(
      requestedKeys.difference(providedKeys),
    );
  }

  AIIntent _detectIntent(
    String? currentQuestion,
    Map<String, Object?> metadata,
  ) {
    if (currentQuestion == null || currentQuestion.trim().isEmpty) {
      return AIIntent.generalChat;
    }

    final result = _intentDetector.detect(
      IntentDetectionRequest(message: currentQuestion, metadata: metadata),
    );
    return result.intent;
  }
}
