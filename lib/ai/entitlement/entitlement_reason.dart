/// Reasons explaining an entitlement decision.
enum EntitlementReason {
  capabilityGrantedByPlan,
  capabilityGrantedByTrial,
  capabilityGrantedByTemporaryUnlock,
  capabilityGrantedByGift,
  capabilityGrantedByPromoCode,
  capabilityGrantedByEnterprisePolicy,
  capabilityGrantedByLifetimePlan,
  missingCapability,
  trialExpired,
  dailyLimitReached,
  monthlyLimitReached,
  tokenLimitReached,
  skillLimitReached,
  planInactive,
  featureDisabled,
  validationFailed,
}
