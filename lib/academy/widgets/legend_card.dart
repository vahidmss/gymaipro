import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/fitness_legend.dart';
import 'package:gymaipro/academy/screens/legend_detail_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LegendCard extends StatelessWidget {
  const LegendCard({required this.legend, super.key});

  final FitnessLegend legend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push<LegendDetailScreen>(
          context,
          MaterialPageRoute<LegendDetailScreen>(
            builder: (_) => LegendDetailScreen(legend: legend),
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
            Container(
              margin: EdgeInsets.all(8.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  width: 90.w,
                  height: 90.h,
                  color: Colors.black26,
                  child: legend.featuredImageUrl != null
                      ? GymaiNetworkImage(
                          imageUrl: legend.featuredImageUrl!,
                          errorWidget: const Icon(
                            LucideIcons.user,
                            color: Colors.white54,
                            size: 48,
                          ),
                        )
                      : const Icon(
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
                      legend.fullName,
                      style: AppTheme.headingStyle.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (legend.nickname != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        legend.nickname!,
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 12.sp,
                          color: AppTheme.goldColor,
                          fontStyle: FontStyle.italic,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 6.h),
                    if (legend.nationality != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 14.sp,
                            color: AppTheme.goldColor,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              legend.nationality!,
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 12.sp,
                                fontFamily: AppTheme.fontFamily,
                                color: context.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (legend.olympiaTitles != null) ...[
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.trophy,
                            size: 14.sp,
                            color: AppTheme.goldColor,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              '${legend.olympiaTitles} قهرمانی مستر المپیا',
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 11.sp,
                                color: AppTheme.goldColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTheme.fontFamily,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (legend.heightCm != null ||
                        legend.weightStage != null) ...[
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (legend.heightCm != null) ...[
                            Icon(
                              LucideIcons.ruler,
                              size: 14.sp,
                              color: context.textSecondary,
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                '${legend.heightCm} سانتی‌متر',
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 11.sp,
                                  color: context.textSecondary,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (legend.weightStage != null)
                              SizedBox(width: 12.w),
                          ],
                          if (legend.weightStage != null) ...[
                            Icon(
                              LucideIcons.scale,
                              size: 14.sp,
                              color: context.textSecondary,
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                '${legend.weightStage} کیلوگرم',
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 11.sp,
                                  color: context.textSecondary,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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
}
