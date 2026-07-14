import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/skills/coach_skill_registry.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_data_validator.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_reason_type.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_response_builder.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

void main() {
  final metadata = CoachContextMetadata(
    buildTime: DateTime(2026, 7, 12),
    sourceCount: 4,
    missingProviders: const {},
    confidence: 0.8,
    contextVersion: CoachContext.contextVersion,
  );

  CoachContext richContext({
    AIIntent intent = AIIntent.workoutToday,
    String question = 'امروز چی تمرین کنم؟',
  }) {
    return CoachContext(
      intent: intent,
      metadata: metadata,
      goals: const <String>['عضله‌سازی'],
      equipment: const <String>['دمبل', 'بارفیکس'],
      restrictions: const <String>['درد شانه'],
      activeProgram: const <String, Object?>{
        'active_program_id': 'program_1',
        'name': 'برنامه قدرتی',
      },
      workoutHistory: <WorkoutDailyLog>[
        WorkoutDailyLog(
          userId: 'user_1',
          logDate: DateTime(2026, 7, 7),
          sessions: const <WorkoutSessionLog>[],
        ),
      ],
      weeklyHeatmap: const WeeklyMuscleHeatmapResult(
        targets: <String, int>{
          'chest_middle': 40,
          'quads': 8,
          'back_lat': 12,
        },
        previousWeekTargets: <String, int>{'chest_middle': 30},
        workoutDays: 3,
        sessionCount: 4,
        previousSessionCount: 3,
        hasHeatmapData: true,
        hasPreviousWeekData: true,
        balanceLine: 'بیشترین: سینه میانی · کم‌رنگ: چهارسر ران',
        weekTrendLine: 'فعال‌تر از هفته قبل',
      ),
      preferences: const <String, Object?>{'bb_sleep_hours': 7},
      apiUsage: const <String, Object?>{
        'ai_chat': <String, Object?>{
          'daily_used': 2,
          'daily_limit': 10,
          'daily_remaining': 8,
        },
        'progress_analysis': <String, Object?>{
          'free_used': 1,
          'free_limit': 3,
          'free_remaining': 2,
        },
      },
      currentQuestion: question,
    );
  }

  group('SkillDataValidator', () {
    const validator = SkillDataValidator();

    test('workout today confidence increases with richer context', () {
      final sparse = CoachContext(
        intent: AIIntent.workoutToday,
        metadata: metadata,
        activeProgram: const <String, Object?>{'active_program_id': 'p1'},
      );
      final rich = richContext();

      final sparseCoverage = validator.workoutToday(sparse);
      final richCoverage = validator.workoutToday(rich);

      expect(richCoverage.confidence, greaterThan(sparseCoverage.confidence));
      expect(richCoverage.requiresAI, isFalse);
    });

    test('requests AI when coverage is below threshold', () {
      const validator = SkillDataValidator();
      final empty = CoachContext.empty(intent: AIIntent.workoutToday);
      final coverage = validator.workoutToday(empty);
      expect(coverage.requiresAI, isTrue);
    });
  });

  group('WorkoutTodaySkill intelligence', () {
    const builder = SkillResponseBuilder();

    test('returns focus, reasons, recommendations, and dynamic confidence', () {
      final response = builder.buildWorkoutToday(richContext());

      expect(response.requiresAI, isFalse);
      expect(response.message, contains('تمرکز امروز'));
      expect(response.structuredData['todaysFocus'], isNotNull);
      expect(response.structuredData['priority'], isNotNull);
      expect(response.reasons, isNotEmpty);
      expect(response.explanation, isNotNull);
      expect(response.recommendations, isNotEmpty);
      expect(response.confidence, greaterThan(0.55));
      expect(
        response.reasons.any(
          (reason) => reason.type == SkillReasonType.goalAlignment,
        ),
        isTrue,
      );
    });

    test('execute delegates to intelligent builder', () {
      const skill = WorkoutTodaySkill();
      final response = skill.execute(
        context: richContext(),
        intent: AIIntent.workoutToday,
      );

      expect(response.handledLocally, isTrue);
      expect(response.reasons, isNotEmpty);
    });
  });

  group('HeatmapSkill intelligence', () {
    const builder = SkillResponseBuilder();

    test('analyzes most and least trained muscles with explainability', () {
      final response = builder.buildHeatmap(richContext(intent: AIIntent.recovery));

      expect(response.requiresAI, isFalse);
      expect(response.message, contains('بیشترین تمرین'));
      expect(response.message, contains('کمترین تمرین'));
      expect(response.structuredData['imbalanceDetected'], isTrue);
      expect(response.explanation!.bullets, isNotEmpty);
      expect(response.recommendations.first.priority, 1);
    });

    test('falls back to AI without heatmap data', () {
      final response = builder.buildHeatmap(
        CoachContext(
          intent: AIIntent.recovery,
          metadata: metadata,
          currentQuestion: 'هیت‌مپ',
        ),
      );

      expect(response.requiresAI, isTrue);
      expect(response.message, isNull);
    });
  });

  group('MotivationSkill intelligence', () {
    const builder = SkillResponseBuilder();

    test('personalizes message from goal and progress trend', () {
      final response = builder.buildMotivation(
        richContext(
          intent: AIIntent.motivation,
          question: 'انگیزه ندارم و خسته‌ام',
        ),
      );

      expect(response.requiresAI, isFalse);
      expect(response.message, isNot(contains('ادامه بده — هر قدم کوچک')));
      expect(response.message!, contains('عضله‌سازی'));
      expect(response.structuredData['tone'], 'supportive');
      expect(response.reasons, isNotEmpty);
    });
  });

  group('AppHelpSkill intelligence', () {
    const builder = SkillResponseBuilder();

    test('uses api usage and program state for help response', () {
      final response = builder.buildAppHelp(
        context: richContext(
          intent: AIIntent.appHelp,
          question: 'سهمیه چت من چقدره؟',
        ),
        intent: AIIntent.appHelp,
      );

      expect(response.requiresAI, isFalse);
      expect(response.message, contains('2/10'));
      expect(
        response.reasons.any(
          (reason) => reason.type == SkillReasonType.usageLimit,
        ),
        isTrue,
      );
      expect(response.nextActions, isNotEmpty);
    });

    test('escalates bug reports to AI', () {
      final response = builder.buildAppHelp(
        context: richContext(
          intent: AIIntent.bugReport,
          question: 'باگ دارم',
        ),
        intent: AIIntent.bugReport,
      );

      expect(response.requiresAI, isTrue);
    });
  });
}
