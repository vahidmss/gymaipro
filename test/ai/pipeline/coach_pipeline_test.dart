import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_context.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_stage.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_execution_result.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';

void main() {
  group('CoachPipeline', () {
    test('default order runs entitlement between skill and decision', () {
      expect(
        CoachPipelineConfig.defaultExecutionOrder,
        containsAllInOrder(<CoachPipelineStage>[
          CoachPipelineStage.knowledge,
          CoachPipelineStage.skill,
          CoachPipelineStage.entitlement,
          CoachPipelineStage.decision,
        ]),
      );
    });

    test('executes stages in configured order', () async {
      final order = <CoachPipelineStage>[];
      final pipeline = CoachPipeline(
        runners: {
          CoachPipelineStage.entity: _RecordingRunner(
            stage: CoachPipelineStage.entity,
            order: order,
          ),
          CoachPipelineStage.intent: _RecordingRunner(
            stage: CoachPipelineStage.intent,
            order: order,
          ),
          CoachPipelineStage.decision: _RecordingRunner(
            stage: CoachPipelineStage.decision,
            order: order,
          ),
        },
        config: const CoachPipelineConfig(
          executionOrder: <CoachPipelineStage>[
            CoachPipelineStage.entity,
            CoachPipelineStage.intent,
            CoachPipelineStage.decision,
          ],
        ),
      );

      final result = await pipeline.run(
        CoachPipelineContext.initial(
          userId: 'user_1',
          userMessage: 'hello',
        ),
      );

      expect(result.success, isTrue);
      expect(
        order,
        <CoachPipelineStage>[
          CoachPipelineStage.entity,
          CoachPipelineStage.intent,
          CoachPipelineStage.decision,
        ],
      );
    });

    test('records skipped stages in trace', () async {
      final pipeline = CoachPipeline(
        runners: {
          CoachPipelineStage.entity: _RecordingRunner(
            stage: CoachPipelineStage.entity,
            order: <CoachPipelineStage>[],
          ),
        },
        config: const CoachPipelineConfig(
          executionOrder: <CoachPipelineStage>[
            CoachPipelineStage.entity,
            CoachPipelineStage.memory,
          ],
          disabledStages: <CoachPipelineStage>{CoachPipelineStage.memory},
        ),
      );

      final result = await pipeline.run(
        CoachPipelineContext.initial(
          userId: 'user_1',
          userMessage: 'hello',
        ),
      );

      expect(result.success, isTrue);
      final memoryTrace = result.trace.traceFor(CoachPipelineStage.memory);
      expect(memoryTrace, isNotNull);
      expect(memoryTrace!.skipped, isTrue);
      expect(memoryTrace.success, isTrue);
      expect(memoryTrace.reason, contains('disabled'));
    });

    test('stops pipeline when a stage fails', () async {
      final order = <CoachPipelineStage>[];
      final pipeline = CoachPipeline(
        runners: {
          CoachPipelineStage.entity: _RecordingRunner(
            stage: CoachPipelineStage.entity,
            order: order,
          ),
          CoachPipelineStage.intent: const _FailingRunner(
            stage: CoachPipelineStage.intent,
          ),
          CoachPipelineStage.decision: _RecordingRunner(
            stage: CoachPipelineStage.decision,
            order: order,
          ),
        },
        config: const CoachPipelineConfig(
          executionOrder: <CoachPipelineStage>[
            CoachPipelineStage.entity,
            CoachPipelineStage.intent,
            CoachPipelineStage.decision,
          ],
        ),
      );

      final result = await pipeline.run(
        CoachPipelineContext.initial(
          userId: 'user_1',
          userMessage: 'hello',
        ),
      );

      expect(result.success, isFalse);
      expect(result.trace.success, isFalse);
      expect(order, <CoachPipelineStage>[CoachPipelineStage.entity]);
      final intentTrace = result.trace.traceFor(CoachPipelineStage.intent);
      expect(intentTrace, isNotNull);
      expect(intentTrace!.success, isFalse);
      expect(intentTrace.skipped, isFalse);
      expect(result.trace.traceFor(CoachPipelineStage.decision), isNull);
    });

    test('generates trace with execution time and confidence', () async {
      final pipeline = CoachPipeline(
        runners: {
          CoachPipelineStage.entity: _RecordingRunner(
            stage: CoachPipelineStage.entity,
            order: <CoachPipelineStage>[],
            confidence: 0.92,
            reason: 'entity ok',
          ),
        },
        config: const CoachPipelineConfig(
          executionOrder: <CoachPipelineStage>[CoachPipelineStage.entity],
        ),
      );

      final result = await pipeline.run(
        CoachPipelineContext.initial(
          userId: 'user_1',
          userMessage: 'hello',
        ),
      );

      expect(result.success, isTrue);
      expect(result.trace.stages, hasLength(1));
      final trace = result.trace.stages.first;
      expect(trace.stage, CoachPipelineStage.entity);
      expect(trace.success, isTrue);
      expect(trace.skipped, isFalse);
      expect(trace.confidence, 0.92);
      expect(trace.reason, 'entity ok');
      expect(trace.executionTime, isNot(Duration.zero));
      expect(result.trace.totalDuration, isNot(Duration.zero));
    });

    test('fails fast on invalid input without running stages', () async {
      final order = <CoachPipelineStage>[];
      final pipeline = CoachPipeline(
        runners: {
          CoachPipelineStage.entity: _RecordingRunner(
            stage: CoachPipelineStage.entity,
            order: order,
          ),
        },
      );

      final result = await pipeline.run(
        CoachPipelineContext.initial(
          userId: '',
          userMessage: 'hello',
        ),
      );

      expect(result.success, isFalse);
      expect(result.trace.stages, isEmpty);
      expect(order, isEmpty);
    });

    test('skips AI stages after local skill runtime response', () async {
      final order = <CoachPipelineStage>[];
      final pipeline = CoachPipeline(
        runners: {
          CoachPipelineStage.skill: _LocalSkillRunner(order: order),
          CoachPipelineStage.decision: _RecordingRunner(
            stage: CoachPipelineStage.decision,
            order: order,
          ),
          CoachPipelineStage.prompt: _RecordingRunner(
            stage: CoachPipelineStage.prompt,
            order: order,
          ),
        },
        config: const CoachPipelineConfig(
          executionOrder: <CoachPipelineStage>[
            CoachPipelineStage.skill,
            CoachPipelineStage.decision,
            CoachPipelineStage.prompt,
          ],
        ),
      );

      final result = await pipeline.run(
        CoachPipelineContext.initial(
          userId: 'user_1',
          userMessage: 'motivation please',
        ),
      );

      expect(result.success, isTrue);
      expect(result.context.localSkillHandled, isTrue);
      expect(order, <CoachPipelineStage>[CoachPipelineStage.skill]);
      final decisionTrace = result.trace.traceFor(CoachPipelineStage.decision);
      expect(decisionTrace, isNotNull);
      expect(decisionTrace!.skipped, isTrue);
      expect(decisionTrace.reason, contains('Local skill'));
    });
  });
}

