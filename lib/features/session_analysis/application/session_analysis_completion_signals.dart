import 'package:shared_preferences/shared_preferences.dart';

/// Marks a workout session as explicitly finished for recovery / coach home.
abstract final class SessionAnalysisCompletionSignals {
  static Future<void> markCompleted({
    required String userId,
    required int completedSets,
    SharedPreferences? preferences,
  }) async {
    if (userId.isEmpty) return;
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final fatigue = (completedSets * 2).clamp(0, 40);
    final previous =
        int.tryParse(prefs.getString('recovery_score_$userId') ?? '') ?? 70;
    final next = (previous - fatigue).clamp(15, 100);
    await prefs.setString('recovery_score_$userId', '$next');
    await prefs.setString(
      'last_workout_completed_at_$userId',
      DateTime.now().toIso8601String(),
    );
  }
}
