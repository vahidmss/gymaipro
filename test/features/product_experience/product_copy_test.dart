import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_execution_result.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

void main() {
  test('recoverySnapshot derives readiness from preferences and heatmap', () {
    final context = CoachContext(
      intent: AIIntent.workoutToday,
      profile: const <String, Object?>{'first_name': 'وحید'},
      preferences: const <String, Object?>{
        'recovery_score': 82,
        'bb_sleep_hours': 7.5,
      },
      metadata: CoachContextMetadata(
        buildTime: DateTime(2026, 7, 13),
        sourceCount: 2,
        missingProviders: const {},
        confidence: 0.9,
        contextVersion: CoachContext.contextVersion,
      ),
    );

    final snapshot = ProductExperienceFormatter.recoverySnapshot(context: context);

    expect(snapshot.recovery, 82);
    expect(snapshot.readiness, greaterThan(0));
  });

  test('coachBrief composes narrative from integration bundle', () {
    const recovery = CoachRecoverySnapshot(
      recovery: 85,
      fatigue: 20,
      sleep: 80,
      readiness: 78,
    );
    final result = CoachIntegrationResult.local(
      intent: AIIntent.workoutToday,
      coachContext: CoachContext(
        intent: AIIntent.workoutToday,
        goals: const <String>['عضله‌سازی'],
        metadata: CoachContextMetadata(
          buildTime: DateTime(2026, 7, 13),
          sourceCount: 1,
          missingProviders: const {},
          confidence: 0.9,
          contextVersion: CoachContext.contextVersion,
        ),
      ),
      skillExecution: const CoachSkillExecutionResult(
        skillId: 'workout_today_skill',
        response: CoachSkillResponse(
          confidence: 0.9,
          requiresAI: false,
          message: 'تمرکز امروز روی سینه است.',
        ),
        executionTime: Duration(milliseconds: 1),
        success: true,
      ),
      processingTime: const Duration(milliseconds: 1),
      logs: const [],
      pipelineMode: CoachPipelineMode.preview,
    );

    final brief = ProductExperienceFormatter.coachBrief(
      context: result.coachContext,
      result: result,
      recovery: recovery,
      workout: null,
      memories: const <String>['یادم هست گفتی زانوت اذیت می‌شود.'],
      insights: const <String>['این هفته عضلات پشت کمتر تمرین داده شده‌اند.'],
    );

    expect(brief, contains('ریکاوری خوبی'));
    expect(brief, contains('زانوت'));
  });

  test('humanizeReason strips technical tokens', () {
    expect(
      ProductExperienceFormatter.humanizeReason('knowledge_node:selected_workout'),
      isEmpty,
    );
    expect(
      ProductExperienceFormatter.humanizeReason(
        'intent matched workoutToday with score 0.54',
      ),
      isEmpty,
    );

    expect(
      ProductExperienceFormatter.humanizeReason('Recovery پایین بود.'),
      'چون ریکاوری کامل نبود، تمرین سبک‌تر پیشنهاد شد.',
    );
  });

  test('localizeCardTitle maps English card titles', () {
    expect(ProductExperienceFormatter.localizeCardTitle('Reasons'), 'دلایل');
    expect(
      ProductExperienceFormatter.localizeCardTitle('Coach Notes'),
      ProductCopy.coachNotes,
    );
  });

  test('localizePrimaryAction maps session CTA labels', () {
    expect(
      ProductExperienceFormatter.localizePrimaryAction('Complete Set'),
      'تکمیل ست',
    );
    expect(
      ProductExperienceFormatter.localizePrimaryAction('Finish Workout'),
      'پایان تمرین',
    );
  });
}
