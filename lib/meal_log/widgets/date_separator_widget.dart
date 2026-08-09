import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// چیپ تاریخ جمع‌وجور با swipe و دکمه‌های روز قبل/بعد.
class DateSeparatorWidget extends StatelessWidget {
  const DateSeparatorWidget({
    required this.selectedDate,
    this.onTap,
    this.onPreviousDay,
    this.onNextDay,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback? onTap;
  final VoidCallback? onPreviousDay;
  final VoidCallback? onNextDay;

  @override
  Widget build(BuildContext context) {
    final dateText = MealLogUtils.getPersianFormattedDate(selectedDate);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 180) {
          onPreviousDay?.call();
        } else if (v < -180) {
          onNextDay?.call();
        }
      },
      child: Row(
        children: [
          _navButton(
            context,
            icon: LucideIcons.chevronRight,
            onTap: onPreviousDay,
            tooltip: 'روز قبل',
          ),
          Expanded(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(999.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: MealLogColors.sectionBackground(context),
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(
                        color: MealLogColors.chipBorder(
                          context,
                          selected: false,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 14.sp,
                          color: MealLogColors.accent(context),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          dateText,
                          style: MealLogTypography.sectionTitle(context)
                              .copyWith(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _navButton(
            context,
            icon: LucideIcons.chevronLeft,
            onTap: onNextDay,
            tooltip: 'روز بعد',
          ),
        ],
      ),
    );
  }

  Widget _navButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 18.sp,
        color: onTap == null
            ? MealLogColors.hintText(context)
            : MealLogColors.secondaryText(context),
      ),
    );
  }
}
