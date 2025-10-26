import 'package:gymaipro/academy/services/article_like_supabase_service.dart';
import 'package:gymaipro/academy/services/article_rating_supabase_service.dart';

class ArticleStatsCacheService {
  static const Duration _cacheExpiry = Duration(minutes: 10);

  // Cache for article stats
  static final Map<int, ArticleStats> _statsCache = {};
  static DateTime? _lastCacheTime;

  static bool get _isCacheValid {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheExpiry;
  }

  // Get stats for a single article
  static Future<ArticleStats> getArticleStats(int articleId) async {
    // Check cache first
    if (_isCacheValid && _statsCache.containsKey(articleId)) {
      return _statsCache[articleId]!;
    }

    // Load from database
    try {
      final likeState = await ArticleLikeSupabaseService.getState(articleId);
      final rating = await ArticleRatingSupabaseService.getStats(articleId);

      final stats = ArticleStats(
        likeCount: likeState.likeCount,
        avgRating: rating.avg,
        ratingCount: rating.count,
      );

      // Cache the result
      _statsCache[articleId] = stats;
      _lastCacheTime = DateTime.now();

      return stats;
    } catch (e) {
      // Return default stats on error
      return ArticleStats(likeCount: 0, avgRating: 0, ratingCount: 0);
    }
  }

  // Load stats for multiple articles at once
  static Future<Map<int, ArticleStats>> loadMultipleStats(
    List<int> articleIds,
  ) async {
    final Map<int, ArticleStats> results = {};

    // Check cache for existing stats
    for (final id in articleIds) {
      if (_isCacheValid && _statsCache.containsKey(id)) {
        results[id] = _statsCache[id]!;
      }
    }

    // Find articles that need loading
    final articlesToLoad = articleIds
        .where((id) => !results.containsKey(id))
        .toList();

    if (articlesToLoad.isNotEmpty) {
      try {
        // Load all stats in parallel
        final futures = articlesToLoad.map(_loadSingleStats);
        final stats = await Future.wait(futures);

        for (int i = 0; i < articlesToLoad.length; i++) {
          final articleId = articlesToLoad[i];
          final statsData = stats[i];
          results[articleId] = statsData;
          _statsCache[articleId] = statsData;
        }

        _lastCacheTime = DateTime.now();
      } catch (e) {
        // Fill with default stats for failed articles
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

  // Clear cache
  static void clearCache() {
    _statsCache.clear();
    _lastCacheTime = null;
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
}