class _RecordingRunner extends CoachPipelineStageRunner {
  _RecordingRunner({
    required this.stage,
    required this.order,
    this.confidence,
    this.reason = 'ok',
  });

  @override
  final CoachPipelineStage stage;

  final List<CoachPipelineStage> order;
  final double? confidence;
  final String reason;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    order.add(stage);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return CoachPipelineStageOutcome(
      context: context,
      success: true,
      confidence: confidence,
      reason: reason,
    );
  }
}

class _FailingRunner extends CoachPipelineStageRunner {
  const _FailingRunner({required this.stage});

  @override
  final CoachPipelineStage stage;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    return CoachPipelineStageOutcome(
      context: context,
      success: false,
      reason: 'stage failed',
    );
  }
}

class _LocalSkillRunner extends CoachPipelineStageRunner {
  const _LocalSkillRunner({required this.order});

  final List<CoachPipelineStage> order;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.skill;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    order.add(stage);
    const execution = CoachSkillExecutionResult(
      skillId: 'motivation_skill',
      response: CoachSkillResponse(
        message: 'ادامه بده',
        confidence: 0.9,
        requiresAI: false,
      ),
      executionTime: Duration(milliseconds: 2),
      success: true,
    );
    return CoachPipelineStageOutcome(
      context: context.copyWith(skillExecutionResult: execution),
      success: true,
      confidence: 0.9,
      reason: 'Executed motivation_skill locally. requiresAI=false',
    );
  }
}
