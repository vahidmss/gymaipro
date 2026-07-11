import 'package:gymaipro/ai/memory/coach_memory.dart';

/// Validation result for a memory item.
class MemoryValidationResult {
  const MemoryValidationResult({
    required this.isValid,
    this.errors = const <String>[],
  });

  /// Whether the memory can be stored.
  final bool isValid;

  /// Validation errors.
  final List<String> errors;
}

/// Validates coach memory items before persistence or merge.
class MemoryValidator {
  const MemoryValidator();

  /// Validates one memory item.
  MemoryValidationResult validate(CoachMemory memory) {
    final errors = <String>[];

    if (memory.key.trim().isEmpty) {
      errors.add('key_empty');
    }
    if (memory.value.trim().isEmpty) {
      errors.add('value_empty');
    }
    if (memory.confidence < 0 || memory.confidence > 1) {
      errors.add('confidence_out_of_range');
    }
    final expiresAt = memory.expiresAt;
    if (expiresAt != null && expiresAt.isBefore(memory.createdAt)) {
      errors.add('expires_before_created');
    }
    if (memory.updatedAt.isBefore(memory.createdAt)) {
      errors.add('updated_before_created');
    }

    return MemoryValidationResult(
      isValid: errors.isEmpty,
      errors: List<String>.unmodifiable(errors),
    );
  }
}
