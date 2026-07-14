import 'package:gymaipro/ai/config/coach_v2_config.dart';

/// Execution mode for [CoachPipeline] runs.
enum CoachPipelineMode {
  /// Full chat runtime with persistence and side effects.
  runtime,

  /// Dry-run preview: same stages, no writes or usage consumption.
  preview,
}

/// Whether Coach v2 intelligence stages should execute for [mode].
bool coachPipelineV2Active(CoachPipelineMode mode) {
  return CoachV2Config.coachV2Enabled || mode == CoachPipelineMode.preview;
}

/// Extension helpers for pipeline mode checks.
extension CoachPipelineModeContext on CoachPipelineMode {
  /// Whether this mode is a dry-run preview.
  bool get isPreview => this == CoachPipelineMode.preview;

  /// Whether this mode is the live runtime path.
  bool get isRuntime => this == CoachPipelineMode.runtime;
}
