class Workout {
  final String id;
  final String name;
  final String description;
  final List<Exercise> exercises;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.exercises,
    required this.createdAt,
    this.updatedAt,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class Exercise {
  final String id;
  final String name;
  final String description;
  final String muscleGroup;
  final String equipment;
  final String difficulty;
  final List<String> instructions;
  final List<String> tips;
  final List<String> imageUrls;
  final String? videoUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    required this.instructions,
    required this.tips,
    required this.imageUrls,
    this.videoUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      muscleGroup: json['muscle_group'] as String,
      equipment: json['equipment'] as String,
      difficulty: json['difficulty'] as String,
      instructions: (json['instructions'] as List<dynamic>).cast<String>(),
      tips: (json['tips'] as List<dynamic>).cast<String>(),
      imageUrls: (json['image_urls'] as List<dynamic>).cast<String>(),
      videoUrl: json['video_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'difficulty': difficulty,
      'instructions': instructions,
      'tips': tips,
      'image_urls': imageUrls,
      'video_url': videoUrl,
    };
  }
}

class WorkoutSet {
  final String id;
  final String exerciseId;
  final int reps;
  final double weight;
  final int restSeconds;
  final DateTime createdAt;

  WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.reps,
    required this.weight,
    required this.restSeconds,
    required this.createdAt,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      restSeconds: json['rest_seconds'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'reps': reps,
      'weight': weight,
      'rest_seconds': restSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class WorkoutLog {
  final String id;
  final String workoutId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutSet> sets;
  final String? notes;

  WorkoutLog({
    required this.id,
    required this.workoutId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.sets,
    this.notes,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'] as String,
      workoutId: json['workout_id'] as String,
      userId: json['user_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      sets: (json['sets'] as List<dynamic>)
          .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_id': workoutId,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'sets': sets.map((e) => e.toJson()).toList(),
      'notes': notes,
    };
  }
}
