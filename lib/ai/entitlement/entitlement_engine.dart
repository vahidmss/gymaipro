import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_entitlement.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/entitlement/entitlement_reason.dart';
import 'package:gymaipro/ai/entitlement/entitlement_registry.dart';
import 'package:gymaipro/ai/entitlement/entitlement_result.dart';
import 'package:gymaipro/ai/entitlement/entitlement_validator.dart';
import 'package:gymaipro/ai/entitlement/feature_gate.dart';

/// Capability-first entitlement engine for GymAI Coach.
///
/// This engine is infrastructure-only. It does not call APIs, mutate state,
/// navigate, build prompts, or inspect UI.
class EntitlementEngine {
  const EntitlementEngine({
    EntitlementRegistry registry = const EntitlementRegistry(),
    EntitlementValidator validator = const EntitlementValidator(),
  }) : _registry = registry,
       _validator = validator;

  final EntitlementRegistry _registry;
  final EntitlementValidator _validator;

  /// Checks one capability directly.
  EntitlementResult checkCapability({
    required CoachEntitlement entitlement,
    required CoachCapability capability,
    DateTime? now,
  }) {
    return checkGate(
      entitlement: entitlement,
      gate: FeatureGate(
        id: 'capability_${capability.name}',
        requiredCapabilities: <CoachCapability>{capability},
      ),
      now: now,
    );
  }

  /// Checks a feature gate against a user entitlement snapshot.
  EntitlementResult checkGate({
    required CoachEntitlement entitlement,
    required FeatureGate gate,
    DateTime? now,
  }) {
    final entitlementValidation = _validator.validateEntitlement(entitlement);
    final gateValidation = _validator.validateGate(gate);
    if (!entitlementValidation.isValid || !gateValidation.isValid) {
      return EntitlementResult(
        allowed: false,
        featureId: gate.id,
        requiredCapabilities: gate.allReferencedCapabilities,
        capabilityResults: const <CapabilityEntitlementResult>[],
        reasons: const <EntitlementReason>{EntitlementReason.validationFailed},
        message: <String>[
          ...entitlementValidation.issues,
          ...gateValidation.issues,
        ].join(' '),
      );
    }

    final requiredResults = <CapabilityEntitlementResult>[
      for (final capability in gate.requiredCapabilities)
        _checkCapability(
          entitlement: entitlement,
          capability: capability,
          gate: gate,
          now: now,
        ),
    ];

    final anyOfResults = <CapabilityEntitlementResult>[
      for (final capability in gate.anyOfCapabilities)
        _checkCapability(
          entitlement: entitlement,
          capability: capability,
          gate: gate,
          now: now,
        ),
    ];

    final requiredAllowed = requiredResults.every((result) => result.allowed);
    final anyOfAllowed =
        anyOfResults.isEmpty || anyOfResults.any((result) => result.allowed);
    final allowed = requiredAllowed && anyOfAllowed;
    final allResults = <CapabilityEntitlementResult>[
      ...requiredResults,
      ...anyOfResults,
    ];
    final reasons = <EntitlementReason>{
      for (final result in allResults) ...result.reasons,
    };
    final deniedCapability = allResults
        .where((result) => !result.allowed)
        .map((result) => result.capability)
        .firstOrNull;

    return EntitlementResult(
      allowed: allowed,
      featureId: gate.id,
      requiredCapabilities: gate.allReferencedCapabilities,
      capabilityResults: List<CapabilityEntitlementResult>.unmodifiable(
        allResults,
      ),
      reasons: Set<EntitlementReason>.unmodifiable(reasons),
      upgradePlanId: deniedCapability == null
          ? null
          : _registry.upgradePlanFor(deniedCapability)?.id,
      message: allowed
          ? 'Feature ${gate.id} is allowed.'
          : 'Feature ${gate.id} is blocked by entitlement.',
    );
  }

