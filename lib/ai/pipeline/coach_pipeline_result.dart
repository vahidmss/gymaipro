import 'package:gymaipro/ai/pipeline/coach_pipeline.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_context.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_trace.dart';

/// Final result returned by [CoachPipeline].
class CoachPipelineResult {
  const CoachPipelineResult({
    required this.context,
    required this.trace,
    required this.success,
    this.mode = CoachPipelineMode.runtime,
  });

  /// Final mutable context snapshot.
  final CoachPipelineContext context;

  /// Execution trace for all stages.
  final CoachPipelineTrace trace;

  /// Whether the pipeline completed successfully.
  final bool success;

  /// Execution mode for this pipeline run.
  final CoachPipelineMode mode;
}
