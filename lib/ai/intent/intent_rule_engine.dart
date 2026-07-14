import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/intent/intent_detection_trace.dart';
import 'package:gymaipro/ai/intent/intent_keyword_dictionary.dart';
import 'package:gymaipro/ai/intent/intent_regex_matcher.dart';
import 'package:gymaipro/ai/intent/intent_rule_definition.dart';
import 'package:gymaipro/ai/intent/intent_rule_registry.dart';
import 'package:gymaipro/ai/intent/intent_rule_type.dart';

/// Evaluates data-driven intent rules against a user message.
class IntentRuleEngine {
  IntentRuleEngine({
    IntentRuleRegistry? registry,
    IntentRegexMatcher regexMatcher = const IntentRegexMatcher(),
    IntentMessageNormalizer normalizer = const IntentMessageNormalizer(),
  }) : _registry = registry ?? IntentRuleRegistry(),
       _regexMatcher = regexMatcher,
       _normalizer = normalizer;

  final IntentRuleRegistry _registry;
  final IntentRegexMatcher _regexMatcher;
  final IntentMessageNormalizer _normalizer;

  /// Evaluates all registered rules for [request].
  List<IntentRuleMatch> evaluate(IntentDetectionRequest request) {
    final normalized = _normalizer.normalize(request.message);
    final matches = <IntentRuleMatch>[];

    for (final rule in _registry.rules) {
      matches.add(
        _evaluateRule(
          rule: rule,
          normalizedMessage: normalized,
          metadata: request.metadata,
        ),
      );
    }

    return List<IntentRuleMatch>.unmodifiable(matches);
  }

  IntentRuleMatch _evaluateRule({
    required IntentRuleDefinition rule,
    required String normalizedMessage,
    required Map<String, Object?> metadata,
  }) {
    switch (rule.type) {
      case IntentRuleType.keyword:
        return _evaluateKeywordRule(
          rule: rule,
          normalizedMessage: normalizedMessage,
        );
      case IntentRuleType.regex:
        return _evaluateRegexRule(
          rule: rule,
          normalizedMessage: normalizedMessage,
        );
      case IntentRuleType.metadata:
        return _evaluateMetadataRule(rule: rule, metadata: metadata);
    }
  }

  IntentRuleMatch _evaluateKeywordRule({
    required IntentRuleDefinition rule,
    required String normalizedMessage,
  }) {
    final terms = <IntentKeywordEntry>[
      if (rule.dictionaryKey != null)
        ...IntentKeywordDictionary.forKey(rule.dictionaryKey!),
      for (final keyword in rule.keywords)
        IntentKeywordEntry(term: keyword, weight: 1),
    ];

    for (final entry in terms) {
      final term = rule.caseInsensitive ? entry.term.toLowerCase() : entry.term;
      if (!normalizedMessage.contains(term)) continue;

      final awarded = rule.weight * entry.weight;
      return IntentRuleMatch(
        ruleId: rule.id,
        intent: rule.intent,
        type: rule.type,
        awardedScore: awarded,
        matched: true,
        matchedToken: entry.term,
        detail: rule.description,
      );
    }

    return IntentRuleMatch(
      ruleId: rule.id,
      intent: rule.intent,
      type: rule.type,
      awardedScore: 0,
      matched: false,
      detail: rule.description,
    );
  }

  IntentRuleMatch _evaluateRegexRule({
    required IntentRuleDefinition rule,
    required String normalizedMessage,
  }) {
    final pattern = rule.regexPattern;
    if (pattern == null || pattern.isEmpty) {
      return IntentRuleMatch(
        ruleId: rule.id,
        intent: rule.intent,
        type: rule.type,
        awardedScore: 0,
        matched: false,
        detail: 'Missing regex pattern.',
      );
    }

    final matchedToken = _regexMatcher.firstMatch(
      message: normalizedMessage,
      pattern: pattern,
      caseInsensitive: rule.caseInsensitive,
    );
    if (matchedToken == null) {
      return IntentRuleMatch(
        ruleId: rule.id,
        intent: rule.intent,
        type: rule.type,
        awardedScore: 0,
        matched: false,
        detail: rule.description,
      );
    }

    return IntentRuleMatch(
      ruleId: rule.id,
      intent: rule.intent,
      type: rule.type,
      awardedScore: rule.weight,
      matched: true,
      matchedToken: matchedToken,
      detail: rule.description,
    );
  }

  IntentRuleMatch _evaluateMetadataRule({
    required IntentRuleDefinition rule,
    required Map<String, Object?> metadata,
  }) {
    final key = rule.metadataKey;
    if (key == null) {
      return IntentRuleMatch(
        ruleId: rule.id,
        intent: rule.intent,
        type: rule.type,
        awardedScore: 0,
        matched: false,
        detail: 'Missing metadata key.',
      );
    }

    final actual = metadata[key];
    final expected = rule.metadataEquals;
    final matched =
        actual == expected ||
        (actual != null &&
            expected != null &&
            actual.toString() == expected.toString());

    return IntentRuleMatch(
      ruleId: rule.id,
      intent: rule.intent,
      type: rule.type,
      awardedScore: matched ? rule.weight : 0,
      matched: matched,
      matchedToken: actual?.toString(),
      detail: rule.description,
    );
  }

  /// Builds a debug trace from rule matches.
  IntentDetectionTrace buildTrace({
    required IntentDetectionRequest request,
    required List<IntentRuleMatch> matches,
    required Map<AIIntent, double> rawScores,
  }) {
    return IntentDetectionTrace(
      normalizedMessage: _normalizer.normalize(request.message),
      locale: request.locale,
      rawScores: rawScores.map(
        (key, value) => MapEntry<String, double>(key.name, value),
      ),
      entries: List<IntentRuleTraceEntry>.unmodifiable(
        matches
            .map(
              (match) => IntentRuleTraceEntry(
                ruleId: match.ruleId,
                intentName: match.intent.name,
                ruleType: match.type.name,
                awardedScore: match.awardedScore,
                matched: match.matched,
                matchedToken: match.matchedToken,
                detail: match.detail,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
