import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_engine.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/utils/auth_helper.dart';

/// Read-only seed package for Coach preview pipeline runs.
class CoachPreviewSeed {
  const CoachPreviewSeed({
    required this.userId,
    required this.context,
    required this.message,
    required this.intent,
  });

  final String userId;
  final CoachContext context;
  final String message;
  final AIIntent intent;
}

/// Contract for loading preview seed context.
abstract class CoachPreviewSeedProvider {
  Future<CoachPreviewSeed> load({
    required AIIntent intent,
    required String message,
  });
}

/// Loads authenticated [CoachContext] snapshots for preview facades.
///
/// Preview pipeline tests always pass [CoachContext] as `seedCoachContext`.
/// Runtime UI loads must do the same; otherwise the context stage may fail
/// before `coachContext` is produced.
class CoachPreviewSeedLoader implements CoachPreviewSeedProvider {
  CoachPreviewSeedLoader({AIContextEngine? contextEngine})
    : _contextEngine = contextEngine;

  final AIContextEngine? _contextEngine;

  @override
  Future<CoachPreviewSeed> load({
    required AIIntent intent,
    required String message,
  }) async {
    final userId = AuthHelper.currentUserIdSync;
    if (userId == null || userId.isEmpty) {
      throw StateError('برای مشاهده Coach باید وارد حساب شوید.');
    }

    final engine = _contextEngine ?? AIContextEngine();
    final context = await engine.buildCoachContext(
      request: AIContextRequest(
        userId: userId,
        intent: intent,
        currentQuestion: message,
        source: 'runtime',
      ),
      intent: intent,
    );

    return CoachPreviewSeed(
      userId: userId,
      context: context,
      message: message,
      intent: intent,
    );
  }
}
