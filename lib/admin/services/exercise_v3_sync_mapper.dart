import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/network/wordpress_http.dart';

/// دریافت و ادغام خروجی `gymai/v3/exercises` (v3.6-patched) در ردیف Supabase.
class ExerciseV3SyncMapper {
  static String get _listUrl =>
      '${AppConfig.wordpressApiOrigin}/wp-json/gymai/v3/exercises';

  /// همه آیتم‌های v3 را بر اساس id برمی‌گرداند.
  static Future<Map<int, Map<String, dynamic>>> fetchAllById() async {
    final out = <int, Map<String, dynamic>>{};
    var page = 1;
    var totalPages = 1;

    while (page <= totalPages && page <= 50) {
      final uri = Uri.parse('$_listUrl?per_page=100&page=$page');
      try {
        final response = await wordpressGet(
          uri,
          headers: {'Content-Type': 'application/json'},
          timeout: const Duration(seconds: 30),
        );
        if (response.statusCode != 200) {
          if (kDebugMode) {
            debugPrint('[V3Sync] list page $page HTTP ${response.statusCode}');
          }
          break;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) break;

        totalPages = (decoded['total_pages'] as num?)?.toInt() ?? 1;
        final items = decoded['items'];
        if (items is! List) break;

        for (final raw in items) {
          if (raw is! Map<String, dynamic>) continue;
          final id = (raw['id'] as num?)?.toInt();
          if (id != null && id > 0) out[id] = raw;
        }

        page++;
        if (items.isEmpty) break;
      } catch (e) {
        if (kDebugMode) debugPrint('[V3Sync] page $page error: $e');
        break;
      }
    }

    if (kDebugMode) {
      debugPrint('[V3Sync] loaded ${out.length} items from gymai/v3');
    }
    return out;
  }

  /// ادغام فیلدهای v3 روی map آمادهٔ upsert (مقادیر v3 اولویت دارند).
  static void applyToSupabaseRow(
    Map<String, dynamic> row,
    Map<String, dynamic> v3,
  ) {
    final description = _map(v3['description']);
    final classification = _map(v3['classification']);
    final metrics = _map(v3['metrics']);
    final stats = _map(v3['stats']);
    final media = _map(v3['media']);
    final programming = _map(v3['programming']);
    final instructions = _map(v3['instructions']);
    final safety = _map(v3['safety']);
    final seo = _map(v3['seo']);

    _setIfNonEmpty(row, 'name', v3['name_app'] ?? v3['title']);
    _setIfNonEmpty(row, 'short_description', description?['short']);
    _setIfNonEmpty(row, 'detailed_description', description?['detailed']);
    _setIfNonEmpty(row, 'seo_content', seo?['content']);

    if (classification != null) {
      _setIfNonEmpty(row, 'main_muscle', classification['main_muscle']);
      _setIfNonEmpty(
        row,
        'secondary_muscles',
        _joinLabels(
          classification['secondary_muscle_labels'],
          classification['secondary_muscles'],
        ),
      );
      _setIfNonEmpty(row, 'target_area', classification['target_area']);
      _setIfNonEmpty(
        row,
        'difficulty',
        classification['difficulty_label'] ?? classification['difficulty'],
      );
      _setIfNonEmpty(
        row,
        'equipment',
        _joinLabels(
          classification['equipment_labels'],
          classification['equipment'],
        ),
      );
      _setIfNonEmpty(
        row,
        'exercise_type',
        classification['exercise_type_label'] ?? classification['exercise_type'],
      );
      _setIfNonEmpty(row, 'movement_pattern', classification['movement_pattern']);
      _setIfNonEmpty(row, 'body_engagement', classification['body_engagement']);
      _setIfNonEmpty(
        row,
        'estimated_1rm_formula',
        metrics?['estimated_1rm_formula'] ?? classification['estimated_1rm_formula'],
      );
    }

    final targets = v3['muscle_targets'];
    if (targets is Map && targets.isNotEmpty) {
      row['muscle_targets_json'] = Map<String, dynamic>.from(targets);
    }

    if (metrics != null) {
      _setNum(row, 'met', metrics['met']);
      _setInt(row, 'movement_distance_cm', metrics['movement_distance_cm']);
      _setInt(row, 'calories_per_1000kg', metrics['calories_per_1000kg']);
      _setInt(row, 'exercise_difficulty_score', metrics['exercise_difficulty_score']);
      _setNum(row, 'typical_rpe', metrics['typical_rpe']);
    }

    if (stats != null) {
      _setInt(row, 'views_count', stats['views_count']);
      _setInt(row, 'likes_count', stats['likes_count']);
    }

    if (media != null) {
      _setIfNonEmpty(row, 'image_url', media['image_url'] ?? media['thumbnail_url']);
      _setIfNonEmpty(row, 'video_url', media['video_url']);
    }

    final aliases = v3['aliases'];
    if (aliases is List && aliases.isNotEmpty) {
      row['other_names'] = aliases.whereType<String>().toList();
    }

    final tips = v3['tips'];
    if (tips is List &&
        tips.isNotEmpty &&
        (row['tips'] == null || (row['tips'] as List).isEmpty)) {
      row['tips'] = tips.whereType<String>().toList();
    }

    final learn = _buildLearnContent(instructions, description);
    if (learn.isNotEmpty) {
      row['learn'] = learn;
      if (_str(row['content']).isEmpty) row['content'] = learn;
    }

    final modified = v3['updated_at']?.toString();
    if (modified != null && modified.isNotEmpty) {
      row['wordpress_modified'] =
          DateTime.tryParse(modified)?.toIso8601String() ?? modified;
    }

    final slug = (v3['slug_decoded'] ?? v3['slug'] ?? '').toString().trim();
    row['exercise_extended_json'] = _buildExtendedJson(
      classification: classification,
      programming: programming,
      instructions: instructions,
      safety: safety,
      v3Version: v3['version'] ?? v3['_normalization'],
      slug: slug,
    );

    final sourceRaw = row['source'];
    Map<String, dynamic> source = {};
    if (sourceRaw is String && sourceRaw.isNotEmpty) {
      try {
        final d = jsonDecode(sourceRaw);
        if (d is Map<String, dynamic>) source = d;
      } catch (_) {}
    } else if (sourceRaw is Map<String, dynamic>) {
      source = Map<String, dynamic>.from(sourceRaw);
    }
    source['v3_version'] = 'gymai/v3.6';
    source['v3_id'] = v3['id'];
    row['source'] = jsonEncode(source);
  }

