import 'package:gymaipro/ai/skills/intelligence/skill_reason_type.dart';

/// One explainable reason behind a skill response.
class SkillReason {
  const SkillReason({
    required this.type,
    required this.message,
    this.weight = 0.1,
  });

  /// Reason category for trace and UI grouping.
  final SkillReasonType type;

  /// Human-readable reason in Persian.
  final String message;

  /// Relative contribution to confidence scoring from 0 to 1.
  final double weight;
}
