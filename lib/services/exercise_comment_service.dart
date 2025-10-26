import 'package:gymaipro/models/comment_reaction.dart';
import 'package:gymaipro/models/exercise_comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseCommentService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get comments for an exercise
  static Future<List<ExerciseComment>> getExerciseComments(
    String exerciseId,
  ) async {
    try {
      final response = await _supabase
          .from('exercise_comments')
          .select('''
            *,
            comment_reactions(*)
          ''')
          .eq('exercise_id', exerciseId)
          .order('created_at', ascending: false);

      final List<ExerciseComment> comments = [];
      for (final commentData in response) {
        // Get user profile info
        final userProfile = await _getUserProfile(
          commentData['user_id'] as String,
        );

        // Parse reactions
        final List<CommentReaction> reactions = [];
        if (commentData['comment_reactions'] != null) {
          for (final reactionData
              in commentData['comment_reactions'] as List<dynamic>) {
            reactions.add(
              CommentReaction.fromJson(reactionData as Map<String, dynamic>),
            );
          }
        }

        // Create comment with user info
        final comment = ExerciseComment(
          id: commentData['id'] as String,
          exerciseId: commentData['exercise_id'] as String,
          userId: commentData['user_id'] as String,
          content: commentData['content'] as String,
          rating: commentData['rating'] as int?,
          parentId: commentData['parent_id'] as String?,
          isEdited: (commentData['is_edited'] as bool?) ?? false,
          createdAt: DateTime.parse(commentData['created_at'] as String),
          updatedAt: DateTime.parse(commentData['updated_at'] as String),
          username: userProfile['username'] as String?,
          userAvatar: userProfile['avatar_url'] as String?,
          userFullName: userProfile['full_name'] as String?,
          reactions: reactions,
        );

        comments.add(comment);
      }

      return comments;
    } catch (e) {
      print('خطا در دریافت نظرات: $e');
      return [];
    }
  }

  // Add new comment
  static Future<ExerciseComment?> addComment({
    required String exerciseId,
    required String content,
    int? rating,
    String? parentId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('exercise_comments')
          .insert({
            'exercise_id': exerciseId,
            'user_id': user.id,
            'content': content,
            'rating': rating,
            'parent_id': parentId,
          })
          .select()
          .single();

      // Get user profile info
      final userProfile = await _getUserProfile(user.id);

      return ExerciseComment(
        id: response['id'] as String,
        exerciseId: response['exercise_id'] as String,
        userId: response['user_id'] as String,
        content: response['content'] as String,
        rating: response['rating'] as int?,
        parentId: response['parent_id'] as String?,
        isEdited: (response['is_edited'] as bool?) ?? false,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
        username: userProfile['username'] as String?,
        userAvatar: userProfile['avatar_url'] as String?,
        userFullName: userProfile['full_name'] as String?,
        reactions: [],
      );
    } catch (e) {
      print('خطا در افزودن نظر: $e');
      return null;
    }
  }

  // Update comment
  static Future<bool> updateComment({
    required String commentId,
    required String content,
    int? rating,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('exercise_comments')
          .update({'content': content, 'rating': rating, 'is_edited': true})
          .eq('id', commentId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('خطا در بروزرسانی نظر: $e');
      return false;
    }
  }

  // Delete comment
  static Future<bool> deleteComment(String commentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('exercise_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('خطا در حذف نظر: $e');
      return false;
    }
  }

  // Add reaction to comment
  static Future<bool> addReaction({
    required String commentId,
    required String reactionType,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('comment_reactions').upsert({
        'comment_id': commentId,
        'user_id': user.id,
        'reaction_type': reactionType,
      });

      return true;
    } catch (e) {
      print('خطا در افزودن واکنش: $e');
      return false;
    }
  }

  // Remove reaction from comment
  static Future<bool> removeReaction({
    required String commentId,
    required String reactionType,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('comment_reactions')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', user.id)
          .eq('reaction_type', reactionType);

      return true;
    } catch (e) {
      print('خطا در حذف واکنش: $e');
      return false;
    }
  }

  // Get user profile info
  static Future<Map<String, dynamic>> _getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('username, avatar_url, full_name')
          .eq('id', userId)
          .single();

      return {
        'username': response['username'] ?? 'کاربر',
        'avatar_url': response['avatar_url'],
        'full_name': response['full_name'] ?? response['username'] ?? 'کاربر',
      };
    } catch (e) {
      return {'username': 'کاربر', 'avatar_url': null, 'full_name': 'کاربر'};
    }
  }
}
