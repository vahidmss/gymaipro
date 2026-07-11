import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';

/// Read-only adapter for active program and workout history.
class WorkoutContextAdapter {
  WorkoutContextAdapter({
    ActiveProgramService? activeProgramService,
    WorkoutDailyLogService? workoutLogService,
  }) : _activeProgramService = activeProgramService ?? ActiveProgramService(),
       _workoutLogService = workoutLogService ?? WorkoutDailyLogService();

  final ActiveProgramService _activeProgramService;
  final WorkoutDailyLogService _workoutLogService;

  /// Returns the current active program state from the existing service.
  Future<Map<String, Object?>?> getActiveProgram() async {
    final state = await _activeProgramService.getActiveProgramState();
    if (state == null) return null;
    return Map<String, Object?>.from(state);
  }

  /// Returns workout logs for [userId] without transforming log behavior.
  Future<List<WorkoutDailyLog>> getWorkoutHistory(String userId) {
    return _workoutLogService.getUserDailyLogs(userId);
  }
}
