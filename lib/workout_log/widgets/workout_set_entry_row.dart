import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:gymaipro/workout_log/widgets/workout_set_numpad.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

/// ردیف ست به سبک Hevy/Strong:
/// مقدار بده → تیک بزن تا ثبت شود.
/// بعد از ثبت، ویرایش همان‌جا DB را به‌روز می‌کند.
class WorkoutSetEntryRow extends StatefulWidget {
  const WorkoutSetEntryRow({
    required this.setIndex,
    required this.isSaved,
    required this.setControllers,
    required this.style,
    required this.onSaveSet,
    this.onUnsaveSet,
    this.focusNodes,
    this.isLastSet = false,
    this.defaultReps,
    this.defaultWeight,
    this.defaultTimeSeconds,
    this.previousReps,
    this.previousWeight,
    this.previousTimeSeconds,
    this.showColumnLabels = false,
    this.numpad,
    this.onOpenNextSet,
    super.key,
  });

  final int setIndex;
  final bool isSaved;
  final Map<String, TextEditingController> setControllers;
  final ExerciseStyle style;
  final Future<bool> Function() onSaveSet;
  final VoidCallback? onUnsaveSet;
  final Map<String, FocusNode>? focusNodes;
  final bool isLastSet;
  /// هدف برنامه (fallback)
  final int? defaultReps;
  final double? defaultWeight;
  final int? defaultTimeSeconds;
  /// آخرین اجرای واقعی همان ست — اولویت هینت/seed
  final int? previousReps;
  final double? previousWeight;
  final int? previousTimeSeconds;
  final bool showColumnLabels;
  final WorkoutSetNumpadController? numpad;
  final VoidCallback? onOpenNextSet;

  @override
  State<WorkoutSetEntryRow> createState() => _WorkoutSetEntryRowState();
}

class _WorkoutSetEntryRowState extends State<WorkoutSetEntryRow> {
  int? get _hintReps => widget.previousReps ?? widget.defaultReps;
  double? get _hintWeight => widget.previousWeight ?? widget.defaultWeight;
  int? get _hintTime => widget.previousTimeSeconds ?? widget.defaultTimeSeconds;

  void _seedDefaults() {
    final c = widget.setControllers;
    if (widget.style == ExerciseStyle.setsReps) {
      if ((c['reps']?.text.trim().isEmpty ?? true) && _hintReps != null) {
        c['reps']!.text = _hintReps.toString();
      }
      if ((c['weight']?.text.trim().isEmpty ?? true) &&
          _hintWeight != null &&
          _hintWeight! > 0) {
        final w = _hintWeight!;
        c['weight']!.text =
            w == w.roundToDouble() ? w.toInt().toString() : w.toString();
      }
    } else {
      if ((c['time']?.text.trim().isEmpty ?? true) && _hintTime != null) {
        c['time']!.text = _hintTime.toString();
      }
    }
  }

  void _openDock(WorkoutSetNumpadFieldKind field) {
    final numpad = widget.numpad;
    if (numpad == null) return;

    // عمداً seed نمی‌کنیم — hint فقط نمایش است تا حس «ثبت‌شده» ندهد
    numpad.open(
      WorkoutSetNumpadSession(
        controllers: widget.setControllers,
        style: widget.style,
        isSaved: widget.isSaved,
        repsHint: _hintReps?.toString(),
        weightHint: _hintWeight != null && _hintWeight! > 0
            ? (_hintWeight == _hintWeight!.roundToDouble()
                  ? _hintWeight!.toInt().toString()
                  : _hintWeight.toString())
            : null,
        timeHint: _hintTime?.toString(),
        onCommit: () async {
          _seedDefaults();
          return widget.onSaveSet();
        },
        onUncommit: () => widget.onUnsaveSet?.call(),
        onPersistEdits: () {
          unawaited(widget.onSaveSet());
        },
        onFinished: widget.isLastSet ? null : widget.onOpenNextSet,
        field: field,
      ),
      field: field,
    );
  }

  String _displayOrHint(String raw, String hint) =>
      raw.trim().isNotEmpty ? raw.trim() : hint;

