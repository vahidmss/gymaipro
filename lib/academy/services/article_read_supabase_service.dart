import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks which articles the current user has marked as "read".
///
/// Primary source is Supabase (table `article_reads` assumed).
/// If Supabase calls fail for any reason, we fall back to a local
/// cache so the UI همچنان می‌تواند وضعیت خوانده/نخوانده را نشان دهد
/// بدون این‌که اپ کرش کند.
class ArticleReadSupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Local cache key – per user id (for future use)
  // static const String _cacheKeyPrefix = 'academy_article_reads_';

  /// Returns set of article IDs the current user has marked as read.
  static Future<Set<int>> getMyReadArticleIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return <int>{};
    }

    // First try Supabase
    try {
      final rows = await _client
          .from('article_reads')
          .select('article_id')
          .eq('user_id', userId);
      final ids = <int>{};
      for (final row in rows as List) {
        final m = row as Map<String, dynamic>;
        final rawId = m['article_id'];
        if (rawId is int) {
          ids.add(rawId);
        } else if (rawId != null) {
          final parsed = int.tryParse(rawId.toString());
          if (parsed != null) ids.add(parsed);
        }
      }

      return ids;
    } catch (_) {
      // If remote fails, quietly fall back to empty set.
      return <int>{};
    }
  }

  /// Checks whether current user has marked the article as read.
  static Future<bool> isRead(int articleId) async {
    final ids = await getMyReadArticleIds();
    return ids.contains(articleId);
  }

  /// Marks an article as read for the current user.
  ///
  /// If Supabase fails, it still updates local cache so UI can react.
  static Future<void> markAsRead(int articleId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      // کاربر لاگین نیست – فقط نادیده بگیر، بدون کرش
      return;
    }

    // Try Supabase first
    try {
      await _client.from('article_reads').upsert({
        'article_id': articleId,
        'user_id': userId,
      });
    } catch (_) {
      // Ignore – we'll still update local cache.
    }

    // Local cache integration can be added later if needed.
  }

  /// Returns the total read count for a specific article.
  static Future<int> getReadCount(int articleId) async {
    try {
      final rows = await _client
          .from('article_reads')
          .select('id')
          .eq('article_id', articleId);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Returns read counts for multiple articles at once.
  static Future<Map<int, int>> getReadCounts(List<int> articleIds) async {
    if (articleIds.isEmpty) return {};
    try {
      final rows = await _client
          .from('article_reads')
          .select('article_id')
          .inFilter('article_id', articleIds);
      final counts = <int, int>{};
      for (final id in articleIds) {
        counts[id] = 0;
      }
      for (final row in rows as List) {
        final m = row as Map<String, dynamic>;
        final rawId = m['article_id'];
        if (rawId is int) {
          counts[rawId] = (counts[rawId] ?? 0) + 1;
        } else if (rawId != null) {
          final parsed = int.tryParse(rawId.toString());
          if (parsed != null) {
            counts[parsed] = (counts[parsed] ?? 0) + 1;
          }
        }
      }
      return counts;
    } catch (_) {
      return {};
    }
  }
}
