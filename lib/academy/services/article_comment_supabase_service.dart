import 'package:supabase_flutter/supabase_flutter.dart';

class ArticleCommentSupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> fetchComments(int articleId) async {
    final res = await _client
        .from('article_comments')
        .select(
          'id, article_id, user_id, author_name, content, parent_id, created_at',
        )
        .eq('article_id', articleId)
        .order('created_at', ascending: true);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<void> addComment({
    required int articleId,
    required String authorName,
    required String content,
    String? parentId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    await _client.from('article_comments').insert({
      'article_id': articleId,
      'user_id': userId,
      'author_name': authorName,
      'content': content,
      if (parentId != null) 'parent_id': parentId,
    });
  }
}
