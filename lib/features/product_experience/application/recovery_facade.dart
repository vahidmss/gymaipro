import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/recovery/last_night_sleep.dart';
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';

class RecoveryFacadeResult {
  const RecoveryFacadeResult({
    required this.guidance,
    required this.userId,
    this.lastNightSleepHours,
    this.suggestedSleepHours = LastNightSleep.defaultHours,
  });

  final RecoveryGuidance guidance;
  final String userId;
  final double? lastNightSleepHours;
  final double suggestedSleepHours;

  CoachRecoverySnapshot get snapshot => guidance.snapshot;

  bool get hasLastNightSleep => lastNightSleepHours != null;
}

/// Loads live recovery signals for the dedicated Recovery screen.
class RecoveryFacade {
  RecoveryFacade({
    CoachPreviewSeedProvider? seedLoader,
    LastNightSleepStore? sleepStore,
  }) : _seedLoader = seedLoader,
       _sleepStore = sleepStore ?? LastNightSleepStore();

  final CoachPreviewSeedProvider? _seedLoader;
  final LastNightSleepStore _sleepStore;

  Future<RecoveryFacadeResult> load() async {
    const message = 'ریکاوری من برای تمرین امروز چطوره؟';
    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: AIIntent.recovery,
      message: message,
    );
    final sleep = await _sleepStore.readToday(seed.userId);
    final context = LastNightSleep.applyToContext(seed.context, sleep);
    return RecoveryFacadeResult(
      guidance: RecoveryGuidance.fromContext(context),
      userId: seed.userId,
      lastNightSleepHours: sleep?.hours,
      suggestedSleepHours: LastNightSleep.suggestedHours(
        seed.context.preferences,
        logged: sleep?.hours,
      ),
    );
  }

  Future<RecoveryFacadeResult> saveLastNightSleep({
    required String userId,
    required double hours,
  }) async {
    await _sleepStore.save(userId: userId, hours: hours);
    return load();
  }
}
