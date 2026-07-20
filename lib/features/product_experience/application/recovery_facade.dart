import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';

class RecoveryFacadeResult {
  const RecoveryFacadeResult({
    required this.guidance,
    required this.userId,
  });

  final RecoveryGuidance guidance;
  final String userId;

  CoachRecoverySnapshot get snapshot => guidance.snapshot;
}

/// Loads live recovery signals for the dedicated Recovery screen.
class RecoveryFacade {
  RecoveryFacade({CoachPreviewSeedProvider? seedLoader})
    : _seedLoader = seedLoader;

  final CoachPreviewSeedProvider? _seedLoader;

  Future<RecoveryFacadeResult> load() async {
    const message = 'ریکاوری من برای تمرین امروز چطوره؟';
    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: AIIntent.recovery,
      message: message,
    );
    return RecoveryFacadeResult(
      guidance: RecoveryGuidance.fromContext(seed.context),
      userId: seed.userId,
    );
  }
}
