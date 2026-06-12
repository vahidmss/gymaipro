import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/trainer_channel/constants/trainer_channel_constants.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel_post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _CacheEntry<T> {
  _CacheEntry(this.value, this.at);
  final T value;
  final DateTime at;
}

/// Supabase access for trainer channels. Short in-memory TTL reduces duplicate calls.
class TrainerChannelService {
  TrainerChannelService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const Duration _cacheTtl = Duration(seconds: 45);
  static final Map<String, _CacheEntry<TrainerChannel?>> _channelByTrainer =
      {};
  static final Map<String, _CacheEntry<int>> _postCountByChannel = {};
  static final Map<String, _CacheEntry<List<TrainerChannelPost>>> _postsByTrainer =
      {};

  static void invalidateCacheForTrainer(String trainerId) {
    _channelByTrainer.remove(trainerId);
    _postsByTrainer.remove(trainerId);
    _postsByTrainer.remove('$trainerId:owner');
  }

  static void invalidateCacheForChannel(String channelId) {
    _postCountByChannel.remove(channelId);
    _channelByTrainer.clear();
    _postsByTrainer.clear();
  }

  static void clearAllCaches() {
    _channelByTrainer.clear();
    _postCountByChannel.clear();
    _postsByTrainer.clear();
  }

  T? _readCache<T>(Map<String, _CacheEntry<T>> map, String key) {
    final entry = map[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > _cacheTtl) {
      map.remove(key);
      return null;
    }
    return entry.value;
  }

  void _writeCache<T>(Map<String, _CacheEntry<T>> map, String key, T value) {
    map[key] = _CacheEntry(value, DateTime.now());
  }

  Future<TrainerChannel?> getChannelByTrainerId(
    String trainerId, {
    bool includeStats = true,
  }) async {
    if (!includeStats) {
      return _fetchChannelRow(trainerId);
    }

    final entry = _channelByTrainer[trainerId];
    if (entry != null &&
        DateTime.now().difference(entry.at) <= _cacheTtl) {
      return entry.value;
    }

    try {
      final channel = await _fetchChannelRow(trainerId);
      if (channel == null) {
        _writeCache(_channelByTrainer, trainerId, null);
        return null;
      }
      final count = await getActivePostCount(channel.id);
      final enriched = TrainerChannel(
        id: channel.id,
        trainerId: channel.trainerId,
        isEnabled: channel.isEnabled,
        createdAt: channel.createdAt,
        updatedAt: channel.updatedAt,
        postCount: count,
        lastPostAt: await _getLastPostAt(channel.id),
      );
      _writeCache(_channelByTrainer, trainerId, enriched);
      return enriched;
    } catch (e) {
      debugPrint('TrainerChannelService.getChannelByTrainerId: $e');
      rethrow;
    }
  }

  Future<TrainerChannel?> _fetchChannelRow(String trainerId) async {
    final row = await _client
        .from('trainer_channels')
        .select()
        .eq('trainer_id', trainerId)
        .maybeSingle();
    if (row == null) return null;
    return TrainerChannel.fromMap(row);
  }

  Future<bool> isChannelVisibleToPublic(String trainerId) async {
    final ch = await getChannelByTrainerId(trainerId);
    return ch != null && ch.isEnabled && ch.postCount > 0;
  }

  Future<int> getActivePostCount(String channelId) async {
    final cached = _readCache(_postCountByChannel, channelId);
    if (cached != null) return cached;

    final res = await _client
        .from('trainer_channel_posts')
        .select('id')
        .eq('channel_id', channelId)
        .eq('is_deleted', false)
        .count();
    final count = res.count;
    _writeCache(_postCountByChannel, channelId, count);
    return count;
  }

  Future<int> getTodayPostCount(String channelId) async {
    final now = DateTime.now();
    final startOfDayLocal = DateTime(now.year, now.month, now.day);
    final startUtc = startOfDayLocal.toUtc().toIso8601String();

    final res = await _client
        .from('trainer_channel_posts')
        .select('id')
        .eq('channel_id', channelId)
        .eq('is_deleted', false)
        .gte('created_at', startUtc)
        .count();
    return res.count;
  }

