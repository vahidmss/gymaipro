import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/intent/intent_detection_trace.dart';
import 'package:gymaipro/ai/intent/intent_rule_type.dart';

/// Secondary intent candidate with confidence metadata.
class IntentAlternative {
  const IntentAlternative({
    required this.intent,
    required this.confidence,
    required this.rawScore,
  });

  final AIIntent intent;
  final double confidence;
  final double rawScore;
}

/// Immutable result produced by the intent intelligence engine.
class IntentIntelligenceResult {
  const IntentIntelligenceResult({
    required this.primaryIntent,
    required this.primaryConfidence,
    required this.alternatives,
    required this.trace,
    required this.strategy,
    this.reason,
    this.rawPrimaryScore = 0,
  });

  final AIIntent primaryIntent;
  final double primaryConfidence;
  final List<IntentAlternative> alternatives;
  final IntentDetectionTrace trace;
  final IntentIntelligenceStrategy strategy;
  final String? reason;
  final double rawPrimaryScore;
}