  static Map<String, dynamic> _buildExtendedJson({
    Map<String, dynamic>? classification,
    Map<String, dynamic>? programming,
    Map<String, dynamic>? instructions,
    Map<String, dynamic>? safety,
    dynamic v3Version,
    String slug = '',
  }) {
    final ext = <String, dynamic>{};
    if (slug.isNotEmpty) {
      ext['slug'] = slug;
    }
    if (classification != null && classification.isNotEmpty) {
      ext['classification'] = classification;
    }
    if (programming != null && programming.isNotEmpty) {
      ext['programming'] = programming;
    }
    if (instructions != null && instructions.isNotEmpty) {
      ext['instructions'] = instructions;
    }
    if (safety != null && safety.isNotEmpty) {
      ext['safety'] = safety;
    }
    if (v3Version != null) {
      ext['sync_note'] = v3Version;
    }
    return ext;
  }

  static String _buildLearnContent(
    Map<String, dynamic>? instructions,
    Map<String, dynamic>? description,
  ) {
    if (instructions == null) return '';
    final parts = <String>[];
    void addSection(String title, dynamic block) {
      if (block is! List || block.isEmpty) return;
      final lines = block.whereType<String>().where((s) => s.trim().isNotEmpty);
      if (lines.isEmpty) return;
      parts.add('$title:\n${lines.join('\n')}');
    }

    addSection('آماده‌سازی', instructions['setup']);
    addSection('اجرا', instructions['execution']);
    final breathing = instructions['breathing']?.toString().trim() ?? '';
    if (breathing.isNotEmpty) parts.add('تنفس: $breathing');
    if (parts.isNotEmpty) return parts.join('\n\n');
    return description?['detailed']?.toString().trim() ?? '';
  }

  static Map<String, dynamic>? _map(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static String _str(dynamic v) => v?.toString().trim() ?? '';

  static void _setIfNonEmpty(Map<String, dynamic> row, String key, dynamic value) {
    final s = _str(value);
    if (s.isNotEmpty) row[key] = s;
  }

  static void _setNum(Map<String, dynamic> row, String key, dynamic value) {
    if (value == null) return;
    final n = value is num ? value : num.tryParse(value.toString());
    if (n != null) row[key] = n;
  }

  static void _setInt(Map<String, dynamic> row, String key, dynamic value) {
    if (value == null) return;
    final n = value is num ? value.round() : int.tryParse(value.toString());
    if (n != null) row[key] = n;
  }

  static String _joinLabels(dynamic labels, dynamic keys) {
    if (labels is List && labels.isNotEmpty) {
      return labels.whereType<String>().join('، ');
    }
    if (keys is List && keys.isNotEmpty) {
      return keys.map((e) => e.toString()).join('، ');
    }
    return '';
  }

  /// تبدیل muscle_targets به Map برای jsonb (با fallback از Exercise).
  static Map<String, dynamic> resolveMuscleTargetsJson({
    required Map<String, dynamic> metaMap,
    required Map<String, int> exerciseTargets,
  }) {
    final mtRaw = metaMap['muscle_targets_json'] ?? metaMap['muscle_targets'];
    final parsed = MuscleTargets.parse(mtRaw);
    if (parsed.isNotEmpty) {
      return parsed.map(MapEntry.new);
    }
    if (exerciseTargets.isNotEmpty) {
      return exerciseTargets.map(MapEntry.new);
    }
    return {};
  }
}
