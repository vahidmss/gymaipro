import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/coach_engine_facts.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';

void main() {
  test('CoachEngineFacts cites profile weight and nutrition targets', () {
    final context = CoachContext(
      intent: AIIntent.nutrition,
      metadata: CoachContextMetadata(
        buildTime: DateTime(2026, 8, 11),
        sourceCount: 2,
        missingProviders: const {},
        confidence: 0.9,
        contextVersion: CoachContext.contextVersion,
      ),
      profile: const <String, Object?>{
        'height': 178,
        'latest_recorded_weight_kg': 92,
        'bmi': 29.0,
        'current_streak_days': 4,
      },
      nutrition: const <String, Object?>{
        'daily_targets': <String, Object?>{
          'calories_kcal': 2200,
          'protein_g': 160,
          'maintenance_kcal': 2400,
          'has_active_goal': true,
        },
        'today': <String, Object?>{
          'logged': true,
          'consumed': <String, Object?>{
            'calories_kcal': 900,
            'protein_g': 55,
          },
        },
      },
      activeProgram: const <String, Object?>{
        'program_name': 'فول‌بادی مبتدی',
        'selected_session_day': 'روز ۱ — فول‌بادی',
        'today_session': <String, Object?>{'exercise_count': 8},
      },
      weeklyHeatmap: const WeeklyMuscleHeatmapResult(
        targets: <String, int>{'chest': 80, 'back': 40},
        previousWeekTargets: <String, int>{},
        workoutDays: 3,
        sessionCount: 3,
        previousSessionCount: 2,
        hasHeatmapData: true,
        hasPreviousWeekData: false,
        balanceLine: 'بالا‌تنه جلو نسبت به پشت قوی‌تر کار شده.',
      ),
    );

    final facts = CoachEngineFacts.build(context);
    expect(facts, isNotNull);
    final list = facts!['use_these_facts_in_answers'] as List<Object?>;
    final text = list.join(' | ');

    expect(text, contains('178'));
    expect(text, contains('92'));
    expect(text, contains('2200'));
    expect(text, contains('900'));
    expect(text, contains('فول‌بادی مبتدی'));
    expect(text, contains('استریک'));
    expect(text, contains('بالا‌تنه'));
  });

  test('CoachEngineFacts returns null when context is empty', () {
    final context = CoachContext.empty(intent: AIIntent.generalChat);
    expect(CoachEngineFacts.build(context), isNull);
  });
}
