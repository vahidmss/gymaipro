import 'package:uuid/uuid.dart';

class WorkoutDailyLog {
  WorkoutDailyLog({
    required this.userId,
    required this.logDate,
    required this.sessions,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory WorkoutDailyLog.fromJson(Map<String, dynamic> json) {
    return WorkoutDailyLog(
      id: (json['id'] as String?) ?? _uuid.v4(),
      userId: (json['user_id'] as String?) ?? '',
      logDate: json['log_date'] is String
          ? DateTime.parse(json['log_date'] as String)
          : (json['log_date'] is DateTime
                ? json['log_date'] as DateTime
                : DateTime.now()),
      sessions: ((json['sessions'] as List?) ?? const [])
          .map((s) => WorkoutSessionLog.fromJson(s as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : (json['created_at'] is DateTime
                ? json['created_at'] as DateTime
                : DateTime.now()),
      updatedAt: json['updated_at'] is String
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updated_at'] is DateTime
                ? json['updated_at'] as DateTime
                : DateTime.now()),
    );
  }
  static const _uuid = Uuid();
  String id;
  String userId;
  DateTime logDate; // تاریخ روز لاگ
  List<WorkoutSessionLog> sessions;
  DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'log_date': logDate.toIso8601String().substring(0, 10),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class WorkoutSessionLog {
  WorkoutSessionLog({
    required this.id,
    required this.day,
    required this.exercises,
  });

  factory WorkoutSessionLog.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionLog(
      id: (json['id'] as String?) ?? const Uuid().v4(),
      day: (json['day'] as String?) ?? '',
      exercises: ((json['exercises'] as List?) ?? const []).map((e) {
        final map = e as Map<String, dynamic>;
        final String type = map['type']?.toString() ?? '';
        if (type == 'superset') {
          return SupersetExerciseLog.fromJson(map);
        } else {
          return NormalExerciseLog.fromJson(map);
        }
      }).toList(),
    );
  }
  String id;
  String day;
  List<WorkoutExerciseLog> exercises;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

abstract class WorkoutExerciseLog {
  WorkoutExerciseLog({
    required this.id,
    required this.type,
    required this.tag,
    required this.style,
  });
  String id;
  String type;
  String tag;
  String style;

  Map<String, dynamic> toJson();
}

class NormalExerciseLog extends WorkoutExerciseLog {
  // Add note field

  NormalExerciseLog({
    required super.id,
    required this.exerciseId,
    required this.exerciseName,
    required super.tag,
    required super.style,
    required this.sets,
    this.note, // Add note parameter
  }) : super(type: 'normal');

  factory NormalExerciseLog.fromJson(Map<String, dynamic> json) {
    return NormalExerciseLog(
      id: (json['id'] as String?) ?? const Uuid().v4(),
      exerciseId: json['exercise_id'] is int
          ? json['exercise_id'] as int
          : int.tryParse(json['exercise_id']?.toString() ?? '0') ?? 0,
      exerciseName: (json['exercise_name'] as String?) ?? '',
      tag: (json['tag'] as String?) ?? '',
      style: (json['style'] as String?) ?? 'sets_reps',
      sets: ((json['sets'] as List?) ?? const [])
          .map((s) => ExerciseSetLog.fromJson(s as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
    );
  }
  int exerciseId;
  String exerciseName;
  List<ExerciseSetLog> sets;
  String? note;

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
      if (note != null) 'note': note, // Include note in JSON if not null
    };
  }
}

class SupersetExerciseLog extends WorkoutExerciseLog {
  // Add note field

  SupersetExerciseLog({
    required super.id,
    required super.tag,
    required super.style,
    required this.exercises,
    this.note, // Add note parameter
  }) : super(type: 'superset');

  factory SupersetExerciseLog.fromJson(Map<String, dynamic> json) {
    return SupersetExerciseLog(
      id: (json['id'] as String?) ?? const Uuid().v4(),
      tag: (json['tag'] as String?) ?? '',
      style: (json['style'] as String?) ?? 'sets_reps',
      exercises: ((json['exercises'] as List?) ?? const [])
          .map((e) => SupersetItemLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
    );
  }
  List<SupersetItemLog> exercises;
  String? note;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'tag': tag,
      'style': style,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      if (note != null) 'note': note, // Include note in JSON if not null
    };
  }
}

class SupersetItemLog {
  SupersetItemLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  factory SupersetItemLog.fromJson(Map<String, dynamic> json) {
    return SupersetItemLog(
      exerciseId: json['exercise_id'] is int
          ? json['exercise_id'] as int
          : int.tryParse(json['exercise_id']?.toString() ?? '0') ?? 0,
      exerciseName: (json['exercise_name'] as String?) ?? '',
      sets: ((json['sets'] as List?) ?? const [])
          .map((s) => ExerciseSetLog.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
  int exerciseId;
  String exerciseName;
  List<ExerciseSetLog> sets;

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }
}

class ExerciseSetLog {
  ExerciseSetLog({this.reps, this.seconds, this.weight});

  factory ExerciseSetLog.fromJson(Map<String, dynamic> json) {
    return ExerciseSetLog(
      reps: json['reps'] is int
          ? json['reps'] as int?
          : int.tryParse(json['reps']?.toString() ?? ''),
      seconds: json['seconds'] is int
          ? json['seconds'] as int?
          : int.tryParse(json['seconds']?.toString() ?? ''),
      weight: json['weight'] != null
          ? (json['weight'] is num
                ? (json['weight'] as num).toDouble()
                : double.tryParse(json['weight'].toString()))
          : null,
    );
  }
  int? reps;
  int? seconds;
  double? weight;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (reps != null) data['reps'] = reps;
    if (seconds != null) data['seconds'] = seconds;
    if (weight != null) data['weight'] = weight;

    return data;
  }
}
