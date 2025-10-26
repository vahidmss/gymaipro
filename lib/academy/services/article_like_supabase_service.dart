import 'package:supabase_flutter/supabase_flutter.dart';

class ArticleLikeSupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<({bool liked, int likeCount})> getState(int articleId) async {
    final userId = _client.auth.currentUser?.id;

    // like count
    final countRes = await _client
        .from('article_like_counts')
        .select('like_count')
        .eq('article_id', articleId)
        .maybeSingle();
    int likeCount = 0;
    bool liked = false;
    if (countRes is Map<String, dynamic>) {
      final raw = countRes['like_count'];
      if (raw is int) likeCount = raw;
      if (raw is num) likeCount = raw.toInt();
      if (raw is String) likeCount = int.tryParse(raw) ?? 0;
    } else if (countRes is List || countRes == null) {
      final List<dynamic> list =
          (countRes as List<dynamic>?) ?? const <dynamic>[];
      if (list.isEmpty) {
        // continue to check liked state
      } else {
        final row = list.first;
        if (row is Map<String, dynamic>) {
          final raw = row['like_count'];
          if (raw is int) likeCount = raw;
          if (raw is num) likeCount = raw.toInt();
          if (raw is String) likeCount = int.tryParse(raw) ?? 0;
        }
      }
    }

    // liked by current user?
    liked = false;
    if (userId != null) {
      final exists = await _client
          .from('article_likes')
          .select('id')
          .eq('article_id', articleId)
          .eq('user_id', userId)
          .maybeSingle();
      liked = exists != null;
    }

    return (liked: liked, likeCount: likeCount);
  }

  static Future<({bool liked, int likeCount})> toggle(int articleId) async {
    try {
      final builder = _client.rpc<dynamic>(
        'toggle_article_like',
        params: {'p_article_id': articleId},
      );
      final dynamic res = await builder.single();
      if (res != null) {
        final map = res as Map<String, dynamic>;
        final likedRaw = map['liked'];
        final countRaw = map['like_count'];
        final liked = likedRaw is bool
            ? likedRaw
            : (likedRaw is num
                  ? likedRaw != 0
                  : (likedRaw?.toString() == 'true'));
        final likeCount = () {
          if (countRaw is int) return countRaw;
          if (countRaw is num) return countRaw.toInt();
          if (countRaw is String) return int.tryParse(countRaw) ?? 0;
          return 0;
        }();
        return (liked: liked, likeCount: likeCount);
      }
      // fallthrough to manual toggle
    } catch (_) {
      // Fallback if RPC is not available: toggle directly in tables
    }
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    final existing = await _client
        .from('article_likes')
        .select('id')
        .eq('article_id', articleId)
        .eq('user_id', userId);
    bool liked;
    if (existing.isNotEmpty) {
      // unlike
      await _client
          .from('article_likes')
          .delete()
          .eq('article_id', articleId)
          .eq('user_id', userId);
      liked = false;
    } else {
      // like
      await _client.from('article_likes').insert({
        'article_id': articleId,
        'user_id': userId,
      });
      liked = true;
    }
    // recount
    final rows = await _client
        .from('article_likes')
        .select('id')
        .eq('article_id', articleId);
    final likeCount = rows.length;
    return (liked: liked, likeCount: likeCount);
  }
}
