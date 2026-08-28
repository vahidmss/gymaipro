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
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'بازگشت',
          icon: Icon(LucideIcons.arrowRight, color: context.textColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'جزئیات اسطوره',
          style: context.headingStyle.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.legend.featuredImageUrl != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: ArticleImage(
                    imageUrl: widget.legend.featuredImageUrl!,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.legend.fullName,
                    style: context.headingStyle.copyWith(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  if (widget.legend.nickname != null) ...[
                    SizedBox(height: 6.h),
                    Text(
                      widget.legend.nickname!,
                      style: context.bodyStyle.copyWith(
                        fontSize: 15.sp,
                        color: AppTheme.goldColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  SizedBox(height: 14.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      if (widget.legend.nationality != null)
                        _StatChip(
                          icon: LucideIcons.mapPin,
                          label: widget.legend.nationality!,
                        ),
                      if (widget.legend.olympiaTitles != null)
                        _StatChip(
                          icon: LucideIcons.trophy,
                          label: '${widget.legend.olympiaTitles} مستر المپیا',
                          accent: true,
                        ),
                      if (widget.legend.heightCm != null)
                        _StatChip(
                          icon: LucideIcons.ruler,
                          label: '${widget.legend.heightCm} cm',
                        ),
                      if (widget.legend.weightStage != null)
                        _StatChip(
                          icon: LucideIcons.scale,
                          label: '${widget.legend.weightStage} kg',
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 14.sp,
                        color: context.textSecondary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _formatJalali(widget.legend.date),
                        style: context.bodyStyle.copyWith(
                          fontSize: 12.sp,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: context.separatorColor),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: ArticleContent(
                        contentHtml: widget.legend.contentHtml,
                        stripDuplicateTitle: widget.legend.fullName,
                      ),
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

  String _formatJalali(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    final f = j.formatter;
    return '${j.day} ${f.mN} ${j.year}';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: accent
            ? AppTheme.goldColor.withValues(alpha: 0.12)
            : context.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent
              ? AppTheme.goldColor.withValues(alpha: 0.35)
              : context.separatorColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: accent ? AppTheme.goldColor : context.textSecondary,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: context.bodyStyle.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: accent ? AppTheme.goldColor : context.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
