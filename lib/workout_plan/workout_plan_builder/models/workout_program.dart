import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    debugPrint('Unable to format ID as UUID: $e');
  }

  // If all else fails, generate a new UUID
  return const Uuid().v4();
}

// Main workout program class
class WorkoutProgram {
  WorkoutProgram({
    required this.name,
    required this.sessions,
    String? id,
    this.userId,
    this.trainerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = _normalizeUuid(id),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) {
    // اطمینان از اینکه فیلدهای ضروری وجود دارند
    final String id = _normalizeUuid(json['id']);
    final String name = (json['program_name'] as String?) ?? 'برنامه جدید';
    final List<dynamic> rawSessions = (json['sessions'] as List?) ?? const [];
    final String? userId = json['user_id'] as String?;
    final String? trainerId = json['trainer_id'] as String?;

    // پارس کردن تاریخ‌ها با استفاده از DateTime.parse و try-catch برای جلوگیری از خطا
    DateTime createdAt;
    DateTime updatedAt;

    try {
      if (json['created_at'] is String) {
        createdAt = DateTime.parse(json['created_at'] as String);
      } else if (json['created_at'] is DateTime) {
        createdAt = json['created_at'] as DateTime;
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      debugPrint('خطا در پارس تاریخ ایجاد: $e');
      createdAt = DateTime.now();
    }

    try {
      if (json['updated_at'] is String) {
        updatedAt = DateTime.parse(json['updated_at'] as String);
      } else if (json['updated_at'] is DateTime) {
        updatedAt = json['updated_at'] as DateTime;
      } else {
        updatedAt = DateTime.now();
      }
    } catch (e) {
      debugPrint('خطا در پارس تاریخ بروزرسانی: $e');
      updatedAt = DateTime.now();
    }

    // پارس کردن سشن‌ها
    final List<WorkoutSession> sessions = rawSessions.map<WorkoutSession>((
      sessionJson,
    ) {
      try {
        return WorkoutSession.fromJson(sessionJson as Map<String, dynamic>);
      } catch (e) {
        debugPrint('خطا در پارس سشن: $e');
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

  // Create an empty program with 7 sessions (days)
  factory WorkoutProgram.empty() {
    return WorkoutProgram(
      name: 'برنامه جدید',
      sessions: List.generate(
        7,
        (index) => WorkoutSession(day: 'روز ${index + 1}', exercises: []),
      ),
    );
  }
  String id;
  String name;
  List<WorkoutSession> sessions;
  String? userId; // User who owns this program
  String?
  trainerId; // Trainer who created this program for a client (if applicable)
  DateTime createdAt;
  DateTime updatedAt;

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
  // توضیحات تکمیلی و نکات کلی روز تمرینی

  WorkoutSession({
    required this.day,
    required this.exercises,
    String? id,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    // اطمینان از اینکه فیلدهای ضروری وجود دارند
    final String id = (json['id'] as String?) ?? const Uuid().v4();
    final String day = (json['day'] as String?) ?? 'روز جدید';
    final String? notes = json['notes'] as String?;
    final List<dynamic> rawExercises = (json['exercises'] as List?) ?? const [];

    // پارس کردن تمرین‌ها با مدیریت خطا
    final List<WorkoutExercise> exercises = [];

    for (final e in rawExercises) {
      try {
        final Map<String, dynamic> map = e as Map<String, dynamic>;
        final String type = map['type']?.toString() ?? '';

        if (type == 'normal') {
          exercises.add(NormalExercise.fromJson(map));
        } else if (type == 'superset') {
          exercises.add(SupersetExercise.fromJson(map));
        } else if (type == 'triset') {
          exercises.add(TrisetExercise.fromJson(map));
        } else {
          debugPrint('نوع تمرین ناشناخته: $type');
        }
      } catch (e) {
        debugPrint('خطا در پارس تمرین: $e');
      }
    }

    return WorkoutSession(id: id, day: day, exercises: exercises, notes: notes);
  }

  // Create an empty session
  factory WorkoutSession.empty() {
    return WorkoutSession(day: 'Day 1', exercises: []);
  }
  String id;
  String day;
  List<WorkoutExercise> exercises;
  String? notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      if (notes != null) 'notes': notes,
    };
  }

  // Copy with method
  WorkoutSession copyWith({
    String? id,
    String? day,
    List<WorkoutExercise>? exercises,
    String? notes,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      day: day ?? this.day,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }
}

// Base class for all exercise types
abstract class WorkoutExercise {
  WorkoutExercise({
    required this.type,
    required this.tag,
    required this.style,
    String? id,
  }) : id = id ?? const Uuid().v4();
  String id;
  ExerciseType type;
  String tag;
  ExerciseStyle style;

  Map<String, dynamic> toJson();
}

// Normal exercise (single exercise)
class NormalExercise extends WorkoutExercise {
  NormalExercise({
    required this.exerciseId,
    required super.tag,
    required super.style,
    required this.sets,
    super.id,
    this.note,
  }) : super(type: ExerciseType.normal);

  factory NormalExercise.fromJson(Map<String, dynamic> json) {
    return NormalExercise(
      id: json['id'] as String?,
      exerciseId: json['exercise_id'] is int
          ? json['exercise_id'] as int
          : int.tryParse(json['exercise_id']?.toString() ?? '0') ?? 0,
      tag: (json['tag'] as String?) ?? '',
      style: json['style'] == 'sets_reps'
          ? ExerciseStyle.setsReps
          : ExerciseStyle.setsTime,
      sets: ((json['sets'] as List?) ?? const [])
          .map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
    );
  }
  int exerciseId;
  List<ExerciseSet> sets;
  String? note;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'normal',
      'exercise_id': exerciseId,
      'tag': tag,
      'style': style == ExerciseStyle.setsReps ? 'sets_reps' : 'sets_time',
      'sets': sets.map((set) => set.toJson()).toList(),
      if (note != null) 'note': note,
    };
  }
}

// Superset exercise (two exercises)
class SupersetExercise extends WorkoutExercise {
  SupersetExercise({
    required this.exercises,
    required super.tag,
    required super.style,
    super.id,
    this.note,
  }) : super(type: ExerciseType.superset);

  factory SupersetExercise.fromJson(Map<String, dynamic> json) {
    return SupersetExercise(
      id: json['id'] as String?,
      tag: (json['tag'] as String?) ?? '',
      style: json['style'] == 'sets_reps'
          ? ExerciseStyle.setsReps
          : ExerciseStyle.setsTime,
      exercises: ((json['exercises'] as List?) ?? const [])
          .map((e) => SupersetItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
    );
  }
  List<SupersetItem> exercises;
  String? note;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'superset',
      'tag': tag,
      'style': style == ExerciseStyle.setsReps ? 'sets_reps' : 'sets_time',
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      if (note != null) 'note': note,
    };
  }
}

// Triset exercise (three exercises)
class TrisetExercise extends WorkoutExercise {
  TrisetExercise({
    required this.exercises,
    required super.tag,
    required super.style,
    super.id,
  }) : super(type: ExerciseType.triset);

  factory TrisetExercise.fromJson(Map<String, dynamic> json) {
    return TrisetExercise(
      id: json['id'] as String?,
      tag: (json['tag'] as String?) ?? '',
      style: json['style'] == 'sets_reps'
          ? ExerciseStyle.setsReps
          : ExerciseStyle.setsTime,
      exercises: ((json['exercises'] as List?) ?? const [])
          .map((e) => SupersetItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  List<SupersetItem> exercises;

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
  // Add individual style for each exercise

  SupersetItem({
    required this.exerciseId,
    required this.sets,
    required this.style,
  });

  factory SupersetItem.fromJson(Map<String, dynamic> json) {
    return SupersetItem(
      exerciseId: json['exercise_id'] is int
          ? json['exercise_id'] as int
          : int.tryParse(json['exercise_id']?.toString() ?? '0') ?? 0,
      sets: ((json['sets'] as List?) ?? const [])
          .map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      style: json['style'] == 'sets_time'
          ? ExerciseStyle.setsTime
          : ExerciseStyle.setsReps,
    );
  }
  int exerciseId;
  List<ExerciseSet> sets;
  ExerciseStyle style;

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'sets': sets.map((set) => set.toJson()).toList(),
      'style': style == ExerciseStyle.setsReps ? 'sets_reps' : 'sets_time',
    };
  }
}

// Exercise set with reps/time and weight
class ExerciseSet {
  ExerciseSet({this.reps, this.timeSeconds, this.weight});

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      reps: json['reps'] is int
          ? json['reps'] as int?
          : int.tryParse(json['reps']?.toString() ?? ''),
      timeSeconds: json['time_seconds'] is int
          ? json['time_seconds'] as int?
          : int.tryParse(json['time_seconds']?.toString() ?? ''),
      weight: json['weight'] != null
          ? (json['weight'] is num
                ? (json['weight'] as num).toDouble()
                : double.tryParse(json['weight'].toString()))
          : null,
    );
  }
  int? reps;
  int? timeSeconds;
  double? weight;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (reps != null) data['reps'] = reps;
    if (timeSeconds != null) data['time_seconds'] = timeSeconds;
    if (weight != null) data['weight'] = weight;

    return data;
  }
}

// Exercise type enum
enum ExerciseType { normal, superset, triset }

// Exercise style enum
enum ExerciseStyle { setsReps, setsTime }

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
