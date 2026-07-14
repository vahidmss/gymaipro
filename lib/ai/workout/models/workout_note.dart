/// Scope of a workout note in the program tree.
enum WorkoutNoteScope { program, week, day, exercise, set }

/// Persistent note attached to any level of a workout program.
class WorkoutNote {
  const WorkoutNote({
    required this.id,
    required this.text,
    required this.scope,
    this.createdAt,
  });

  factory WorkoutNote.fromJson(Map<String, Object?> json) {
    final createdAtRaw = json['createdAt'];
    return WorkoutNote(
      id: (json['id'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      scope: WorkoutNoteScope.values.firstWhere(
        (value) => value.name == json['scope'],
        orElse: () => WorkoutNoteScope.program,
      ),
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw)
          : null,
    );
  }

  final String id;
  final String text;
  final WorkoutNoteScope scope;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'text': text,
    'scope': scope.name,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };
}
