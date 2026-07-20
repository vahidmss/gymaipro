/// One exercise's local form tips for the Form Guidance screen.
class FormExerciseGuidance {
  const FormExerciseGuidance({
    required this.name,
    required this.tips,
    this.catalogExerciseId,
    this.primaryMuscle,
    this.programNote,
  });

  final String name;
  final int? catalogExerciseId;
  final String? primaryMuscle;
  final List<String> tips;
  final String? programNote;

  bool get hasLocalTips => tips.isNotEmpty;

  /// Tips to show: catalog tips, else short program note as a single tip.
  List<String> get displayTips {
    if (tips.isNotEmpty) return tips;
    final note = programNote?.trim();
    if (note != null && note.isNotEmpty && note.length <= 180) {
      return <String>[note];
    }
    return const <String>[];
  }

  String get askCoachPrompt =>
      'فرم و تکنیک حرکت «$name» را دقیق راهنمایی کن؛ '
      'نکات ایمنی، دامنه حرکتی و اشتباهات رایج را بگو.';
}

/// Session-scoped form guidance payload.
class FormGuidanceSession {
  const FormGuidanceSession({
    required this.sessionDay,
    required this.exercises,
    this.programTitle,
  });

  final String? programTitle;
  final String sessionDay;
  final List<FormExerciseGuidance> exercises;

  bool get isEmpty => exercises.isEmpty;

  FormExerciseGuidance? byCatalogId(int? id) {
    if (id == null || id <= 0) return null;
    for (final item in exercises) {
      if (item.catalogExerciseId == id) return item;
    }
    return null;
  }
}
