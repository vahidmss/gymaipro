import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';

class ExerciseCatalogFilters {
  const ExerciseCatalogFilters({
    this.query = '',
    this.muscleGroup = '',
    this.difficulty = '',
    this.equipment = '',
    this.exerciseType = '',
    this.sortBy = 'popularity',
    this.sortAscending = false,
  });

  final String query;
  final String muscleGroup;
  final String difficulty;
  final String equipment;
  final String exerciseType;
  final String sortBy;
  final bool sortAscending;

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      muscleGroup.isNotEmpty ||
      difficulty.isNotEmpty ||
      equipment.isNotEmpty ||
      exerciseType.isNotEmpty;

  ExerciseCatalogFilters copyWith({
    String? query,
    String? muscleGroup,
    String? difficulty,
    String? equipment,
    String? exerciseType,
    String? sortBy,
    bool? sortAscending,
  }) {
    return ExerciseCatalogFilters(
      query: query ?? this.query,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      difficulty: difficulty ?? this.difficulty,
      equipment: equipment ?? this.equipment,
      exerciseType: exerciseType ?? this.exerciseType,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

class ExerciseCatalogLogic {
  /// جلوگیری از rebuild گرید وقتی نتیجه فیلتر عوض نشده.
  static bool sameIds(List<Exercise> a, List<Exercise> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  /// آیا دادهٔ نمایشی عوض شده (مثلاً بعد از sync تصاویر از شبکه).
  static bool displayDataChanged(List<Exercise> prev, List<Exercise> next) {
    if (identical(prev, next)) return false;
    if (prev.length != next.length) return true;
    final byId = {for (final e in next) e.id: e};
    for (final e in prev) {
      final n = byId[e.id];
      if (n == null) return true;
      if (n.imageUrl != e.imageUrl) return true;
      if (n.likes != e.likes) return true;
      if (n.isFavorite != e.isFavorite) return true;
      if (n.isLikedByUser != e.isLikedByUser) return true;
    }
    return false;
  }

  static List<Exercise> apply(
    List<Exercise> source,
    ExerciseCatalogFilters filters,
  ) {
    var list = List<Exercise>.from(source);

    if (filters.muscleGroup.isNotEmpty) {
      final muscle = filters.muscleGroup;
      list = list
          .where(
            (e) => ExerciseDisplayLabels.muscleMatchesFilter(
              muscle,
              mainMuscle: e.mainMuscle,
              secondaryMuscles: e.secondaryMuscles,
            ),
          )
          .toList();
    }

    if (filters.difficulty.isNotEmpty) {
      list = list
          .where(
            (e) => ExerciseDisplayLabels.fieldMatchesFilter(
              filters.difficulty,
              e.difficulty,
              ExerciseDisplayLabels.difficultyLabel,
            ),
          )
          .toList();
    }

    if (filters.equipment.isNotEmpty) {
      list = list
          .where(
            (e) => ExerciseDisplayLabels.fieldMatchesFilter(
              filters.equipment,
              e.equipment,
              ExerciseDisplayLabels.equipmentLabel,
            ),
          )
          .toList();
    }

    if (filters.exerciseType.isNotEmpty) {
      list = list
          .where(
            (e) => ExerciseDisplayLabels.fieldMatchesFilter(
              filters.exerciseType,
              e.exerciseType,
              ExerciseDisplayLabels.type,
            ),
          )
          .toList();
    }

    if (filters.query.isNotEmpty) {
      final q = filters.query.toLowerCase();
      list = list.where((exercise) {
        return exercise.name.toLowerCase().contains(q) ||
            ExerciseDisplayLabels.muscle(exercise.mainMuscle)
                .toLowerCase()
                .contains(q) ||
            ExerciseDisplayLabels.musclesCsv(exercise.secondaryMuscles)
                .toLowerCase()
                .contains(q) ||
            exercise.mainMuscle.toLowerCase().contains(q) ||
            exercise.secondaryMuscles.toLowerCase().contains(q) ||
            exercise.otherNames.any(
              (name) => name.toLowerCase().contains(q),
            );
      }).toList();
    }

    list.sort((a, b) {
      final cmp = _compare(a, b, filters.sortBy);
      final primary = filters.sortAscending ? cmp : -cmp;
      if (primary != 0) return primary;
      return a.id.compareTo(b.id);
    });

    return list;
  }

  static int _compare(Exercise a, Exercise b, String sortBy) {
    switch (sortBy) {
      case 'difficulty':
        return a.difficulty.compareTo(b.difficulty);
      case 'duration':
        return a.estimatedDuration.compareTo(b.estimatedDuration);
      case 'equipment':
        return a.equipment.compareTo(b.equipment);
      case 'type':
        return a.exerciseType.compareTo(b.exerciseType);
      case 'name':
        return a.name.compareTo(b.name);
      case 'popularity':
      case 'likes':
        return a.likes.compareTo(b.likes);
      default:
        return a.likes.compareTo(b.likes);
    }
  }
}
