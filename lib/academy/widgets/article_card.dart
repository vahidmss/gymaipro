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
    final likeCount = stats?.likeCount ?? 0;
    final avgRating = stats?.avgRating ?? 0.0;
    final ratingCount = stats?.ratingCount ?? 0;

    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/article-detail', arguments: article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.featuredImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
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
                    ),
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
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _buildArticleStats(
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

  Widget _buildArticleStats({
    required int likeCount,
    required double avgRating,
    required int ratingCount,
    required DateTime date,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 14.sp, color: AppTheme.goldColor),
            SizedBox(width: 6.w),
            Text(
              _formatJalali(date),
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: 12.w),
            Icon(LucideIcons.heart, size: 14.sp, color: Colors.pinkAccent),
            SizedBox(width: 4.w),
            Text(
              '$likeCount',
              style: AppTheme.bodyStyle.copyWith(fontSize: 11.sp),
            ),
            SizedBox(width: 12.w),
            Icon(LucideIcons.star, size: 14.sp, color: AppTheme.goldColor),
            SizedBox(width: 4.w),
            Text(
              '${avgRating.toStringAsFixed(1)} ($ratingCount)',
              style: AppTheme.bodyStyle.copyWith(fontSize: 11.sp),
            ),
            const Spacer(),
            Icon(LucideIcons.chevronLeft, size: 18.sp, color: Colors.white70),
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
