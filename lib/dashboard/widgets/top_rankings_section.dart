import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/screens/leaderboard_screen.dart';
import 'package:gymaipro/ranking/services/ranking_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_detail_screen.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_ranking_screen.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart'
    show TrainerRankingService, TrainerTopLeagueEntry;
import 'package:gymaipro/utils/format_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TopRankingsSection extends StatefulWidget {
  const TopRankingsSection({super.key});

  @override
  State<TopRankingsSection> createState() => _TopRankingsSectionState();
}

class _TopRankingsSectionState extends State<TopRankingsSection> {
  final RankingService _rankingService = RankingService();
  final TrainerRankingService _trainerService = TrainerRankingService();
  final PageController _pageController = PageController();

  List<UserRanking> _topAthletes = [];
  List<TrainerTopLeagueEntry> _topTrainerLeague = [];
  bool _isLoading = true;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _loadTopRankings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTopRankings() async {
    try {
      final results = await Future.wait<dynamic>([
        _rankingService.getGlobalLeaderboard(limit: 3),
        _trainerService.getTopTrainersByLeagueScores(),
      ]);

      if (!mounted) return;
      setState(() {
        _topAthletes = results[0] as List<UserRanking>;
        _topTrainerLeague = results[1] as List<TrainerTopLeagueEntry>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading top rankings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyData = _topAthletes.isNotEmpty || _topTrainerLeague.isNotEmpty;
    if (_isLoading) return _buildSkeleton(context);
    if (!hasAnyData) return const SizedBox.shrink();

    final hasBoth = _topAthletes.isNotEmpty && _topTrainerLeague.isNotEmpty;

    return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: _dashboardCardDecoration(context),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, hasBoth: hasBoth),
                if (hasBoth) ...[
                  SizedBox(height: 8.h),
                  _buildSegmentedTabs(context),
                ],
                SizedBox(height: 8.h),
                SizedBox(
                  height: 186.h,
                  child: hasBoth
                      ? PageView(
                          controller: _pageController,
                          onPageChanged: (tabIndex) {
                            if (mounted) {
                              setState(() => _activeTab = tabIndex);
                            }
                          },
                          children: [
                            _buildLeaderboardPage(context, isAthletes: true),
                            _buildLeaderboardPage(context, isAthletes: false),
                          ],
                        )
                      : _buildLeaderboardPage(
                          context,
                          isAthletes: _topAthletes.isNotEmpty,
                        ),
                ),
                SizedBox(height: 8.h),
                _buildSeeAllButton(context),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 320.ms)
        .slideY(begin: 0.04, end: 0, duration: 420.ms, curve: Curves.easeOut);
  }

  Widget _buildHeader(BuildContext context, {required bool hasBoth}) {
    final palette = _palette(context);
    final isAthletes = hasBoth ? _activeTab == 0 : _topAthletes.isNotEmpty;
    final subtitle = isAthletes ? 'ورزشکاران' : 'مربیان';

    return Row(
      children: [
        Container(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.goldColor.withValues(alpha: 0.18),
          ),
          child: Icon(
            LucideIcons.trophy,
            size: 14.sp,
            color: AppTheme.goldColor,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نفرات برتر',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  color: palette.primaryText,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 1.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 10.sp,
                  color: palette.secondaryText,
                ),
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTabs(BuildContext context) {
    final palette = _palette(context);
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabChip(
              label: 'ورزشکاران',
              icon: LucideIcons.dumbbell,
              selected: _activeTab == 0,
              palette: palette,
              onTap: () {
                setState(() => _activeTab = 0);
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: _TabChip(
              label: 'مربیان',
              icon: LucideIcons.award,
              selected: _activeTab == 1,
              palette: palette,
              onTap: () {
                setState(() => _activeTab = 1);
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardPage(BuildContext context, {required bool isAthletes}) {
    final palette = _palette(context);
    final items = _buildItems(isAthletes: isAthletes);
    if (items.isEmpty) return const SizedBox.shrink();

    final topOne = items.first;
    final rest = items.length > 1 ? items.sublist(1) : const <_RankData>[];

    return Column(
      children: [
        _TopChampionCard(
          item: topOne,
          isAthletes: isAthletes,
          palette: palette,
          onTap: () => _openRankingDetail(topOne, isAthletes: isAthletes),
        ),
        SizedBox(height: 6.h),
        if (rest.isNotEmpty)
          Row(
            children: rest
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: _CompactRankCard(
                        item: item,
                        isAthletes: isAthletes,
                        palette: palette,
                        onTap: () => _openRankingDetail(item, isAthletes: isAthletes),
                      ),
                    ),
                  ),
                )
                .toList(),
          )
        else
          SizedBox(height: 62.h),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  List<_RankData> _buildItems({required bool isAthletes}) {
    final items = <_RankData>[];
    if (isAthletes) {
      for (var i = 0; i < _topAthletes.length; i++) {
        final athlete = _topAthletes[i];
        items.add(
          _RankData(
            rank: i + 1,
            name: athlete.displayName,
            userId: athlete.userId,
            avatarUrl: athlete.avatarUrl,
            scoreText: FormatUtils.formatNumber(athlete.totalScore),
            badgeText: athlete.league.icon,
          ),
        );
      }
      return items;
    }

    for (var i = 0; i < _topTrainerLeague.length; i++) {
      final entry = _topTrainerLeague[i];
      final trainer = entry.profile;
      final displayName = trainer.fullName.isNotEmpty
          ? trainer.fullName
          : (trainer.username.isNotEmpty ? trainer.username : 'مربی');
      items.add(
        _RankData(
          rank: i + 1,
          name: displayName,
          userId: trainer.id ?? '',
          avatarUrl: trainer.avatarUrl,
          scoreText: FormatUtils.formatNumber(entry.leaguePoints),
          badgeText: '',
          trainerProfile: trainer,
        ),
      );
    }
    return items;
  }

  Future<void> _openRankingDetail(
    _RankData item, {
    required bool isAthletes,
  }) async {
    if (item.userId.isEmpty) return;

    if (isAthletes) {
      await Navigator.pushNamed(context, '/user-profile', arguments: item.userId);
      return;
    }

    final trainer = item.trainerProfile;
    if (trainer == null) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TrainerDetailScreen(trainer: trainer)));
  }

  Widget _buildSeeAllButton(BuildContext context) {
    final hasBoth = _topAthletes.isNotEmpty && _topTrainerLeague.isNotEmpty;
    final isAthletes = hasBoth ? _activeTab == 0 : _topAthletes.isNotEmpty;
    final palette = _palette(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => isAthletes
                  ? const LeaderboardScreen()
                  : const TrainerRankingScreen(),
            ),
          );
        },
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: Colors.transparent,
            border: Border.all(color: palette.buttonBorder, width: 1.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isAthletes
                    ? 'مشاهده همه ورزشکاران'
                    : 'مشاهده همه مربیان',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.sp,
                  color: palette.buttonText,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(
                LucideIcons.arrowLeft,
                size: 13.sp,
                color: palette.buttonText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _dashboardCardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: isDark
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightGradientStart.withValues(alpha: 0.15),
                context.cardColor,
                AppTheme.lightGradientEnd.withValues(alpha: 0.1),
              ],
            ),
      color: isDark ? context.cardColor : null,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(
        color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.35),
        width: 0.5.w,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 2,
        ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      height: 186.h,
      decoration: _dashboardCardDecoration(context),
      child: Center(
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppTheme.goldColor,
          ),
        ),
      ),
    );
  }

  _LeaderboardPalette _palette(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return _LeaderboardPalette(
        baseBackground: const Color(0xFF101726),
        baseBackgroundSoft: const Color(0xFF141E31),
        chipBackground: Colors.white.withValues(alpha: 0.02),
        chipSelectedBackground: AppTheme.goldColor.withValues(alpha: 0.12),
        borderColor: Colors.white.withValues(alpha: 0.09),
        glowColor: Colors.transparent,
        primaryText: context.textColor,
        secondaryText: context.textSecondary,
        buttonBackground: Colors.transparent,
        buttonBorder: Colors.white.withValues(alpha: 0.16),
        buttonText: context.textColor,
        goldStrong: const Color(0xFFFFD56A),
        goldSoft: const Color(0xFFFFB84C),
      );
    }

    return _LeaderboardPalette(
      baseBackground: const Color(0xFFFFFBF2),
      baseBackgroundSoft: const Color(0xFFFFF9EC),
      chipBackground: const Color(0xFF1A1A1A).withValues(alpha: 0.03),
      chipSelectedBackground: AppTheme.goldColor.withValues(alpha: 0.12),
      borderColor: const Color(0xFF202430).withValues(alpha: 0.08),
      glowColor: Colors.transparent,
      primaryText: context.textColor,
      secondaryText: context.textSecondary,
      buttonBackground: Colors.transparent,
      buttonBorder: const Color(0xFF21242D).withValues(alpha: 0.14),
      buttonText: context.textColor,
      goldStrong: const Color(0xFFFFD56A),
      goldSoft: const Color(0xFFFFB84C),
    );
  }
}

class _RankData {
  const _RankData({
    required this.rank,
    required this.name,
    required this.userId,
    required this.avatarUrl,
    required this.scoreText,
    required this.badgeText,
    this.trainerProfile,
  });

