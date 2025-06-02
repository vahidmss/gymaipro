class ExerciseComment {
  final String id;
  final String userId;
  final int exerciseId;
  final String comment;
  final String profileName; // User's display name
  final String? profileAvatar; // User's avatar URL
  final DateTime createdAt;
  final DateTime updatedAt;

  ExerciseComment({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.comment,
    required this.profileName,
    this.profileAvatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExerciseComment.fromJson(Map<String, dynamic> json) {
    return ExerciseComment(
      id: json['id'],
      userId: json['user_id'],
      exerciseId: json['exercise_id'],
      comment: json['comment'],
      profileName: json['profile_name'] ?? 'کاربر',
      profileAvatar: json['profile_avatar'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exercise_id': exerciseId,
      'comment': comment,
      'profile_name': profileName,
      'profile_avatar': profileAvatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // For new comments that haven't been saved yet
  factory ExerciseComment.create({
    required String userId,
    required int exerciseId,
    required String comment,
    required String profileName,
    String? profileAvatar,
  }) {
    final now = DateTime.now();
    return ExerciseComment(
      id: '', // Will be assigned by Supabase
      userId: userId,
      exerciseId: exerciseId,
      comment: comment,
      profileName: profileName,
      profileAvatar: profileAvatar,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseComment &&
        other.id == id &&
        other.userId == userId &&
        other.exerciseId == exerciseId &&
        other.comment == comment &&
        other.profileName == profileName &&
        other.profileAvatar == profileAvatar &&
        other.createdAt.isAtSameMomentAs(createdAt) &&
        other.updatedAt.isAtSameMomentAs(updatedAt);
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        exerciseId,
        comment,
        profileName,
        profileAvatar,
        createdAt,
        updatedAt,
      );
}
