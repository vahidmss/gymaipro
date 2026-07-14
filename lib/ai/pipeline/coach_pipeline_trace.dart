import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_stage.dart';

/// Trace entry for one pipeline stage execution.
class CoachPipelineStageTrace {
  const CoachPipelineStageTrace({
    required this.stage,
    required this.executionTime,
    required this.success,
    required this.skipped,
    this.confidence,
    this.reason,
    this.metadata = const <String, Object?>{},
  });

  /// Stage that was executed or skipped.
  final CoachPipelineStage stage;

  /// Wall-clock execution time for the stage.
  final Duration executionTime;

  /// Whether the stage completed successfully.
  final bool success;

  /// Whether the stage was skipped by configuration.
  final bool skipped;

  /// Optional confidence emitted by the stage.
  final double? confidence;

  /// Human-readable reason for skip, success, or failure.
  final String? reason;

  /// Structured stage metadata for diagnostics.
  final Map<String, Object?> metadata;
}

/// Full trace for one pipeline run.
class CoachPipelineTrace {
  const CoachPipelineTrace({
    required this.stages,
    required this.totalDuration,
    required this.success,
    this.mode = CoachPipelineMode.runtime,
  });

  /// Per-stage traces in execution order.
  final List<CoachPipelineStageTrace> stages;

  /// Total pipeline duration.
  final Duration totalDuration;

  /// Whether the pipeline completed without a failed stage.
  final bool success;

  /// Execution mode for this pipeline run.
  final CoachPipelineMode mode;

  /// Trace for [stage], if present.
  CoachPipelineStageTrace? traceFor(CoachPipelineStage stage) {
    for (final trace in stages) {
      if (trace.stage == stage) return trace;
    }
    return null;
  }
}
