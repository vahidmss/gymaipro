import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

enum WorkoutSetNumpadFieldKind { reps, weight, time, rpe }

/// جلسهٔ ویرایش یک ست روی پد (الگوی Hevy/Strong).
class WorkoutSetNumpadSession {
  WorkoutSetNumpadSession({
    required this.controllers,
    required this.style,
    required this.isSaved,
    required this.onCommit,
    required this.field,
    this.onUncommit,
    this.onFinished,
    this.onPersistEdits,
    this.repsHint,
    this.weightHint,
    this.timeHint,
  });

  final Map<String, TextEditingController> controllers;
  final ExerciseStyle style;
  final bool isSaved;
  final VoidCallback? onUncommit;

  /// بعد از ثبت موفق — مثلاً باز کردن ست بعدی.
  final VoidCallback? onFinished;

  /// بستن پد وقتی ست از قبل ثبت بوده → آپدیت DB.
  final VoidCallback? onPersistEdits;

  /// راهنمای برنامه (فقط نمایش؛ تا قبل از ثبت در controller نوشته نمی‌شود)
  final String? repsHint;
  final String? weightHint;
  final String? timeHint;

  WorkoutSetNumpadFieldKind field;

  /// `true` = ثبت شد؛ `false` = لغو/رد (مثلاً وسط استراحت صبر کرد).
  final Future<bool> Function() onCommit;

  TextEditingController? get activeController {
    switch (field) {
      case WorkoutSetNumpadFieldKind.reps:
        return controllers['reps'];
      case WorkoutSetNumpadFieldKind.weight:
        return controllers['weight'];
      case WorkoutSetNumpadFieldKind.time:
        return controllers['time'];
      case WorkoutSetNumpadFieldKind.rpe:
        return controllers['rpe'];
    }
  }

  String? get activeHint {
    switch (field) {
      case WorkoutSetNumpadFieldKind.reps:
        return repsHint;
      case WorkoutSetNumpadFieldKind.weight:
        return weightHint;
      case WorkoutSetNumpadFieldKind.time:
        return timeHint;
      case WorkoutSetNumpadFieldKind.rpe:
        return null;
    }
  }

  bool get allowDecimal => field == WorkoutSetNumpadFieldKind.weight;

  String get fieldTitle {
    switch (field) {
      case WorkoutSetNumpadFieldKind.reps:
        return 'تکرار';
      case WorkoutSetNumpadFieldKind.weight:
        return 'وزن';
      case WorkoutSetNumpadFieldKind.time:
        return 'زمان';
      case WorkoutSetNumpadFieldKind.rpe:
        return 'شدت';
    }
  }
}

/// کنترلر پد — بدون IME؛ ذخیره فقط با تیک.
class WorkoutSetNumpadController extends ChangeNotifier {
  WorkoutSetNumpadSession? _session;
  bool _replaceNext = true;
  bool _committing = false;

  WorkoutSetNumpadSession? get session => _session;
  bool get isOpen => _session != null;

  static double contentHeight(BuildContext context) => 196.h;

  bool isEditing(TextEditingController? c) =>
      c != null && identical(_session?.activeController, c);

  bool isSessionFor(Map<String, TextEditingController> controllers) =>
      identical(_session?.controllers, controllers);

  /// تیک روی پد = ثبت/لغو همان ست.
  Future<void> toggleCommit() async {
    final s = _session;
    if (s == null || _committing) return;
    HapticFeedback.mediumImpact();
    if (s.isSaved) {
      s.onUncommit?.call();
      close(persistEdits: false);
      return;
    }

    _committing = true;
    try {
      final ok = await s.onCommit();
      if (!ok) return;
      // جلسه ممکن است وسط await عوض شده باشد
      if (!identical(_session, s)) return;
      final next = s.onFinished;
      if (next != null) {
        // پد را نببند — فقط جلسه را عوض کن تا صفحه بالا/پایین نپرد
        next();
        return;
      }
      _session = null;
      _replaceNext = true;
      notifyListeners();
    } finally {
      _committing = false;
    }
  }

