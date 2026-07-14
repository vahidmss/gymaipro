/// Explainable reason for a workout modification decision.
class WorkoutModificationReason {
  const WorkoutModificationReason({
    required this.code,
    required this.subject,
    required this.because,
  });

  factory WorkoutModificationReason.fromJson(Map<String, Object?> json) {
    return WorkoutModificationReason(
      code: (json['code'] as String?) ?? '',
      subject: (json['subject'] as String?) ?? '',
      because: (json['because'] as List<Object?>? ?? const <Object?>[])
          .map((item) => item.toString())
          .toList(),
    );
  }

  final String code;
  final String subject;
  final List<String> because;

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code,
    'subject': subject,
    'because': because,
  };

  WorkoutModificationReason copyWith({
    String? code,
    String? subject,
    List<String>? because,
  }) {
    return WorkoutModificationReason(
      code: code ?? this.code,
      subject: subject ?? this.subject,
      because: because ?? this.because,
    );
  }
}
