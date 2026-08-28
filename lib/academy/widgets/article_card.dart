import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/services/article_stats_cache_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({
    required this.article,
    this.stats,
    this.isRead = false,
    this.readCount = 0,
    this.onTap,
    super.key,
  });

  final Article article;
  final ArticleStats? stats;
  final bool isRead;
  final int readCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final likeCount = stats?.likeCount ?? 0;
    final avgRating = stats?.avgRating ?? 0.0;
    final ratingCount = stats?.ratingCount ?? 0;
    final excerpt = article.excerpt.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              onTap ??
              () => Navigator.pushNamed(
                context,
                '/article-detail',
                arguments: article,
              ),
          borderRadius: BorderRadius.circular(16.r),
          child: Ink(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.separatorColor),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (article.featuredImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.r),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GymaiNetworkImage(
                          imageUrl: article.featuredImageUrl!,
                          errorWidget: ColoredBox(
                            color: context.surfaceElevated,
                            child: Center(
                              child: Icon(
                                LucideIcons.imageOff,
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 48.h,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.35),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isRead)
                          Positioned(
                            top: 10.h,
                            right: 10.w,
                            child: _Pill(
                              color: AppTheme.goldColor,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.check,
                                    size: 12.sp,
                                    color: AppTheme.onGoldColor,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'مطالعه شده',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onGoldColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (readCount > 0)
                          Positioned(
                            bottom: 10.h,
                            left: 10.w,
                            child: _Pill(
                              color: Colors.black.withValues(alpha: 0.65),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.eye,
                                    size: 12.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    _formatCount(readCount),
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: context.headingStyle.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (excerpt.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodyStyle.copyWith(
                          height: 1.5,
                          fontSize: 12.5.sp,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 13.sp,
                          color: context.textSecondary,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          _formatJalali(article.date),
                          style: context.bodyStyle.copyWith(
                            fontSize: 11.sp,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          LucideIcons.heart,
                          size: 13.sp,
                          color: context.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _formatCount(likeCount),
                          style: context.bodyStyle.copyWith(
                            fontSize: 11.sp,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          LucideIcons.star,
                          size: 13.sp,
                          color: context.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          ratingCount > 0
                              ? avgRating.toStringAsFixed(1)
                              : '—',
                          style: context.bodyStyle.copyWith(
                            fontSize: 11.sp,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          LucideIcons.chevronLeft,
                          size: 16.sp,
                          color: context.textSecondary.withValues(alpha: 0.7),
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

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatJalali(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    final f = j.formatter;
    return '${j.day} ${f.mN} ${j.year}';
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}
