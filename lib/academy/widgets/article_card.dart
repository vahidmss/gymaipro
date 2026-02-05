import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/services/article_stats_cache_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({required this.article, this.stats, super.key});

  final Article article;
  final ArticleStats? stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final likeCount = stats?.likeCount ?? 0;
    final avgRating = stats?.avgRating ?? 0.0;
    final ratingCount = stats?.ratingCount ?? 0;

    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/article-detail', arguments: article),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.goldGradientColors[0].withValues(alpha: 0.15),
                    context.cardColor,
                    context.goldGradientColors[1].withValues(alpha: 0.1),
                  ],
                ),
          color: isDark ? context.cardColor : null,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.35),
              blurRadius: 16.r,
              offset: Offset(0.w, 6.h),
              spreadRadius: 1.r,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : AppTheme.lightTextColor.withValues(alpha: 0.08),
              blurRadius: 8.r,
              offset: Offset(0.w, 2.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.featuredImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        article.featuredImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const ColoredBox(
                          color: Colors.black12,
                          child: Center(
                            child: Icon(
                              LucideIcons.imageOff,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0.w,
                      right: 0.w,
                      bottom: 0.h,
                      height: 36.h,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.25),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(
                                  alpha: isDark ? 0.35 : 0.45,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: AppTheme.headingStyle.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                      height: 1.2.h,
                      color: context.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    article.excerpt.isNotEmpty ? article.excerpt : '...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyStyle.copyWith(
                      height: 1.5.h,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w400,
                      color: context.textSecondary,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _buildArticleStats(
                    context,
                    likeCount: likeCount,
                    avgRating: avgRating,
                    ratingCount: ratingCount,
                    date: article.date,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleStats(
    BuildContext context, {
    required int likeCount,
    required double avgRating,
    required int ratingCount,
    required DateTime date,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? context.cardColor.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? context.separatorColor
              : AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppTheme.goldColor.withValues(alpha: 0.1),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 14.sp, color: AppTheme.goldColor),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                _formatJalali(date),
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                  fontFamily: AppTheme.fontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(LucideIcons.heart, size: 14.sp, color: Colors.pinkAccent),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                '$likeCount',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                  fontFamily: AppTheme.fontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(LucideIcons.star, size: 14.sp, color: AppTheme.goldColor),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                '${avgRating.toStringAsFixed(1)} ($ratingCount)',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                  fontFamily: AppTheme.fontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              LucideIcons.chevronLeft,
              size: 18.sp,
              color: context.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _formatJalali(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    final f = j.formatter;
    return '${j.day} ${f.mN} ${j.year}';
  }
}
