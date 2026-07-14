import 'package:gymaipro/ai/entitlement/coach_entitlement.dart';
import 'package:gymaipro/ai/entitlement/feature_gate.dart';

/// Validation result for entitlement inputs.
class EntitlementValidationResult {
  const EntitlementValidationResult({
    required this.isValid,
    this.issues = const <String>[],
  });

  /// Whether validation passed.
  final bool isValid;

  /// Human-readable issues.
  final List<String> issues;
}

/// Validates entitlement snapshots and feature gates.
class EntitlementValidator {
  const EntitlementValidator();

  /// Validates a user entitlement snapshot.
  EntitlementValidationResult validateEntitlement(
    CoachEntitlement entitlement,
  ) {
    final issues = <String>[];

    if (entitlement.userId.trim().isEmpty) {
      issues.add('userId must not be empty.');
    }

    for (final entry in entitlement.usage.dailyUsage.entries) {
      if (entry.value < 0) {
        issues.add('Daily usage for ${entry.key.name} must not be negative.');
      }
    }
    for (final entry in entitlement.usage.monthlyUsage.entries) {
      if (entry.value < 0) {
        issues.add('Monthly usage for ${entry.key.name} must not be negative.');
      }
    }
    for (final entry in entitlement.usage.tokenUsage.entries) {
      if (entry.value < 0) {
        issues.add('Token usage for ${entry.key.name} must not be negative.');
      }
    }

    for (final grant in <EntitlementGrant>[
      ...entitlement.temporaryUnlocks,
      ...entitlement.gifts,
      ...entitlement.promoCodes,
      ...entitlement.enterpriseGrants,
    ]) {
      if (grant.id.trim().isEmpty) {
        issues.add('Entitlement grant id must not be empty.');
      }
      if (grant.capabilities.isEmpty) {
        issues.add('Grant ${grant.id} must include at least one capability.');
      }
    }

    return EntitlementValidationResult(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }

  /// Validates a feature gate declaration.
  EntitlementValidationResult validateGate(FeatureGate gate) {
    final issues = <String>[];

    if (gate.id.trim().isEmpty) {
      issues.add('FeatureGate id must not be empty.');
    }
    if (gate.requiredCapabilities.isEmpty && gate.anyOfCapabilities.isEmpty) {
      issues.add('FeatureGate must reference at least one capability.');
    }

    return EntitlementValidationResult(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }
}
