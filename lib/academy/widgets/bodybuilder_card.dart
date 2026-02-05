import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/professional_bodybuilder.dart';
import 'package:gymaipro/academy/screens/bodybuilder_detail_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BodybuilderCard extends StatelessWidget {
  const BodybuilderCard({required this.bodybuilder, super.key});

  final ProfessionalBodybuilder bodybuilder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push<BodybuilderDetailScreen>(
          context,
          MaterialPageRoute<BodybuilderDetailScreen>(
            builder: (_) =>
                BodybuilderDetailScreen(bodybuilder: bodybuilder),
          ),
        );
      },
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
        child: Row(
          children: [
            // Profile Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
              child: Container(
                width: 120.w,
                height: 120.h,
                color: Colors.black26,
                child: Image.network(
                  bodybuilder.profileImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(
                    LucideIcons.user,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bodybuilder.name,
                      style: AppTheme.headingStyle.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 14.sp,
                          color: AppTheme.goldColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          bodybuilder.nationality,
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          LucideIcons.cake,
                          size: 14.sp,
                          color: context.textSecondary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${bodybuilder.age} سال',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 12.sp,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (bodybuilder.height != null || bodybuilder.weight != null) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          if (bodybuilder.height != null) ...[
                            Icon(
                              LucideIcons.ruler,
                              size: 14.sp,
                              color: context.textSecondary,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${bodybuilder.height!.toStringAsFixed(0)} سانتی‌متر',
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 11.sp,
                                color: context.textSecondary,
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                          if (bodybuilder.weight != null) ...[
                            Icon(
                              LucideIcons.scale,
                              size: 14.sp,
                              color: context.textSecondary,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${bodybuilder.weight!.toStringAsFixed(0)} کیلوگرم',
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 11.sp,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _getCategoryLabel(bodybuilder.category),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10.sp,
                          color: AppTheme.goldColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Icon(
                LucideIcons.chevronLeft,
                color: context.textSecondary,
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'classic':
        return 'کلاسیک';
      case 'bodybuilding':
        return 'بدنسازی';
      case 'physique':
        return 'فیزیک';
      case 'wellness':
        return 'ولنس';
      default:
        return category;
    }
  }
}

