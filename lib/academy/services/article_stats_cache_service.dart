import 'package:gymaipro/academy/services/article_like_supabase_service.dart';
import 'package:gymaipro/academy/services/article_rating_supabase_service.dart';

class ArticleStatsCacheService {
  static const Duration _cacheExpiry = Duration(minutes: 10);

  // Cache for article stats
  static final Map<int, ArticleStats> _statsCache = {};
  static final Map<int, DateTime> _entryTimes = {};

  static bool _isEntryValid(int articleId) {
    final t = _entryTimes[articleId];
    if (t == null) return false;
    return DateTime.now().difference(t) < _cacheExpiry;
  }

  /// Get stats for a single article.
  /// [forceRefresh] bypasses cache (e.g. after like/rating on detail).
  static Future<ArticleStats> getArticleStats(
    int articleId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _isEntryValid(articleId) &&
        _statsCache.containsKey(articleId)) {
      return _statsCache[articleId]!;
    }

    try {
      final likeState = await ArticleLikeSupabaseService.getState(articleId);
      final rating = await ArticleRatingSupabaseService.getStats(articleId);

      final stats = ArticleStats(
        likeCount: likeState.likeCount,
        avgRating: rating.avg,
        ratingCount: rating.count,
      );

      put(articleId, stats);
      return stats;
    } catch (e) {
      return ArticleStats(likeCount: 0, avgRating: 0, ratingCount: 0);
    }
  }

  /// Load stats for multiple articles at once
  static Future<Map<int, ArticleStats>> loadMultipleStats(
    List<int> articleIds, {
    bool forceRefresh = false,
  }) async {
    final Map<int, ArticleStats> results = {};

    if (!forceRefresh) {
      for (final id in articleIds) {
        if (_isEntryValid(id) && _statsCache.containsKey(id)) {
          results[id] = _statsCache[id]!;
        }
      }
    }

    final articlesToLoad = articleIds
        .where((id) => !results.containsKey(id))
        .toList();

    if (articlesToLoad.isNotEmpty) {
      try {
        final futures = articlesToLoad.map(_loadSingleStats);
        final stats = await Future.wait(futures);

        for (int i = 0; i < articlesToLoad.length; i++) {
          final articleId = articlesToLoad[i];
          final statsData = stats[i];
          results[articleId] = statsData;
          put(articleId, statsData);
        }
      } catch (e) {
        for (final id in articlesToLoad) {
          if (!results.containsKey(id)) {
            results[id] = ArticleStats(
              likeCount: 0,
              avgRating: 0,
              ratingCount: 0,
            );
          }
        }
      }
    }

    return results;
  }

  static Future<ArticleStats> _loadSingleStats(int articleId) async {
    try {
      final likeState = await ArticleLikeSupabaseService.getState(articleId);
      final rating = await ArticleRatingSupabaseService.getStats(articleId);

      return ArticleStats(
        likeCount: likeState.likeCount,
        avgRating: rating.avg,
        ratingCount: rating.count,
      );
    } catch (e) {
      return ArticleStats(likeCount: 0, avgRating: 0, ratingCount: 0);
    }
  }

  /// Write/update cached stats (e.g. right after like toggle).
  static void put(int articleId, ArticleStats stats) {
    _statsCache[articleId] = stats;
    _entryTimes[articleId] = DateTime.now();
  }

  /// Drop one article so next read hits the network.
  static void invalidate(int articleId) {
    _statsCache.remove(articleId);
    _entryTimes.remove(articleId);
  }

  static void clearCache() {
    _statsCache.clear();
    _entryTimes.clear();
  }
}

class ArticleStats {
  ArticleStats({
    required this.likeCount,
    required this.avgRating,
    required this.ratingCount,
  });
  final int likeCount;
  final double avgRating;
  final int ratingCount;

  ArticleStats copyWith({
    int? likeCount,
    double? avgRating,
    int? ratingCount,
  }) {
    return ArticleStats(
      likeCount: likeCount ?? this.likeCount,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}
