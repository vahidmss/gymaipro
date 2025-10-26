import 'dart:convert';

import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:http/http.dart' as http;

class ArticleService {
  static const String _baseUrl =
      'https://gymaipro.ir/wp-json/wp/v2/coaches-article?_embed=true';
  static const String _cacheKey = 'academy_articles';
  static const Duration _cacheExpiry = Duration(minutes: 15);

  static Future<List<Article>> fetchArticles({
    int page = 1,
    int perPage = 20,
    bool forceRefresh = false,
  }) async {
    // Check cache for first page only
    if (page == 1 && !forceRefresh) {
      final lastUpdate = await CacheService.getUpdatedAt(_cacheKey);
      if (lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < _cacheExpiry) {
        final cachedData = await CacheService.getJsonList(_cacheKey);
        if (cachedData != null) {
          return cachedData
              .cast<Map<String, dynamic>>()
              .map(Article.fromJson)
              .toList();
        }
      }
    }

    final uri = Uri.parse('$_baseUrl&per_page=$perPage&page=$page');
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded =
          json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      final articles = Article.listFromWordPress(decoded);

      // Cache first page
      if (page == 1) {
        final jsonData = articles.map((article) => article.toJson()).toList();
        await CacheService.setJson(_cacheKey, jsonData);
      }

      return articles;
    }
    throw Exception('Failed to load articles: ${response.statusCode}');
  }

  static Future<Article> fetchArticleById(int id) async {
    final uri = Uri.parse(
      'https://gymaipro.ir/wp-json/wp/v2/coaches-article/$id?_embed=true',
    );
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return Article.fromWordPressJson(decoded);
    }
    throw Exception('Failed to load article $id: ${response.statusCode}');
  }

  // Clear cache manually
  static Future<void> clearCache() async {
    await CacheService.clear(_cacheKey);
  }
}
