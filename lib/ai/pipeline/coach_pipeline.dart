import 'package:gymaipro/ai/pipeline/coach_pipeline_context.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_result.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_stage.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_trace.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_validator.dart';

/// Orchestrates Coach v2 intelligence stages without embedding business rules.
class CoachPipeline {
  CoachPipeline({
    required Map<CoachPipelineStage, CoachPipelineStageRunner> runners,
    this.config = const CoachPipelineConfig(),
    this.validator = const CoachPipelineValidator(),
  }) : _runners = Map<CoachPipelineStage, CoachPipelineStageRunner>.unmodifiable(
         runners,
       );

  final Map<CoachPipelineStage, CoachPipelineStageRunner> _runners;
  final CoachPipelineConfig config;
  final CoachPipelineValidator validator;

  /// Executes configured stages in order and returns the final result.
  Future<CoachPipelineResult> run(CoachPipelineContext context) async {
    final inputValidation = validator.validateInput(context);
    if (!inputValidation.isValid) {
      return CoachPipelineResult(
        context: context,
        trace: CoachPipelineTrace(
          stages: const <CoachPipelineStageTrace>[],
          totalDuration: Duration.zero,
          success: false,
          mode: context.mode,
        ),
        success: false,
        mode: context.mode,
      );
    }

    final startedAt = DateTime.now();
    final traces = <CoachPipelineStageTrace>[];
    var current = context;
    var pipelineSuccess = true;

    for (final stage in config.executionOrder) {
      if (current.localSkillHandled &&
          CoachPipelineContext.stagesSkippedAfterLocalSkill.contains(stage)) {
        traces.add(
          CoachPipelineStageTrace(
            stage: stage,
            executionTime: Duration.zero,
            success: true,
            skipped: true,
            reason: 'Local skill response produced; stage skipped.',
          ),
        );
        continue;
      }

      if (!config.isEnabled(stage)) {
        traces.add(
          CoachPipelineStageTrace(
            stage: stage,
            executionTime: Duration.zero,
            success: true,
            skipped: true,
            reason: 'Stage disabled by pipeline configuration.',
          ),
        );
        continue;
      }

      final runner = _runners[stage];
      if (runner == null) {
        traces.add(
          CoachPipelineStageTrace(
            stage: stage,
            executionTime: Duration.zero,
            success: false,
            skipped: false,
            reason: 'No runner registered for stage.',
          ),
        );
        pipelineSuccess = false;
        break;
      }

      final stopwatch = Stopwatch()..start();
      try {
        final outcome = await runner.run(current);
        stopwatch.stop();
        current = outcome.context;
        traces.add(
          CoachPipelineStageTrace(
            stage: stage,
            executionTime: stopwatch.elapsed,
            success: outcome.success,
            skipped: outcome.skipped,
            confidence: outcome.confidence,
            reason: outcome.reason,
            metadata: outcome.metadata,
          ),
        );
        if (!outcome.success && !outcome.skipped) {
          pipelineSuccess = false;
          break;
        }
      } on Object catch (error) {
        stopwatch.stop();
        traces.add(
          CoachPipelineStageTrace(
            stage: stage,
            executionTime: stopwatch.elapsed,
            success: false,
            skipped: false,
            reason: error.toString(),
          ),
        );
        pipelineSuccess = false;
        break;
      }
    }

    final result = CoachPipelineResult(
      context: current,
      trace: CoachPipelineTrace(
        stages: List<CoachPipelineStageTrace>.unmodifiable(traces),
        totalDuration: DateTime.now().difference(startedAt),
        success: pipelineSuccess,
        mode: current.mode,
      ),
      success: pipelineSuccess,
      mode: current.mode,
    );

    return result;
  }
}
