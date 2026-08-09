import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WorkoutLogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WorkoutLogAppBar({
    required this.selectedDate,
    required this.onBackPressed,
    this.onLogSummaryPressed,
    this.onHeatmapPressed,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback onBackPressed;

  /// خلاصهٔ ست‌های ثبت‌شده (دفترچه)
  final VoidCallback? onLogSummaryPressed;

  /// نقشهٔ عضلانی جلسه
  final VoidCallback? onHeatmapPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActions =
        onLogSummaryPressed != null || onHeatmapPressed != null;

    return AppBar(
      backgroundColor: isDark ? context.backgroundColor : Colors.transparent,
      elevation: 0,
      leading: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: onBackPressed,
          child: Container(
            width: 36.w,
            height: 36.h,
            padding: EdgeInsets.all(6.w),
            child: Icon(
              LucideIcons.arrowRight,
              color: WorkoutLogColors.iconOnSurface(context),
              size: 22.sp,
            ),
          ),
        ),
      ),
      title: Text(
        'ثبت تمرین',
        style: WorkoutLogTypography.sectionTitle(context).copyWith(
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
          color: WorkoutLogColors.primaryText(context),
        ),
      ),
      centerTitle: true,
      actions: [
        if (onLogSummaryPressed != null)
          _AppBarIconButton(
            tooltip: 'خلاصه ثبت',
            icon: LucideIcons.notebookText,
            onTap: () {
              HapticFeedback.selectionClick();
              onLogSummaryPressed!();
            },
          ),
        if (onHeatmapPressed != null)
          Tooltip(
            message: 'نقشه عضلات',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8.r),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onHeatmapPressed!();
                },
                child: SizedBox(
                  width: 36.w,
                  height: 36.h,
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Image.asset(
                      'assets/icons/heatmap_muscles.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        LucideIcons.flame,
                        color: WorkoutLogColors.iconOnSurface(context),
                        size: 18.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (hasActions) SizedBox(width: 4.w),
      ],
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: onTap,
          child: Container(
            width: 36.w,
            height: 36.h,
            padding: EdgeInsets.all(8.w),
            child: Icon(
              icon,
              color: WorkoutLogColors.iconOnSurface(context),
              size: 18.sp,
            ),
          ),
        ),
      ),
    );
  }
}
