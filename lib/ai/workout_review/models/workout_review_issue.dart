import 'package:gymaipro/ai/workout_review/models/workout_review_enums.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_reason.dart';

/// A detected problem in a workout program.
class WorkoutReviewIssue {
  const WorkoutReviewIssue({
    required this.code,
    required this.severity,
    required this.subject,
    required this.message,
    required this.reasons,
  });

  factory WorkoutReviewIssue.fromJson(Map<String, Object?> json) {
    return WorkoutReviewIssue(
      code: WorkoutReviewIssueCode.values.firstWhere(
        (value) => value.name == json['code'],
        orElse: () => WorkoutReviewIssueCode.emptyProgram,
      ),
      severity: WorkoutReviewIssueSeverity.values.firstWhere(
        (value) => value.name == json['severity'],
        orElse: () => WorkoutReviewIssueSeverity.medium,
      ),
      subject: (json['subject'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      reasons: (json['reasons'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map(WorkoutReviewReason.fromJson)
          .toList(),
    );
  }

  final WorkoutReviewIssueCode code;
  final WorkoutReviewIssueSeverity severity;
  final String subject;
  final String message;
  final List<WorkoutReviewReason> reasons;

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code.name,
    'severity': severity.name,
    'subject': subject,
    'message': message,
    'reasons': reasons.map((reason) => reason.toJson()).toList(),
  };

  WorkoutReviewIssue copyWith({
    WorkoutReviewIssueCode? code,
    WorkoutReviewIssueSeverity? severity,
    String? subject,
    String? message,
    List<WorkoutReviewReason>? reasons,
  }) {
    return WorkoutReviewIssue(
      code: code ?? this.code,
      severity: severity ?? this.severity,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      reasons: reasons ?? this.reasons,
    );
  }
}
