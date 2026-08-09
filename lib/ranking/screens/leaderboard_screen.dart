import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/services/ranking_service.dart';
import 'package:gymaipro/ranking/widgets/leaderboard_item.dart';
import 'package:gymaipro/ranking/widgets/user_rank_card.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final RankingService _rankingService = RankingService();
  String _selectedLeagueId = 'bronze';
  List<UserRanking> _leaderboard = [];
  UserRanking? _currentUserRanking;
  int _leagueMemberCount = 0;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      _currentUserId = profile?['id'] as String?;

      if (_currentUserId != null) {
        await _rankingService.updateCurrentUserRanking(
          userId: _currentUserId,
        );
        _currentUserRanking = await _rankingService.getUserRanking(
          _currentUserId!,
        );
        final userLeague = _currentUserRanking?.currentLeague;
        if (userLeague != null && userLeague.isNotEmpty) {
          _selectedLeagueId = userLeague;
        }
      }

      await _rankingService.refreshLeagueRanks(_selectedLeagueId);

      if (_currentUserId != null) {
        _currentUserRanking = await _rankingService.getUserRanking(
          _currentUserId!,
        );
      }

      final results = await Future.wait<Object?>([
        _rankingService.getLeagueLeaderboard(_selectedLeagueId),
        _rankingService.getLeagueMemberCount(_selectedLeagueId),
      ]);

      if (!mounted) return;
      setState(() {
        _leaderboard = results[0]! as List<UserRanking>;
        _leagueMemberCount = results[1]! as int;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading leaderboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectLeague(String leagueId) async {
    if (leagueId == _selectedLeagueId) return;
    setState(() {
      _selectedLeagueId = leagueId;
      _isLoading = true;
    });
    try {
      await _rankingService.refreshLeagueRanks(leagueId);
      if (_currentUserId != null) {
        _currentUserRanking = await _rankingService.getUserRanking(
          _currentUserId!,
        );
      }
      final results = await Future.wait<Object?>([
        _rankingService.getLeagueLeaderboard(leagueId),
        _rankingService.getLeagueMemberCount(leagueId),
      ]);
      if (!mounted) return;
      setState(() {
        _leaderboard = results[0]! as List<UserRanking>;
        _leagueMemberCount = results[1]! as int;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _myIndex =>
      _leaderboard.indexWhere((r) => r.userId == _currentUserId);

  int _displayRank() {
    if (_myIndex >= 0) return _myIndex + 1;
    final stored = _currentUserRanking?.leagueRank;
    if (stored != null && stored > 0) return stored;
    if (_leaderboard.isNotEmpty) return _leaderboard.length + 1;
    return 1;
  }

  bool get _showUserCard {
    final ranking = _currentUserRanking;
    if (ranking == null || _currentUserId == null) return false;
    return ranking.currentLeague == _selectedLeagueId;
  }

  bool get _userInList => _myIndex >= 0;

  String? _gapHint() {
    if (_currentUserRanking == null) return null;
    if (_currentUserRanking!.currentLeague != _selectedLeagueId) return null;

    final i = _myIndex;
    if (i < 0) {
      if (_leaderboard.isEmpty) return null;
      final last = _leaderboard.last.totalScore;
      final mine = _currentUserRanking!.totalScore;
      final need = (last - mine + 1).clamp(1, 999999);
      return '${FormatUtils.toPersianDigits('$need')} امتیاز تا ورود به جدول برتر';
    }

    final mine = _leaderboard[i].totalScore;
    if (i == 0) {
      if (_leaderboard.length < 2) return 'صدر جدول لیگ ${League.byId(_selectedLeagueId).nameFa}';
      final gap = mine - _leaderboard[1].totalScore;
      if (gap <= 0) {
        return 'رقابت نزدیک با نفر دوم';
      }
      return '${FormatUtils.toPersianDigits('$gap')} امتیاز جلوتر از نفر دوم';
    }

    final ahead = _leaderboard[i - 1].totalScore - mine;
    if (ahead <= 0) {
      return 'هم‌امتیاز با رتبه ${FormatUtils.toPersianDigits('$i')}';
    }
    return 'فقط ${FormatUtils.toPersianDigits('$ahead')} امتیاز تا رتبه ${FormatUtils.toPersianDigits('$i')}';
  }

  Future<void> _openProfile(UserRanking ranking) async {
    await Navigator.pushNamed(
      context,
      '/user-profile',
      arguments: ranking.userId,
    );
    if (!mounted) return;
    await _loadData();
  }

  void _openWorkout() {
    unawaited(Navigator.pushNamed(context, '/workout-log'));
  }

  @override
  Widget build(BuildContext context) {
    final selectedLeague = League.byId(_selectedLeagueId);
    final gap = _gapHint();

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'رتبه‌بندی',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 17.sp,
            color: context.textColor,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            LucideIcons.arrowRight,
            color: context.textColor,
            size: 20.sp,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 6.h),
            child: _LeagueChips(
              selectedId: _selectedLeagueId,
              onSelect: _selectLeague,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: _LeagueHero(
              league: selectedLeague,
              memberCount: _leagueMemberCount,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.goldColor),
                  )
                : RefreshIndicator(
                    color: AppTheme.goldColor,
                    onRefresh: _loadData,
                    child: _leaderboard.isEmpty
                        ? _EmptyLeagueState(
                            leagueName: selectedLeague.nameFa,
                            onStartWorkout: _openWorkout,
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                            itemCount: _leaderboard.length,
                            itemBuilder: (context, index) {
                              final ranking = _leaderboard[index];
                              final isMe = ranking.userId == _currentUserId;
                              return LeaderboardItem(
                                ranking: ranking,
                                position: index + 1,
                                isCurrentUser: isMe,
                                gapHint: isMe ? gap : null,
                                onTap: () => _openProfile(ranking),
                              );
                            },
                          ),
                  ),
          ),
          if (_showUserCard && _currentUserRanking != null)
            SafeArea(
              top: false,
              child: UserRankCard(
                ranking: _currentUserRanking!,
                displayRank: _displayRank(),
                gapHint: gap,
                compact: _userInList,
              ),
            ),
        ],
      ),
    );
  }
}

