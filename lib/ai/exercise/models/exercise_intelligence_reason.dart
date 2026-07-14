/// Explainable reason for an exercise intelligence decision.
class ExerciseIntelligenceReason {
  const ExerciseIntelligenceReason({
    required this.code,
    required this.subject,
    required this.because,
  });

  factory ExerciseIntelligenceReason.fromJson(Map<String, Object?> json) {
    return ExerciseIntelligenceReason(
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

  ExerciseIntelligenceReason copyWith({
    String? code,
    String? subject,
    List<String>? because,
  }) {
    return ExerciseIntelligenceReason(
      code: code ?? this.code,
      subject: subject ?? this.subject,
      because: because ?? this.because,
    );
  }
}
