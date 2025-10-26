import 'package:supabase_flutter/supabase_flutter.dart';

class ArticleRatingSupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<({double avg, int count, int? my})> getStats(
    int articleId,
  ) async {
    final statsRes = await _client
        .from('article_rating_stats')
        .select('avg_rating, rating_count')
        .eq('article_id', articleId)
        .maybeSingle();
    double avg = 0;
    int count = 0;
    if (statsRes is Map<String, dynamic>) {
      final avgRaw = statsRes['avg_rating'];
      if (avgRaw is num) avg = avgRaw.toDouble();
      if (avgRaw is String) avg = double.tryParse(avgRaw) ?? 0.0;
      final cntRaw = statsRes['rating_count'];
      if (cntRaw is int) count = cntRaw;
      if (cntRaw is num) count = cntRaw.toInt();
      if (cntRaw is String) count = int.tryParse(cntRaw) ?? 0;
    }

    int? my;
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      final row = await _client
          .from('article_ratings')
          .select('rating')
          .eq('article_id', articleId)
          .eq('user_id', userId)
          .maybeSingle();
      if (row is Map<String, dynamic>) {
        final raw = row['rating'];
        if (raw is int) my = raw;
        if (raw is num) my = raw.toInt();
        if (raw is String) my = int.tryParse(raw);
      }
    }

    return (avg: avg, count: count, my: my);
  }

  static Future<({double avg, int count})> upsert(
    int articleId,
    int rating,
  ) async {
    try {
      final builder = _client.rpc<dynamic>(
        'upsert_article_rating',
        params: {'p_article_id': articleId, 'p_rating': rating},
      );
      final dynamic res = await builder.single();
      if (res != null) {
        final map = res as Map<String, dynamic>;
        final avgRaw = map['avg_rating'];
        final cntRaw = map['rating_count'];
        final avg = avgRaw is num
            ? avgRaw.toDouble()
            : (avgRaw is String ? double.tryParse(avgRaw) ?? 0.0 : 0.0);
        final count = cntRaw is int
            ? cntRaw
            : (cntRaw is num
                  ? cntRaw.toInt()
                  : (cntRaw is String ? int.tryParse(cntRaw) ?? 0 : 0));
        return (avg: avg, count: count);
      }
      return (avg: 0.0, count: 0);
    } catch (_) {
      // Fallback without RPC: upsert in table and recalc
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');
      // upsert rating
      final existing = await _client
          .from('article_ratings')
          .select('id')
          .eq('article_id', articleId)
          .eq('user_id', userId);
      if (existing.isNotEmpty) {
        await _client
            .from('article_ratings')
            .update({'rating': rating})
            .eq('article_id', articleId)
            .eq('user_id', userId);
      } else {
        await _client.from('article_ratings').insert({
          'article_id': articleId,
          'user_id': userId,
          'rating': rating,
        });
      }
      // recalc stats
      final rows = await _client
          .from('article_ratings')
          .select('rating')
          .eq('article_id', articleId);
      if (rows.isNotEmpty) {
        double sum = 0;
        for (final r in rows) {
          final val = (r['rating'] as num?)?.toDouble() ?? 0.0;
          sum += val;
        }
        final avg = sum / rows.length;
        final count = rows.length;
        return (avg: avg, count: count);
      }
      return (avg: 0.0, count: 0);
    }
  }
}