class _LeagueHero extends StatelessWidget {
  const _LeagueHero({
    required this.league,
    required this.memberCount,
  });

  final League league;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Color(league.color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Color(league.color).withValues(alpha: 0.35)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(league.icon, style: TextStyle(fontSize: 22.sp)),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لیگ ${league.nameFa}',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.sp,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  memberCount > 0
                      ? '${FormatUtils.toPersianDigits('$memberCount')} شرکت‌کننده'
                      : 'هنوز شرکت‌کننده‌ای ثبت نشده',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLeagueState extends StatelessWidget {
  const _EmptyLeagueState({
    required this.leagueName,
    required this.onStartWorkout,
  });

  final String leagueName;
  final VoidCallback onStartWorkout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      children: [
        SizedBox(height: 48.h),
        Icon(LucideIcons.trophy, size: 44.sp, color: AppTheme.goldColor),
        SizedBox(height: 14.h),
        Text(
          'اولین نفر لیگ $leagueName باش',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 16.sp,
            color: context.textColor,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'با ثبت تمرین و وعده غذایی امتیاز بگیر و صدر جدول را مال خودت کن.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13.sp,
            height: 1.5,
            color: context.textSecondary,
          ),
        ),
        SizedBox(height: 20.h),
        Center(
          child: FilledButton(
            onPressed: onStartWorkout,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: AppTheme.onGoldColor,
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
            ),
            child: Text(
              'شروع تمرین',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeagueChips extends StatelessWidget {
  const _LeagueChips({
    required this.selectedId,
    required this.onSelect,
  });

  final String selectedId;
  final ValueChanged<String> onSelect;

  static String _shortName(League league) {
    switch (league.id) {
      case 'platinum':
        return 'پلاتین';
      default:
        return league.nameFa;
    }
  }

  @override
  Widget build(BuildContext context) {
    // همه تب‌ها هم‌زمان دیده شوند — بدون اسکرول افقی
    return Row(
      children: [
        for (var i = 0; i < League.all.length; i++) ...[
          if (i > 0) SizedBox(width: 6.w),
          Expanded(child: _chip(context, League.all[i])),
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, League league) {
    final selected = league.id == selectedId;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(league.id),
        borderRadius: BorderRadius.circular(10.r),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: selected
                ? Color(league.color).withValues(alpha: 0.2)
                : context.cardColor,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected ? Color(league.color) : context.separatorColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(league.icon, style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 2.h),
              Text(
                _shortName(league),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 10.5.sp,
                  color: selected ? Color(league.color) : context.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
