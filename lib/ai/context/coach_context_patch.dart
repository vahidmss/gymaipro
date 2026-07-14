import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// Partial coach context returned by providers and merged by [AIContextBuilder].
class CoachContextPatch {
  const CoachContextPatch({
    this.profile,
    this.goals,
    this.restrictions,
    this.equipment,
    this.preferences,
    this.activeProgram,
    this.workoutHistory,
    this.weeklyHeatmap,
    this.apiUsage,
    this.currentQuestion,
  });

  /// Empty patch used as a merge seed.
  static const CoachContextPatch empty = CoachContextPatch();

  final Map<String, Object?>? profile;
  final List<String>? goals;
  final List<String>? restrictions;
  final List<String>? equipment;
  final Map<String, Object?>? preferences;
  final Map<String, Object?>? activeProgram;
  final List<WorkoutDailyLog>? workoutHistory;
  final WeeklyMuscleHeatmapResult? weeklyHeatmap;
  final Map<String, Object?>? apiUsage;
  final String? currentQuestion;

  /// Merges [other] into this patch.
  CoachContextPatch merge(CoachContextPatch other) {
    return CoachContextPatch(
      profile: _mergeMap(profile, other.profile),
      goals: _mergeList(goals, other.goals),
      restrictions: _mergeList(restrictions, other.restrictions),
      equipment: _mergeList(equipment, other.equipment),
      preferences: _mergeMap(preferences, other.preferences),
      activeProgram: other.activeProgram ?? activeProgram,
      workoutHistory: other.workoutHistory?.isNotEmpty == true
          ? other.workoutHistory
          : workoutHistory,
      weeklyHeatmap: other.weeklyHeatmap ?? weeklyHeatmap,
      apiUsage: _mergeMap(apiUsage, other.apiUsage),
      currentQuestion: other.currentQuestion ?? currentQuestion,
    );
  }

  Map<String, Object?>? _mergeMap(
    Map<String, Object?>? current,
    Map<String, Object?>? incoming,
  ) {
    if (incoming == null || incoming.isEmpty) return current;
    if (current == null || current.isEmpty) return incoming;
    return <String, Object?>{...current, ...incoming};
  }

  List<String>? _mergeList(List<String>? current, List<String>? incoming) {
    if (incoming == null || incoming.isEmpty) return current;
    if (current == null || current.isEmpty) return incoming;
    return <String>[...current, ...incoming];
  }
}
