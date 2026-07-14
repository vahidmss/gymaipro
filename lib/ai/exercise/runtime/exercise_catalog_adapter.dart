import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile_mapper.dart';
import 'package:gymaipro/models/exercise.dart';

/// One catalog row mapped for intelligence and execution.
class ExerciseCatalogEntry {
  const ExerciseCatalogEntry({
    required this.profile,
    required this.exercise,
  });

  final ExerciseProfile profile;
  final Exercise exercise;
}

/// Unified adapter from catalog sources to [ExerciseProfile].
///
/// Generator only depends on this abstraction — not on individual mappers.
abstract class ExerciseCatalogAdapter {
  List<ExerciseCatalogEntry> loadEntries();

  ExerciseCatalogEntry? findById(int id) {
    for (final entry in loadEntries()) {
      if (entry.profile.id == id) return entry;
    }
    return null;
  }

  List<ExerciseProfile> loadProfiles() {
    return loadEntries().map((entry) => entry.profile).toList();
  }

  bool get isEmpty => loadEntries().isEmpty;
}

/// Adapter over an in-memory [Exercise] list (tests and offline runtime).
class ListExerciseCatalogAdapter extends ExerciseCatalogAdapter {
  ListExerciseCatalogAdapter(
    List<Exercise> exercises, {
    ExerciseProfileMapper mapper = const ExerciseProfileMapper(),
  }) : _entries = exercises
           .map(
             (exercise) => ExerciseCatalogEntry(
               profile: mapper.fromExercise(exercise),
               exercise: exercise,
             ),
           )
           .toList();

  final List<ExerciseCatalogEntry> _entries;

  @override
  List<ExerciseCatalogEntry> loadEntries() => _entries;
}
