import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/widgets/exercise_stepper.dart';

/// Compact style toggle: reps vs time.
class ExerciseStyleToggle extends StatelessWidget {
  const ExerciseStyleToggle({
    required this.style,
    required this.onChanged,
    super.key,
  });

  final ExerciseStyle style;
  final ValueChanged<ExerciseStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppTheme.lightButtonBackground,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'تکرار',
            selected: style == ExerciseStyle.setsReps,
            onTap: () => onChanged(ExerciseStyle.setsReps),
          ),
          _Segment(
            label: 'زمان',
            selected: style == ExerciseStyle.setsTime,
            onTap: () => onChanged(ExerciseStyle.setsTime),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
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
      color: selected ? AppTheme.goldColor : Colors.transparent,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppTheme.onGoldColor
                  : (isDark
                        ? AppTheme.goldColor.withValues(alpha: 0.85)
                        : context.textColor.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fast-path uniform editor; expands to per-set only when needed.
class SetSchemeEditor extends StatefulWidget {
  const SetSchemeEditor({
    required this.sets,
    required this.style,
    required this.onSetsChanged,
    required this.onSetValueChanged,
    required this.onApplyAllValues,
    super.key,
    this.restSeconds,
    this.onRestChanged,
  });

  final List<ExerciseSet> sets;
  final ExerciseStyle style;
  final ValueChanged<int> onSetsChanged;
  final void Function(int setIndex, int value) onSetValueChanged;
  final ValueChanged<int> onApplyAllValues;
  final int? restSeconds;
  final ValueChanged<int?>? onRestChanged;

  @override
  State<SetSchemeEditor> createState() => _SetSchemeEditorState();
}

class _SetSchemeEditorState extends State<SetSchemeEditor> {
  bool _forceCustom = false;
  bool _customRest = false;

  static const _restPresets = [45, 60, 90, 120, 150, 180];

  bool get _isReps => widget.style == ExerciseStyle.setsReps;

  bool get _uniform => areSetValuesUniform(widget.sets, widget.style);

  bool get _showPerSet => _forceCustom || !_uniform;

  int _valueOf(ExerciseSet set) {
    if (_isReps) return set.reps ?? 10;
    return set.timeSeconds ?? 30;
  }

  int get _primaryValue =>
      widget.sets.isEmpty ? (_isReps ? 10 : 30) : _valueOf(widget.sets.first);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.goldColor : context.textColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fast row: sets · reps/time
        Wrap(
          spacing: 10.w,
          runSpacing: 8.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LabeledStepper(
              label: 'ست',
              value: widget.sets.length,
              min: 1,
              max: 12,
              onChanged: widget.onSetsChanged,
            ),
            if (!_showPerSet)
              _LabeledStepper(
                label: _isReps ? 'تکرار' : 'ثانیه',
                value: _primaryValue,
                min: 1,
                max: _isReps ? 50 : 600,
                onChanged: widget.onApplyAllValues,
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  if (_showPerSet && !_uniform) {
                    widget.onApplyAllValues(_primaryValue);
                    _forceCustom = false;
                  } else {
                    _forceCustom = !_forceCustom;
                  }
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.goldColor,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                _showPerSet
                    ? (_uniform ? 'حالت ساده' : 'یکسان‌سازی')
                    : (_isReps ? 'تکرار متفاوت (مثل ۱۲-۱۰-۸)' : 'زمان متفاوت'),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (_showPerSet) ...[
          SizedBox(height: 6.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < widget.sets.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      child: Text(
                        '—',
                        style: TextStyle(
                          color: AppTheme.goldColor.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  _SetPill(
                    index: i + 1,
                    value: _valueOf(widget.sets[i]),
                    unit: _isReps ? null : 'ث',
                    onChanged: (v) => widget.onSetValueChanged(i, v),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (widget.onRestChanged != null) ...[
          SizedBox(height: 10.h),
          Text(
            'استراحت',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: labelColor.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
              fontSize: 10.sp,
            ),
          ),
          SizedBox(height: 5.h),
          Wrap(
            spacing: 5.w,
            runSpacing: 5.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _RestChip(
                label: 'پیش‌فرض',
                selected: widget.restSeconds == null && !_customRest,
                onTap: () {
                  setState(() => _customRest = false);
                  widget.onRestChanged!(null);
                },
              ),
              for (final sec in _restPresets)
                _RestChip(
                  label: '$secث',
                  selected: widget.restSeconds == sec && !_customRest,
                  onTap: () {
                    setState(() => _customRest = false);
                    widget.onRestChanged!(
                      widget.restSeconds == sec ? null : sec,
                    );
                  },
                ),
              _RestChip(
                label: 'سفارشی',
                selected: _customRest,
                onTap: () {
                  setState(() {
                    _customRest = true;
                    widget.onRestChanged!(widget.restSeconds ?? 90);
                  });
                },
              ),
              if (_customRest ||
                  (widget.restSeconds != null &&
                      !_restPresets.contains(widget.restSeconds)))
                ExerciseStepper(
                  value: widget.restSeconds ?? 90,
                  min: 15,
                  max: 600,
                  small: true,
                  suffix: 'ث',
                  onChanged: (v) {
                    setState(() => _customRest = true);
                    widget.onRestChanged!(v);
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LabeledStepper extends StatelessWidget {
  const _LabeledStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.onChanged,
    this.max,
    this.suffix,
  });

  final String label;
  final int value;
  final int min;
  final int? max;
  final String? suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark ? AppTheme.goldColor : context.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 11.sp,
          ),
        ),
        SizedBox(width: 6.w),
        ExerciseStepper(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          small: true,
          suffix: suffix,
        ),
      ],
    );
  }
}

class _SetPill extends StatelessWidget {
  const _SetPill({
    required this.index,
    required this.value,
    required this.onChanged,
    this.unit,
  });

  final int index;
  final int value;
  final String? unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 4.h, 6.w, 4.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.35),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$index',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.7)
                  : context.textColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 2.h),
          ExerciseStepper(
            value: value,
            min: 1,
            max: unit != null ? 600 : 50,
            onChanged: onChanged,
            small: true,
            suffix: unit,
          ),
        ],
      ),
    );
  }
}

class _RestChip extends StatelessWidget {
  const _RestChip({
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
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppTheme.onGoldColor
                  : (isDark
                        ? AppTheme.goldColor.withValues(alpha: 0.85)
                        : context.textColor.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ),
    );
  }
}
