import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AcademyStoryCard extends StatelessWidget {
  const AcademyStoryCard({required this.article, super.key});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/article-detail', arguments: article),
      child: Container(
        width: 90.w,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          children: [
            Container(
              width: 70.w,
              height: 70.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.2),
                    AppTheme.goldColor.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cardColor,
                    border: Border.all(color: AppTheme.goldColor, width: 2.w),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: article.featuredImageUrl != null
                      ? Image.network(
                          article.featuredImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              LucideIcons.bookOpen,
                              color: AppTheme.goldColor,
                              size: 28.sp,
                            );
                          },
                        )
                      : Icon(
                          LucideIcons.bookOpen,
                          color: AppTheme.goldColor,
                          size: 28.sp,
                        ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              article.title.length > 15
                  ? '${article.title.substring(0, 15)}...'
                  : article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
