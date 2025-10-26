import 'package:gymaipro/models/comment_reaction.dart';

class ExerciseComment {
  ExerciseComment({
    required this.id,
    required this.exerciseId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.rating,
    this.parentId,
    this.isEdited = false,
    this.username,
    this.userAvatar,
    this.userFullName,
    this.reactions = const [],
  });

  factory ExerciseComment.fromJson(Map<String, dynamic> json) {
    return ExerciseComment(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      rating: json['rating'] as int?,
      parentId: json['parent_id'] as String?,
      isEdited: (json['is_edited'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      username: json['username'] as String?,
      userAvatar: json['user_avatar'] as String?,
      userFullName: json['user_full_name'] as String?,
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map((r) => CommentReaction.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  final String id;
  final String exerciseId;
  final String userId;
  final String content;
  final int? rating;
  final String? parentId;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? username;
  final String? userAvatar;
  final String? userFullName;
  final List<CommentReaction> reactions;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'user_id': userId,
      'content': content,
      'rating': rating,
      'parent_id': parentId,
      'is_edited': isEdited,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'username': username,
      'user_avatar': userAvatar,
      'user_full_name': userFullName,
      'reactions': reactions.map((r) => r.toJson()).toList(),
    };
  }

  // Helper methods
  bool get hasRating => rating != null;
  bool get hasReactions => reactions.isNotEmpty;
  int get likeCount => reactions.where((r) => r.reactionType == 'like').length;
  int get heartCount =>
      reactions.where((r) => r.reactionType == 'heart').length;
  int get dislikeCount =>
      reactions.where((r) => r.reactionType == 'dislike').length;

  // Check if current user has reacted
  bool hasUserReaction(String userId, String reactionType) {
    return reactions.any(
      (r) => r.userId == userId && r.reactionType == reactionType,
    );
  }
}
