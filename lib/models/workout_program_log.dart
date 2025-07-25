import 'package:uuid/uuid.dart';

class WorkoutProgramLog {
  static const _uuid = Uuid();
  String id;
  String userId;
  String programName;
  DateTime logDate; // تاریخ روز لاگ
  List<WorkoutSessionLog> sessions;
  DateTime createdAt;
  DateTime updatedAt;

  WorkoutProgramLog({
    String? id,
    required this.userId,
    required this.programName,
    required this.logDate,
    required this.sessions,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory WorkoutProgramLog.fromJson(Map<String, dynamic> json) {
    return WorkoutProgramLog(
      id: json['id'],
      userId: json['user_id'],
      programName: json['program_name'],
      logDate: DateTime.parse(json['log_date']),
      sessions: (json['sessions'] as List)
          .map((s) => WorkoutSessionLog.fromJson(s))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'program_name': programName,
      'log_date': logDate.toIso8601String().substring(0, 10),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class WorkoutSessionLog {
  String id;
  String day;
  List<WorkoutExerciseLog> exercises;

  WorkoutSessionLog({
    required this.id,
    required this.day,
    required this.exercises,
  });

  factory WorkoutSessionLog.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionLog(
      id: json['id'],
      day: json['day'],
      exercises: (json['exercises'] as List).map((e) {
        final type = e['type'] as String;
        if (type == 'superset') {
          return SupersetExerciseLog.fromJson(e);
        } else {
          return NormalExerciseLog.fromJson(e);
        }
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

abstract class WorkoutExerciseLog {
  String id;
  String type;
  String tag;
  String style;

  WorkoutExerciseLog({
    required this.id,
    required this.type,
    required this.tag,
    required this.style,
  });

  Map<String, dynamic> toJson();
}

class NormalExerciseLog extends WorkoutExerciseLog {
  int exerciseId;
  String exerciseName;
  List<ExerciseSetLog> sets;

  NormalExerciseLog({
    required String id,
    required this.exerciseId,
    required this.exerciseName,
    required String tag,
    required String style,
    required this.sets,
  }) : super(
          id: id,
          type: 'normal',
          tag: tag,
          style: style,
        );

  factory NormalExerciseLog.fromJson(Map<String, dynamic> json) {
    return NormalExerciseLog(
      id: json['id'],
      exerciseId: json['exercise_id'],
      exerciseName: json['exercise_name'],
      tag: json['tag'],
      style: json['style'],
      sets: (json['sets'] as List)
          .map((s) => ExerciseSetLog.fromJson(s))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'tag': tag,
      'style': style,
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }
}

class SupersetExerciseLog extends WorkoutExerciseLog {
  List<SupersetItemLog> exercises;

  SupersetExerciseLog({
    required String id,
    required String tag,
    required String style,
    required this.exercises,
  }) : super(
          id: id,
          type: 'superset',
          tag: tag,
          style: style,
        );

  factory SupersetExerciseLog.fromJson(Map<String, dynamic> json) {
    return SupersetExerciseLog(
      id: json['id'],
      tag: json['tag'],
      style: json['style'],
      exercises: (json['exercises'] as List)
          .map((e) => SupersetItemLog.fromJson(e))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'tag': tag,
      'style': style,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class SupersetItemLog {
  int exerciseId;
  String exerciseName;
  List<ExerciseSetLog> sets;

  SupersetItemLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  factory SupersetItemLog.fromJson(Map<String, dynamic> json) {
    return SupersetItemLog(
      exerciseId: json['exercise_id'],
      exerciseName: json['exercise_name'],
      sets: (json['sets'] as List)
          .map((s) => ExerciseSetLog.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }
}

class ExerciseSetLog {
  int? reps;
  int? seconds;
  double? weight;

  ExerciseSetLog({
    this.reps,
    this.seconds,
    this.weight,
  });

  factory ExerciseSetLog.fromJson(Map<String, dynamic> json) {
    return ExerciseSetLog(
      reps: json['reps'],
      seconds: json['seconds'],
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (reps != null) data['reps'] = reps;
    if (seconds != null) data['seconds'] = seconds;
    if (weight != null) data['weight'] = weight;

    return data;
  }
}
