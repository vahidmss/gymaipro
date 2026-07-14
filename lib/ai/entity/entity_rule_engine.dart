import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/entity/entity_normalizer.dart';
import 'package:gymaipro/ai/entity/entity_registry.dart';
import 'package:gymaipro/ai/entity/entity_rule.dart';
import 'package:gymaipro/ai/entity/entity_trace.dart';
import 'package:gymaipro/ai/entity/entity_type.dart';

/// Raw output of evaluating entity rules.
class EntityRuleEngineResult {
  const EntityRuleEngineResult({required this.matches, required this.trace});

  /// Raw entity matches.
  final List<EntityMatch> matches;

  /// Debug trace.
  final EntityTrace trace;
}

/// Rule-based entity matcher.
class EntityRuleEngine {
  const EntityRuleEngine({
    EntityRegistry registry = const EntityRegistry(),
    EntityNormalizer normalizer = const EntityNormalizer(),
  }) : _registry = registry,
       _normalizer = normalizer;

  final EntityRegistry _registry;
  final EntityNormalizer _normalizer;

  /// Evaluates all registry rules against [message].
  EntityRuleEngineResult evaluate(String message) {
    return evaluateNormalized(_normalizer.normalizeMessage(message));
  }

  /// Evaluates all registry rules against an already-normalized message.
  EntityRuleEngineResult evaluateNormalized(String normalizedMessage) {
    final matches = <EntityMatch>[];
    final traceEntries = <EntityTraceEntry>[];

    for (final rule in _registry.rules) {
      final ruleMatches = _evaluateRule(rule, normalizedMessage);
      matches.addAll(ruleMatches);
      traceEntries.add(
        EntityTraceEntry(
          ruleId: rule.id,
          entityType: rule.type.name,
          ruleType: rule.ruleType.name,
          matched: ruleMatches.isNotEmpty,
          score: ruleMatches.fold<double>(
            0,
            (total, match) => total + match.score,
          ),
          rawText: ruleMatches.isEmpty ? null : ruleMatches.first.rawText,
          detail: rule.description,
        ),
      );
    }

    return EntityRuleEngineResult(
      matches: List<EntityMatch>.unmodifiable(matches),
      trace: EntityTrace(
        normalizedMessage: normalizedMessage,
        entries: List<EntityTraceEntry>.unmodifiable(traceEntries),
      ),
    );
  }

  List<EntityMatch> _evaluateRule(EntityRule rule, String message) {
    switch (rule.ruleType) {
      case EntityRuleType.keyword:
        return _evaluateKeywordRule(rule, message);
      case EntityRuleType.regex:
        return _evaluateRegexRule(rule, message);
    }
  }

  List<EntityMatch> _evaluateKeywordRule(EntityRule rule, String message) {
    final matches = <EntityMatch>[];
    for (final synonym in rule.synonyms) {
      for (final term in synonym.terms) {
        final needle = rule.caseInsensitive ? term.toLowerCase() : term;
        final index = message.indexOf(needle);
        if (index < 0) continue;
        matches.add(
          EntityMatch(
            ruleId: rule.id,
            type: rule.type,
            rawText: term,
            rawValue: synonym.value,
            score: rule.weight * synonym.weight,
            start: index,
            end: index + needle.length,
            locale: synonym.locale,
          ),
        );
      }
    }
    return List<EntityMatch>.unmodifiable(matches);
  }

  List<EntityMatch> _evaluateRegexRule(EntityRule rule, String message) {
    final pattern = rule.regexPattern;
    if (pattern == null || pattern.isEmpty) return const <EntityMatch>[];

    final regex = RegExp(
      pattern,
      caseSensitive: !rule.caseInsensitive,
      unicode: true,
    );
    final matches = <EntityMatch>[];

    for (final match in regex.allMatches(message)) {
      final rawText = match.group(0);
      final rawValue = _group(match, rule.valueGroup);
      if (rawText == null || rawValue == null) continue;
      matches.add(
        EntityMatch(
          ruleId: rule.id,
          type: rule.type,
          rawText: rawText,
          rawValue: rawValue,
          rawUnit: rule.unitGroup == null
              ? null
              : _group(match, rule.unitGroup!),
          score: rule.weight,
          start: match.start,
          end: match.end,
        ),
      );
    }

    return List<EntityMatch>.unmodifiable(matches);
  }

  String? _group(RegExpMatch match, int group) {
    if (group > match.groupCount) return null;
    return match.group(group);
  }
}
