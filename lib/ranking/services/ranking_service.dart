import 'package:flutter/foundation.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/services/ranking_score_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس اصلی مدیریت رتبه‌بندی کاربران
class RankingService {
  factory RankingService() => _instance;
  RankingService._internal();
  static final RankingService _instance = RankingService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final RankingScoreService _scoreService = RankingScoreService();

  /// به‌روزرسانی رتبه کاربر فعلی
  /// بهینه‌سازی شده: فقط امتیاز کاربر رو به‌روزرسانی می‌کنه، بدون به‌روزرسانی همه رتبه‌ها
  Future<void> updateCurrentUserRanking({bool updateAllRanks = false}) async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId == null) return;

      await _scoreService.updateUserScore(userId);
      
      // فقط اگه لازم باشه همه رتبه‌ها رو به‌روزرسانی کن (مثلاً در background job)
      if (updateAllRanks) {
        await _updateRanks();
      }
    } catch (e) {
      debugPrint('❌ Error updating current user ranking: $e');
    }
  }

  /// به‌روزرسانی رتبه‌های همه کاربران
  Future<void> updateAllRankings() async {
    try {
      // دریافت همه کاربران فعال (آخرین فعالیت در 30 روز گذشته)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final activeUsers = await _client
          .from('profiles')
          .select('id')
          .gte('last_active_at', thirtyDaysAgo.toIso8601String());

      for (final user in activeUsers) {
        final userId = user['id'] as String;
        await _scoreService.updateUserScore(userId);
      }

      await _updateRanks();
    } catch (e) {
      debugPrint('❌ Error updating all rankings: $e');
    }
  }

  /// به‌روزرسانی رتبه‌های global و league
  Future<void> _updateRanks() async {
    try {
      // به‌روزرسانی رتبه‌های global
      await _updateGlobalRanks();

      // به‌روزرسانی رتبه‌های هر لیگ
      for (final league in League.all) {
        await _updateLeagueRanks(league.id);
      }
    } catch (e) {
      debugPrint('❌ Error updating ranks: $e');
    }
  }

  /// به‌روزرسانی رتبه‌های global
  Future<void> _updateGlobalRanks() async {
    try {
      final rankings = await _client
          .from('user_rankings')
          .select('user_id, total_score')
          .order('total_score', ascending: false);

      int rank = 1;
      for (final ranking in rankings) {
        await _client
            .from('user_rankings')
            .update({'global_rank': rank})
            .eq('user_id', ranking['user_id'] as String);
        rank++;
      }
    } catch (e) {
      debugPrint('❌ Error updating global ranks: $e');
    }
  }

  /// به‌روزرسانی رتبه‌های یک لیگ خاص
  Future<void> _updateLeagueRanks(String leagueId) async {
    try {
      final rankings = await _client
          .from('user_rankings')
          .select('user_id, league_points')
          .eq('current_league', leagueId)
          .order('league_points', ascending: false);

      int rank = 1;
      for (final ranking in rankings) {
        await _client
            .from('user_rankings')
            .update({'league_rank': rank})
            .eq('user_id', ranking['user_id'] as String);
        rank++;
      }
    } catch (e) {
      debugPrint('❌ Error updating league ranks: $e');
    }
  }

  /// دریافت رتبه کاربر فعلی
  Future<UserRanking?> getCurrentUserRanking() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId == null) return null;

      return await getUserRanking(userId);
    } catch (e) {
      debugPrint('❌ Error getting current user ranking: $e');
      return null;
    }
  }

  /// دریافت رتبه یک کاربر خاص
  /// همیشه یک ranking برمی‌گرداند - اگر رکورد نداشته باشه، بر اساس امتیاز می‌سازه
  /// بهینه‌سازی شده: فقط فیلدهای لازم رو می‌گیره و join رو ساده می‌کنه
  Future<UserRanking?> getUserRanking(String userId) async {
    try {
      // استفاده از join برای یک کوئری واحد - خیلی سریع‌تر
      // از left join استفاده می‌کنیم تا حتی اگه ranking نداشته باشه، profile رو بگیریم
      final response = await _client
          .from('user_rankings')
          .select('''
            *,
            profiles:user_id (
              username,
              avatar_url,
              first_name,
              last_name,
              role
            )
          ''')
          .eq('user_id', userId)
          .maybeSingle();

      // Parse profile data
      Map<String, dynamic>? profile;
      if (response != null) {
        final profilesData = response['profiles'];
        if (profilesData is Map<String, dynamic>) {
          profile = profilesData;
        } else if (profilesData is List && profilesData.isNotEmpty) {
          profile = profilesData[0] as Map<String, dynamic>?;
        }
      }

      // اگر profile وجود نداشت، از دیتابیس بگیر
      if (profile == null) {
        final profileResponse = await _client
            .from('profiles')
            .select('username, avatar_url, first_name, last_name, role')
            .eq('id', userId)
            .maybeSingle();
        
        if (profileResponse == null) return null;
        profile = profileResponse;
      }

      // چک کن که athlete باشه
      final role = (profile['role'] ?? 'athlete').toString();
      if (role != 'athlete') return null;

      // اگر ranking وجود داشت، برگردون
      if (response != null) {
        return UserRanking.fromJson({
          ...response,
          'username': profile['username'],
          'avatar_url': profile['avatar_url'],
          'first_name': profile['first_name'],
          'last_name': profile['last_name'],
        });
      }

      // اگر ranking نداشت، یک ranking با امتیاز 0 بساز (بدون محاسبه سنگین)
      return UserRanking(
        userId: userId,
        totalScore: 0,
        currentLeague: 'bronze',
        username: profile['username'] as String?,
        avatarUrl: profile['avatar_url'] as String?,
        firstName: profile['first_name'] as String?,
        lastName: profile['last_name'] as String?,
      );
    } catch (e) {
      debugPrint('❌ Error getting user ranking: $e');
      return null;
    }
  }

  /// دریافت Leaderboard برای یک لیگ خاص
  /// بهینه‌سازی شده: فقط فیلدهای لازم رو می‌گیره
  /// فقط ورزشکاران (athletes) نمایش داده می‌شوند - مربیان حذف می‌شوند
  Future<List<UserRanking>> getLeagueLeaderboard(
    String leagueId, {
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from('user_rankings')
          .select('''
            user_id,
            total_score,
            current_league,
            league_points,
            league_rank,
            global_rank,
            profiles:user_id!inner (
              username,
              avatar_url,
              first_name,
              last_name,
              role
            )
          ''')
          .eq('current_league', leagueId)
          .eq('profiles.role', 'athlete') // فقط ورزشکاران
          .order('league_points', ascending: false)
          .limit(limit);

      final rankings = <UserRanking>[];
      for (final item in response) {
        // Parse profile data (could be Map or List)
        Map<String, dynamic>? profile;
        final profilesData = item['profiles'];
        if (profilesData is Map<String, dynamic>) {
          profile = profilesData;
        } else if (profilesData is List && profilesData.isNotEmpty) {
          profile = profilesData[0] as Map<String, dynamic>?;
        }

        // چک نهایی: فقط athletes رو اضافه کن
        final role = (profile?['role'] ?? 'athlete').toString();
        if (role != 'athlete') continue; // مربیان رو رد کن

        rankings.add(UserRanking.fromJson({
          ...item,
          'username': profile?['username'],
          'avatar_url': profile?['avatar_url'],
          'first_name': profile?['first_name'],
          'last_name': profile?['last_name'],
        }));
      }
      return rankings;
    } catch (e) {
      debugPrint('❌ Error getting league leaderboard: $e');
      return [];
    }
  }

  /// دریافت Global Leaderboard
  /// فقط ورزشکاران (athletes) نمایش داده می‌شوند - مربیان حذف می‌شوند
  Future<List<UserRanking>> getGlobalLeaderboard({int limit = 100}) async {
    try {
      final response = await _client
          .from('user_rankings')
          .select('''
            *,
            profiles:user_id!inner (
              username,
              avatar_url,
              first_name,
              last_name,
              role
            )
          ''')
          .eq('profiles.role', 'athlete') // فقط ورزشکاران
          .order('total_score', ascending: false)
          .limit(limit);

      final rankings = <UserRanking>[];
      for (final item in response) {
        // Parse profile data (could be Map or List)
        Map<String, dynamic>? profile;
        final profilesData = item['profiles'];
        if (profilesData is Map<String, dynamic>) {
          profile = profilesData;
        } else if (profilesData is List && profilesData.isNotEmpty) {
          profile = profilesData[0] as Map<String, dynamic>?;
        }

        // چک نهایی: فقط athletes رو اضافه کن
        final role = (profile?['role'] ?? 'athlete').toString();
        if (role != 'athlete') continue; // مربیان رو رد کن

        rankings.add(UserRanking.fromJson({
          ...item,
          'username': profile?['username'],
          'avatar_url': profile?['avatar_url'],
          'first_name': profile?['first_name'],
          'last_name': profile?['last_name'],
        }));
      }
      return rankings;
    } catch (e) {
      debugPrint('❌ Error getting global leaderboard: $e');
      return [];
    }
  }

  /// پیدا کردن رتبه کاربر در یک لیگ خاص
  Future<int?> getUserRankInLeague(String userId, String leagueId) async {
    try {
      final ranking = await getUserRanking(userId);
      if (ranking == null || ranking.currentLeague != leagueId) {
        return null;
      }
      return ranking.leagueRank;
    } catch (e) {
      debugPrint('❌ Error getting user rank in league: $e');
      return null;
    }
  }
}
