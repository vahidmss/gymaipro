import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/intent/intent_rule_type.dart';

/// Data-driven intent rule definition.
///
/// Rules are declared in the intent rule registry and evaluated by the rule
/// engine. No rule text is hardcoded inside the legacy intent detector.
class IntentRuleDefinition {
  const IntentRuleDefinition({
    required this.id,
    required this.intent,
    required this.type,
    required this.weight,
    this.keywords = const <String>[],
    this.dictionaryKey,
    this.regexPattern,
    this.metadataKey,
    this.metadataEquals,
    this.caseInsensitive = true,
    this.description,
  });

  final String id;
  final AIIntent intent;
  final IntentRuleType type;
  final double weight;
  final List<String> keywords;
  final String? dictionaryKey;
  final String? regexPattern;
  final String? metadataKey;
  final Object? metadataEquals;
  final bool caseInsensitive;
  final String? description;
}

/// One rule evaluation match.
class IntentRuleMatch {
  const IntentRuleMatch({
    required this.ruleId,
    required this.intent,
    required this.type,
    required this.awardedScore,
    required this.matched,
    this.matchedToken,
    this.detail,
  });

  final String ruleId;
  final AIIntent intent;
  final IntentRuleType type;
  final double awardedScore;
  final bool matched;
  final String? matchedToken;
  final String? detail;
}
