import 'package:gymaipro/ai/workout_review/models/workout_review_enums.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_reason.dart';

/// Actionable suggestion to improve a workout program.
class WorkoutReviewRecommendation {
  const WorkoutReviewRecommendation({
    required this.code,
    required this.action,
    required this.priority,
    required this.target,
    required this.reasons,
  });

  factory WorkoutReviewRecommendation.fromJson(Map<String, Object?> json) {
    return WorkoutReviewRecommendation(
      code: WorkoutReviewRecommendationCode.values.firstWhere(
        (value) => value.name == json['code'],
        orElse: () => WorkoutReviewRecommendationCode.increaseRest,
      ),
      action: (json['action'] as String?) ?? '',
      priority: (json['priority'] as int?) ?? 1,
      target: (json['target'] as String?) ?? '',
      reasons: (json['reasons'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map(WorkoutReviewReason.fromJson)
          .toList(),
    );
  }

  final WorkoutReviewRecommendationCode code;
  final String action;
  final int priority;
  final String target;
  final List<WorkoutReviewReason> reasons;

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code.name,
    'action': action,
    'priority': priority,
    'target': target,
    'reasons': reasons.map((reason) => reason.toJson()).toList(),
  };

  WorkoutReviewRecommendation copyWith({
    WorkoutReviewRecommendationCode? code,
    String? action,
    int? priority,
    String? target,
    List<WorkoutReviewReason>? reasons,
  }) {
    return WorkoutReviewRecommendation(
      code: code ?? this.code,
      action: action ?? this.action,
      priority: priority ?? this.priority,
      target: target ?? this.target,
      reasons: reasons ?? this.reasons,
    );
  }
}
