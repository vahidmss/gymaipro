import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/screens/leaderboard_screen.dart';
import 'package:gymaipro/ranking/services/ranking_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_ranking_screen.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:gymaipro/utils/format_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// ویجت نفرات برتر — طراحی حرفه‌ای سکویی
class TopRankingsSection extends StatefulWidget {
  const TopRankingsSection({super.key});

  @override
  State<TopRankingsSection> createState() => _TopRankingsSectionState();
}

class _TopRankingsSectionState extends State<TopRankingsSection>
    with TickerProviderStateMixin {
  final RankingService _rankingService = RankingService();
  final TrainerRankingService _trainerService = TrainerRankingService();

  List<UserRanking> _topAthletes = [];
  List<UserProfile> _topTrainers = [];
  bool _isLoading = true;
  int _activeTab = 0;
  final PageController _pageController = PageController();

  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _loadTopRankings();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTopRankings() async {
    try {
      final results = await Future.wait([
        _rankingService.getGlobalLeaderboard(limit: 3),
        _trainerService.getTopTrainers(limit: 3),
      ]);

      if (mounted) {
        setState(() {
          _topAthletes = results[0] as List<UserRanking>;
          _topTrainers = results[1] as List<UserProfile>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading top rankings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAny = _topAthletes.isNotEmpty || _topTrainers.isNotEmpty;

    if (_isLoading) return _buildSkeleton(context);
    if (!hasAny) return const SizedBox.shrink();

    final hasBoth = _topAthletes.isNotEmpty && _topTrainers.isNotEmpty;

    return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF16213E),
                      context.veryDarkBackground,
                    ]
                  : [
                      context.goldGradientColors[0].withValues(alpha: 0.15),
                      context.cardColor,
                      context.cardColor,
                    ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.08 : 0.12,
                ),
                blurRadius: 20.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // هدر
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 0),
                  child: _buildHeader(context),
                ),
                SizedBox(height: 12.h),
                // تب‌ها
                if (hasBoth) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _buildTabBar(context),
                  ),
                  SizedBox(height: 8.h),
                ],
                // محتوای سکو
                SizedBox(
                  height: 240.h,
                  child: hasBoth
                      ? PageView(
                          controller: _pageController,
                          onPageChanged: (i) => setState(() => _activeTab = i),
                          children: [
                            _buildPodiumPage(context, isAthletes: true),
                            _buildPodiumPage(context, isAthletes: false),
                          ],
                        )
                      : _topAthletes.isNotEmpty
                      ? _buildPodiumPage(context, isAthletes: true)
                      : _buildPodiumPage(context, isAthletes: false),
                ),
                // دکمه مشاهده همه
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.w),
                  child: _buildSeeAllButton(context),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.04, end: 0, duration: 450.ms, curve: Curves.easeOut);
  }

  // ─── هدر ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.rtl,
      children: [
        Icon(LucideIcons.trophy, size: 20.sp, color: context.textColor)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.08, 1.08),
              duration: 1800.ms,
              curve: Curves.easeInOut,
            ),
        SizedBox(width: 8.w),
        Text(
          'نفرات برتر',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 16.sp,
            color: context.textColor,
          ),
        ),
      ],
    );
  }

  // ─── تب‌ها ──────────────────────────────────────────────
  Widget _buildTabBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabChip(
              context,
              label: 'ورزشکاران',
              icon: LucideIcons.dumbbell,
              isSelected: _activeTab == 0,
              onTap: () {
                setState(() => _activeTab = 0);
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
          Expanded(
            child: _buildTabChip(
              context,
              label: 'مربیان',
              icon: LucideIcons.award,
              isSelected: _activeTab == 1,
              onTap: () {
                setState(() => _activeTab = 1);
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            border: isSelected
                ? Border.all(color: AppTheme.goldColor.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                size: 14.sp,
                color: isSelected
                    ? AppTheme.goldColor
                    : context.textColor.withValues(alpha: 0.6),
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.sp,
                  color: isSelected
                      ? AppTheme.goldColor
                      : context.textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── صفحه سکو ──────────────────────────────────────────
  Widget _buildPodiumPage(BuildContext context, {required bool isAthletes}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // تعیین داده‌ها
    final List<_RankData> items = [];
    if (isAthletes) {
      for (var i = 0; i < _topAthletes.length; i++) {
        final a = _topAthletes[i];
        final league = a.league;
        items.add(
          _RankData(
            rank: i + 1,
            name: a.displayName,
            avatarUrl: a.avatarUrl,
            value: FormatUtils.formatNumber(a.totalScore),
            valueSuffix: league.icon,
            accentColor: Color(league.color),
            isStar: false,
          ),
        );
      }
    } else {
      for (var i = 0; i < _topTrainers.length; i++) {
        final t = _topTrainers[i];
        final name = t.fullName.isNotEmpty
            ? t.fullName
            : (t.username.isNotEmpty ? t.username : 'مربی');
        items.add(
          _RankData(
            rank: i + 1,
            name: name,
            avatarUrl: t.avatarUrl,
            value: (t.rating ?? 0).toStringAsFixed(1),
            valueSuffix: null,
            accentColor: AppTheme.goldColor,
            isStar: true,
          ),
        );
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    // ترتیب نمایش: 2 - 1 - 3 (رتبه ۱ وسط و بالاتر)
    final displayOrder = items.length == 3
        ? [items[1], items[0], items[2]]
        : items;
    final rankOrder = items.length == 3
        ? [2, 1, 3]
        : List.generate(items.length, (i) => i + 1);

    // ارتفاع سکوها
    const double bar1Height = 95;
    const double bar2Height = 72;
    const double bar3Height = 58;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: TextDirection.ltr,
        children: List.generate(displayOrder.length, (i) {
          final item = displayOrder[i];
          final rank = rankOrder[i];
          final double barHeight;
          switch (rank) {
            case 1:
              barHeight = bar1Height;
            case 2:
              barHeight = bar2Height;
            default:
              barHeight = bar3Height;
          }

          return Expanded(
            child: _PodiumColumn(
              item: item,
              rank: rank,
              barHeight: barHeight.h,
              isDark: isDark,
              glowAnimation: _glowController,
              delay: i * 120,
            ),
          );
        }),
      ),
    );
  }

  // ─── دکمه مشاهده ───────────────────────────────────────
  Widget _buildSeeAllButton(BuildContext context) {
    final hasBoth = _topAthletes.isNotEmpty && _topTrainers.isNotEmpty;
    final isAthletes = hasBoth ? _activeTab == 0 : _topAthletes.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isAthletes) {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const LeaderboardScreen(),
              ),
            );
          } else {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const TrainerRankingScreen(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.4),
              width: 1.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                isAthletes
                    ? 'مشاهده رتبه‌بندی ورزشکاران'
                    : 'مشاهده رتبه‌بندی مربیان',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                  color: AppTheme.goldColor,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(
                    LucideIcons.arrowLeft,
                    size: 16.sp,
                    color: AppTheme.goldColor,
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveX(
                    begin: 0,
                    end: -3,
                    duration: 800.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── اسکلتون ────────────────────────────────────────────
  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      height: 240.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1A2E), context.veryDarkBackground]
              : [
                  context.goldGradientColors[0].withValues(alpha: 0.1),
                  context.cardColor,
                ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: CircularProgressIndicator(
            color: AppTheme.goldColor,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

// ─── مدل داده ─────────────────────────────────────────────
class _RankData {
  const _RankData({
    required this.rank,
    required this.name,
    required this.avatarUrl,
    required this.value,
    required this.accentColor,
    required this.isStar,
    this.valueSuffix,
  });

  final int rank;
  final String name;
  final String? avatarUrl;
  final String value;
  final String? valueSuffix;
  final Color accentColor;
  final bool isStar;
}

// ─── ستون سکو (آواتار + اسم + امتیاز بالا، بار پایین) ──
class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.item,
    required this.rank,
    required this.barHeight,
    required this.isDark,
    required this.glowAnimation,
    required this.delay,
  });

  final _RankData item;
  final int rank;
  final double barHeight;
  final bool isDark;
  final Animation<double> glowAnimation;
  final int delay;

  double get _avatarSize => rank == 1 ? 60.w : 50.w;
  double get _ringSize => _avatarSize + 5.w;
  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // طلایی
      case 2:
        return const Color(0xFFC0C0C0); // نقره‌ای
      case 3:
        return const Color(0xFFCD7F32); // برنزی
      default:
        return item.accentColor;
    }
  }

  Color get _valueColor {
    if (isDark) return item.accentColor;
    final luminance = item.accentColor.computeLuminance();
    return luminance > 0.6 ? AppTheme.darkGold : item.accentColor;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // === بخش بالا: آواتار + اسم + امتیاز ===
              _buildProfileSection(context),
              SizedBox(height: 6.h),
              // === بار سکو ===
              _buildPodiumBar(context),
            ],
          ),
        )
        .animate(delay: delay.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildProfileSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // آواتار با حلقه رنگی
        _buildAvatar(context),
        SizedBox(height: 5.h),
        // اسم
        SizedBox(
          width: 90.w,
          child: Text(
            item.name,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: rank == 1 ? 12.sp : 11.sp,
              color: context.textColor,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 2.h),
        // امتیاز
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: [
            if (item.isStar)
              Icon(LucideIcons.star, size: 12.sp, color: _valueColor)
            else if (item.valueSuffix != null)
              Text(item.valueSuffix!, style: TextStyle(fontSize: 12.sp)),
            SizedBox(width: 3.w),
            Text(
              item.value,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: rank == 1 ? 13.sp : 11.sp,
                color: _valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return SizedBox(
      width: _ringSize + 6.w,
      height: _ringSize + (rank == 1 ? 16.h : 6.h),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // حلقه بیرونی درخشان
          Positioned(
            bottom: 0,
            child: AnimatedBuilder(
              animation: glowAnimation,
              builder: (context, child) {
                final glowAlpha = rank == 1
                    ? 0.3 + glowAnimation.value * 0.3
                    : 0.2 + glowAnimation.value * 0.15;
                return Container(
                  width: _ringSize,
                  height: _ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _rankColor.withValues(alpha: isDark ? 0.9 : 0.8),
                      width: rank == 1 ? 3.w : 2.5.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _rankColor.withValues(alpha: glowAlpha),
                        blurRadius: rank == 1 ? 16 : 10,
                        spreadRadius: rank == 1 ? 2 : 1,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // آواتار
          Positioned(
            bottom: (_ringSize - _avatarSize) / 2,
            child: ClipOval(
              child: SizedBox(
                width: _avatarSize,
                height: _avatarSize,
                child: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                    ? Image.network(
                        item.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
          ),
          // بج رتبه (تاج/مدال) بالای آواتار
          if (rank <= 3)
            Positioned(
                  top: 0,
                  child: Container(
                    width: rank == 1 ? 28.w : 24.w,
                    height: rank == 1 ? 28.w : 24.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_rankColor, _rankColor.withValues(alpha: 0.8)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.8),
                        width: 2.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _rankColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: rank == 1
                          ? Icon(
                              LucideIcons.crown,
                              size: 14.sp,
                              color: isDark ? Colors.black : Colors.white,
                            )
                          : Text(
                              '$rank',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.sp,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                    ),
                  ),
                )
                .animate(delay: (delay + 200).ms)
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildPodiumBar(BuildContext context) {
    return Container(
          height: barHeight,
          margin: EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _rankColor.withValues(alpha: isDark ? 0.35 : 0.45),
                _rankColor.withValues(alpha: isDark ? 0.15 : 0.2),
                _rankColor.withValues(alpha: isDark ? 0.08 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
            border: Border.all(
              color: _rankColor.withValues(alpha: isDark ? 0.4 : 0.5),
              width: 1.w,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شماره رتبه بزرگ
              Text(
                '$rank',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: rank == 1 ? 32.sp : 26.sp,
                  color: _rankColor.withValues(alpha: isDark ? 0.6 : 0.4),
                ),
              ),
            ],
          ),
        )
        .animate(delay: (delay + 80).ms)
        .slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 400.ms);
  }

  Widget _placeholder() {
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      color: _rankColor.withValues(alpha: 0.2),
      child: Icon(LucideIcons.user, size: 24.sp, color: _rankColor),
    );
  }
}
