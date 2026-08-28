import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/product_experience/application/recovery_facade.dart';
import 'package:gymaipro/features/product_experience/presentation/screens/recovery_screen.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/product_experience/recovery/last_night_sleep.dart';
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';
import 'package:gymaipro/features/product_experience/training_metric_guides.dart';

void main() {
  testWidgets('RecoveryScreen asks for last-night sleep before metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: RecoveryScreen(facade: _FakeRecoveryFacade()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ProductCopy.lastNightSleepTitle), findsOneWidget);
    expect(find.text(ProductCopy.lastNightSleepSubmit), findsOneWidget);
    expect(find.text(TrainingMetricGuides.readinessTitle), findsNothing);
  });

  testWidgets('RecoveryScreen shows metrics after last-night sleep is saved', (
    tester,
  ) async {
    final facade = _FakeRecoveryFacade();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: RecoveryScreen(facade: facade),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(
      GymButton,
      ProductCopy.lastNightSleepSubmit,
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(facade.lastNight, isNotNull);
    expect(find.text(ProductCopy.lastNightSleepSubmit), findsNothing);
    expect(find.text(TrainingMetricGuides.readinessTitle), findsOneWidget);
    expect(find.textContaining('خواب مفید'), findsWidgets);
  });
}

class _FakeRecoveryFacade extends RecoveryFacade {
  _FakeRecoveryFacade() : super(seedLoader: _FakeSeedLoader());

  double? lastNight;

  @override
  Future<RecoveryFacadeResult> load() async {
    final seed = await _FakeSeedLoader().load(
      intent: AIIntent.recovery,
      message: 'ریکاوری',
    );
    final log = lastNight == null
        ? null
        : LastNightSleepLog(hours: lastNight!, dateKey: '2026-08-13');
    final context = LastNightSleep.applyToContext(seed.context, log);
    return RecoveryFacadeResult(
      guidance: RecoveryGuidance.fromContext(context),
      userId: seed.userId,
      lastNightSleepHours: lastNight,
      suggestedSleepHours: 7.5,
    );
  }

  @override
  Future<RecoveryFacadeResult> saveLastNightSleep({
    required String userId,
    required double hours,
  }) async {
    lastNight = hours;
    return load();
  }
}

class _FakeSeedLoader implements CoachPreviewSeedProvider {
  @override
  Future<CoachPreviewSeed> load({
    required AIIntent intent,
    required String message,
  }) async {
    return CoachPreviewSeed(
      userId: 'u1',
      intent: intent,
      message: message,
      context: CoachContext(
        intent: intent,
        profile: const <String, Object?>{'first_name': 'وحید'},
        preferences: const <String, Object?>{
          'recovery_score': 80,
          'bb_sleep_hours': 7.5,
        },
        metadata: CoachContextMetadata(
          buildTime: DateTime(2026, 8, 13),
          sourceCount: 2,
          missingProviders: const {},
          confidence: 0.9,
          contextVersion: CoachContext.contextVersion,
        ),
      ),
    );
  }
}
