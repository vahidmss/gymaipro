import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/services/ranking_service.dart';
import 'package:gymaipro/ranking/widgets/league_card.dart';
import 'package:gymaipro/ranking/widgets/leaderboard_item.dart';
import 'package:gymaipro/ranking/widgets/user_rank_card.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// صفحه Leaderboard با طراحی دارک/لایت و کارت‌های لیگ
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
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      _currentUserId = profile?['id'] as String?;

      // فقط رنکینگ کاربر رو بگیریم - بدون به‌روزرسانی سنگین
      if (_currentUserId != null) {
        _currentUserRanking = await _rankingService.getUserRanking(
          _currentUserId!,
        );
      }

      // Leaderboard رو موازی با getUserRanking لود کنیم
      await _loadLeaderboard();
    } catch (e) {
      debugPrint('❌ Error loading leaderboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final leaderboard = await _rankingService.getLeagueLeaderboard(
        _selectedLeagueId,
        limit: 20,
      );

      setState(() {
        _leaderboard = leaderboard;
      });
    } catch (e) {
      debugPrint('❌ Error loading leaderboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLeague = League.all.firstWhere(
      (l) => l.id == _selectedLeagueId,
    );

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // اپ‌بار با گرادیان طلایی
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: context.backgroundColor,
            elevation: 0,
            title: Text(
              'رتبه‌بندی',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: context.textColor,
              ),
            ),
            centerTitle: true,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان بخش لیگ‌ها
                  Text(
                    'انتخاب لیگ',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // کارت‌های لیگ (سلکت کارت)
                  SizedBox(
                    height: 120.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      itemCount: League.all.length,
                      itemBuilder: (context, index) {
                        final league = League.all[index];
                        final isSelected = league.id == _selectedLeagueId;
                        return SizedBox(
                          width: 88.w,
                          child: LeagueCard(
                            league: league,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() => _selectedLeagueId = league.id);
                              _loadLeaderboard();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // عنوان لیست برترها
                  Row(
                    children: [
                      Icon(
                        LucideIcons.trophy,
                        size: 20.sp,
                        color: AppTheme.goldColor,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '۲۰ نفر برتر لیگ ${selectedLeague.nameFa}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),

          _isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.goldColor),
                  ),
                )
              : _leaderboard.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState(context))
              : SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final ranking = _leaderboard[index];
                      final isCurrentUser = ranking.userId == _currentUserId;
                      return LeaderboardItem(
                        ranking: ranking,
                        position: ranking.leagueRank ?? (index + 1),
                        isCurrentUser: isCurrentUser,
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            '/user-profile',
                            arguments: ranking.userId,
                          );
                          if (!mounted) return;
                          await _loadData();
                        },
                      );
                    }, childCount: _leaderboard.length),
                  ),
                ),

          // کارت رتبه کاربر (اگر جز ۲۰ نفر برتر نبود)
          if (_currentUserRanking != null &&
              _currentUserRanking!.currentLeague == _selectedLeagueId &&
              (_currentUserRanking!.leagueRank == null ||
                  _currentUserRanking!.leagueRank! > 20))
            SliverToBoxAdapter(
              child: UserRankCard(
                ranking: _currentUserRanking!,
                leagueId: _selectedLeagueId,
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              LucideIcons.trophy,
              size: 56.sp,
              color: context.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'هنوز کاربری در این لیگ وجود ندارد',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15.sp,
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'با فعالیت بیشتر، اولین نفر در این لیگ باشید',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              color: context.textSecondary.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
