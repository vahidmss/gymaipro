import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// انتخاب کاربر وقتی وسط استراحت می‌خواهد ست بعدی را ثبت کند.
enum RestStillActiveChoice {
  /// تایمر ادامه؛ ثبت انجام نشود
  wait,

  /// استراحت رد شود و ثبت ادامه یابد
  skipAndSave,
}

/// نوار استراحت — داک نزدیک اکشن (بالای نام‌پد)، نه FAB.
class WorkoutRestTimerBar extends StatefulWidget {
  const WorkoutRestTimerBar({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.onTogglePause,
    required this.onMinus15,
    required this.onPlus15,
    required this.onSkip,
    this.attentionToken = 0,
    super.key,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final VoidCallback onTogglePause;
  final VoidCallback onMinus15;
  final VoidCallback onPlus15;
  final VoidCallback onSkip;

  /// با افزایش، یک پالس توجه کوتاه اجرا می‌شود.
  final int attentionToken;

  static String format(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  State<WorkoutRestTimerBar> createState() => _WorkoutRestTimerBarState();
}

class _WorkoutRestTimerBarState extends State<WorkoutRestTimerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didUpdateWidget(covariant WorkoutRestTimerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attentionToken != oldWidget.attentionToken &&
        widget.attentionToken > 0) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalSeconds <= 0
        ? 0.0
        : (widget.remainingSeconds / widget.totalSeconds).clamp(0.0, 1.0);
    final accent = WorkoutLogColors.successSolid(context);
    final bg = WorkoutLogColors.sectionBackground(context);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_pulse.value);
        final glow = accent.withValues(alpha: 0.14 * (1 - t));
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(bg, accent.withValues(alpha: 0.12), t * 0.55),
            border: Border(
              top: BorderSide(
                color: Color.lerp(
                  WorkoutLogColors.inputBorder(context),
                  accent,
                  t,
                )!,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: glow,
                blurRadius: 18.r,
                offset: Offset(0, -4.h),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRect(
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3.h,
              backgroundColor: WorkoutLogColors.inputBorder(context)
                  .withValues(alpha: 0.55),
              color: accent,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 6.w, 8.h),
            child: Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.timer,
                    size: 14.sp,
                    color: WorkoutLogColors.successText(context),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'استراحت',
                  style: WorkoutLogTypography.caption(
                    context,
                    color: WorkoutLogColors.successText(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _ChipButton(label: '−۱۵', onTap: widget.onMinus15),
                SizedBox(width: 8.w),
                Text(
                  WorkoutRestTimerBar.format(widget.remainingSeconds),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: WorkoutLogColors.primaryText(context),
                    letterSpacing: 0.6,
                    height: 1,
                  ),
                ),
                SizedBox(width: 8.w),
                _ChipButton(label: '+۱۵', onTap: widget.onPlus15),
                SizedBox(width: 2.w),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      BoxConstraints.tightFor(width: 34.w, height: 34.w),
                  tooltip: widget.isRunning ? 'توقف' : 'ادامه',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onTogglePause();
                  },
                  icon: Icon(
                    widget.isRunning ? LucideIcons.pause : LucideIcons.play,
                    size: 16.sp,
                    color: WorkoutLogColors.secondaryText(context),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      BoxConstraints.tightFor(width: 34.w, height: 34.w),
                  tooltip: 'رد کردن',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onSkip();
                  },
                  icon: Icon(
                    LucideIcons.x,
                    size: 16.sp,
                    color: WorkoutLogColors.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WorkoutLogColors.chipFill(context, selected: false),
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
          child: Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: WorkoutLogColors.secondaryText(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// شیت کوتاه وقتی کاربر وسط استراحت می‌خواهد ست ثبت کند — بدون قفل کردن ثبت اجباری.
Future<RestStillActiveChoice?> showRestStillActiveSheet(
  BuildContext context, {
  required int remainingSeconds,
}) {
  return showModalBottomSheet<RestStillActiveChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16.w,
            0,
            16.w,
            12.h + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Material(
            color: WorkoutLogColors.sectionBackground(ctx),
            borderRadius: BorderRadius.circular(18.r),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: WorkoutLogColors.successSolid(ctx)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.timer,
                          size: 17.sp,
                          color: WorkoutLogColors.successText(ctx),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'استراحت هنوز تموم نشده',
                              style: WorkoutLogTypography.sectionTitle(ctx)
                                  .copyWith(fontSize: 14.5.sp),
                            ),
                            SizedBox(height: 2.h),
                            Text.rich(
                              TextSpan(
                                style: WorkoutLogTypography.caption(
                                  ctx,
                                  color: WorkoutLogColors.mutedText(ctx),
                                ),
                                children: [
                                  const TextSpan(text: 'حدود '),
                                  TextSpan(
                                    text: WorkoutRestTimerBar.format(
                                      remainingSeconds,
                                    ),
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontWeight: FontWeight.w900,
                                      color: WorkoutLogColors.successText(ctx),
                                    ),
                                  ),
                                  const TextSpan(text: ' مانده'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  FilledButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx, RestStillActiveChoice.skipAndSave);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: WorkoutLogColors.successSolid(ctx),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'رد کردن و ثبت ست',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx, RestStillActiveChoice.wait);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: WorkoutLogColors.secondaryText(ctx),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    child: Text(
                      'صبر می‌کنم',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// انتخاب سریع مدت استراحت پیش‌فرض (۰ = خاموش).
Future<int?> showRestDurationPicker(
  BuildContext context, {
  required int currentSeconds,
}) {
  const options = <(int, String)>[
    (0, 'خاموش'),
    (60, '۶۰ ث'),
    (90, '۹۰ ث'),
    (120, '۲ دقیقه'),
    (180, '۳ دقیقه'),
  ];

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16.w,
            0,
            16.w,
            12.h + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Material(
            color: WorkoutLogColors.sectionBackground(ctx),
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'استراحت بین ست‌ها',
                    style: WorkoutLogTypography.sectionTitle(ctx),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'بعد از ثبت هر ست، تایمر خودکار شروع می‌شود',
                    style: WorkoutLogTypography.caption(
                      ctx,
                      color: WorkoutLogColors.mutedText(ctx),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final (seconds, label) in options)
                        _DurationChoice(
                          label: label,
                          selected: currentSeconds == seconds,
                          onTap: () => Navigator.pop(ctx, seconds),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DurationChoice extends StatelessWidget {
  const _DurationChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.goldColor.withValues(alpha: 0.18)
          : WorkoutLogColors.chipFill(context, selected: false),
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: selected
                  ? AppTheme.goldColor
                  : WorkoutLogColors.primaryText(context),
            ),
          ),
        ),
      ),
    );
  }
}
