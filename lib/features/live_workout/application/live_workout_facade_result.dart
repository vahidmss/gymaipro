import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';

class LiveWorkoutFacadeResult {
  const LiveWorkoutFacadeResult({
    required this.state,
    this.gaps = const <String>[],
    this.previewDuration = Duration.zero,
  });

  final LiveWorkoutState state;
  final List<String> gaps;
  final Duration previewDuration;

  bool get hasGaps => gaps.isNotEmpty;
}
