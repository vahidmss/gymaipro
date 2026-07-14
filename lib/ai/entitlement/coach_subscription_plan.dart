/// Subscription plans known to Coach entitlement infrastructure.
///
/// Plans are capability bundles only. Runtime code should ask for capabilities,
/// not specific plans.
enum CoachSubscriptionPlan {
  free,
  coachPro,
  nutritionPro,
  recoveryPro,
  ultimateAI,
  enterprise,
  lifetime,
}

/// Metadata for one subscription plan.
class CoachSubscriptionPlanDefinition {
  const CoachSubscriptionPlanDefinition({
    required this.plan,
    required this.id,
    required this.title,
    required this.description,
    this.rank = 0,
    this.active = true,
  });

  /// Plan enum value.
  final CoachSubscriptionPlan plan;

  /// Stable machine id.
  final String id;

  /// Human-readable plan name.
  final String title;

  /// Product description.
  final String description;

  /// Relative plan rank for future upgrade suggestions.
  final int rank;

  /// Whether this plan is available for entitlement evaluation.
  final bool active;
}
