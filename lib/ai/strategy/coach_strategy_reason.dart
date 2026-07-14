/// Reasons explaining how a coach strategy was derived.
enum CoachStrategyReason {
  decisionRequiresAi,
  decisionRequiresFollowUp,
  decisionLocalResponse,
  knowledgeRequiresAi,
  knowledgeDefaultAction,
  knowledgeMissingBehaviour,
  sufficientContext,
  insufficientContext,
  medicalSafety,
  providerMissing,
  localRoutePreferred,
  validationBlocked,
  lowConfidenceContext,
  intentAligned,
  contextMetadataWeak,
}
