import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
                    color: context.cardColor,
                    border: Border.all(color: AppTheme.goldColor, width: 2.w),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: article.featuredImageUrl != null
                      ? GymaiNetworkImage(
                          imageUrl: article.featuredImageUrl!,
                          errorWidget: Icon(
                            LucideIcons.bookOpen,
                            color: AppTheme.goldColor,
                            size: 28.sp,
                          ),
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
