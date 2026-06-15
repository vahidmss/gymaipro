import 'package:flutter/foundation.dart';
import 'package:gymaipro/models/comment_reaction.dart';
import 'package:gymaipro/models/exercise_comment.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _CommentAuthor {
  const _CommentAuthor({
    required this.displayName,
    this.username,
    this.avatarUrl,
  });

  factory _CommentAuthor.fromProfileRow(Map<String, dynamic> row) {
    final first = (row['first_name'] as String?)?.trim() ?? '';
    final last = (row['last_name'] as String?)?.trim() ?? '';
    final username = (row['username'] as String?)?.trim();
    final combined = '$first $last'.trim();

    String displayName;
    if (combined.isNotEmpty) {
      displayName = combined;
    } else if (username != null && username.isNotEmpty) {
      displayName = username;
    } else {
      displayName = 'کاربر';
    }

    return _CommentAuthor(
      displayName: displayName,
      username: username,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  final String displayName;
  final String? username;
  final String? avatarUrl;

  static const fallback = _CommentAuthor(displayName: 'کاربر');
}

class ExerciseCommentService {
  static final SupabaseClient _supabase = Supabase.instance.client;

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

      final rows = List<Map<String, dynamic>>.from(response as List);
      final userIds = rows
          .map((r) => (r['user_id'] as String?)?.trim())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      final authors = await _loadAuthorsForUserIds(userIds);

      final comments = <ExerciseComment>[];
      for (final commentData in rows) {
        final userId = commentData['user_id'] as String;
        final author = authors[userId] ?? _CommentAuthor.fallback;

        final reactions = <CommentReaction>[];
        final rawReactions = commentData['comment_reactions'];
        if (rawReactions is List) {
          for (final reactionData in rawReactions) {
            reactions.add(
              CommentReaction.fromJson(
                Map<String, dynamic>.from(reactionData as Map),
              ),
            );
          }
        }

        comments.add(
          ExerciseComment(
            id: commentData['id'] as String,
            exerciseId: commentData['exercise_id'] as String,
            userId: userId,
            content: commentData['content'] as String,
            rating: commentData['rating'] as int?,
            parentId: commentData['parent_id'] as String?,
            isEdited: (commentData['is_edited'] as bool?) ?? false,
            createdAt: DateTime.parse(commentData['created_at'] as String),
            updatedAt: DateTime.parse(commentData['updated_at'] as String),
            username: author.username,
            userAvatar: author.avatarUrl,
            userFullName: author.displayName,
            reactions: reactions,
          ),
        );
      }

      return comments;
    } catch (e) {
      // ignore: avoid_print
      print('خطا در دریافت نظرات: $e');
      return [];
    }
  }

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

      final authors = await _loadAuthorsForUserIds({user.id});
      final author = authors[user.id] ?? _CommentAuthor.fallback;

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
        username: author.username,
        userAvatar: author.avatarUrl,
        userFullName: author.displayName,
        reactions: [],
      );
    } catch (e) {
      // ignore: avoid_print
      print('خطا در افزودن نظر: $e');
      return null;
    }
  }

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
      // ignore: avoid_print
      print('خطا در بروزرسانی نظر: $e');
      return false;
    }
  }

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
      // ignore: avoid_print
      print('خطا در حذف نظر: $e');
      return false;
    }
  }

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
      // ignore: avoid_print
      print('خطا در افزودن واکنش: $e');
      return false;
    }
  }

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
      // ignore: avoid_print
      print('خطا در حذف واکنش: $e');
      return false;
    }
  }

  /// `exercise_comments.user_id` = auth.users.id — پروفایل با auth_user_id یا id.
  static Future<Map<String, _CommentAuthor>> _loadAuthorsForUserIds(
    Set<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    const select =
        'id, auth_user_id, first_name, last_name, username, avatar_url';
    final out = <String, _CommentAuthor>{};

    try {
      final rows = await UserProfileService.fetchProfilesByIdentifiers(
        userIds.toList(),
        columns: select,
      );

      for (final row in rows) {
        final authId = (row['auth_user_id'] as String?)?.trim();
        final id = (row['id'] as String?)?.trim();
        if (authId != null && authId.isNotEmpty && userIds.contains(authId)) {
          out[authId] = _CommentAuthor.fromProfileRow(row);
        } else if (id != null && id.isNotEmpty && userIds.contains(id)) {
          out[id] = _CommentAuthor.fromProfileRow(row);
        }
      }
    } catch (e) {
      debugPrint('خطا در بارگذاری پروفایل نویسندگان کامنت: $e');
    }

    return out;
  }
}
