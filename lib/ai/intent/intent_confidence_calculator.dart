import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/intent/intent_intelligence_result.dart';

/// Converts raw weighted scores into normalized confidence values.
class IntentConfidenceCalculator {
  const IntentConfidenceCalculator();

  /// Normalizes [rawScores] into confidence values from 0 to 1.
  Map<AIIntent, double> normalize(Map<AIIntent, double> rawScores) {
    if (rawScores.isEmpty) {
      return const <AIIntent, double>{AIIntent.generalChat: 0};
    }

    final total = rawScores.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return const <AIIntent, double>{AIIntent.generalChat: 0};
    }

    final normalized = <AIIntent, double>{};
    for (final entry in rawScores.entries) {
      normalized[entry.key] = (entry.value / total).clamp(0, 1);
    }
    return Map<AIIntent, double>.unmodifiable(normalized);
  }

  /// Builds ranked secondary intents excluding [primary].
  List<IntentAlternative> alternatives({
    required AIIntent primary,
    required Map<AIIntent, double> rawScores,
    required Map<AIIntent, double> confidences,
    double minConfidence = 0.08,
    int maxAlternatives = 3,
  }) {
    final ranked = rawScores.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    final alternatives = <IntentAlternative>[];
    for (final entry in ranked) {
      if (entry.key == primary) continue;
      final confidence = confidences[entry.key] ?? 0;
      if (confidence < minConfidence) continue;
      alternatives.add(
        IntentAlternative(
          intent: entry.key,
          confidence: confidence,
          rawScore: entry.value,
        ),
      );
      if (alternatives.length >= maxAlternatives) break;
    }

    return List<IntentAlternative>.unmodifiable(alternatives);
  }
}
