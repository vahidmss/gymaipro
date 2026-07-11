/// Action requested by a coach response plan.
enum CoachAction {
  callOpenAI,
  localResponse,
  followUp,
  showProgram,
  showHeatmap,
  showProgress,
  showRecovery,
  showChat,
  error,
}

/// Stable external names for integration boundaries.
extension CoachActionWireName on CoachAction {
  /// Upper snake case action id requested by product architecture.
  String get wireName {
    switch (this) {
      case CoachAction.callOpenAI:
        return 'CALL_OPENAI';
      case CoachAction.localResponse:
        return 'LOCAL_RESPONSE';
      case CoachAction.followUp:
        return 'FOLLOW_UP';
      case CoachAction.showProgram:
        return 'SHOW_PROGRAM';
      case CoachAction.showHeatmap:
        return 'SHOW_HEATMAP';
      case CoachAction.showProgress:
        return 'SHOW_PROGRESS';
      case CoachAction.showRecovery:
        return 'SHOW_RECOVERY';
      case CoachAction.showChat:
        return 'SHOW_CHAT';
      case CoachAction.error:
        return 'ERROR';
    }
  }
}