  void open(
    WorkoutSetNumpadSession session, {
    required WorkoutSetNumpadFieldKind field,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    final prev = _session;
    final wasOpen = prev != null;
    if (prev != null &&
        prev.isSaved &&
        !identical(prev.controllers, session.controllers)) {
      prev.onPersistEdits?.call();
    }
    session.field = field;
    _session = session;
    _replaceNext = true;
    if (wasOpen) {
      // تعویض ست: فوری، بدون ensureVisible / پرش
      notifyListeners();
      return;
    }
    // باز شدن اول: بعد از ژست تپ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!identical(_session, session)) return;
      notifyListeners();
    });
  }

  void selectField(WorkoutSetNumpadFieldKind field) {
    final s = _session;
    if (s == null || s.field == field) return;
    s.field = field;
    _replaceNext = true;
    notifyListeners();
  }

  void close({bool persistEdits = true}) {
    if (_session == null) return;
    final s = _session!;
    final persist =
        persistEdits && s.isSaved ? s.onPersistEdits : null;
    _session = null;
    _replaceNext = true;
    notifyListeners();
    persist?.call();
  }

  void typeDigit(String digit) {
    final s = _session;
    final c = s?.activeController;
    if (s == null || c == null || digit.isEmpty) return;

    if (s.field == WorkoutSetNumpadFieldKind.rpe) {
      final next = _replaceNext ? digit : '${c.text}$digit';
      final n = int.tryParse(next);
      if (n == null || n < 1 || n > 10) return;
    }

    HapticFeedback.selectionClick();
    if (_replaceNext) {
      c.text = digit;
      _replaceNext = false;
    } else if (c.text == '0') {
      c.text = digit;
    } else {
      c.text = '${c.text}$digit';
    }
    c.selection = TextSelection.collapsed(offset: c.text.length);
    notifyListeners();
  }

  void type00() {
    final s = _session;
    final c = s?.activeController;
    if (s == null || c == null) return;
    if (s.field == WorkoutSetNumpadFieldKind.rpe) return;
    HapticFeedback.selectionClick();
    if (_replaceNext) {
      c.text = '00';
      _replaceNext = false;
    } else if (c.text.isEmpty || c.text == '0') {
      c.text = '00';
    } else {
      c.text = '${c.text}00';
    }
    c.selection = TextSelection.collapsed(offset: c.text.length);
    notifyListeners();
  }

  void typeDot() {
    final s = _session;
    final c = s?.activeController;
    if (s == null || c == null || !s.allowDecimal) return;
    HapticFeedback.selectionClick();
    if (_replaceNext) {
      c.text = '0.';
      _replaceNext = false;
    } else if (c.text.isEmpty) {
      c.text = '0.';
    } else if (!c.text.contains('.')) {
      c.text = '${c.text}.';
    }
    c.selection = TextSelection.collapsed(offset: c.text.length);
    notifyListeners();
  }

  void backspace() {
    final c = _session?.activeController;
    if (c == null) return;
    HapticFeedback.selectionClick();
    if (_replaceNext) {
      c.clear();
      _replaceNext = false;
      notifyListeners();
      return;
    }
    if (c.text.isEmpty) return;
    c.text = c.text.substring(0, c.text.length - 1);
    c.selection = TextSelection.collapsed(offset: c.text.length);
    notifyListeners();
  }
}

/// داک فشرده پایین صفحه.
class WorkoutSetNumpadBar extends StatelessWidget {
  const WorkoutSetNumpadBar({required this.controller, super.key});

  final WorkoutSetNumpadController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final session = controller.session;
        if (session == null) return const SizedBox.shrink();

