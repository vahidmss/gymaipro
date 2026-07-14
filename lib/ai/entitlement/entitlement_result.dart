import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/entitlement_reason.dart';

/// Result for one capability check.
class CapabilityEntitlementResult {
  const CapabilityEntitlementResult({
    required this.capability,
    required this.allowed,
    required this.reasons,
    this.dailyRemaining,
    this.monthlyRemaining,
    this.tokenRemaining,
  });

  /// Capability that was evaluated.
  final CoachCapability capability;

  /// Whether access is allowed.
  final bool allowed;

  /// Reasons explaining the decision.
  final Set<EntitlementReason> reasons;

  /// Remaining daily usage when known.
  final int? dailyRemaining;

  /// Remaining monthly usage when known.
  final int? monthlyRemaining;

  /// Remaining token budget when known.
  final int? tokenRemaining;
}

/// Immutable entitlement output for a feature gate check.
class EntitlementResult {
  const EntitlementResult({
    required this.allowed,
    required this.requiredCapabilities,
    required this.capabilityResults,
    required this.reasons,
    this.featureId,
    this.upgradePlanId,
    this.message,
  });

  /// Whether the feature is allowed.
  final bool allowed;

  /// Optional feature id evaluated.
  final String? featureId;

  /// Capabilities requested by the feature.
  final Set<CoachCapability> requiredCapabilities;

  /// Per-capability decisions.
  final List<CapabilityEntitlementResult> capabilityResults;

  /// Aggregate reasons.
  final Set<EntitlementReason> reasons;

  /// Future upgrade suggestion.
  final String? upgradePlanId;

  /// Optional diagnostic message.
  final String? message;
}
