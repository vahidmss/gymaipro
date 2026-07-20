import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/features/product_experience/presentation/metric_guide_card.dart';
import 'package:gymaipro/features/product_experience/training_metric_guides.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

/// Shared set row UI used in Workout Log and Live Workout.
class WorkoutSetEntryRow extends StatelessWidget {
  const WorkoutSetEntryRow({
    required this.setIndex,
    required this.isSaved,
    required this.setControllers,
    required this.style,
    required this.onSaveSet,
    this.focusNodes,
    this.isLastSet = false,
    this.defaultReps,
    this.defaultTimeSeconds,
    this.onFocusNextSet,
    super.key,
  });

  final int setIndex;
  final bool isSaved;
  final Map<String, TextEditingController> setControllers;
  final ExerciseStyle style;
  final VoidCallback onSaveSet;
  final Map<String, FocusNode>? focusNodes;
  final bool isLastSet;
  final int? defaultReps;
  final int? defaultTimeSeconds;
  final void Function(int nextSetIndex, String fieldType)? onFocusNextSet;

  @override
  Widget build(BuildContext context) {
    final isDark = WorkoutLogColors.isDark(context);
    final savedReps = setControllers['reps']?.text.trim() ?? '';
    final savedTime = setControllers['time']?.text.trim() ?? '';
    final savedWeight = setControllers['weight']?.text.trim() ?? '';

    final numericHint = style == ExerciseStyle.setsReps
        ? (savedReps.isNotEmpty ? savedReps : (defaultReps?.toString() ?? ''))
        : (savedTime.isNotEmpty
              ? savedTime
              : (defaultTimeSeconds?.toString() ?? ''));

    final weightHint = savedWeight.isNotEmpty ? savedWeight : '0';
    final isEven = setIndex.isEven;

    final cardFill = isSaved
        ? WorkoutLogColors.successBackground(context)
        : isEven
        ? WorkoutLogColors.sectionBackground(context)
        : (isDark
              ? const Color(0xFF141414)
              : Colors.white.withValues(alpha: 0.92));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isSaved
              ? WorkoutLogColors.successBorder(context)
              : WorkoutLogColors.inputBorder(context).withValues(alpha: 0.9),
          width: isSaved ? 1.4.w : 1.w,
        ),
        boxShadow: isSaved
            ? <BoxShadow>[
                BoxShadow(
                  color: WorkoutLogColors.successBorder(
                    context,
                  ).withValues(alpha: 0.12),
                  blurRadius: 10.r,
                  offset: Offset(0, 3.h),
                ),
              ]
            : <BoxShadow>[
                BoxShadow(
                  color: (isDark ? Colors.black : AppTheme.lightTextColor)
                      .withValues(alpha: isDark ? 0.22 : 0.05),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 4.w,
                color: isSaved
                    ? WorkoutLogColors.successSolid(context)
                    : WorkoutLogColors.accent(context).withValues(
                        alpha: isEven ? 0.55 : 0.35,
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _SetBadge(
                            setIndex: setIndex,
                            isSaved: isSaved,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _MetricInputGroup(
                              children: <Widget>[
                                Expanded(
                                  flex: style == ExerciseStyle.setsReps
                                      ? 5
                                      : 10,
                                  child: TextField(
                                    controller: style == ExerciseStyle.setsReps
                                        ? setControllers['reps']
                                        : setControllers['time'],
                                    focusNode: focusNodes != null
                                        ? (style == ExerciseStyle.setsReps
                                              ? focusNodes!['reps']
                                              : focusNodes!['time'])
                                        : null,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    textInputAction:
                                        style == ExerciseStyle.setsReps
                                        ? TextInputAction.next
                                        : (isLastSet
                                              ? TextInputAction.done
                                              : TextInputAction.next),
                                    enableSuggestions: false,
                                    autocorrect: false,
                                    onSubmitted: (_) {
                                      if (style == ExerciseStyle.setsReps) {
                                        focusNodes?['weight']?.requestFocus();
                                      } else if (isLastSet) {
                                        focusNodes?['time']?.unfocus();
                                      } else {
                                        onFocusNextSet?.call(
                                          setIndex + 1,
                                          'time',
                                        );
                                      }
                                      onSaveSet();
                                    },
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: WorkoutLogTypography.inputValue(
                                      context,
                                    ).copyWith(fontSize: 16.sp),
                                    decoration:
                                        WorkoutSetEntryDecorations.input(
                                          context: context,
                                          hintText: numericHint.isNotEmpty
                                              ? numericHint
                                              : '0',
                                          prefixText: style ==
                                                  ExerciseStyle.setsReps
                                              ? 'تکرار '
                                              : 'زمان ',
                                          suffixText:
                                              style == ExerciseStyle.setsTime
                                              ? 'ث'
                                              : null,
                                          grouped: true,
                                        ),
                                  ),
                                ),
                                if (style == ExerciseStyle.setsReps) ...<Widget>[
                                  _GroupDivider(context: context),
                                  Expanded(
                                    flex: 6,
                                    child: TextField(
                                      controller: setControllers['weight'],
                                      focusNode: focusNodes?['weight'],
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      textAlign: TextAlign.center,
                                      textInputAction: isLastSet
                                          ? TextInputAction.done
                                          : TextInputAction.next,
                                      enableSuggestions: false,
                                      autocorrect: false,
                                      onSubmitted: (_) {
                                        if (isLastSet) {
                                          focusNodes?['weight']?.unfocus();
                                        } else {
                                          onFocusNextSet?.call(
                                            setIndex + 1,
                                            'reps',
                                          );
                                        }
                                        onSaveSet();
                                      },
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(
                                          RegExp('[0-9.]'),
                                        ),
                                      ],
                                      style: WorkoutLogTypography.inputValue(
                                        context,
                                      ).copyWith(fontSize: 16.sp),
                                      decoration:
                                          WorkoutSetEntryDecorations.input(
                                            context: context,
                                            hintText: weightHint,
                                            prefixText: 'وزن ',
                                            suffixText: 'کیلو',
                                            grouped: true,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (style == ExerciseStyle.setsReps) ...<Widget>[
                        SizedBox(height: 8.h),
                        Row(
                          children: <Widget>[
                            Text(
                              'شدت',
                              style: WorkoutLogTypography.caption(
                                context,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'راهنمای شدت تلاش',
                              onPressed: () => showMetricGuideDialog(
                                context,
                                title: TrainingMetricGuides.rpeTitle,
                                explanation:
                                    TrainingMetricGuides.rpeExplanation,
                              ),
                              icon: Icon(
                                Icons.info_outline_rounded,
                                size: 15.sp,
                                color: WorkoutLogColors.accent(context),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            SizedBox(
                              width: 72.w,
                              child: TextField(
                                controller: setControllers['rpe'],
                                focusNode: focusNodes?['rpe'],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                textInputAction: TextInputAction.done,
                                enableSuggestions: false,
                                autocorrect: false,
                                onSubmitted: (_) => onSaveSet(),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: WorkoutLogTypography.inputValue(
                                  context,
                                ).copyWith(fontSize: 14.sp),
                                decoration: WorkoutSetEntryDecorations.input(
                                  context: context,
                                  hintText: '۱–۱۰',
                                  compact: true,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (isSaved)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 14.sp,
                                    color: WorkoutLogColors.successText(
                                      context,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'ثبت شد',
                                    style: WorkoutLogTypography.caption(
                                      context,
                                      color: WorkoutLogColors.successText(
                                        context,
                                      ),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ] else if (isSaved)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14.sp,
                                color: WorkoutLogColors.successText(context),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'ثبت شد',
                                style: WorkoutLogTypography.caption(
                                  context,
                                  color: WorkoutLogColors.successText(context),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetBadge extends StatelessWidget {
  const _SetBadge({
    required this.setIndex,
    required this.isSaved,
  });

  final int setIndex;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: WorkoutLogColors.setBadgeFill(context, isSaved: isSaved),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSaved
              ? WorkoutLogColors.successBorder(context)
              : WorkoutLogColors.accent(context).withValues(alpha: 0.4),
          width: 1.2.w,
        ),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: isSaved
              ? Icon(
                  Icons.check_rounded,
                  key: const ValueKey('check'),
                  color: Colors.white,
                  size: 18.sp,
                )
              : Text(
                  '${setIndex + 1}',
                  key: ValueKey('number-$setIndex'),
                  style: TextStyle(
                    color: WorkoutLogColors.setBadgeText(
                      context,
                      isSaved: isSaved,
                    ),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
        ),
      ),
    );
  }
}

class _MetricInputGroup extends StatelessWidget {
  const _MetricInputGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WorkoutLogColors.inputFill(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: WorkoutLogColors.inputBorder(context),
          width: 1.w,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.w,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      color: WorkoutLogColors.inputBorder(context),
    );
  }
}

abstract final class WorkoutSetEntryDecorations {
  static InputDecoration input({
    required BuildContext context,
    required String hintText,
    String? prefixText,
    String? suffixText,
    bool grouped = false,
    bool compact = false,
  }) {
    final borderRadius = grouped
        ? BorderRadius.zero
        : BorderRadius.circular(10.r);

    return InputDecoration(
      hintText: hintText,
      hintStyle: WorkoutLogTypography.inputHint(context).copyWith(
        fontSize: compact ? 12.sp : 14.sp,
      ),
      prefixText: prefixText,
      prefixStyle: WorkoutLogTypography.caption(
        context,
        fontWeight: FontWeight.w700,
      ),
      suffixText: suffixText,
      suffixStyle: WorkoutLogTypography.inputSuffix(context),
      filled: !grouped,
      fillColor: grouped ? Colors.transparent : WorkoutLogColors.inputFill(context),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: grouped
            ? BorderSide.none
            : BorderSide(
                color: WorkoutLogColors.inputBorder(context),
                width: 1.w,
              ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: grouped
            ? BorderSide.none
            : BorderSide(
                color: WorkoutLogColors.inputBorderFocused(context),
                width: 1.6.w,
              ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 8.w : 10.w,
        vertical: compact ? 7.h : 11.h,
      ),
      isDense: true,
    );
  }
}