  Future<int> remainingPostsToday(String channelId) async {
    final today = await getTodayPostCount(channelId);
    final left = TrainerChannelConstants.maxPostsPerDay - today;
    return left < 0 ? 0 : left;
  }

  Future<DateTime?> _getLastPostAt(String channelId) async {
    final row = await _client
        .from('trainer_channel_posts')
        .select('created_at')
        .eq('channel_id', channelId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return DateTime.tryParse(row['created_at']?.toString() ?? '');
  }

  Future<List<TrainerChannelPost>> getPosts({
    required String trainerId,
    int limit = TrainerChannelConstants.feedPageSize,
    bool includeWhenDisabledForOwner = false,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        includeWhenDisabledForOwner ? '$trainerId:owner' : trainerId;
    if (!forceRefresh) {
      final cached = _readCache(_postsByTrainer, cacheKey);
      if (cached != null) return List<TrainerChannelPost>.from(cached);
    }

    final channel = await getChannelByTrainerId(trainerId);
    if (channel == null) {
      return [];
    }

    if (!channel.isEnabled) {
      if (!includeWhenDisabledForOwner) {
        return [];
      }
      final profile = await SimpleProfileService.getCurrentProfile();
      final myId = profile?['id']?.toString();
      if (myId != trainerId) {
        return [];
      }
    }

    final rows = await _client
        .from('trainer_channel_posts')
        .select()
        .eq('channel_id', channel.id)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(limit);

    final profile = await _client
        .from('profiles')
        .select('first_name, last_name, username, avatar_url')
        .eq('id', trainerId)
        .maybeSingle();

    String? trainerName;
    if (profile != null) {
      final fn = profile['first_name']?.toString() ?? '';
      final ln = profile['last_name']?.toString() ?? '';
      trainerName = '$fn $ln'.trim();
      if (trainerName.isEmpty) {
        trainerName = profile['username']?.toString();
      }
    }

    final posts = <TrainerChannelPost>[];
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      map['trainer_name'] = trainerName;
      map['trainer_avatar_url'] = profile?['avatar_url'];
      map['trainer_username'] = profile?['username'];
      posts.add(TrainerChannelPost.fromMap(map));
    }

    _writeCache(_postsByTrainer, cacheKey, posts);
    return posts;
  }

  Future<TrainerChannel> ensureChannelForCurrentTrainer() async {
    final profile = await SimpleProfileService.getCurrentProfile();
    if (profile == null) {
      throw Exception('پروفایل یافت نشد');
    }
    final trainerId = profile['id']?.toString();
    if (trainerId == null || trainerId.isEmpty) {
      throw Exception('شناسه کاربر نامعتبر است');
    }
    final role = profile['role']?.toString();
    if (role != 'trainer' && role != 'admin') {
      throw Exception('فقط مربیان می‌توانند کانال داشته باشند');
    }

    final existing = await getChannelByTrainerId(trainerId);
    if (existing != null) return existing;

    final inserted = await _client
        .from('trainer_channels')
        .insert({'trainer_id': trainerId, 'is_enabled': false})
        .select()
        .single();

    invalidateCacheForTrainer(trainerId);
    return TrainerChannel.fromMap(inserted);
  }

  Future<void> setChannelEnabled({
    required String channelId,
    required bool enabled,
    String? trainerId,
  }) async {
    await _client
        .from('trainer_channels')
        .update({
          'is_enabled': enabled,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', channelId);
    invalidateCacheForChannel(channelId);
    if (trainerId != null) {
      invalidateCacheForTrainer(trainerId);
    }
  }

  Future<TrainerChannelPost> createPost({
    required String channelId,
    required String trainerId,
    required TrainerChannelContentType contentType,
    String? textContent,
    String? mediaUrl,
    int? mediaDurationSeconds,
  }) async {
    final todayCount = await getTodayPostCount(channelId);
    if (todayCount >= TrainerChannelConstants.maxPostsPerDay) {
      throw Exception(
        'امروز به سقف ${TrainerChannelConstants.maxPostsPerDay} پست رسیده‌اید. '
        'فردا می‌توانید دوباره منتشر کنید.',
      );
    }

    final trimmedText = textContent?.trim();
    if (contentType == TrainerChannelContentType.text &&
        (trimmedText == null || trimmedText.isEmpty)) {
      throw Exception('متن پست نمی‌تواند خالی باشد');
    }
    if (contentType != TrainerChannelContentType.text &&
        (mediaUrl == null || mediaUrl.trim().isEmpty)) {
      throw Exception('فایل رسانه برای این پست لازم است');
    }
    if (trimmedText != null &&
        trimmedText.length > TrainerChannelConstants.maxTextLength) {
      throw Exception(
        'متن پست حداکثر ${TrainerChannelConstants.maxTextLength} کاراکتر می‌تواند باشد',
      );
    }

    final payload = <String, dynamic>{
      'channel_id': channelId,
      'trainer_id': trainerId,
      'content_type': TrainerChannelPost.contentTypeToDb(contentType),
      'text_content': trimmedText,
      'media_url': mediaUrl,
      'media_duration_seconds': mediaDurationSeconds,
    };

    final row = await _client
        .from('trainer_channel_posts')
        .insert(payload)
        .select()
        .single();

    await _client
        .from('trainer_channels')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', channelId);

    invalidateCacheForChannel(channelId);
    invalidateCacheForTrainer(trainerId);

    return TrainerChannelPost.fromMap(row);
  }

  Future<void> deletePost(String postId, {String? trainerId}) async {
    if (postId.startsWith('sending_')) return;

    try {
      final rpcOk = await _client.rpc<bool>(
        'trainer_channel_soft_delete_post',
        params: {'p_post_id': postId},
      );
      if (rpcOk == true) {
        if (trainerId != null) invalidateCacheForTrainer(trainerId);
        return;
      }
    } catch (e) {
      debugPrint('TrainerChannelService.deletePost RPC: $e');
    }

    final profile = await SimpleProfileService.getCurrentProfile();
    final profileId = profile?['id']?.toString();
    final authId = _client.auth.currentUser?.id;

    final ownerIds = <String>{
      if (profileId != null && profileId.isNotEmpty) profileId,
      if (authId != null && authId.isNotEmpty) authId,
    };

    for (final ownerId in ownerIds) {
      try {
        await _client
            .from('trainer_channel_posts')
            .update({
              'is_deleted': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', postId)
            .eq('trainer_id', ownerId)
            .eq('is_deleted', false);
        if (trainerId != null) invalidateCacheForTrainer(trainerId);
        return;
      } catch (e) {
        debugPrint('TrainerChannelService.deletePost fallback ($ownerId): $e');
      }
    }

    throw Exception(
      'حذف انجام نشد. migration جدید را در Supabase اجرا کنید:\n'
      'supabase/migrations/20260521120000_trainer_channel_delete_fix.sql',
    );
  }

  Future<void> updatePostText({
    required String postId,
    required TrainerChannelContentType contentType,
    required String textContent,
    String? trainerId,
  }) async {
    final trimmed = textContent.trim();
    if (contentType == TrainerChannelContentType.text && trimmed.isEmpty) {
      throw Exception('متن پست نمی‌تواند خالی باشد');
    }
    if (trimmed.length > TrainerChannelConstants.maxTextLength) {
      throw Exception(
        'متن حداکثر ${TrainerChannelConstants.maxTextLength} کاراکتر می‌تواند باشد',
      );
    }

    await _client.from('trainer_channel_posts').update({
      'text_content': trimmed.isEmpty ? null : trimmed,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', postId);

    if (trainerId != null) invalidateCacheForTrainer(trainerId);
  }
}
