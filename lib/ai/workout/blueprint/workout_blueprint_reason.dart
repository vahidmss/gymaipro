/// Explainability record for one blueprint planning decision.
class WorkoutBlueprintReason {
  const WorkoutBlueprintReason({
    required this.code,
    required this.subject,
    required this.because,
  });

  factory WorkoutBlueprintReason.fromJson(Map<String, Object?> json) {
    return WorkoutBlueprintReason(
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

  WorkoutBlueprintReason copyWith({
    String? code,
    String? subject,
    List<String>? because,
  }) {
    return WorkoutBlueprintReason(
      code: code ?? this.code,
      subject: subject ?? this.subject,
      because: because ?? this.because,
    );
  }
}
