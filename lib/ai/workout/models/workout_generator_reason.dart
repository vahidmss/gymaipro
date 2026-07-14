/// Explainable reason for a generator decision.
class WorkoutGeneratorReason {
  const WorkoutGeneratorReason({
    required this.code,
    required this.subject,
    required this.because,
  });

  factory WorkoutGeneratorReason.fromJson(Map<String, Object?> json) {
    return WorkoutGeneratorReason(
      code: (json['code'] as String?) ?? '',
      subject: (json['subject'] as String?) ?? '',
      because: List<String>.from(
        (json['because'] as List<Object?>?) ?? const <Object?>[],
      ),
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
}