  final int rank;
  final String name;
  final String userId;
  final String? avatarUrl;
  final String scoreText;
  final String badgeText;
  final UserProfile? trainerProfile;
}

class _LeaderboardPalette {
  const _LeaderboardPalette({
    required this.baseBackground,
    required this.baseBackgroundSoft,
    required this.chipBackground,
    required this.chipSelectedBackground,
    required this.borderColor,
    required this.glowColor,
    required this.primaryText,
    required this.secondaryText,
    required this.buttonBackground,
    required this.buttonBorder,
    required this.buttonText,
    required this.goldStrong,
    required this.goldSoft,
  });

  final Color baseBackground;
  final Color baseBackgroundSoft;
  final Color chipBackground;
  final Color chipSelectedBackground;
  final Color borderColor;
  final Color glowColor;
  final Color primaryText;
  final Color secondaryText;
  final Color buttonBackground;
  final Color buttonBorder;
  final Color buttonText;
  final Color goldStrong;
  final Color goldSoft;
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final _LeaderboardPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: 7.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            color: selected ? palette.chipSelectedBackground : Colors.transparent,
            border: selected
                ? Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    width: 1.w,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 12.sp,
                color: selected
                    ? AppTheme.goldColor
                    : palette.secondaryText.withValues(alpha: 0.8),
              ),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 10.5.sp,
                  color: selected ? AppTheme.goldColor : palette.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopChampionCard extends StatelessWidget {
  const _TopChampionCard({
    required this.item,
    required this.isAthletes,
    required this.palette,
    required this.onTap,
  });

  final _RankData item;
  final bool isAthletes;
  final _LeaderboardPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: AppTheme.goldColor.withValues(alpha: 0.08),
        child: Container(
          height: 94.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: palette.chipBackground,
            border: Border.all(
              color: palette.secondaryText.withValues(alpha: 0.12),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              _RankAvatar(item: item, size: 52.w),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.crown,
                          color: AppTheme.goldColor,
                          size: 12.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'رتبه ۱',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.sp,
                            color: AppTheme.goldColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5.sp,
                        color: palette.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isAthletes
                          ? '${item.badgeText} ${item.scoreText} امتیاز'
                          : '${item.scoreText} امتیاز',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 10.sp,
                        color: palette.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactRankCard extends StatelessWidget {
  const _CompactRankCard({
    required this.item,
    required this.isAthletes,
    required this.palette,
    required this.onTap,
  });

  final _RankData item;
  final bool isAthletes;
  final _LeaderboardPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: onTap,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: AppTheme.goldColor.withValues(alpha: 0.08),
        child: Container(
          height: 58.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: palette.chipBackground,
            border: Border.all(
              color: palette.secondaryText.withValues(alpha: 0.12),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              _RankAvatar(item: item, size: 34.w),
              SizedBox(width: 7.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5.sp,
                        color: palette.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isAthletes
                          ? '${item.badgeText} ${item.scoreText}'
                          : item.scoreText,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 9.8.sp,
                        color: palette.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankAvatar extends StatelessWidget {
  const _RankAvatar({required this.item, required this.size});

  final _RankData item;
  final double size;

  Color get _ringColor {
    if (item.rank == 1) return const Color(0xFFFFC83D);
    if (item.rank == 2) return const Color(0xFFB5BDCC);
    return const Color(0xFFC98B58);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _ringColor.withValues(alpha: 0.9), width: 1.3.w),
          ),
          child: ClipOval(
            child: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                ? Image.network(
                    item.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackAvatar(),
                  )
                : _fallbackAvatar(),
          ),
        ),
        Positioned(
          left: -2.w,
          top: -5.h,
          child: Container(
            width: 17.w,
            height: 17.w,
            decoration: BoxDecoration(
              color: _ringColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${item.rank}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 8.6.sp,
                  color: const Color(0xFF1B1B1B),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackAvatar() {
    return ColoredBox(
      color: _ringColor.withValues(alpha: 0.16),
      child: Icon(
        LucideIcons.user,
        size: size * 0.45,
        color: _ringColor,
      ),
    );
  }
}
