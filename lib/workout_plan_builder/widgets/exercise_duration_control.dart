import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Compact tappable time chip — opens a duration picker.
class ExerciseDurationControl extends StatelessWidget {
  const ExerciseDurationControl({
    required this.seconds,
    required this.onChanged,
    super.key,
    this.min = 1,
    this.max = 600,
    this.compact = false,
  });

  final int seconds;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool compact;

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showExerciseDurationPicker(
      context,
      currentSeconds: seconds,
      min: min,
      max: max,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = formatExerciseDuration(seconds);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          Text(
            'زمان',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark ? AppTheme.goldColor : context.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(width: 6.w),
        ],
        Material(
          color: isDark ? AppTheme.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          child: InkWell(
            onTap: () => _openPicker(context),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8.w : 10.w,
                vertical: compact ? 5.h : 6.h,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.25 : 0.2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.goldColor,
                      fontSize: compact ? 11.sp : 12.sp,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 12.sp,
                    color: AppTheme.goldColor.withValues(alpha: 0.65),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<int?> showExerciseDurationPicker(
  BuildContext context, {
  required int currentSeconds,
  int min = 1,
  int max = 600,
}) {
  const presets = <(int, String)>[
    (30, '۳۰ث'),
    (45, '۴۵ث'),
    (60, '۱د'),
    (90, '۱:۳۰'),
    (120, '۲د'),
    (180, '۳د'),
    (300, '۵د'),
    (600, '۱۰د'),
  ];

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      var total = currentSeconds.clamp(min, max);

      return Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final bottom = MediaQuery.paddingOf(ctx).bottom;
            final minutes = total ~/ 60;
            final secs = total % 60;
            final muted = sheetContext.textColor.withValues(alpha: 0.45);

            void applyTotal(int value) {
              setLocal(() => total = value.clamp(min, max));
            }

            void applyParts({int? m, int? s}) {
              final nextM = m ?? minutes;
              final nextS = s ?? secs;
              var next = nextM * 60 + nextS;
              if (next < min) next = min;
              if (next > max) next = max;
              applyTotal(next);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h + bottom),
              child: Material(
                color: isDark
                    ? sheetContext.backgroundColor
                    : sheetContext.cardColor,
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: muted.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        formatExerciseDuration(total),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: sheetContext.textColor,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final (value, label) in presets)
                            if (value >= min && value <= max)
                              _PresetChip(
                                label: label,
                                selected: total == value,
                                onTap: () => applyTotal(value),
                              ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            Expanded(
                              child: _WheelColumn(
                                label: 'دقیقه',
                                value: minutes,
                                min: 0,
                                max: max ~/ 60,
                                onChanged: (v) => applyParts(m: v),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Text(
                                ':',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w600,
                                  color: muted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _WheelColumn(
                                label: 'ثانیه',
                                value: secs,
                                min: 0,
                                max: 59,
                                step: 5,
                                onChanged: (v) => applyParts(s: v),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldColor,
                          foregroundColor: AppTheme.onGoldColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        onPressed: () => Navigator.pop(ctx, total),
                        child: Text(
                          'تأیید',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? AppTheme.goldColor
          : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.lightButtonBackground),
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppTheme.onGoldColor
                  : context.textColor.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = context.textColor.withValues(alpha: 0.4);
    final canDec = value > min;
    final canInc = value < max;

    return Column(
      children: [
        _TapIcon(
          icon: LucideIcons.chevronUp,
          enabled: canInc,
          onTap: () => onChanged((value + step).clamp(min, max)),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 26.sp,
            fontWeight: FontWeight.w700,
            color: context.textColor,
            height: 1.2,
          ),
        ),
        _TapIcon(
          icon: LucideIcons.chevronDown,
          enabled: canDec,
          onTap: () => onChanged((value - step).clamp(min, max)),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? muted : context.textColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _TapIcon extends StatelessWidget {
  const _TapIcon({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? context.textColor.withValues(alpha: 0.7)
        : context.textColor.withValues(alpha: 0.2);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8.r),
      child: SizedBox(
        width: 40.w,
        height: 32.h,
        child: Icon(icon, size: 18.sp, color: color),
      ),
    );
  }
}
