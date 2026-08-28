import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/features/product_experience/calendar_day.dart';
import 'package:gymaipro/features/product_experience/recovery/last_night_sleep.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LastNightSleep', () {
    test('snaps to half-hour steps inside 3–10', () {
      expect(LastNightSleep.snap(4.24), 4.0);
      expect(LastNightSleep.snap(4.26), 4.5);
      expect(LastNightSleep.snap(2), 3);
      expect(LastNightSleep.snap(12), 10);
    });

    test('scores hours against an 8-hour night', () {
      expect(LastNightSleep.scoreFromHours(4), 50);
      expect(LastNightSleep.scoreFromHours(8), 100);
      expect(LastNightSleep.scoreFromHours(10), 100);
    });

    test('short nights raise fatigue and long nights ease it', () {
      expect(LastNightSleep.fatigueAdjustment(5), 15);
      expect(LastNightSleep.fatigueAdjustment(7.5), 0);
      expect(LastNightSleep.fatigueAdjustment(9), -9);
    });
  });

  group('LastNightSleepStore', () {
    test('returns null until today is logged', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = LastNightSleepStore(
        clock: () => DateTime(2026, 8, 13, 9),
      );

      expect(await store.readToday('u1'), isNull);

      final saved = await store.save(userId: 'u1', hours: 6.2);
      expect(saved.hours, 6.0);
      expect(saved.dateKey, '2026-08-13');

      final loaded = await store.readToday('u1');
      expect(loaded?.hours, 6.0);
      expect(loaded?.dateKey, CalendarDay.dateKey(DateTime(2026, 8, 13)));
    });

    test('yesterday’s log does not count as today', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LastNightSleepStore.hoursKey('u1'): 8.0,
        LastNightSleepStore.dateKey('u1'): '2026-08-12',
      });
      final store = LastNightSleepStore(
        clock: () => DateTime(2026, 8, 13, 8),
      );

      expect(await store.readToday('u1'), isNull);
    });

    test('applyToContext overlays last-night hours onto preferences', () {
      final context = CoachContext(
        intent: AIIntent.recovery,
        preferences: const <String, Object?>{'bb_sleep_hours': 8},
        metadata: CoachContextMetadata(
          buildTime: DateTime(2026, 8, 13),
          sourceCount: 1,
          missingProviders: const {},
          confidence: 0.9,
          contextVersion: CoachContext.contextVersion,
        ),
      );
      final updated = LastNightSleep.applyToContext(
        context,
        const LastNightSleepLog(hours: 5, dateKey: '2026-08-13'),
      );

      expect(updated.preferences['last_night_sleep_hours'], 5);
      expect(updated.preferences['sleep_hours'], 5);
      expect(updated.preferences['bb_sleep_hours'], 8);
    });
  });
}
