import 'package:gymaipro/ai/prompt/prompt_package.dart';

/// Validation result for prompt packages.
class PromptValidationResult {
  const PromptValidationResult({
    required this.isValid,
    this.errors = const <String>[],
    this.warnings = const <String>[],
  });

  /// Whether the package is structurally valid.
  final bool isValid;

  /// Blocking validation errors.
  final List<String> errors;

  /// Non-blocking validation warnings.
  final List<String> warnings;
}

/// Validates prompt package structure without rendering or calling OpenAI.
class PromptValidator {
  const PromptValidator();

  /// Validates a prompt package.
  PromptValidationResult validate(PromptPackage package) {
    final errors = <String>[];
    final warnings = <String>[];

    if (package.id.trim().isEmpty) {
      errors.add('package_id_empty');
    }
    if (package.sections.isEmpty) {
      errors.add('sections_empty');
    }
    if (package.metadata.estimatedTokens >
        package.budget.availableInputTokens) {
      errors.add('token_budget_exceeded');
    }
    if (package.metadata.estimatedCost > package.budget.maxEstimatedCost) {
      warnings.add('estimated_cost_exceeds_budget');
    }
    if (package.memoryKeys.toSet().length != package.memoryKeys.length) {
      warnings.add('duplicate_memory_keys');
    }

    return PromptValidationResult(
      isValid: errors.isEmpty,
      errors: List<String>.unmodifiable(errors),
      warnings: List<String>.unmodifiable(warnings),
    );
  }
}
