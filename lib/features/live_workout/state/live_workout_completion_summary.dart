import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/services/muscle_heatmap_aggregate.dart';

/// Summary shown after a live workout session completes.
class LiveWorkoutCompletionSummary {
  const LiveWorkoutCompletionSummary({
    required this.focus,
    required this.completedSets,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.headline,
    required this.bodyLine,
    required this.tipLine,
    required this.muscleTargets,
    required this.synced,
    this.topMuscleLabel,
  });

  factory LiveWorkoutCompletionSummary.fromSessionStats({
    required String focus,
    required int completedSets,
    required int totalSets,
    required double totalVolumeKg,
    required MuscleHeatmapSnapshot heatmap,
    required bool synced,
  }) {
    final top = heatmap.topMuscleLabel;
    final volumePart = totalVolumeKg > 0
        ? ' · حجم ${formatVolume(totalVolumeKg)} کیلو'
        : '';

    final headline = completedSets >= totalSets && totalSets > 0
        ? 'آفرین — جلسه کامل ثبت شد'
        : 'جلسه امروز ثبت شد';

    final bodyLine = top != null
        ? 'بیشترین فشار روی $top بود · $completedSets ست$volumePart'
        : '$completedSets از $totalSets ست ثبت شد$volumePart';

    final tipLine = top != null
        ? 'نقشه عضلانی همین جلسه اینجاست. برای دیدن روند هفته، تحلیل امروز را باز کن.'
        : 'ست‌ها ذخیره شدند. برای دیدن روند تمرین، تحلیل امروز را باز کن.';

    return LiveWorkoutCompletionSummary(
      focus: focus,
      completedSets: completedSets,
      totalSets: totalSets,
      totalVolumeKg: totalVolumeKg,
      headline: headline,
      bodyLine: bodyLine,
      tipLine: tipLine,
      muscleTargets: Map<String, int>.from(heatmap.targets),
      topMuscleLabel: top,
      synced: synced,
    );
  }

  final String focus;
  final int completedSets;
  final int totalSets;
  final double totalVolumeKg;
  final String headline;
  final String bodyLine;
  final String tipLine;
  final Map<String, int> muscleTargets;
  final String? topMuscleLabel;
  final bool synced;

  bool get hasHeatmapData => MuscleTargets.hasData(muscleTargets);

  static String formatVolume(double volume) {
    if (volume >= 100) return volume.round().toString();
    if (volume == volume.roundToDouble()) return volume.toInt().toString();
    return volume.toStringAsFixed(1);
  }
}
