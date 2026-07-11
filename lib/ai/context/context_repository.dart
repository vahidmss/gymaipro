import 'package:gymaipro/ai/context/adapters/api_usage_context_adapter.dart';
import 'package:gymaipro/ai/context/adapters/heatmap_context_adapter.dart';
import 'package:gymaipro/ai/context/adapters/user_fields_context_adapter.dart';
import 'package:gymaipro/ai/context/adapters/workout_context_adapter.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// Repository responsible for collecting raw app data for AI context.
///
/// This class is a unified facade over read-only adapters. It must not alter
/// business rules, prompts, generation behavior, or UI state.
class AIContextRepository {
  AIContextRepository({
    UserFieldsContextAdapter? userFieldsAdapter,
    WorkoutContextAdapter? workoutAdapter,
    HeatmapContextAdapter? heatmapAdapter,
    ApiUsageContextAdapter? apiUsageAdapter,
  }) : _userFieldsAdapter = userFieldsAdapter ?? UserFieldsContextAdapter(),
       _workoutAdapter = workoutAdapter ?? WorkoutContextAdapter(),
       _heatmapAdapter = heatmapAdapter ?? HeatmapContextAdapter(),
       _apiUsageAdapter = apiUsageAdapter ?? ApiUsageContextAdapter();

  final UserFieldsContextAdapter _userFieldsAdapter;
  final WorkoutContextAdapter _workoutAdapter;
  final HeatmapContextAdapter _heatmapAdapter;
  final ApiUsageContextAdapter _apiUsageAdapter;

  String? _cachedFieldsUserId;
  UserFieldsSnapshot? _cachedFieldsSnapshot;

  /// Clears in-memory field snapshot cache between dry-run requests.
  void clearFieldCache() {
    _cachedFieldsUserId = null;
    _cachedFieldsSnapshot = null;
  }

  Future<UserFieldsSnapshot> _userFields(String userId) async {
    if (_cachedFieldsUserId == userId && _cachedFieldsSnapshot != null) {
      return _cachedFieldsSnapshot!;
    }

    final snapshot = await _userFieldsAdapter.load(userId);
    _cachedFieldsUserId = userId;
    _cachedFieldsSnapshot = snapshot;
    return snapshot;
  }

  /// Returns the raw user profile row for the provided user id.
  Future<Map<String, Object?>?> getProfile(String userId) async {
    final snapshot = await _userFields(userId);
    return snapshot.profile;
  }

  /// Returns the current active program state.
  Future<Map<String, Object?>?> getActiveProgram() {
    return _workoutAdapter.getActiveProgram();
  }

  /// Returns workout logs without transforming current log behavior.
  Future<List<WorkoutDailyLog>> getWorkoutHistory(String userId) {
    return _workoutAdapter.getWorkoutHistory(userId);
  }

  /// Returns the current weekly muscle heatmap from the existing service.
  Future<WeeklyMuscleHeatmapResult> getWeeklyHeatmap(String userId) {
    return _heatmapAdapter.getWeeklyHeatmap(userId);
  }

  /// Returns user restrictions from profile, confidential, and questionnaire
  /// sources without applying injury parsing rules.
  Future<List<String>> getRestrictions(String userId) async {
    final snapshot = await _userFields(userId);
    return _userFieldsAdapter.restrictionsFrom(snapshot);
  }

  /// Returns user goals from profile, confidential, and questionnaire sources.
  Future<List<String>> getGoals(String userId) async {
    final snapshot = await _userFields(userId);
    return _userFieldsAdapter.goalsFrom(snapshot);
  }

  /// Returns coaching and lifestyle preferences from existing sources.
  Future<Map<String, Object?>> getPreferences(String userId) async {
    final snapshot = await _userFields(userId);
    return _userFieldsAdapter.preferencesFrom(snapshot);
  }

  /// Returns available equipment from profile and questionnaire sources.
  Future<List<String>> getEquipment(String userId) async {
    final snapshot = await _userFields(userId);
    return _userFieldsAdapter.equipmentFrom(snapshot);
  }

  /// Returns a read-only local usage snapshot.
  Future<Map<String, Object?>> getApiUsage(String userId) {
    return _apiUsageAdapter.getUsageSnapshot(userId);
  }
}
