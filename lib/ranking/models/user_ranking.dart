import 'package:gymaipro/ranking/models/league.dart';

/// مدل رتبه‌بندی کاربر
class UserRanking {
  UserRanking({
    required this.userId,
    required this.totalScore,
    required this.currentLeague,
    this.globalRank,
    this.leagueRank,
    this.leaguePoints = 0,
    this.leagueChangedAt,
    this.previousLeague,
    this.rankUpdatedAt,
    // اطلاعات کاربر برای نمایش
    this.username,
    this.avatarUrl,
    this.firstName,
    this.lastName,
  });

  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      userId: json['user_id'] as String,
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      currentLeague: json['current_league'] as String? ?? 'bronze',
      globalRank: (json['global_rank'] as num?)?.toInt(),
      leagueRank: (json['league_rank'] as num?)?.toInt(),
      leaguePoints: (json['league_points'] as num?)?.toInt() ?? 0,
      leagueChangedAt: json['league_changed_at'] != null
          ? DateTime.parse(json['league_changed_at'] as String)
          : null,
      previousLeague: json['previous_league'] as String?,
      rankUpdatedAt: json['rank_updated_at'] != null
          ? DateTime.parse(json['rank_updated_at'] as String)
          : null,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }

  final String userId;
  final int totalScore;
  final String currentLeague;
  final int? globalRank;
  final int? leagueRank;
  final int leaguePoints;
  final DateTime? leagueChangedAt;
  final String? previousLeague;
  final DateTime? rankUpdatedAt;
  
  // اطلاعات کاربر
  final String? username;
  final String? avatarUrl;
  final String? firstName;
  final String? lastName;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_score': totalScore,
      'current_league': currentLeague,
      'global_rank': globalRank,
      'league_rank': leagueRank,
      'league_points': leaguePoints,
      'league_changed_at': leagueChangedAt?.toIso8601String(),
      'previous_league': previousLeague,
      'rank_updated_at': rankUpdatedAt?.toIso8601String(),
      'username': username,
      'avatar_url': avatarUrl,
      'first_name': firstName,
      'last_name': lastName,
    };
  }

  /// دریافت لیگ فعلی
  League get league => League.getLeagueByScore(totalScore);

  /// نام کامل کاربر
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username ?? 'کاربر ناشناس';
  }

  /// کپی با تغییرات
  UserRanking copyWith({
    String? userId,
    int? totalScore,
    String? currentLeague,
    int? globalRank,
    int? leagueRank,
    int? leaguePoints,
    DateTime? leagueChangedAt,
    String? previousLeague,
    DateTime? rankUpdatedAt,
    String? username,
    String? avatarUrl,
    String? firstName,
    String? lastName,
  }) {
    return UserRanking(
      userId: userId ?? this.userId,
      totalScore: totalScore ?? this.totalScore,
      currentLeague: currentLeague ?? this.currentLeague,
      globalRank: globalRank ?? this.globalRank,
      leagueRank: leagueRank ?? this.leagueRank,
      leaguePoints: leaguePoints ?? this.leaguePoints,
      leagueChangedAt: leagueChangedAt ?? this.leagueChangedAt,
      previousLeague: previousLeague ?? this.previousLeague,
      rankUpdatedAt: rankUpdatedAt ?? this.rankUpdatedAt,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}
