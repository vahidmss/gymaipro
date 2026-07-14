import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/entitlement_reason.dart';
import 'package:gymaipro/ai/entitlement/entitlement_result.dart';

/// Normalizes entitlement engine output into Coach runtime decisions.
class CoachEntitlementValidator {
  const CoachEntitlementValidator();

  /// Decision status implied by [result].
  CoachDecisionStatus statusFor(EntitlementResult result) {
    if (result.allowed) return CoachDecisionStatus.allowed;
    if (result.reasons.contains(EntitlementReason.featureDisabled)) {
      return CoachDecisionStatus.featureDisabled;
    }
    if (result.reasons.contains(EntitlementReason.planInactive)) {
      return CoachDecisionStatus.temporarilyLocked;
    }
    if (_usageExceeded(result.reasons)) {
      return CoachDecisionStatus.usageExceeded;
    }
    return CoachDecisionStatus.upgradeRequired;
  }

  /// Capabilities blocked by policy or usage limits.
  Set<CoachCapability> blockedCapabilities(EntitlementResult result) {
    return Set<CoachCapability>.unmodifiable(
      result.capabilityResults
          .where((entry) => !entry.allowed)
          .map((entry) => entry.capability),
    );
  }

  /// Capabilities missing from the current plan/grants.
  Set<CoachCapability> missingCapabilities(EntitlementResult result) {
    return Set<CoachCapability>.unmodifiable(
      result.capabilityResults
          .where(
            (entry) =>
                entry.reasons.contains(EntitlementReason.missingCapability),
          )
          .map((entry) => entry.capability),
    );
  }

  bool _usageExceeded(Set<EntitlementReason> reasons) {
    return reasons.contains(EntitlementReason.dailyLimitReached) ||
        reasons.contains(EntitlementReason.monthlyLimitReached) ||
        reasons.contains(EntitlementReason.tokenLimitReached) ||
        reasons.contains(EntitlementReason.skillLimitReached);
  }
}
