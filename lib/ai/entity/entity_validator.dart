import 'package:gymaipro/ai/entity/entity_result.dart';
import 'package:gymaipro/ai/entity/entity_rule.dart';
import 'package:gymaipro/ai/entity/entity_type.dart';

/// Validation result for entity infrastructure.
class EntityValidationResult {
  const EntityValidationResult({
    required this.isValid,
    this.issues = const <String>[],
  });

  /// Whether validation passed.
  final bool isValid;

  /// Validation issues.
  final List<String> issues;
}

/// Validates entity rules and extraction outputs.
class EntityValidator {
  const EntityValidator();

  /// Validates data-driven rules.
  EntityValidationResult validateRules(List<EntityRule> rules) {
    final issues = <String>[];
    final ids = <String>{};

    for (final rule in rules) {
      if (rule.id.trim().isEmpty) {
        issues.add('Entity rule id must not be empty.');
      }
      if (!ids.add(rule.id)) {
        issues.add('Duplicate entity rule id: ${rule.id}.');
      }
      if (rule.weight <= 0) {
        issues.add('Entity rule ${rule.id} weight must be positive.');
      }
      if (rule.ruleType == EntityRuleType.regex &&
          (rule.regexPattern == null || rule.regexPattern!.isEmpty)) {
        issues.add('Regex rule ${rule.id} must define regexPattern.');
      }
      if (rule.ruleType == EntityRuleType.keyword && rule.synonyms.isEmpty) {
        issues.add('Keyword rule ${rule.id} must define synonyms.');
      }
    }

    return EntityValidationResult(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }

  /// Validates extraction output.
  EntityValidationResult validateResult(EntityExtractionResult result) {
    final issues = <String>[];

    if (result.originalMessage.trim().isEmpty) {
      issues.add('originalMessage must not be empty.');
    }
    for (final entity in result.entities) {
      if (entity.confidence < 0 || entity.confidence > 1) {
        issues.add('Entity ${entity.type.name} confidence must be 0..1.');
      }
    }

    return EntityValidationResult(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }
}
