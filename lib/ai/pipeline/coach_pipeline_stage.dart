/// Ordered stages executed by the unified Coach v2 decision pipeline.
enum CoachPipelineStage {
  entity,
  intent,
  state,
  memory,
  knowledge,
  skill,
  entitlement,
  strategy,
  context,
  decision,
  stateFinalize,
  promptPlanning,
  prompt,
  execution,
}

/// Runtime configuration for enabling or disabling pipeline stages.
///
/// Disabled stages are recorded in the trace as skipped without changing legacy
/// runtime outcomes.
class CoachPipelineConfig {
  const CoachPipelineConfig({
    this.disabledStages = const <CoachPipelineStage>{},
    this.executionOrder = CoachPipelineConfig.defaultExecutionOrder,
  });

  /// Default execution order for Coach v2 runtime.
  ///
  /// Entitlement runs after skill and before decision so [CoachBrain] can
  /// apply entitlement blocks. Strategy runs after decision because
  /// [CoachStrategyEngine] requires a [CoachDecision]. Entitlement does not
  /// read strategy output to avoid forward dependencies.
  static const List<CoachPipelineStage> defaultExecutionOrder =
      <CoachPipelineStage>[
        CoachPipelineStage.entity,
        CoachPipelineStage.intent,
        CoachPipelineStage.state,
        CoachPipelineStage.memory,
        CoachPipelineStage.context,
        CoachPipelineStage.knowledge,
        CoachPipelineStage.skill,
        CoachPipelineStage.entitlement,
        CoachPipelineStage.decision,
        CoachPipelineStage.strategy,
        CoachPipelineStage.stateFinalize,
        CoachPipelineStage.promptPlanning,
        CoachPipelineStage.prompt,
        CoachPipelineStage.execution,
      ];

  /// Stages that should be skipped for this run.
  final Set<CoachPipelineStage> disabledStages;

  /// Stage execution order for this run.
  final List<CoachPipelineStage> executionOrder;

  /// Whether [stage] is enabled.
  bool isEnabled(CoachPipelineStage stage) => !disabledStages.contains(stage);
}