        return Material(
          color: WorkoutLogColors.sectionBackground(context),
          elevation: 10,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: WorkoutSetNumpadController.contentHeight(context),
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    color: WorkoutLogColors.inputBorder(context),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(8.w, 6.h, 4.w, 4.h),
                    child: Row(
                      children: [
                        Expanded(child: _FieldTabs(session: session, controller: controller)),
                        SizedBox(width: 6.w),
                        ListenableBuilder(
                          listenable: session.activeController!,
                          builder: (context, _) {
                            final raw = session.activeController?.text ?? '';
                            final hint = session.activeHint;
                            final showingHint = raw.isEmpty &&
                                hint != null &&
                                hint.isNotEmpty;
                            return Text(
                              raw.isNotEmpty
                                  ? raw
                                  : (hint?.isNotEmpty == true ? hint! : '—'),
                              textDirection: TextDirection.ltr,
                              style: WorkoutLogTypography.inputValue(context)
                                  .copyWith(
                                fontSize: 18.sp,
                                fontWeight: showingHint
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: showingHint
                                    ? WorkoutLogColors.mutedText(context)
                                    : WorkoutLogColors.primaryText(context),
                              ),
                            );
                          },
                        ),
                        if (session.field == WorkoutSetNumpadFieldKind.weight)
                          Text(
                            'kg',
                            style: WorkoutLogTypography.caption(context)
                                .copyWith(fontSize: 10.sp),
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints.tightFor(
                            width: 32.w,
                            height: 32.w,
                          ),
                          onPressed: () => controller.close(),
                          icon: Icon(
                            Icons.keyboard_hide_rounded,
                            size: 18.sp,
                            color: WorkoutLogColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (session.field == WorkoutSetNumpadFieldKind.rpe)
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h, right: 10.w, left: 10.w),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '۱ آسان  ·  ۱۰ حداکثر توان',
                          style: WorkoutLogTypography.caption(
                            context,
                            color: WorkoutLogColors.mutedText(context),
                          ).copyWith(fontSize: 10.sp),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 6.h),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: _PadGrid(
                          allowDecimal: session.allowDecimal,
                          allow00:
                              session.field != WorkoutSetNumpadFieldKind.rpe,
                          isSaved: session.isSaved,
                          onDigit: controller.typeDigit,
                          on00: controller.type00,
                          onDot: controller.typeDot,
                          onBackspace: controller.backspace,
                          onCommit: controller.toggleCommit,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FieldTabs extends StatelessWidget {
  const _FieldTabs({required this.session, required this.controller});

  final WorkoutSetNumpadSession session;
  final WorkoutSetNumpadController controller;

  @override
  Widget build(BuildContext context) {
    final tabs = <(WorkoutSetNumpadFieldKind, String)>[
      if (session.style == ExerciseStyle.setsReps) ...[
        (WorkoutSetNumpadFieldKind.reps, 'تکرار'),
        (WorkoutSetNumpadFieldKind.weight, 'وزن'),
        (WorkoutSetNumpadFieldKind.rpe, 'RPE'),
      ] else ...[
        (WorkoutSetNumpadFieldKind.time, 'زمان'),
        (WorkoutSetNumpadFieldKind.rpe, 'RPE'),
      ],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: [
          for (final (kind, label) in tabs)
            Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: _TabChip(
                label: label,
                selected: session.field == kind,
                onTap: () => controller.selectField(kind),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
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
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: selected
                  ? AppTheme.goldColor
                  : WorkoutLogColors.secondaryText(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _PadGrid extends StatelessWidget {
  const _PadGrid({
    required this.allowDecimal,
    required this.allow00,
    required this.isSaved,
    required this.onDigit,
    required this.on00,
    required this.onDot,
    required this.onBackspace,
    required this.onCommit,
  });

  final bool allowDecimal;
  final bool allow00;
  final bool isSaved;
  final ValueChanged<String> onDigit;
  final VoidCallback on00;
  final VoidCallback onDot;
  final VoidCallback onBackspace;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _keys(context, ['1', '2', '3']),
              _keys(context, ['4', '5', '6']),
              _keys(context, ['7', '8', '9']),
              _keys(context, [allowDecimal ? '.' : '', '0', allow00 ? '00' : '']),
            ],
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _action(context, icon: Icons.backspace_outlined, onTap: onBackspace)),
              Expanded(
                flex: 3,
                child: _action(
                  context,
                  icon: isSaved ? Icons.close_rounded : Icons.check_rounded,
                  label: isSaved ? 'لغو' : 'ثبت',
                  emphasized: !isSaved,
                  danger: isSaved,
                  onTap: onCommit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _keys(BuildContext context, List<String> keys) {
    return Expanded(
      child: Row(
        children: [
          for (final k in keys)
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(1.5.w),
                child: k.isEmpty
                    ? const SizedBox.shrink()
                    : Material(
                        color: WorkoutLogColors.isDark(context)
                            ? const Color(0xFF1A1A1A)
                            : AppTheme.lightSurfaceColor,
                        borderRadius: BorderRadius.circular(8.r),
                        child: InkWell(
                          onTap: () {
                            if (k == '.') {
                              onDot();
                            } else if (k == '00') {
                              on00();
                            } else {
                              onDigit(k);
                            }
                          },
                          borderRadius: BorderRadius.circular(8.r),
                          child: Center(
                            child: Text(
                              k,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: k == '00' ? 13.sp : 17.sp,
                                fontWeight: FontWeight.w600,
                                color: WorkoutLogColors.primaryText(context),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required VoidCallback onTap,
    IconData? icon,
    String? label,
    bool emphasized = false,
    bool danger = false,
  }) {
    final bg = emphasized
        ? WorkoutLogColors.successSolid(context)
        : danger
        ? WorkoutLogColors.warningBackground(context)
        : (WorkoutLogColors.isDark(context)
              ? const Color(0xFF1A1A1A)
              : AppTheme.lightSurfaceColor);
    final fg = emphasized
        ? Colors.white
        : danger
        ? WorkoutLogColors.warningText(context)
        : WorkoutLogColors.secondaryText(context);

    return Padding(
      padding: EdgeInsets.all(1.5.w),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, size: 18.sp, color: fg),
                if (label != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
