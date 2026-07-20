import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_completion_summary.dart';
import 'package:gymaipro/services/muscle_heatmap_aggregate.dart';

void main() {
  test('fromSessionStats builds clean Persian copy with heatmap', () {
    final summary = LiveWorkoutCompletionSummary.fromSessionStats(
      focus: 'روز ۱',
      completedSets: 12,
      totalSets: 12,
      totalVolumeKg: 2840,
      heatmap: const MuscleHeatmapSnapshot(
        targets: {'chest_middle': 100, 'triceps': 55},
        completedSets: 12,
        exercisesWithSets: 4,
      ),
      synced: true,
    );

    expect(summary.headline, contains('آفرین'));
    expect(summary.bodyLine, contains('سینه میانی'));
    expect(summary.bodyLine, isNot(contains('برنامه فعال')));
    expect(summary.hasHeatmapData, isTrue);
    expect(summary.tipLine, contains('تحلیل امروز'));
  });
}
