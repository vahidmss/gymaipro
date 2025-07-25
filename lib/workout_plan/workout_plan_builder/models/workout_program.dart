import 'package:uuid/uuid.dart';

// Utility function to ensure UUID is formatted properly
String _normalizeUuid(dynamic id) {
  if (id == null) {
    return const Uuid().v4();
  }

  final String idStr = id.toString();

  // If it's already a valid UUID, return it
  if (idStr.length == 36 && idStr.contains('-')) {
    return idStr;
  }

  // Try to format it as a UUID if possible
  try {
    // If it's a different format (without dashes), try to add them
    if (idStr.length == 32) {
      return '${idStr.substring(0, 8)}-${idStr.substring(8, 12)}-${idStr.substring(12, 16)}-${idStr.substring(16, 20)}-${idStr.substring(20)}';
    }
  } catch (e) {
    print('Unable to format ID as UUID: $e');
  }

  // If all else fails, generate a new UUID
  return const Uuid().v4();
}

// Main workout program class
class WorkoutProgram {
  String id;
  String name;
  List<WorkoutSession> sessions;
  String? userId; // User who owns this program
  String?
      trainerId; // Trainer who created this program for a client (if applicable)
  DateTime createdAt;
  DateTime updatedAt;

  WorkoutProgram({
    String? id,
    required this.name,
    required this.sessions,
    this.userId,
    this.trainerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = _normalizeUuid(id),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) {
    // اطمینان از اینکه فیلدهای ضروری وجود دارند
    final id = _normalizeUuid(json['id']);
    final name = json['program_name'] ?? 'برنامه جدید';
    final List<dynamic> rawSessions = json['sessions'] ?? [];
    final userId = json['user_id'];
    final trainerId = json['trainer_id'];

    // پارس کردن تاریخ‌ها با استفاده از DateTime.parse و try-catch برای جلوگیری از خطا
    DateTime createdAt;
    DateTime updatedAt;

    try {
      createdAt = json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : DateTime.now();
    } catch (e) {
      print('خطا در پارس تاریخ ایجاد: $e');
      createdAt = DateTime.now();
    }

    try {
      updatedAt = json['updated_at'] is String
          ? DateTime.parse(json['updated_at'])
          : DateTime.now();
    } catch (e) {
      print('خطا در پارس تاریخ بروزرسانی: $e');
      updatedAt = DateTime.now();
    }

    // پارس کردن سشن‌ها
    final List<WorkoutSession> sessions =
        rawSessions.map<WorkoutSession>((sessionJson) {
      try {
        return WorkoutSession.fromJson(sessionJson);
      } catch (e) {
        print('خطا در پارس سشن: $e');
        // اگر سشن با خطا مواجه شد، یک سشن خالی ایجاد می‌کنیم
        return WorkoutSession.empty();
      }
    }).toList();

    // اگر هیچ سشنی وجود نداشت، یک سشن خالی اضافه کنیم
    if (sessions.isEmpty) {
      sessions.add(WorkoutSession.empty());
    }

    return WorkoutProgram(
      id: id,
      name: name,
      sessions: sessions,
      userId: userId,
      trainerId: trainerId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'program_name': name,
      'sessions': sessions.map((session) => session.toJson()).toList(),
      'user_id': userId,
      'trainer_id': trainerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Create an empty program with one empty session
  factory WorkoutProgram.empty() {
    return WorkoutProgram(
      name: "برنامه جدید",
      sessions: [WorkoutSession.empty()],
    );
  }

  // Copy with method
  WorkoutProgram copyWith({
    String? id,
    String? name,
    List<WorkoutSession>? sessions,
    String? userId,
    String? trainerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      sessions: sessions ?? this.sessions,
      userId: userId ?? this.userId,
      trainerId: trainerId ?? this.trainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Workout session (e.g., Day 1, Day 2)
class WorkoutSession {
  String id;
  String day;
  List<WorkoutExercise> exercises;

  WorkoutSession({
    String? id,
    required this.day,
    required this.exercises,
  }) : id = id ?? const Uuid().v4();

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    // اطمینان از اینکه فیلدهای ضروری وجود دارند
    final id = json['id'] ?? const Uuid().v4();
    final day = json['day'] ?? "روز جدید";
    final List<dynamic> rawExercises = json['exercises'] ?? [];

    // پارس کردن تمرین‌ها با مدیریت خطا
    List<WorkoutExercise> exercises = [];

    for (var e in rawExercises) {
      try {
        final type = e['type']?.toString() ?? '';

        if (type == 'normal') {
          exercises.add(NormalExercise.fromJson(e));
        } else if (type == 'superset') {
          exercises.add(SupersetExercise.fromJson(e));
        } else if (type == 'triset') {
          exercises.add(TrisetExercise.fromJson(e));
        } else {
          print('نوع تمرین ناشناخته: $type');
        }
      } catch (e) {
        print('خطا در پارس تمرین: $e');
        // ادامه دادن به تمرین بعدی در صورت خطا
      }
    }

    return WorkoutSession(
      id: id,
      day: day,
      exercises: exercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }

  // Create an empty session
  factory WorkoutSession.empty() {
    return WorkoutSession(
      day: "Day 1",
      exercises: [],
    );
  }
}

// Base class for all exercise types
abstract class WorkoutExercise {
  String id;
  ExerciseType type;
  String tag;
  ExerciseStyle style;

  WorkoutExercise({
    String? id,
    required this.type,
    required this.tag,
    required this.style,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson();
}

// Normal exercise (single exercise)
class NormalExercise extends WorkoutExercise {
  int exerciseId;
  List<ExerciseSet> sets;

  NormalExercise({
    String? id,
    required this.exerciseId,
    required String tag,
    required ExerciseStyle style,
    required this.sets,
  }) : super(
          id: id,
          type: ExerciseType.normal,
          tag: tag,
          style: style,
        );

  factory NormalExercise.fromJson(Map<String, dynamic> json) {
    return NormalExercise(
      id: json['id'],
      exerciseId: json['exercise_id'],
      tag: json['tag'],
      style: json['style'] == 'sets_reps'
          ? ExerciseStyle.setsReps
          : ExerciseStyle.setsTime,
      sets: (json['sets'] as List).map((e) => ExerciseSet.fromJson(e)).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'normal',
      'exercise_id': exerciseId,
      'tag': tag,
      'style': style == ExerciseStyle.setsReps ? 'sets_reps' : 'sets_time',
      'sets': sets.map((set) => set.toJson()).toList(),
    };
  }
}

// Superset exercise (two exercises)
class SupersetExercise extends WorkoutExercise {
  List<SupersetItem> exercises;

  SupersetExercise({
    String? id,
    required this.exercises,
    required String tag,
    required ExerciseStyle style,
  }) : super(
          id: id,
          type: ExerciseType.superset,
          tag: tag,
          style: style,
        );

  factory SupersetExercise.fromJson(Map<String, dynamic> json) {
    return SupersetExercise(
      id: json['id'],
      tag: json['tag'],
      style: json['style'] == 'sets_reps'
          ? ExerciseStyle.setsReps
          : ExerciseStyle.setsTime,
      exercises: (json['exercises'] as List)
          .map((e) => SupersetItem.fromJson(e))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'superset',
      'tag': tag,
      'style': style == ExerciseStyle.setsReps ? 'sets_reps' : 'sets_time',
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }
}

// Triset exercise (three exercises)
class TrisetExercise extends WorkoutExercise {
  List<SupersetItem> exercises;

  TrisetExercise({
    String? id,
    required this.exercises,
    required String tag,
    required ExerciseStyle style,
  }) : super(
          id: id,
          type: ExerciseType.triset,
          tag: tag,
          style: style,
        );

  factory TrisetExercise.fromJson(Map<String, dynamic> json) {
    return TrisetExercise(
      id: json['id'],
      tag: json['tag'],
      style: json['style'] == 'sets_reps'
          ? ExerciseStyle.setsReps
          : ExerciseStyle.setsTime,
      exercises: (json['exercises'] as List)
          .map((e) => SupersetItem.fromJson(e))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'triset',
      'tag': tag,
      'style': style == ExerciseStyle.setsReps ? 'sets_reps' : 'sets_time',
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }
}

// Item in a superset or triset
class SupersetItem {
  int exerciseId;
  List<ExerciseSet> sets;

  SupersetItem({
    required this.exerciseId,
    required this.sets,
  });

  factory SupersetItem.fromJson(Map<String, dynamic> json) {
    return SupersetItem(
      exerciseId: json['exercise_id'],
      sets: (json['sets'] as List).map((e) => ExerciseSet.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'sets': sets.map((set) => set.toJson()).toList(),
    };
  }
}

// Exercise set with reps/time and weight
class ExerciseSet {
  int? reps;
  int? timeSeconds;
  double? weight;

  ExerciseSet({
    this.reps,
    this.timeSeconds,
    this.weight,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      reps: json['reps'],
      timeSeconds: json['time_seconds'],
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (reps != null) data['reps'] = reps;
    if (timeSeconds != null) data['time_seconds'] = timeSeconds;
    if (weight != null) data['weight'] = weight;

    return data;
  }
}

// Exercise type enum
enum ExerciseType {
  normal,
  superset,
  triset,
}

// Exercise style enum
enum ExerciseStyle {
  setsReps,
  setsTime,
}

// Common muscle tags
class MuscleTags {
  static const List<String> availableTags = [
    'سینه',
    'پشت',
    'پا',
    'سرشانه',
    'بازو',
    'ساعد',
    'شکم',
    'سرینی',
    'کاردیو',
    'کل بدن',
  ];
}
