import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/skills/coach_skill_engine.dart';
import 'package:gymaipro/ai/skills/coach_skill_registry.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_executor.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_renderer.dart';
import 'package:gymaipro/ai/skills/skill_result.dart';

void main() {
  group('CoachSkillRenderer', () {
    test('renders motivation locally from current question', () {
      const renderer = CoachSkillRenderer();
      final context = CoachContext(
        intent: AIIntent.motivation,
        metadata: CoachContextMetadata(
          buildTime: DateTime(2026),
          sourceCount: 1,
          missingProviders: const {},
          confidence: 0.8,
          contextVersion: CoachContext.contextVersion,
        ),
        goals: const <String>['عضله‌سازی'],
        currentQuestion: 'انگیزه ندارم',
      );

      final response = renderer.renderMotivation(context);

      expect(response.requiresAI, isFalse);
      expect(response.message, isNotNull);
      expect(response.reasons, isNotEmpty);
    });

    test('requests AI fallback when workout context is missing', () {
      const renderer = CoachSkillRenderer();
      final context = CoachContext.empty(intent: AIIntent.workoutToday);

      final response = renderer.renderWorkoutToday(context);

      expect(response.requiresAI, isTrue);
      expect(response.message, isNull);
    });
  });

  group('CoachSkillExecutor', () {
    test('returns null when coach v2 flag is disabled', () {
      if (CoachV2Config.coachV2Enabled) {
        return;
      }

      const executor = CoachSkillExecutor();
      const skill = MotivationSkill();
      final context = CoachContext(
        intent: AIIntent.motivation,
        metadata: CoachContextMetadata(
          buildTime: DateTime(2026),
          sourceCount: 1,
          missingProviders: const {},
          confidence: 0.8,
          contextVersion: CoachContext.contextVersion,
        ),
        goals: const <String>['استقامت'],
        currentQuestion: 'انگیزه بده',
      );
      final skillResult = SkillResult(
        intent: AIIntent.motivation,
        candidates: const <SkillCandidate>[],
        selectedSkill: SkillCandidate(
          skill: skill,
          evaluation: skill.evaluate(context: context, intent: AIIntent.motivation),
        ),
        shouldInvokeAI: false,
      );

      final result = executor.execute(
        context: context,
        intent: AIIntent.motivation,
        skillResult: skillResult,
      );

      expect(result, isNull);
    });

    test('executes motivation skill when coach v2 flag is enabled', () {
      if (!CoachV2Config.coachV2Enabled) {
        return;
      }

      const executor = CoachSkillExecutor();
      const skill = MotivationSkill();
      final context = CoachContext(
        intent: AIIntent.motivation,
        metadata: CoachContextMetadata(
          buildTime: DateTime(2026),
          sourceCount: 1,
          missingProviders: const {},
          confidence: 0.8,
          contextVersion: CoachContext.contextVersion,
        ),
        goals: const <String>['استقامت'],
        currentQuestion: 'انگیزه بده',
      );
      final skillResult = SkillResult(
        intent: AIIntent.motivation,
        candidates: const <SkillCandidate>[],
        selectedSkill: SkillCandidate(
          skill: skill,
          evaluation: skill.evaluate(context: context, intent: AIIntent.motivation),
        ),
        shouldInvokeAI: false,
      );

      final result = executor.execute(
        context: context,
        intent: AIIntent.motivation,
        skillResult: skillResult,
      );

      expect(result, isNotNull);
      expect(result!.handledLocally, isTrue);
      expect(result.response.requiresAI, isFalse);
    });
  });

  group('MotivationSkill runtime', () {
    test('execute returns local response for valid context', () {
      const skill = MotivationSkill();
      final context = CoachContext(
        intent: AIIntent.motivation,
        metadata: CoachContextMetadata(
          buildTime: DateTime(2026),
          sourceCount: 1,
          missingProviders: const {},
          confidence: 0.8,
          contextVersion: CoachContext.contextVersion,
        ),
        goals: const <String>['استقامت'],
        currentQuestion: 'حالم خوب نیست',
      );

      final response = skill.execute(context: context, intent: AIIntent.motivation);

      expect(response.handledLocally, isTrue);
      expect(response.requiresAI, isFalse);
    });
  });

  group('CoachSkillEngine AI fallback', () {
    test('requests AI when no skill meets confidence threshold', () {
      final engine = CoachSkillEngine(localConfidenceThreshold: 0.99);
      final context = CoachContext(
        intent: AIIntent.motivation,
        metadata: CoachContextMetadata(
          buildTime: DateTime(2026),
          sourceCount: 1,
          missingProviders: const {},
          confidence: 0.8,
          contextVersion: CoachContext.contextVersion,
        ),
        currentQuestion: 'انگیزه',
      );

      final result = engine.evaluate(
        context: context,
        intent: AIIntent.motivation,
      );

      expect(result.shouldInvokeAI, isTrue);
    });
  });
}
