import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';

class CoachFacadeResult {
  const CoachFacadeResult({
    required this.state,
    this.gaps = const <String>[],
    this.previewDuration = Duration.zero,
  });

  final CoachHomeState state;
  final List<String> gaps;
  final Duration previewDuration;

  bool get hasGaps => gaps.isNotEmpty;
}
