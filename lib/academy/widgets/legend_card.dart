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
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push<LegendDetailScreen>(
              context,
              MaterialPageRoute<LegendDetailScreen>(
                builder: (_) => LegendDetailScreen(legend: legend),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Ink(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.separatorColor),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      width: 88.w,
                      height: 88.w,
                      child: legend.featuredImageUrl != null
                          ? GymaiNetworkImage(
                              imageUrl: legend.featuredImageUrl!,
                              errorWidget: ColoredBox(
                                color: context.surfaceElevated,
                                child: Icon(
                                  LucideIcons.user,
                                  color: context.textSecondary,
                                  size: 36.sp,
                                ),
                              ),
                            )
                          : ColoredBox(
                              color: context.surfaceElevated,
                              child: Icon(
                                LucideIcons.user,
                                color: context.textSecondary,
                                size: 36.sp,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          legend.fullName,
                          style: context.headingStyle.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (legend.nickname != null) ...[
                          SizedBox(height: 3.h),
                          Text(
                            legend.nickname!,
                            style: context.bodyStyle.copyWith(
                              fontSize: 12.sp,
                              color: AppTheme.goldColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (legend.nationality != null) ...[
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 13.sp,
                                color: context.textSecondary,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  legend.nationality!,
                                  style: context.bodyStyle.copyWith(
                                    fontSize: 12.sp,
                                    color: context.textSecondary,
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
                            children: [
                              Icon(
                                LucideIcons.trophy,
                                size: 13.sp,
                                color: AppTheme.goldColor,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  '${legend.olympiaTitles} قهرمانی مستر المپیا',
                                  style: context.bodyStyle.copyWith(
                                    fontSize: 11.5.sp,
                                    color: AppTheme.goldColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
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
                            children: [
                              if (legend.heightCm != null) ...[
                                Icon(
                                  LucideIcons.ruler,
                                  size: 13.sp,
                                  color: context.textSecondary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${legend.heightCm} cm',
                                  style: context.bodyStyle.copyWith(
                                    fontSize: 11.sp,
                                    color: context.textSecondary,
                                  ),
                                ),
                                if (legend.weightStage != null)
                                  SizedBox(width: 10.w),
                              ],
                              if (legend.weightStage != null) ...[
                                Icon(
                                  LucideIcons.scale,
                                  size: 13.sp,
                                  color: context.textSecondary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${legend.weightStage} kg',
                                  style: context.bodyStyle.copyWith(
                                    fontSize: 11.sp,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronLeft,
                    color: context.textSecondary.withValues(alpha: 0.7),
                    size: 18.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
