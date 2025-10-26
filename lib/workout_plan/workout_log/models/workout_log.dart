import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:uuid/uuid.dart';

class WorkoutLog {
  WorkoutLog({
    required this.userId,
    required this.workoutData,
    String? id,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> workoutData;

    // Check if we're getting data from the new structure or legacy format
    if (json.containsKey('workout_data')) {
      // New JSON structure
      workoutData = Map<String, dynamic>.from(json['workout_data'] as Map);
    } else {
      // Legacy format or direct mapping
      workoutData = {
        'program_id': json['program_id'],
        'program_name': json['program_name'],
        'session_id': json['session_id'],
        'session_name': json['session_name'],
        'exercise_id': json['exercise_id'],
        'exercise_name': json['exercise_name'],
        'exercise_tag': json['exercise_tag'],
        'exercise_type': json['exercise_type'],
        'sets': json['sets'],
        'notes': json['notes'],
        'duration_seconds': json['duration_seconds'],
        'calories_burned': json['calories_burned'],
        'rating': json['rating'],
        'feeling': json['feeling'],
        'is_completed': json['is_completed'] ?? true,
      };
    }

    return WorkoutLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      workoutData: workoutData,
    );
  }

  // Create a WorkoutLog with specific workout details
  factory WorkoutLog.create({
    required String userId,
    required String programId,
    required String sessionId,
    required String exerciseId,
    required ExerciseType exerciseType,
    required List<WorkoutSet> sets,
    String? id,
    String? programName,
    String? sessionName,
    String? exerciseName,
    String? exerciseTag,
    String? notes,
    int? durationSeconds,
    int? caloriesBurned,
    int? rating,
    String? feeling,
    bool isCompleted = true,
    DateTime? createdAt,
  }) {
    final workoutData = {
      'program_id': programId,
      'program_name': programName,
      'session_id': sessionId,
      'session_name': sessionName,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'exercise_tag': exerciseTag,
      'exercise_type': exerciseType.toString().split('.').last,
      'sets': sets.map((set) => set.toJson()).toList(),
      'notes': notes,
      'duration_seconds': durationSeconds,
      'calories_burned': caloriesBurned,
      'rating': rating,
      'feeling': feeling,
      'is_completed': isCompleted,
    };

    return WorkoutLog(
      id: id,
      userId: userId,
      createdAt: createdAt,
      workoutData: workoutData,
    );
  }
  final String id;
  final String userId;
  final DateTime createdAt;
  final Map<String, dynamic> workoutData;

  // Getter methods for commonly accessed fields
  String get programId => workoutData['program_id'] as String;
  String? get programName => workoutData['program_name'] as String?;
  String get sessionId => workoutData['session_id'] as String;
  String? get sessionName => workoutData['session_name'] as String?;
  String get exerciseId => workoutData['exercise_id'] as String;
  String? get exerciseName => workoutData['exercise_name'] as String?;
  String? get exerciseTag => workoutData['exercise_tag'] as String?;
  ExerciseType get exerciseType =>
      _parseExerciseType(workoutData['exercise_type'] as String);
  List<WorkoutSet> get sets => (workoutData['sets'] as List)
      .map((set) => WorkoutSet.fromJson(set as Map<String, dynamic>))
      .toList();
  String? get notes => workoutData['notes'] as String?;
  int? get durationSeconds => workoutData['duration_seconds'] as int?;
  int? get caloriesBurned => workoutData['calories_burned'] as int?;
  int? get rating => workoutData['rating'] as int?;
  String? get feeling => workoutData['feeling'] as String?;
  bool get isCompleted => workoutData['is_completed'] as bool? ?? true;

  // Setter methods for updating fields
  set programId(String value) => workoutData['program_id'] = value;
  set programName(String? value) => workoutData['program_name'] = value;
  set sessionId(String value) => workoutData['session_id'] = value;
  set sessionName(String? value) => workoutData['session_name'] = value;
  set exerciseId(String value) => workoutData['exercise_id'] = value;
  set exerciseName(String? value) => workoutData['exercise_name'] = value;
  set exerciseTag(String? value) => workoutData['exercise_tag'] = value;
  set notes(String? value) => workoutData['notes'] = value;
  set durationSeconds(int? value) => workoutData['duration_seconds'] = value;
  set caloriesBurned(int? value) => workoutData['calories_burned'] = value;
  set rating(int? value) => workoutData['rating'] = value;
  set feeling(String? value) => workoutData['feeling'] = value;
  set isCompleted(bool value) => workoutData['is_completed'] = value;

  void setExerciseType(ExerciseType type) {
    workoutData['exercise_type'] = type.toString().split('.').last;
  }

  void setSets(List<WorkoutSet> newSets) {
    workoutData['sets'] = newSets.map((set) => set.toJson()).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'workout_data': workoutData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper method to get the full JSON representation (for analytics)
  Map<String, dynamic> toFullJson() {
    final json = Map<String, dynamic>.from(workoutData);
    json['id'] = id;
    json['user_id'] = userId;
    json['created_at'] = createdAt.toIso8601String();
    return json;
  }

  static ExerciseType _parseExerciseType(String type) {
    switch (type.toLowerCase()) {
      case 'superset':
        return ExerciseType.superset;
      case 'triset':
        return ExerciseType.triset;
      case 'normal':
      default:
        return ExerciseType.normal;
    }
  }
}

class WorkoutSet {
  WorkoutSet({
    this.reps,
    this.weight,
    this.timeSeconds,
    this.isCompleted = false,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      reps: json['reps'] as int?,
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      timeSeconds: json['time_seconds'] as int?,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
  final int? reps;
  final double? weight;
  final int? timeSeconds;
  final bool isCompleted;

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'time_seconds': timeSeconds,
      'is_completed': isCompleted,
    };
  }
}

class WorkoutLogFilter {
  WorkoutLogFilter({
    this.startDate,
    this.endDate,
    this.programId,
    this.exerciseTag,
    this.exerciseName,
  });
  final DateTime? startDate;
  final DateTime? endDate;
  final String? programId;
  final String? exerciseTag;
  final String? exerciseName;

  bool matches(WorkoutLog log) {
    if (startDate != null && log.createdAt.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && log.createdAt.isAfter(endDate!)) {
      return false;
    }
    if (programId != null && log.programId != programId) {
      return false;
    }
    if (exerciseTag != null && log.exerciseTag != exerciseTag) {
      return false;
    }
    if (exerciseName != null && log.exerciseName != exerciseName) {
      return false;
    }
    return true;
  }
}
