import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/integration/coach_integration_service.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';

typedef CoachFeatureLoader =
    Future<CoachIntegrationResult> Function({
      required String userMessage,
      String userId,
      CoachContext? context,
      Map<String, Object?> metadata,
    });

/// Routes Coach feature calls through production runtime or preview fallback.
class CoachFeatureIntegration {
  CoachFeatureIntegration({CoachIntegrationService? integrationService})
    : _integrationService = integrationService ?? CoachIntegrationService();

  final CoachIntegrationService _integrationService;

  static CoachFeatureLoader defaultLoader({CoachIntegrationService? service}) {
    final integration = CoachFeatureIntegration(integrationService: service);
    return ({
      required String userMessage,
      String userId = '',
      CoachContext? context,
      Map<String, Object?> metadata = const <String, Object?>{},
    }) {
      final feature = metadata['feature']?.toString() ?? 'coach';
      return integration.load(
        userMessage: userMessage,
        userId: userId,
        context: context,
        feature: feature,
      );
    };
  }

  Future<CoachIntegrationResult> load({
    required String userMessage,
    required String userId,
    CoachContext? context,
    required String feature,
    Map<String, Object?> extraMetadata = const <String, Object?>{},
  }) async {
    final metadata = <String, Object?>{
      'feature': feature,
      ...extraMetadata,
    };

    if (CoachV2Config.coachV2Enabled) {
      metadata['mode'] = CoachPipelineMode.runtime.name;
      return _integrationService.processMessage(
        userId: userId,
        userMessage: userMessage,
        metadata: metadata,
      );
    }

    metadata['mode'] = CoachPipelineMode.preview.name;
    return _integrationService.previewMessage(
      userMessage: userMessage,
      userId: userId,
      context: context,
      metadata: metadata,
    );
  }
}
