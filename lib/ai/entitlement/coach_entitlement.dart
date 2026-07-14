import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';

/// Usage counters used by entitlement checks.
class EntitlementUsageSnapshot {
  const EntitlementUsageSnapshot({
    this.dailyUsage = const <CoachCapability, int>{},
    this.monthlyUsage = const <CoachCapability, int>{},
    this.tokenUsage = const <CoachCapability, int>{},
    this.skillUsage = const <String, int>{},
  });

  /// Daily usage per capability.
  final Map<CoachCapability, int> dailyUsage;

  /// Monthly usage per capability.
  final Map<CoachCapability, int> monthlyUsage;

  /// Token usage per capability.
  final Map<CoachCapability, int> tokenUsage;

  /// Future skill-specific usage.
  final Map<String, int> skillUsage;

  /// Daily usage for [capability].
  int dailyFor(CoachCapability capability) => dailyUsage[capability] ?? 0;

  /// Monthly usage for [capability].
  int monthlyFor(CoachCapability capability) => monthlyUsage[capability] ?? 0;

  /// Token usage for [capability].
  int tokenFor(CoachCapability capability) => tokenUsage[capability] ?? 0;
}

/// Temporary capability grant from trials, gifts, promos, or unlocks.
class EntitlementGrant {
  const EntitlementGrant({
    required this.id,
    required this.capabilities,
    required this.source,
    this.startsAt,
    this.expiresAt,
    this.active = true,
    this.metadata = const <String, Object?>{},
  });

  /// Stable grant id.
  final String id;

  /// Capabilities granted by this entry.
  final Set<CoachCapability> capabilities;

  /// Source label such as trial, gift, promo, temporary_unlock, enterprise.
  final String source;

  /// Optional activation time.
  final DateTime? startsAt;

  /// Optional expiration time.
  final DateTime? expiresAt;

  /// Whether this grant is active.
  final bool active;

  /// Future diagnostic metadata.
  final Map<String, Object?> metadata;

  /// Whether this grant is active at [now].
  bool isActive({DateTime? now}) {
    if (!active) return false;
    final effectiveNow = now ?? DateTime.now();
    final startsAt = this.startsAt;
    final expiresAt = this.expiresAt;
    if (startsAt != null && effectiveNow.isBefore(startsAt)) return false;
    if (expiresAt != null && effectiveNow.isAfter(expiresAt)) return false;
    return true;
  }
}

/// User entitlement snapshot consumed by the entitlement engine.
class CoachEntitlement {
  const CoachEntitlement({
    required this.userId,
    required this.plan,
    this.planActive = true,
    this.trialActive = false,
    this.trialCapabilities = const <CoachCapability>{},
    this.trialExpiresAt,
    this.temporaryUnlocks = const <EntitlementGrant>[],
    this.gifts = const <EntitlementGrant>[],
    this.promoCodes = const <EntitlementGrant>[],
    this.enterpriseGrants = const <EntitlementGrant>[],
    this.lifetimeCapabilities = const <CoachCapability>{},
    this.disabledCapabilities = const <CoachCapability>{},
    this.usage = const EntitlementUsageSnapshot(),
    this.metadata = const <String, Object?>{},
  });

  /// User id.
  final String userId;

  /// Current subscription plan.
  final CoachSubscriptionPlan plan;

  /// Whether current plan should be considered active.
  final bool planActive;

  /// Whether a trial is active.
  final bool trialActive;

  /// Capabilities included in active trial.
  final Set<CoachCapability> trialCapabilities;

  /// Optional trial expiration.
  final DateTime? trialExpiresAt;

  /// Temporary feature unlock grants.
  final List<EntitlementGrant> temporaryUnlocks;

  /// Gift grants.
  final List<EntitlementGrant> gifts;

  /// Promo-code grants.
  final List<EntitlementGrant> promoCodes;

  /// Enterprise-policy grants.
  final List<EntitlementGrant> enterpriseGrants;

  /// Capabilities granted permanently.
  final Set<CoachCapability> lifetimeCapabilities;

  /// Capabilities disabled by policy.
  final Set<CoachCapability> disabledCapabilities;

  /// Read-only usage snapshot.
  final EntitlementUsageSnapshot usage;

  /// Future diagnostic metadata.
  final Map<String, Object?> metadata;

  /// Whether trial is active at [now].
  bool isTrialActive({DateTime? now}) {
    if (!trialActive) return false;
    final trialExpiresAt = this.trialExpiresAt;
    if (trialExpiresAt == null) return true;
    return !(now ?? DateTime.now()).isAfter(trialExpiresAt);
  }
}
