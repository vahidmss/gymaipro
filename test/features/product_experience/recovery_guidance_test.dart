import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';

void main() {
  group('RecoveryGuidance scenarios', () {
    test('after completing today session: recovery focus, no lighter CTA', () {
      // Low readiness after finish is expected — must NOT say "train lighter today".
      final guidance = RecoveryGuidance.fromSnapshot(
        const CoachRecoverySnapshot(
          recovery: 35,
          fatigue: 72,
          sleep: 60,
          readiness: 32,
        ),
        daysSinceLastWorkout: 0,
      );

      expect(guidance.scenario, RecoveryScenario.postSessionToday);
      expect(guidance.suggestLighterSession, isFalse);
      expect(guidance.suggestStartWorkout, isFalse);
      expect(guidance.headline, contains('ریکاوری'));
      expect(guidance.body, contains('انجام شده'));
      expect(guidance.body, isNot(contains('سبک‌تر بزنی')));
      expect(guidance.body, isNot(contains('حجم را کم کنی')));
      expect(guidance.chatMessage, contains('خواب'));
      expect(
        guidance.tips.any((t) => t.contains('خواب') || t.contains('پروتئین')),
        isTrue,
      );
    });

    test('high readiness before training: ready to train', () {
      final guidance = RecoveryGuidance.fromSnapshot(
        const CoachRecoverySnapshot(
          recovery: 80,
          fatigue: 25,
          sleep: 75,
          readiness: 82,
        ),
        daysSinceLastWorkout: 2,
      );

      expect(guidance.scenario, RecoveryScenario.readyToTrain);
      expect(guidance.suggestStartWorkout, isTrue);
      expect(guidance.suggestLighterSession, isFalse);
      expect(guidance.headline, contains('خوبه'));
      expect(guidance.body, contains('شدت برنامه‌ریزی‌شده'));
    });

    test('mid readiness before training: train cautiously', () {
      final guidance = RecoveryGuidance.fromSnapshot(
        const CoachRecoverySnapshot(
          recovery: 55,
          fatigue: 45,
          sleep: 60,
          readiness: 52,
        ),
        daysSinceLastWorkout: 1,
      );

      expect(guidance.scenario, RecoveryScenario.trainCautiously);
      expect(guidance.suggestStartWorkout, isTrue);
      expect(guidance.suggestLighterSession, isFalse);
      expect(guidance.body, contains('گرم'));
    });

    test('mid readiness + high fatigue before training: lighter session', () {
      final guidance = RecoveryGuidance.fromSnapshot(
        const CoachRecoverySnapshot(
          recovery: 50,
          fatigue: 70,
          sleep: 55,
          readiness: 48,
        ),
        daysSinceLastWorkout: 1,
      );

      expect(guidance.scenario, RecoveryScenario.needsRestOrLighter);
      expect(guidance.suggestLighterSession, isTrue);
      expect(guidance.suggestStartWorkout, isFalse);
      expect(guidance.body, contains('شروع نکرده‌ای'));
    });

    test('low readiness before any session today: lighter advice ok', () {
      final guidance = RecoveryGuidance.fromSnapshot(
        const CoachRecoverySnapshot(
          recovery: 30,
          fatigue: 70,
          sleep: 40,
          readiness: 28,
        ),
        daysSinceLastWorkout: 1,
      );

      expect(guidance.scenario, RecoveryScenario.needsRestOrLighter);
      expect(guidance.suggestLighterSession, isTrue);
      expect(guidance.body, contains('کم کنی'));
    });

    test('long break: returning scenario, ease back in', () {
      final guidance = RecoveryGuidance.fromSnapshot(
        const CoachRecoverySnapshot(
          recovery: 70,
          fatigue: 30,
          sleep: 70,
          readiness: 75,
        ),
        daysSinceLastWorkout: 5,
      );

      expect(guidance.scenario, RecoveryScenario.returningAfterBreak);
      expect(guidance.suggestStartWorkout, isTrue);
      expect(guidance.suggestLighterSession, isFalse);
      expect(guidance.headline, contains('فاصله'));
      expect(guidance.body, contains('متوسط'));
    });

    test('unknown readiness without history', () {
      final guidance = RecoveryGuidance.fromSnapshot(
        const CoachRecoverySnapshot(
          recovery: 0,
          fatigue: 0,
          sleep: 0,
          readiness: 0,
        ),
      );

      expect(guidance.scenario, RecoveryScenario.unknown);
      expect(guidance.suggestLighterSession, isFalse);
      expect(guidance.suggestStartWorkout, isFalse);
      expect(guidance.tips, isNotEmpty);
    });

    test('trained today even with high readiness stays post-session', () {
      // Edge: score restored somehow same day — still do not push another hard session.
      final guidance = RecoveryGuidance.fromSnapshot(
        const CoachRecoverySnapshot(
          recovery: 70,
          fatigue: 40,
          sleep: 80,
          readiness: 75,
        ),
        daysSinceLastWorkout: 0,
      );

      expect(guidance.scenario, RecoveryScenario.postSessionToday);
      expect(guidance.suggestStartWorkout, isFalse);
      expect(guidance.suggestLighterSession, isFalse);
    });

    test('readinessHint after today session is recovery-focused', () {
      final hint = ProductExperienceFormatter.readinessHint(
        const CoachRecoverySnapshot(
          recovery: 35,
          fatigue: 70,
          sleep: 50,
          readiness: 30,
          daysSinceLastWorkout: 0,
        ),
      );
      expect(hint, isNotNull);
      expect(hint, contains('ریکاوری'));
      expect(hint, isNot(contains('سبک‌تر')));
      expect(hint, isNot(contains('محافظه‌کار')));
    });
  });
}
