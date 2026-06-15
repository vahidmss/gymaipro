import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/fitness_legend.dart';
import 'package:gymaipro/academy/widgets/article_content.dart';
import 'package:gymaipro/academy/widgets/article_image.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

class LegendDetailScreen extends StatefulWidget {
  const LegendDetailScreen({required this.legend, super.key});
  final FitnessLegend legend;

  @override
  State<LegendDetailScreen> createState() => _LegendDetailScreenState();
}

class _LegendDetailScreenState extends State<LegendDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        title: Text(
          'جزئیات اسطوره',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 18.sp,
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.legend.featuredImageUrl != null)
              Container(
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.2),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.r),
                    bottomRight: Radius.circular(20.r),
                  ),
                  child: ArticleImage(
                    imageUrl: widget.legend.featuredImageUrl!,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(
                            alpha: isDark ? 0.1 : 0.15,
                          ),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.legend.fullName,
                          style: AppTheme.headingStyle.copyWith(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: AppTheme.fontFamily,
                            color: context.textColor,
                          ),
                        ),
                        if (widget.legend.nickname != null) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.star,
                                size: 16.sp,
                                color: AppTheme.goldColor,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                widget.legend.nickname!,
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 16.sp,
                                  color: AppTheme.goldColor,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 16.h),
                        // Stats Row
                        Wrap(
                          spacing: 12.w,
                          runSpacing: 12.h,
                          children: [
                            if (widget.legend.nationality != null)
                              _buildStatItem(
                                icon: LucideIcons.mapPin,
                                label: 'ملیت',
                                value: widget.legend.nationality!,
                              ),
                            if (widget.legend.olympiaTitles != null)
                              _buildStatItem(
                                icon: LucideIcons.trophy,
                                label: 'قهرمانی مستر المپیا',
                                value: widget.legend.olympiaTitles!,
                                isGold: true,
                              ),
                            if (widget.legend.heightCm != null)
                              _buildStatItem(
                                icon: LucideIcons.ruler,
                                label: 'قد',
                                value: '${widget.legend.heightCm} سانتی‌متر',
                              ),
                            if (widget.legend.weightStage != null)
                              _buildStatItem(
                                icon: LucideIcons.scale,
                                label: 'وزن',
                                value: '${widget.legend.weightStage} کیلوگرم',
                              ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 16.sp,
                              color: AppTheme.goldColor,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              _formatJalali(widget.legend.date),
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 12.sp,
                                fontFamily: AppTheme.fontFamily,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Content Card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(
                            alpha: isDark ? 0.1 : 0.15,
                          ),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: ArticleContent(
                      contentHtml: widget.legend.contentHtml,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool isGold = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = context.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isGold
            ? (isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.15)
                  : AppTheme.goldColor.withValues(alpha: 0.1))
            : (isDark ? context.veryDarkBackground : context.cardColor),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isGold
              ? AppTheme.goldColor.withValues(alpha: 0.3)
              : AppTheme.goldColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 2.r,
            offset: Offset(0, 1.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: isGold ? AppTheme.goldColor : textSecondary,
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 10.sp,
                  color: textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 12.sp,
                  color: isGold ? AppTheme.goldColor : context.textColor,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatJalali(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    final f = j.formatter;
    return '${j.day} ${f.mN} ${j.year}';
  }
}