  @override
  Widget build(BuildContext context) {
    final numpad = widget.numpad;

    Widget buildRow() {
      final isSaved = widget.isSaved;
      final style = widget.style;
      final c = widget.setControllers;
      final active = numpad?.isSessionFor(c) ?? false;

      final repsHint = _hintReps?.toString() ?? '—';
      final weightHint = _hintWeight != null && _hintWeight! > 0
          ? (_hintWeight == _hintWeight!.roundToDouble()
                ? _hintWeight!.toInt().toString()
                : _hintWeight.toString())
          : '—';
      final timeHint = _hintTime?.toString() ?? '—';

      final repsEmpty = c['reps']?.text.trim().isEmpty ?? true;
      final weightEmpty = c['weight']?.text.trim().isEmpty ?? true;
      final timeEmpty = c['time']?.text.trim().isEmpty ?? true;
      final rpeEmpty = c['rpe']?.text.trim().isEmpty ?? true;

      return Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.symmetric(vertical: 2.h),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isSaved
                ? WorkoutLogColors.successBackground(context).withValues(
                    alpha: 0.45,
                  )
                : (active
                      ? AppTheme.goldColor.withValues(alpha: 0.06)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: active
                  ? AppTheme.goldColor.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              _SetCheck(
                setIndex: widget.setIndex,
                isSaved: isSaved,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  if (isSaved) {
                    numpad?.close(persistEdits: false);
                    (widget.onUnsaveSet ?? () {
                      unawaited(widget.onSaveSet());
                    })();
                  } else {
                    _seedDefaults();
                    final ok = await widget.onSaveSet();
                    if (!mounted || !ok) return;
                    if (!widget.isLastSet && widget.onOpenNextSet != null) {
                      // پد را نببند؛ مستقیم برو ست بعدی
                      widget.onOpenNextSet!();
                    } else {
                      numpad?.close(persistEdits: false);
                    }
                  }
                },
              ),
              SizedBox(width: 8.w),
              if (style == ExerciseStyle.setsReps) ...[
                Expanded(
                  child: _ValueChip(
                    value: _displayOrHint(c['reps']?.text ?? '', repsHint),
                    muted: repsEmpty,
                    isHint: repsEmpty,
                    active: numpad?.isEditing(c['reps']) ?? false,
                    onTap: () => _openDock(WorkoutSetNumpadFieldKind.reps),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    '×',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: WorkoutLogColors.mutedText(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: _ValueChip(
                    value: _displayOrHint(c['weight']?.text ?? '', weightHint),
                    suffix: 'kg',
                    muted: weightEmpty,
                    isHint: weightEmpty,
                    active: numpad?.isEditing(c['weight']) ?? false,
                    onTap: () => _openDock(WorkoutSetNumpadFieldKind.weight),
                  ),
                ),
                SizedBox(width: 6.w),
                SizedBox(
                  width: 40.w,
                  child: _ValueChip(
                    value: rpeEmpty ? '—' : c['rpe']!.text.trim(),
                    muted: rpeEmpty,
                    isHint: rpeEmpty,
                    active: numpad?.isEditing(c['rpe']) ?? false,
                    onTap: () => _openDock(WorkoutSetNumpadFieldKind.rpe),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: _ValueChip(
                    value: _displayOrHint(c['time']?.text ?? '', timeHint),
                    suffix: 'ث',
                    muted: timeEmpty,
                    isHint: timeEmpty,
                    active: numpad?.isEditing(c['time']) ?? false,
                    onTap: () => _openDock(WorkoutSetNumpadFieldKind.time),
                  ),
                ),
                SizedBox(width: 6.w),
                SizedBox(
                  width: 40.w,
                  child: _ValueChip(
                    value: rpeEmpty ? '—' : c['rpe']!.text.trim(),
                    muted: rpeEmpty,
                    isHint: rpeEmpty,
                    active: numpad?.isEditing(c['rpe']) ?? false,
                    onTap: () => _openDock(WorkoutSetNumpadFieldKind.rpe),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (numpad == null) {
      // مسیر بدون پد (مثلاً live workout) — کیبورد سیستم
      return _LegacyEditableRow(
        setIndex: widget.setIndex,
        isSaved: widget.isSaved,
        setControllers: widget.setControllers,
        style: widget.style,
        defaultReps: _hintReps,
        defaultWeight: _hintWeight,
        defaultTimeSeconds: _hintTime,
        isLastSet: widget.isLastSet,
        onSaveSet: widget.onSaveSet,
        onUnsaveSet: widget.onUnsaveSet,
      );
    }
    return ListenableBuilder(
      listenable: numpad,
      builder: (context, _) => buildRow(),
    );
  }
}

class _LegacyEditableRow extends StatelessWidget {
  const _LegacyEditableRow({
    required this.setIndex,
    required this.isSaved,
    required this.setControllers,
    required this.style,
    required this.onSaveSet,
    required this.isLastSet,
    this.onUnsaveSet,
    this.defaultReps,
    this.defaultWeight,
    this.defaultTimeSeconds,
  });

  final int setIndex;
  final bool isSaved;
  final Map<String, TextEditingController> setControllers;
  final ExerciseStyle style;
  final Future<bool> Function() onSaveSet;
  final VoidCallback? onUnsaveSet;
  final bool isLastSet;
  final int? defaultReps;
  final double? defaultWeight;
  final int? defaultTimeSeconds;

  @override
  Widget build(BuildContext context) {
    final repsHint = defaultReps?.toString() ?? '0';
    final weightHint = defaultWeight != null && defaultWeight! > 0
        ? defaultWeight!.toString()
        : '0';
    final timeHint = defaultTimeSeconds?.toString() ?? '0';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          children: [
            _SetCheck(
              setIndex: setIndex,
              isSaved: isSaved,
              onTap: () async {
                if (isSaved) {
                  (onUnsaveSet ?? () {
                    unawaited(onSaveSet());
                  })();
                } else {
                  await onSaveSet();
                }
              },
            ),
            SizedBox(width: 8.w),
            if (style == ExerciseStyle.setsReps) ...[
              Expanded(
                child: _MiniField(
                  controller: setControllers['reps'],
                  hint: repsHint,
                  emphasized: isSaved,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: const Text('×'),
              ),
              Expanded(
                child: _MiniField(
                  controller: setControllers['weight'],
                  hint: weightHint,
                  suffix: 'kg',
                  decimal: true,
                  emphasized: isSaved,
                ),
              ),
              SizedBox(width: 6.w),
              SizedBox(
                width: 46.w,
                child: _MiniField(
                  controller: setControllers['rpe'],
                  hint: 'RPE',
                  emphasized: isSaved,
                ),
              ),
            ] else ...[
              Expanded(
                child: _MiniField(
                  controller: setControllers['time'],
                  hint: timeHint,
                  suffix: 'ث',
                  emphasized: isSaved,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  const _MiniField({
    required this.hint,
    this.controller,
    this.suffix,
    this.decimal = false,
    this.emphasized = false,
  });

  final TextEditingController? controller;
  final String hint;
  final String? suffix;
  final bool decimal;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      style: WorkoutLogTypography.inputValue(context).copyWith(fontSize: 14.sp),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: emphasized
            ? WorkoutLogColors.successBackground(context).withValues(alpha: 0.5)
            : AppTheme.lightSurfaceColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 7.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SetCheck extends StatelessWidget {
  const _SetCheck({
    required this.setIndex,
    required this.isSaved,
    required this.onTap,
  });

  final int setIndex;
  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 24.w,
          height: 24.w,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSaved
                  ? WorkoutLogColors.successSolid(context)
                  : Colors.transparent,
              border: Border.all(
                color: isSaved
                    ? WorkoutLogColors.successSolid(context)
                    : WorkoutLogColors.inputBorder(context),
                width: 1.3.w,
              ),
            ),
            child: Center(
              child: isSaved
                  ? Icon(Icons.check_rounded, color: Colors.white, size: 14.sp)
                  : Text(
                      '${setIndex + 1}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.sp,
                        color: WorkoutLogColors.secondaryText(context),
                        height: 1,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({
    required this.value,
    required this.onTap,
    this.suffix,
    this.muted = false,
    this.isHint = false,
    this.active = false,
  });

  final String value;
  final String? suffix;
  final bool muted;
  final bool isHint;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ghost = muted || isHint;
    return Material(
      color: active
          ? AppTheme.goldColor.withValues(alpha: 0.12)
          : (WorkoutLogColors.isDark(context)
                ? const Color(0xFF141414)
                : const Color(0xFFF3F1EC)),
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: active
                  ? AppTheme.goldColor
                  : (isHint
                        ? WorkoutLogColors.inputBorder(context)
                        : Colors.transparent),
              width: 1.1.w,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: isHint ? 13.sp : 14.sp,
                    fontWeight: isHint ? FontWeight.w600 : FontWeight.w800,
                    fontStyle: isHint ? FontStyle.italic : FontStyle.normal,
                    color: ghost
                        ? WorkoutLogColors.mutedText(context)
                            .withValues(alpha: 0.75)
                        : WorkoutLogColors.primaryText(context),
                  ),
                ),
              ),
              if (suffix != null) ...[
                SizedBox(width: 2.w),
                Text(
                  suffix!,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9.sp,
                    color: WorkoutLogColors.mutedText(context)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
