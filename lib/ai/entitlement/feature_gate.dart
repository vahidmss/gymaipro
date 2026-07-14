import 'package:gymaipro/ai/entitlement/coach_capability.dart';

/// Feature gate declaration for future Coach surfaces.
///
/// A skill, strategy, prompt, or service can publish one of these declarations
/// so entitlement evaluation remains capability-based.
class FeatureGate {
  const FeatureGate({
    required this.id,
    required this.requiredCapabilities,
    this.anyOfCapabilities = const <CoachCapability>{},
    this.allowTrial = true,
    this.allowTemporaryUnlock = true,
    this.allowGift = true,
    this.allowPromoCode = true,
    this.allowEnterpriseOverride = true,
    this.enforceDailyLimit = true,
    this.enforceMonthlyLimit = true,
    this.enforceTokenLimit = true,
    this.metadata = const <String, Object?>{},
  });

  /// Stable feature id.
  final String id;

  /// Capabilities all required for access.
  final Set<CoachCapability> requiredCapabilities;

  /// Capabilities where any one is enough for access.
  final Set<CoachCapability> anyOfCapabilities;

  /// Whether trial grants can unlock this feature.
  final bool allowTrial;

  /// Whether temporary unlocks can unlock this feature.
  final bool allowTemporaryUnlock;

  /// Whether gifts can unlock this feature.
  final bool allowGift;

  /// Whether promo codes can unlock this feature.
  final bool allowPromoCode;

  /// Whether enterprise policy can unlock this feature.
  final bool allowEnterpriseOverride;

  /// Whether daily limits should be checked.
  final bool enforceDailyLimit;

  /// Whether monthly limits should be checked.
  final bool enforceMonthlyLimit;

  /// Whether token limits should be checked.
  final bool enforceTokenLimit;

  /// Future diagnostic metadata.
  final Map<String, Object?> metadata;

  /// All capabilities referenced by this gate.
  Set<CoachCapability> get allReferencedCapabilities {
    return Set<CoachCapability>.unmodifiable(<CoachCapability>{
      ...requiredCapabilities,
      ...anyOfCapabilities,
    });
  }
}
