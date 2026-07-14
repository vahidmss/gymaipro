/// Debug trace entry for one evaluated intent rule.
class IntentRuleTraceEntry {
  const IntentRuleTraceEntry({
    required this.ruleId,
    required this.intentName,
    required this.ruleType,
    required this.awardedScore,
    required this.matched,
    this.matchedToken,
    this.detail,
  });

  final String ruleId;
  final String intentName;
  final String ruleType;
  final double awardedScore;
  final bool matched;
  final String? matchedToken;
  final String? detail;
}

/// Immutable debug trace for an intent intelligence run.
class IntentDetectionTrace {
  const IntentDetectionTrace({
    required this.normalizedMessage,
    required this.entries,
    required this.rawScores,
    this.locale,
  });

  final String normalizedMessage;
  final List<IntentRuleTraceEntry> entries;
  final Map<String, double> rawScores;
  final String? locale;

  int get matchedRuleCount => entries.where((entry) => entry.matched).length;
}
