import 'package:gymaipro/ai/entity/entity_confidence.dart';
import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/entity/entity_normalizer.dart';
import 'package:gymaipro/ai/entity/entity_registry.dart';
import 'package:gymaipro/ai/entity/entity_result.dart';
import 'package:gymaipro/ai/entity/entity_rule_engine.dart';
import 'package:gymaipro/ai/entity/entity_validator.dart';

/// Rule-based user-message entity extractor.
///
/// This extractor does not call LLMs, APIs, prompts, UI, or existing runtime
/// services. It is infrastructure-only until explicitly integrated.
class EntityExtractor {
  const EntityExtractor({
    EntityRegistry registry = const EntityRegistry(),
    EntityRuleEngine ruleEngine = const EntityRuleEngine(),
    EntityNormalizer normalizer = const EntityNormalizer(),
    EntityConfidenceCalculator confidenceCalculator =
        const EntityConfidenceCalculator(),
    EntityValidator validator = const EntityValidator(),
  }) : _registry = registry,
       _ruleEngine = ruleEngine,
       _normalizer = normalizer,
       _confidenceCalculator = confidenceCalculator,
       _validator = validator;

  final EntityRegistry _registry;
  final EntityRuleEngine _ruleEngine;
  final EntityNormalizer _normalizer;
  final EntityConfidenceCalculator _confidenceCalculator;
  final EntityValidator _validator;

  /// Extracts and normalizes entities from [message].
  EntityExtractionResult extract(String message) {
    final ruleValidation = _validator.validateRules(_registry.rules);
    if (!ruleValidation.isValid) {
      throw StateError(ruleValidation.issues.join(' '));
    }

    final normalizedMessage = _normalizer.normalizeMessage(message);
    final ruleResult = _ruleEngine.evaluateNormalized(normalizedMessage);
    final normalizedEntities = _normalizeMatches(ruleResult.matches);
    final result = EntityExtractionResult(
      originalMessage: message,
      normalizedMessage: normalizedMessage,
      rawMatches: ruleResult.matches,
      entities: normalizedEntities,
      trace: ruleResult.trace,
    );

    final resultValidation = _validator.validateResult(result);
    if (!resultValidation.isValid) {
      throw StateError(resultValidation.issues.join(' '));
    }

    return result;
  }

  List<NormalizedEntity> _normalizeMatches(List<EntityMatch> matches) {
    final sorted = matches.toList(growable: false)
      ..sort((a, b) => b.score.compareTo(a.score));
    final selected = <NormalizedEntity>[];
    final occupied = <String>{};

    for (final match in sorted) {
      final key = '${match.type.name}:${match.start}:${match.end}';
      if (!occupied.add(key)) continue;

      final confidence = _confidenceCalculator.confidenceFor(match);
      final alternatives = _confidenceCalculator.alternativesFor(
        primary: match,
        matches: sorted,
      );

      selected.add(
        _normalizer.normalizeMatch(
          match: match,
          confidence: confidence,
          alternatives: alternatives,
        ),
      );
    }

    selected.sort((a, b) => b.confidence.compareTo(a.confidence));
    return List<NormalizedEntity>.unmodifiable(selected);
  }
}
