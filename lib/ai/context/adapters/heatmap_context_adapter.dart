import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';

/// Read-only adapter for weekly muscle heatmap aggregation.
class HeatmapContextAdapter {
  HeatmapContextAdapter({WeeklyMuscleHeatmapService? heatmapService})
    : _heatmapService = heatmapService ?? WeeklyMuscleHeatmapService();

  final WeeklyMuscleHeatmapService _heatmapService;

  /// Returns the weekly heatmap snapshot for [userId].
  Future<WeeklyMuscleHeatmapResult> getWeeklyHeatmap(String userId) {
    return _heatmapService.loadForUser(userId);
  }
}
