import 'package:gymaipro/academy/models/professional_bodybuilder.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfessionalBodybuilderService {
  static const String _tableName = 'professional_bodybuilders';
  static const String _cacheKey = 'academy_professional_bodybuilders';
  static const Duration _cacheExpiry = Duration(hours: 1);

  static Future<List<ProfessionalBodybuilder>> fetchBodybuilders({
    String? category,
    bool forceRefresh = false,
  }) async {
    // Check cache
    if (!forceRefresh) {
      final lastUpdate = await CacheService.getUpdatedAt(_cacheKey);
      if (lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < _cacheExpiry) {
        final cachedData = await CacheService.getJsonList(_cacheKey);
        if (cachedData != null) {
          var bodybuilders = cachedData
              .cast<Map<String, dynamic>>()
              .map(ProfessionalBodybuilder.fromJson)
              .toList();
          if (category != null) {
            bodybuilders =
                bodybuilders.where((b) => b.category == category).toList();
          }
          return bodybuilders;
        }
      }
    }

    try {
      var query = Supabase.instance.client
          .from(_tableName)
          .select();

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query.order('created_at', ascending: false);

      final bodybuilders = (response as List)
          .map((json) => ProfessionalBodybuilder.fromJson(
              json as Map<String, dynamic>))
          .toList();

      // Cache
      if (category == null) {
        final jsonData = bodybuilders.map((b) => b.toJson()).toList();
        await CacheService.setJson(_cacheKey, jsonData);
      }

      return bodybuilders;
    } catch (e) {
      // Fallback to cache if available
      final cachedData = await CacheService.getJsonList(_cacheKey);
      if (cachedData != null) {
        var bodybuilders = cachedData
            .cast<Map<String, dynamic>>()
            .map(ProfessionalBodybuilder.fromJson)
            .toList();
        if (category != null) {
          bodybuilders =
              bodybuilders.where((b) => b.category == category).toList();
        }
        return bodybuilders;
      }
      throw Exception('Failed to load bodybuilders: $e');
    }
  }

  static Future<ProfessionalBodybuilder?> fetchBodybuilderById(int id) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      return ProfessionalBodybuilder.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    await CacheService.clear(_cacheKey);
  }
}

