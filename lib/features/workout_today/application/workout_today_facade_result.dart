import 'package:gymaipro/features/workout_today/state/workout_today_state.dart';

class WorkoutTodayFacadeResult {
  const WorkoutTodayFacadeResult({
    required this.state,
    this.gaps = const <String>[],
    this.previewDuration = Duration.zero,
  });

  final WorkoutTodayState state;
  final List<String> gaps;
  final Duration previewDuration;

  bool get hasGaps => gaps.isNotEmpty;
}
