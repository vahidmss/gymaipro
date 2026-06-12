import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/widgets/league_badge.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// ویجت نمایش یک آیتم در Leaderboard — طراحی دارک/لایت
/// نکته: نمایش رتبه فقط به صورت عدد (بدون متن/آیکن)
class LeaderboardItem extends StatelessWidget {
  const LeaderboardItem({
    required this.ranking,
    required this.position,
    this.isCurrentUser = false,
    this.onTap,
    super.key,
  });

  final UserRanking ranking;
  final int position;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final league = ranking.league;

    final radius = BorderRadius.circular(16.r);
    final avatarUrl = _normalizeUrl(ranking.avatarUrl);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: AppTheme.goldColor.withValues(alpha: 0.08),
          highlightColor: AppTheme.goldColor.withValues(alpha: 0.06),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppTheme.goldColor.withValues(alpha: 0.10)
                  : context.cardColor,
              borderRadius: radius,
              border: Border.all(
                color: isCurrentUser
                    ? AppTheme.goldColor.withValues(alpha: 0.75)
                    : context.textSecondary.withValues(alpha: 0.10),
                width: isCurrentUser ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                if (isCurrentUser)
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Row(
              children: [
                _RankNumberBadge(
                  rank: position,
                  accentColor: Color(league.color),
                  isHighlighted: isCurrentUser,
                ),
                SizedBox(width: 14.w),
                _AvatarCircle(url: avatarUrl, displayName: ranking.displayName),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ranking.displayName,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: context.goldGradientColors,
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                'شما',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 10.sp,
                                  color: AppTheme.onGoldColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 22.sp,
                              color: context.textSecondary.withValues(
                                alpha: 0.55,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          LeagueBadge(league: league, size: 14),
                          SizedBox(width: 6.w),
                          Text(
                            _formatScore(ranking.totalScore),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.sp,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatScore(int score) {
    final formatted = score.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted امتیاز';
  }

  String _normalizeUrl(String? url) {
    final v = (url ?? '').trim();
    if (v.isEmpty) return '';
    if (v.toLowerCase() == 'null') return '';
    if (!v.startsWith('http://') && !v.startsWith('https://')) return '';
    return v;
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.url, required this.displayName});

  final String url;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final radius = 24.r;
    final bg = AppTheme.goldColor.withValues(alpha: 0.18);

    Widget placeholder() {
      final letter = displayName.isNotEmpty
          ? displayName[0].toUpperCase()
          : '?';
      return Container(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldColor,
          ),
        ),
      );
    }

    if (url.isEmpty) return placeholder();

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return ColoredBox(
              color: bg,
              child: Center(
                child: SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.goldColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RankNumberBadge extends StatelessWidget {
  const _RankNumberBadge({
    required this.rank,
    required this.accentColor,
    required this.isHighlighted,
  });

  final int rank;
  final Color accentColor;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outerRadius = 16.r;
    final size = 46.w;

    final outerGradient = _outerGradient(context);
    final innerColor = rank <= 3
        ? Colors.white.withValues(alpha: 0.18)
        : (isDark ? context.veryDarkBackground : context.cardColor);

    final numberColor = rank <= 3 ? const Color(0xFF141414) : context.textColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer: gradient frame
          Container(
            decoration: BoxDecoration(
              gradient: outerGradient,
              borderRadius: BorderRadius.circular(outerRadius),
              boxShadow: [
                BoxShadow(
                  color: (rank <= 3 ? _medalBaseColor(rank) : accentColor)
                      .withValues(alpha: isDark ? 0.32 : 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                if (isHighlighted)
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
          ),
          // Inner: glossy surface (gives premium depth)
          Padding(
            padding: EdgeInsets.all(2.2.w),
            child: Container(
              decoration: BoxDecoration(
                color: innerColor,
                borderRadius: BorderRadius.circular(outerRadius - 2.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.22),
                  width: 1,
                ),
              ),
            ),
          ),
          // Rank number only
          Text(
            '$rank',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: rank <= 3 ? 18.sp : 17.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              color: numberColor,
            ),
          ),
          // Subtle top shine (glass effect) — no text, purely visual
          Positioned(
            top: 6.h,
            left: 8.w,
            right: 8.w,
            child: Container(
              height: 10.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.14 : 0.22),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _outerGradient(BuildContext context) {
    if (rank == 1) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF3A6), Color(0xFFFFD700), Color(0xFFE6B800)],
      );
    }
    if (rank == 2) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF3F3F3), Color(0xFFC0C0C0), Color(0xFF9E9E9E)],
      );
    }
    if (rank == 3) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE9B06C), Color(0xFFCD7F32), Color(0xFF8B4513)],
      );
    }

    // For other ranks: premium dark frame with accent edge
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base1 = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEDE8DD);
    final base2 = isDark ? const Color(0xFF151515) : const Color(0xFFF8F3EA);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accentColor.withValues(alpha: 0.85), base1, base2],
      stops: const [0.0, 0.35, 1.0],
    );
  }

  Color _medalBaseColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return accentColor;
  }
}
