import 'package:gymaipro/ai/memory/intelligence/memory_extraction_reason.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_rule.dart';

/// Classification result for one text input.
class MemoryClassification {
  const MemoryClassification({
    required this.shouldStore,
    required this.matchedRules,
    required this.reasons,
  });

  /// Whether the text contains memory-worthy information.
  final bool shouldStore;

  /// Rules matched by the text.
  final List<MemoryRule> matchedRules;

  /// Reasons explaining the classification.
  final Set<MemoryExtractionReason> reasons;
}

/// Rule-based classifier for memory-worthy text.
class MemoryClassifier {
  const MemoryClassifier({
    this.rules = MemoryRules.defaults,
    this.minimumSignalLength = 8,
  });

  /// Rules used for classification.
  final List<MemoryRule> rules;

  /// Very short text is treated as low-signal unless a rule matches.
  final int minimumSignalLength;

  /// Classifies normalized or raw user text.
  MemoryClassification classify(String text) {
    final normalizedText = _normalize(text);
    final matchedRules = <MemoryRule>[
      for (final rule in rules)
        if (rule.matches(normalizedText)) rule,
    ];
    final reasons = <MemoryExtractionReason>{
      for (final rule in matchedRules) rule.reason,
    };

    if (matchedRules.isEmpty) {
      reasons.add(
        normalizedText.length < minimumSignalLength
            ? MemoryExtractionReason.ignoredLowSignal
            : MemoryExtractionReason.noRuleMatched,
      );
    }

    return MemoryClassification(
      shouldStore: matchedRules.isNotEmpty,
      matchedRules: List<MemoryRule>.unmodifiable(matchedRules),
      reasons: Set<MemoryExtractionReason>.unmodifiable(reasons),
    );
  }

  String _normalize(String text) {
    return text.trim().toLowerCase();
  }
}
