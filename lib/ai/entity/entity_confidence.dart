import 'package:gymaipro/ai/entity/entity_match.dart';

/// Calculates confidence for extracted entity matches.
class EntityConfidenceCalculator {
  const EntityConfidenceCalculator();

  /// Converts raw match score into a confidence value from 0 to 1.
  double confidenceFor(EntityMatch match) {
    final spanLength = (match.end - match.start).clamp(1, 80);
    final spanBonus = spanLength / 400;
    return (match.score / 1.5 + spanBonus).clamp(0, 1);
  }

  /// Builds alternatives for the same entity type.
  List<EntityAlternative> alternativesFor({
    required EntityMatch primary,
    required List<EntityMatch> matches,
  }) {
    final alternatives = <EntityAlternative>[];
    for (final match in matches) {
      if (match == primary || match.type != primary.type) continue;
      alternatives.add(
        EntityAlternative(
          type: match.type,
          value: match.rawValue,
          unit: match.rawUnit,
          confidence: confidenceFor(match),
        ),
      );
    }
    alternatives.sort((a, b) => b.confidence.compareTo(a.confidence));
    return List<EntityAlternative>.unmodifiable(alternatives.take(3));
  }
}
