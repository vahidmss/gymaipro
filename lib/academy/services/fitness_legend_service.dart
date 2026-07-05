import 'dart:convert';

import 'package:gymaipro/academy/models/fitness_legend.dart';
import 'package:gymaipro/network/wordpress_http.dart';
import 'package:gymaipro/utils/cache_service.dart';

class FitnessLegendService {
  static const String _baseUrl =
      'https://gymaipro.ir/wp-json/wp/v2/fitness_legends?_embed=true';
  static const String _cacheKey = 'academy_fitness_legends';
  static const Duration _cacheExpiry = Duration(minutes: 15);

  static Future<List<FitnessLegend>> fetchLegends({
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
              .map(FitnessLegend.fromJson)
              .toList();
        }
      }
    }

    final uri = Uri.parse('$_baseUrl&per_page=$perPage&page=$page');
    final response = await wordpressGet(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded =
          json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      final legends = FitnessLegend.listFromWordPress(decoded);

      // Cache first page
      if (page == 1) {
        final jsonData = legends.map((legend) => legend.toJson()).toList();
        await CacheService.setJson(_cacheKey, jsonData);
      }

      return legends;
    }
    throw Exception('Failed to load legends: ${response.statusCode}');
  }

  static Future<FitnessLegend> fetchLegendById(int id) async {
    final uri = Uri.parse(
      'https://gymaipro.ir/wp-json/wp/v2/fitness_legends/$id?_embed=true',
    );
    final response = await wordpressGet(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return FitnessLegend.fromWordPressJson(decoded);
    }
    throw Exception('Failed to load legend $id: ${response.statusCode}');
  }

  // Clear cache manually
  static Future<void> clearCache() async {
    await CacheService.clear(_cacheKey);
  }
}
