import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/intent/intent_confidence_calculator.dart';
import 'package:gymaipro/ai/intent/intent_intelligence_result.dart';
import 'package:gymaipro/ai/intent/intent_rule_definition.dart';
import 'package:gymaipro/ai/intent/intent_rule_engine.dart';
import 'package:gymaipro/ai/intent/intent_rule_type.dart';
import 'package:gymaipro/ai/intent/intent_scoring_engine.dart';

/// Rule-based intent intelligence engine.
///
/// Uses keyword dictionaries, regex matchers, metadata rules, weighted scoring,
/// and confidence calculation. This engine is infrastructure-only and is not
/// wired into runtime unless explicitly injected behind the Coach v2 feature flag.
class IntentIntelligenceEngine {
  IntentIntelligenceEngine({
    IntentRuleEngine? ruleEngine,
    IntentScoringEngine scoringEngine = const IntentScoringEngine(),
    IntentConfidenceCalculator confidenceCalculator =
        const IntentConfidenceCalculator(),
    this.alternativeMinConfidence = 0.08,
    this.maxAlternatives = 3,
  }) : _ruleEngine = ruleEngine ?? IntentRuleEngine(),
       _scoringEngine = scoringEngine,
       _confidenceCalculator = confidenceCalculator;

  final IntentRuleEngine _ruleEngine;
  final IntentScoringEngine _scoringEngine;
  final IntentConfidenceCalculator _confidenceCalculator;
  final double alternativeMinConfidence;
  final int maxAlternatives;

  /// Detects primary and secondary intents for [request].
  IntentIntelligenceResult detect(IntentDetectionRequest request) {
    final matches = _ruleEngine.evaluate(request);
    final rawScores = _scoringEngine.score(matches);
    final confidences = _confidenceCalculator.normalize(rawScores);
    final ranked = _scoringEngine.rankedScores(rawScores);

    final primaryEntry = ranked.isEmpty
        ? const MapEntry<AIIntent, double>(AIIntent.generalChat, 0)
        : ranked.first;
    final primaryIntent = primaryEntry.key;
    final primaryConfidence = confidences[primaryIntent] ?? 0;

    final alternatives = _confidenceCalculator.alternatives(
      primary: primaryIntent,
      rawScores: rawScores,
      confidences: confidences,
      minConfidence: alternativeMinConfidence,
      maxAlternatives: maxAlternatives,
    );

    final trace = _ruleEngine.buildTrace(
      request: request,
      matches: matches,
      rawScores: rawScores,
    );

    return IntentIntelligenceResult(
      primaryIntent: primaryIntent,
      primaryConfidence: primaryConfidence,
      alternatives: alternatives,
      trace: trace,
      strategy: _resolveStrategy(matches),
      rawPrimaryScore: primaryEntry.value,
      reason: primaryEntry.value > 0
          ? 'Matched ${trace.matchedRuleCount} rule(s); primary=${primaryIntent.name}.'
          : 'No intent rules matched; fallback=generalChat.',
    );
  }

  IntentIntelligenceStrategy _resolveStrategy(List<IntentRuleMatch> matches) {
    final matchedTypes = matches
        .where((match) => match.matched)
        .map((match) => match.type)
        .toSet();
    if (matchedTypes.isEmpty) return IntentIntelligenceStrategy.rule;
    if (matchedTypes.length == 1) {
      switch (matchedTypes.first) {
        case IntentRuleType.keyword:
          return IntentIntelligenceStrategy.keyword;
        case IntentRuleType.regex:
          return IntentIntelligenceStrategy.regex;
        case IntentRuleType.metadata:
          return IntentIntelligenceStrategy.rule;
      }
    }
    return IntentIntelligenceStrategy.hybrid;
  }
}