  CapabilityEntitlementResult _checkCapability({
    required CoachEntitlement entitlement,
    required CoachCapability capability,
    required FeatureGate gate,
    DateTime? now,
  }) {
    final reasons = <EntitlementReason>{};
    final definition = _registry.capabilityDefinition(capability);

    if (entitlement.disabledCapabilities.contains(capability)) {
      reasons.add(EntitlementReason.featureDisabled);
      return _result(capability: capability, allowed: false, reasons: reasons);
    }

    final hasCapability = _hasCapability(
      entitlement: entitlement,
      capability: capability,
      gate: gate,
      reasons: reasons,
      now: now,
    );

    if (!hasCapability) {
      reasons.add(EntitlementReason.missingCapability);
      return _result(capability: capability, allowed: false, reasons: reasons);
    }

    final dailyRemaining = _remaining(
      limit: gate.enforceDailyLimit ? definition?.defaultDailyLimit : null,
      used: entitlement.usage.dailyFor(capability),
    );
    if (dailyRemaining != null && dailyRemaining < 0) {
      reasons.add(EntitlementReason.dailyLimitReached);
    }

    final monthlyRemaining = _remaining(
      limit: gate.enforceMonthlyLimit ? definition?.defaultMonthlyLimit : null,
      used: entitlement.usage.monthlyFor(capability),
    );
    if (monthlyRemaining != null && monthlyRemaining < 0) {
      reasons.add(EntitlementReason.monthlyLimitReached);
    }

    final tokenRemaining = _remaining(
      limit: gate.enforceTokenLimit ? definition?.defaultTokenLimit : null,
      used: entitlement.usage.tokenFor(capability),
    );
    if (tokenRemaining != null && tokenRemaining < 0) {
      reasons.add(EntitlementReason.tokenLimitReached);
    }

    final blockedByLimit =
        reasons.contains(EntitlementReason.dailyLimitReached) ||
        reasons.contains(EntitlementReason.monthlyLimitReached) ||
        reasons.contains(EntitlementReason.tokenLimitReached);

    return CapabilityEntitlementResult(
      capability: capability,
      allowed: !blockedByLimit,
      reasons: Set<EntitlementReason>.unmodifiable(reasons),
      dailyRemaining: dailyRemaining,
      monthlyRemaining: monthlyRemaining,
      tokenRemaining: tokenRemaining,
    );
  }

  bool _hasCapability({
    required CoachEntitlement entitlement,
    required CoachCapability capability,
    required FeatureGate gate,
    required Set<EntitlementReason> reasons,
    DateTime? now,
  }) {
    if (!entitlement.planActive) {
      reasons.add(EntitlementReason.planInactive);
    } else if (_planCapabilities(entitlement.plan).contains(capability)) {
      reasons.add(_planReason(entitlement.plan));
      return true;
    }

    if (gate.allowTrial && entitlement.isTrialActive(now: now)) {
      if (entitlement.trialCapabilities.contains(capability)) {
        reasons.add(EntitlementReason.capabilityGrantedByTrial);
        return true;
      }
    } else if (entitlement.trialActive) {
      reasons.add(EntitlementReason.trialExpired);
    }

    if (gate.allowTemporaryUnlock &&
        _grantsCapability(entitlement.temporaryUnlocks, capability, now: now)) {
      reasons.add(EntitlementReason.capabilityGrantedByTemporaryUnlock);
      return true;
    }

    if (gate.allowGift &&
        _grantsCapability(entitlement.gifts, capability, now: now)) {
      reasons.add(EntitlementReason.capabilityGrantedByGift);
      return true;
    }

    if (gate.allowPromoCode &&
        _grantsCapability(entitlement.promoCodes, capability, now: now)) {
      reasons.add(EntitlementReason.capabilityGrantedByPromoCode);
      return true;
    }

    if (gate.allowEnterpriseOverride &&
        _grantsCapability(entitlement.enterpriseGrants, capability, now: now)) {
      reasons.add(EntitlementReason.capabilityGrantedByEnterprisePolicy);
      return true;
    }

    if (entitlement.lifetimeCapabilities.contains(capability)) {
      reasons.add(EntitlementReason.capabilityGrantedByLifetimePlan);
      return true;
    }

    return false;
  }

  Set<CoachCapability> _planCapabilities(CoachSubscriptionPlan plan) {
    return _registry.capabilitiesForPlan(plan);
  }

  EntitlementReason _planReason(CoachSubscriptionPlan plan) {
    if (plan == CoachSubscriptionPlan.enterprise) {
      return EntitlementReason.capabilityGrantedByEnterprisePolicy;
    }
    if (plan == CoachSubscriptionPlan.lifetime) {
      return EntitlementReason.capabilityGrantedByLifetimePlan;
    }
    return EntitlementReason.capabilityGrantedByPlan;
  }

  bool _grantsCapability(
    List<EntitlementGrant> grants,
    CoachCapability capability, {
    DateTime? now,
  }) {
    for (final grant in grants) {
      if (grant.isActive(now: now) && grant.capabilities.contains(capability)) {
        return true;
      }
    }
    return false;
  }

  int? _remaining({required int? limit, required int used}) {
    if (limit == null) return null;
    return limit - used;
  }

  CapabilityEntitlementResult _result({
    required CoachCapability capability,
    required bool allowed,
    required Set<EntitlementReason> reasons,
  }) {
    return CapabilityEntitlementResult(
      capability: capability,
      allowed: allowed,
      reasons: Set<EntitlementReason>.unmodifiable(reasons),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
