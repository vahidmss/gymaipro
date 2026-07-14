import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/intent/intent_rule_definition.dart';

/// Aggregates weighted rule matches into intent score buckets.
class IntentScoringEngine {
  const IntentScoringEngine();

  /// Returns raw weighted scores keyed by [AIIntent].
  Map<AIIntent, double> score(List<IntentRuleMatch> matches) {
    final scores = <AIIntent, double>{};
    for (final match in matches) {
      if (!match.matched || match.awardedScore <= 0) continue;
      scores[match.intent] = (scores[match.intent] ?? 0) + match.awardedScore;
    }
    return Map<AIIntent, double>.unmodifiable(scores);
  }

  /// Returns intents sorted by raw score descending.
  List<MapEntry<AIIntent, double>> rankedScores(Map<AIIntent, double> scores) {
    final entries = scores.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    return List<MapEntry<AIIntent, double>>.unmodifiable(entries);
  }
}
