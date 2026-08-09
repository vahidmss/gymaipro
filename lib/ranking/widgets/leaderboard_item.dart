import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/gamification_labels.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// ردیف لیدربورد با وزن بصری برای ۳ نفر اول و امتیاز درشت‌تر.
class LeaderboardItem extends StatelessWidget {
  const LeaderboardItem({
    required this.ranking,
    required this.position,
    this.isCurrentUser = false,
    this.gapHint,
    this.onTap,
    super.key,
  });

  final UserRanking ranking;
  final int position;
  final bool isCurrentUser;
  final String? gapHint;
  final VoidCallback? onTap;

  Color? get _topTint {
    if (position == 1) return const Color(0xFFFFD700);
    if (position == 2) return const Color(0xFFC0C0C0);
    if (position == 3) return const Color(0xFFCD7F32);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tint = _topTint;
    final bg = isCurrentUser
        ? AppTheme.goldColor.withValues(alpha: 0.14)
        : tint != null
            ? tint.withValues(alpha: 0.12)
            : context.cardColor;
    final border = isCurrentUser
        ? AppTheme.goldColor.withValues(alpha: 0.65)
        : tint != null
            ? tint.withValues(alpha: 0.45)
            : context.separatorColor;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: border, width: tint != null || isCurrentUser ? 1.4 : 1),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                _RankBadge(rank: position),
                SizedBox(width: 10.w),
                _Avatar(
                  url: _normalizeUrl(ranking.avatarUrl),
                  name: ranking.displayName,
                  accent: tint ?? Color(ranking.league.color),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Text(
                              ranking.displayName,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: context.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.goldColor,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'شما',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.onGoldColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (gapHint != null && isCurrentUser) ...[
                        SizedBox(height: 3.h),
                        Text(
                          gapHint!,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.goldColor,
                          ),
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      FormatUtils.toPersianDigits('${ranking.totalScore}'),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        color: context.textColor,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      GamificationLabels.points,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 4.w),
                Icon(
                  LucideIcons.chevronLeft,
                  size: 16.sp,
                  color: context.textSecondary.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _normalizeUrl(String? url) {
    final v = (url ?? '').trim();
    if (v.isEmpty || v.toLowerCase() == 'null') return '';
    if (!v.startsWith('http://') && !v.startsWith('https://')) return '';
    return v;
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String? medal;
    if (rank == 1) {
      bg = const Color(0xFFFFD700);
      fg = const Color(0xFF1A1A1A);
      medal = '🥇';
    } else if (rank == 2) {
      bg = const Color(0xFFC0C0C0);
      fg = const Color(0xFF1A1A1A);
      medal = '🥈';
    } else if (rank == 3) {
      bg = const Color(0xFFCD7F32);
      fg = Colors.white;
      medal = '🥉';
    } else {
      bg = context.separatorColor;
      fg = context.textColor;
      medal = null;
    }

    return Container(
      width: 40.w,
      height: 40.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: medal != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(medal, style: TextStyle(fontSize: 11.sp, height: 1)),
                Text(
                  FormatUtils.toPersianDigits('$rank'),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: fg,
                    height: 1,
                  ),
                ),
              ],
            )
          : Text(
              FormatUtils.toPersianDigits('$rank'),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.name,
    required this.accent,
  });

  final String url;
  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final size = 40.w;
    Widget fallback() {
      final letter = name.isNotEmpty ? name.substring(0, 1) : '?';
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
            color: accent,
          ),
        ),
      );
    }

    if (url.isEmpty) return fallback();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: GymaiNetworkImage(
          imageUrl: url,
          errorWidget: fallback(),
          placeholder: fallback(),
        ),
      ),
    );
  }
}
