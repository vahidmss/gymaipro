import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/nutrition_goal.dart';
import 'package:gymaipro/meal_log/services/nutrition_goal_service.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/utils/meal_nutrition_targets.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _PadField { weight, kcal }

/// Bottom sheet for setting a daily calorie goal — no system keyboard.
class NutritionGoalSheet extends StatefulWidget {
  const NutritionGoalSheet({
    required this.profileData,
    this.prefillTargetWeightKg,
    super.key,
  });

  final Map<String, dynamic>? profileData;
  final double? prefillTargetWeightKg;

  static Future<bool?> show(
    BuildContext context, {
    required Map<String, dynamic>? profileData,
    double? prefillTargetWeightKg,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.72)
          : AppTheme.lightTextColor.withValues(alpha: 0.48),
      builder: (context) => NutritionGoalSheet(
        profileData: profileData,
        prefillTargetWeightKg: prefillTargetWeightKg,
      ),
    );
  }

  @override
  State<NutritionGoalSheet> createState() => _NutritionGoalSheetState();
}

class _NutritionGoalSheetState extends State<NutritionGoalSheet> {
  final _service = NutritionGoalService();
  late NutritionGoalMode _mode;
  late double _weeklyRate;
  late String _targetWeight;
  late String _manualKcal;
  _PadField? _activePad;
  bool _replaceNext = false;
  bool _saving = false;

  late final MealNutritionTargets _targets;

  @override
  void initState() {
    super.initState();
    _targets = MealNutritionTargets.fromProfile(widget.profileData);
    final existing = NutritionGoal.fromProfileMap(widget.profileData);
    _mode = existing.mode.isActive ? existing.mode : NutritionGoalMode.lose;
    _weeklyRate = existing.weeklyRateKg ?? 0.5;
    final prefill = existing.targetWeightKg ?? widget.prefillTargetWeightKg;
    _targetWeight = prefill == null
        ? ''
        : prefill.toStringAsFixed(
            prefill == prefill.roundToDouble() ? 0 : 1,
          );
    _manualKcal =
        existing.mode == NutritionGoalMode.custom &&
            existing.calorieGoalKcal != null
        ? '${existing.calorieGoalKcal}'
        : '';
  }

  double? get _targetWeightValue {
    final raw = _targetWeight.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  int? get _manualKcalValue {
    final raw = _manualKcal.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  NutritionGoalPreview get _preview => _service.preview(
    profile: widget.profileData,
    mode: _mode,
    targetWeightKg: _targetWeightValue,
    weeklyRateKg: _weeklyRate,
    manualCalorieKcal: _manualKcalValue,
  );

  String get _activeValue =>
      _activePad == _PadField.kcal ? _manualKcal : _targetWeight;

  set _activeValue(String value) {
    if (_activePad == _PadField.kcal) {
      _manualKcal = value;
    } else {
      _targetWeight = value;
    }
  }

  void _selectMode(NutritionGoalMode mode) {
    setState(() {
      _mode = mode;
      final needsWeight =
          mode == NutritionGoalMode.lose || mode == NutritionGoalMode.gain;
      final needsKcal = mode == NutritionGoalMode.custom;
      if (!needsWeight && _activePad == _PadField.weight) {
        _activePad = null;
      }
      if (!needsKcal && _activePad == _PadField.kcal) {
        _activePad = null;
      }
    });
  }

  void _openPad(_PadField field) {
    setState(() {
      if (_activePad == field) {
        _replaceNext = true;
        return;
      }
      _activePad = field;
      _replaceNext = _activeValue.isNotEmpty;
    });
  }

  void _closePad() {
    if (_activePad == null) return;
    setState(() {
      _activePad = null;
      _replaceNext = false;
    });
  }

  void _onKey(String key) {
    if (_activePad == null) return;
    setState(() {
      var value = _activeValue;
      final allowDecimal = _activePad == _PadField.weight;

      if (key == '⌫') {
        if (value.isNotEmpty) value = value.substring(0, value.length - 1);
        _replaceNext = false;
        _activeValue = value;
        return;
      }

      if (key == '.') {
        if (!allowDecimal) return;
        if (_replaceNext || value.isEmpty) {
          value = '0.';
          _replaceNext = false;
          _activeValue = value;
          return;
        }
        if (!value.contains('.')) value += '.';
        _activeValue = value;
        return;
      }

      if (_replaceNext) {
        value = key;
        _replaceNext = false;
        _activeValue = value;
        return;
      }

      // Soft length caps — avoid absurd numbers.
      final maxLen = allowDecimal ? 5 : 4;
      final digitsOnly = value.replaceAll('.', '');
      if (digitsOnly.length >= maxLen && !value.endsWith('.')) return;

      if (value == '0') {
        value = key;
      } else {
        value += key;
      }
      _activeValue = value;
    });
  }

  void _setWeightPreset(double kg) {
    setState(() {
      _targetWeight = kg == kg.roundToDouble()
          ? kg.toInt().toString()
          : kg.toStringAsFixed(1);
      _activePad = _PadField.weight;
      _replaceNext = true;
    });
  }

  void _setKcalPreset(int kcal) {
    setState(() {
      _manualKcal = '$kcal';
      _activePad = _PadField.kcal;
      _replaceNext = true;
    });
  }

  String? _weightDirectionHint(double? target) {
    final current = _targets.currentWeightKg;
    if (current == null || target == null || target <= 0) return null;
    if (_mode == NutritionGoalMode.lose && target >= current) {
      return MealLogUtils.convertToPersianNumbers(
        'برای کاهش وزن، هدف را کمتر از ${current.toStringAsFixed(current == current.roundToDouble() ? 0 : 1)} کیلو بگذار',
      );
    }
    if (_mode == NutritionGoalMode.gain && target <= current) {
      return MealLogUtils.convertToPersianNumbers(
        'برای افزایش وزن، هدف را بیشتر از ${current.toStringAsFixed(current == current.roundToDouble() ? 0 : 1)} کیلو بگذار',
      );
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    _closePad();

    final target = _targetWeightValue;
    final manual = _manualKcalValue;

    if (_mode == NutritionGoalMode.custom && (manual == null || manual < 800)) {
      _toast('کالری روزانه را درست بنویس (حداقل ۸۰۰)');
      return;
    }

    final directionHint = _weightDirectionHint(target);
    if (directionHint != null) {
      _toast(directionHint);
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await _service.save(
        mode: _mode,
        targetWeightKg: target,
        weeklyRateKg: _weeklyRate,
        manualCalorieKcal: manual,
        profileOverride: widget.profileData,
      );
      if (!mounted) return;
      if (result.ok) {
        Navigator.of(context).pop(true);
      } else {
        _toast(result.message ?? 'ذخیره نشد');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final result = await _service.clear();
      if (!mounted) return;
      if (result.ok) {
        Navigator.of(context).pop(true);
      } else {
        _toast(result.message ?? 'حذف نشد');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = NutritionGoal.fromProfileMap(widget.profileData);
    final accent = MealLogColors.accent(context);
    final padOpen = _activePad != null;

    return PopScope(
      canPop: !padOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (padOpen) _closePad();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          decoration: BoxDecoration(
            color: MealLogColors.sectionBackground(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: MealLogColors.isDark(context) ? 0.5 : 0.12,
                ),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10.h),
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: MealLogColors.inputBorder(context),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 8.w, 0),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          accent.withValues(alpha: 0.28),
                          accent.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                    child: Icon(LucideIcons.target, size: 20.sp, color: accent),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existing.isActive
                              ? 'ویرایش بودجه کالری'
                              : 'بودجه کالری بگذار',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: MealLogColors.primaryText(context),
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'چند کالری در روز بخوری تا به وزن دلخواه برسی',
                          style: MealLogTypography.caption(context).copyWith(
                            fontSize: 12.sp,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (padOpen) {
                        _closePad();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(
                      LucideIcons.x,
                      color: MealLogColors.mutedText(context),
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (_targets.currentWeightKg != null ||
                _targets.maintenanceKcal > 0)
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                child: _ContextStrip(
                  currentWeightKg: _targets.currentWeightKg,
                  maintenanceKcal: _targets.maintenanceKcal.round(),
                ),
              ),
            Expanded(
              child: GestureDetector(
                onTap: _closePad,
                behavior: HitTestBehavior.deferToChild,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                  children: [
                    Text(
                      'می‌خوای چی کار کنی؟',
                      style: MealLogTypography.sectionTitle(context),
                    ),
                    SizedBox(height: 10.h),
                    _ModeGrid(
                      selected: _mode,
                      onSelect: _selectMode,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _mode == NutritionGoalMode.lose ||
                              _mode == NutritionGoalMode.gain
                          ? _WeightPlanSection(
                              mode: _mode,
                              weeklyRate: _weeklyRate,
                              targetWeight: _targetWeight,
                              weightActive: _activePad == _PadField.weight,
                              replaceArmed:
                                  _activePad == _PadField.weight &&
                                  _replaceNext,
                              currentWeightKg: _targets.currentWeightKg,
                              onRateChanged: (r) => setState(() {
                                _weeklyRate = r;
                              }),
                              onOpenWeightPad: () =>
                                  _openPad(_PadField.weight),
                              onWeightPreset: _setWeightPreset,
                            )
                          : _mode == NutritionGoalMode.custom
                          ? _CustomKcalSection(
                              value: _manualKcal,
                              active: _activePad == _PadField.kcal,
                              replaceArmed:
                                  _activePad == _PadField.kcal && _replaceNext,
                              maintenanceKcal: _targets.maintenanceKcal
                                  .round(),
                              onOpenPad: () => _openPad(_PadField.kcal),
                              onPreset: _setKcalPreset,
                            )
                          : Padding(
                              padding: EdgeInsets.only(top: 14.h),
                              child: const _InfoNote(
                                icon: LucideIcons.scale,
                                text:
                                    'کالری روزانه‌ات روی نیاز حفظ وزن تنظیم می‌شود تا وزن فعلی‌ات ثابت بماند.',
                              ),
                            ),
                    ),
                    SizedBox(height: 16.h),
                    _ResultCard(
                      preview: _preview,
                      mode: _mode,
                      weeklyRate: _weeklyRate,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: padOpen
                  ? _InlineKeypad(
                      key: const ValueKey('pad'),
                      allowDecimal: _activePad == _PadField.weight,
                      title: _activePad == _PadField.kcal
                          ? 'کالری روزانه'
                          : 'وزن هدف',
                      onKey: _onKey,
                      onDone: _closePad,
                    )
                  : _FooterActions(
                      key: const ValueKey('footer'),
                      saving: _saving,
                      showClear: existing.isActive,
                      onSave: _save,
                      onClear: _clear,
                    ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ─── Context strip ───────────────────────────────────────────────────────────

class _ContextStrip extends StatelessWidget {
  const _ContextStrip({
    required this.currentWeightKg,
    required this.maintenanceKcal,
  });

  final double? currentWeightKg;
  final int maintenanceKcal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: MealLogColors.panelBackground(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: MealLogColors.chipBorder(context, selected: false),
        ),
      ),
      child: Row(
        children: [
          if (currentWeightKg != null) ...[
            Expanded(
              child: _ContextStat(
                icon: LucideIcons.weight,
                label: 'وزن فعلی',
                value: MealLogUtils.convertToPersianNumbers(
                  '${currentWeightKg!.toStringAsFixed(currentWeightKg == currentWeightKg!.roundToDouble() ? 0 : 1)} کیلو',
                ),
              ),
            ),
            Container(
              width: 1,
              height: 28.h,
              color: MealLogColors.inputBorder(context),
            ),
            SizedBox(width: 10.w),
          ],
          Expanded(
            child: _ContextStat(
              icon: LucideIcons.flame,
              label: 'نیاز روزانه',
              value: MealLogUtils.convertToPersianNumbers(
                '$maintenanceKcal کالری',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextStat extends StatelessWidget {
  const _ContextStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15.sp, color: MealLogColors.accent(context)),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: MealLogTypography.statLabel(context)),
              Text(
                value,
                style: MealLogTypography.caption(
                  context,
                  color: MealLogColors.primaryText(context),
                  fontWeight: FontWeight.w800,
                ).copyWith(fontSize: 12.5.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Mode grid ───────────────────────────────────────────────────────────────

class _ModeGrid extends StatelessWidget {
  const _ModeGrid({
    required this.selected,
    required this.onSelect,
  });

  final NutritionGoalMode selected;
  final ValueChanged<NutritionGoalMode> onSelect;

  static const _items =
      <
        ({
          NutritionGoalMode mode,
          String title,
          String subtitle,
          IconData icon,
        })
      >[
        (
          mode: NutritionGoalMode.lose,
          title: 'کاهش وزن',
          subtitle: 'کسری کالری کنترل‌شده',
          icon: LucideIcons.trendingDown,
        ),
        (
          mode: NutritionGoalMode.gain,
          title: 'افزایش وزن',
          subtitle: 'مازاد کالری برای رشد',
          icon: LucideIcons.trendingUp,
        ),
        (
          mode: NutritionGoalMode.maintain,
          title: 'حفظ وزن',
          subtitle: 'ثابت نگه داشتن فعلی',
          icon: LucideIcons.minus,
        ),
        (
          mode: NutritionGoalMode.custom,
          title: 'کالری دستی',
          subtitle: 'عدد را خودت بنویس',
          icon: LucideIcons.pencil,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _modeTile(context, _items[0])),
            SizedBox(width: 8.w),
            Expanded(child: _modeTile(context, _items[1])),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(child: _modeTile(context, _items[2])),
            SizedBox(width: 8.w),
            Expanded(child: _modeTile(context, _items[3])),
          ],
        ),
      ],
    );
  }

  Widget _modeTile(
    BuildContext context,
    ({
      NutritionGoalMode mode,
      String title,
      String subtitle,
      IconData icon,
    })
    item,
  ) {
    final isSelected = selected == item.mode;
    final accent = MealLogColors.accent(context);

    return Material(
      color: MealLogColors.chipFill(context, selected: isSelected),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: () => onSelect(item.mode),
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: MealLogColors.chipBorder(context, selected: isSelected),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9.r),
                      color: isSelected
                          ? accent.withValues(alpha: 0.2)
                          : MealLogColors.panelBackground(context),
                    ),
                    child: Icon(
                      item.icon,
                      size: 15.sp,
                      color: isSelected
                          ? accent
                          : MealLogColors.mutedText(context),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(LucideIcons.circleCheck, size: 16.sp, color: accent),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                item.title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: MealLogColors.chipText(context, selected: isSelected),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                item.subtitle,
                style: MealLogTypography.caption(context).copyWith(
                  fontSize: 10.5.sp,
                  height: 1.35,
                  color: isSelected
                      ? MealLogColors.secondaryText(context)
                      : MealLogColors.mutedText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Weight / rate section ───────────────────────────────────────────────────

class _WeightPlanSection extends StatelessWidget {
  const _WeightPlanSection({
    required this.mode,
    required this.weeklyRate,
    required this.targetWeight,
    required this.weightActive,
    required this.replaceArmed,
    required this.currentWeightKg,
    required this.onRateChanged,
    required this.onOpenWeightPad,
    required this.onWeightPreset,
  });

  final NutritionGoalMode mode;
  final double weeklyRate;
  final String targetWeight;
  final bool weightActive;
  final bool replaceArmed;
  final double? currentWeightKg;
  final ValueChanged<double> onRateChanged;
  final VoidCallback onOpenWeightPad;
  final ValueChanged<double> onWeightPreset;

  List<double> get _presets {
    final current = currentWeightKg;
    if (current == null) return const <double>[];
    final isLose = mode == NutritionGoalMode.lose;
    final deltas = isLose
        ? const <double>[-2, -4, -6]
        : const <double>[2, 4, 6];
    return [
      for (final d in deltas)
        double.parse((current + d).toStringAsFixed(1)),
    ].where((w) => w > 30 && w < 250).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isLose = mode == NutritionGoalMode.lose;
    final presets = _presets;

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'سرعت تغییر وزن',
            style: MealLogTypography.sectionTitle(context),
          ),
          SizedBox(height: 4.h),
          Text(
            isLose
                ? 'هرچه سریع‌تر، کسری کالری بیشتر'
                : 'هرچه سریع‌تر، مازاد کالری بیشتر',
            style: MealLogTypography.caption(context),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              for (final rate
                  in NutritionGoalService.suggestedWeeklyRatesKg) ...[
                if (rate != NutritionGoalService.suggestedWeeklyRatesKg.first)
                  SizedBox(width: 8.w),
                Expanded(
                  child: _RateChip(
                    rate: rate,
                    selected: (weeklyRate - rate).abs() < 0.01,
                    onTap: () => onRateChanged(rate),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Text(
                'وزن هدف',
                style: MealLogTypography.sectionTitle(context),
              ),
              SizedBox(width: 6.w),
              Text('(اختیاری)', style: MealLogTypography.caption(context)),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            currentWeightKg == null
                ? 'اگر بنویسی، زمان تقریبی رسیدن را هم می‌گوییم'
                : MealLogUtils.convertToPersianNumbers(
                    'الان حدود ${currentWeightKg!.toStringAsFixed(currentWeightKg == currentWeightKg!.roundToDouble() ? 0 : 1)} کیلو هستی',
                  ),
            style: MealLogTypography.caption(context),
          ),
          if (presets.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                for (final p in presets)
                  _QuickChip(
                    label: MealLogUtils.convertToPersianNumbers(
                      '${p.toStringAsFixed(p == p.roundToDouble() ? 0 : 1)} کیلو',
                    ),
                    selected:
                        (double.tryParse(targetWeight.replaceAll(',', '.')) ??
                                -1) ==
                            p,
                    onTap: () => onWeightPreset(p),
                  ),
              ],
            ),
          ],
          SizedBox(height: 8.h),
          _DigitTile(
            value: targetWeight,
            placeholder: isLose ? 'مثلاً ۷۸' : 'مثلاً ۸۵',
            suffix: 'کیلو',
            active: weightActive,
            replaceArmed: replaceArmed,
            onTap: onOpenWeightPad,
          ),
        ],
      ),
    );
  }
}

class _RateChip extends StatelessWidget {
  const _RateChip({
    required this.rate,
    required this.selected,
    required this.onTap,
  });

  final double rate;
  final bool selected;
  final VoidCallback onTap;

  String get _title {
    if ((rate - 0.25).abs() < 0.01) return 'آرام';
    if ((rate - 0.5).abs() < 0.01) return 'معمولی';
    return 'سریع';
  }

  String get _subtitle => MealLogUtils.convertToPersianNumbers(
    '${rate.toStringAsFixed(rate == rate.roundToDouble() ? 0 : 2)} کیلو/هفته',
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MealLogColors.chipFill(context, selected: selected),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 6.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: MealLogColors.chipBorder(context, selected: selected),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                _title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: MealLogColors.chipText(context, selected: selected),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: MealLogTypography.caption(context).copyWith(
                  fontSize: 10.sp,
                  color: selected
                      ? MealLogColors.secondaryText(context)
                      : MealLogColors.mutedText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomKcalSection extends StatelessWidget {
  const _CustomKcalSection({
    required this.value,
    required this.active,
    required this.replaceArmed,
    required this.maintenanceKcal,
    required this.onOpenPad,
    required this.onPreset,
  });

  final String value;
  final bool active;
  final bool replaceArmed;
  final int maintenanceKcal;
  final VoidCallback onOpenPad;
  final ValueChanged<int> onPreset;

  @override
  Widget build(BuildContext context) {
    final presets = <int>{
      (maintenanceKcal - 500).clamp(800, maintenanceKcal + 1000),
      (maintenanceKcal - 250).clamp(800, maintenanceKcal + 1000),
      maintenanceKcal,
      (maintenanceKcal + 250).clamp(800, maintenanceKcal + 1000),
    }.toList()..sort();

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'کالری روزانه',
            style: MealLogTypography.sectionTitle(context),
          ),
          SizedBox(height: 4.h),
          Text(
            'عدد را با کی‌پد بزن یا از میانبرها انتخاب کن',
            style: MealLogTypography.caption(context),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final p in presets)
                _QuickChip(
                  label: MealLogUtils.convertToPersianNumbers('$p'),
                  selected: value == '$p',
                  onTap: () => onPreset(p),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          _DigitTile(
            value: value,
            placeholder: 'مثلاً ۲۲۰۰',
            suffix: 'کالری',
            active: active,
            replaceArmed: replaceArmed,
            onTap: onOpenPad,
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
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
      color: MealLogColors.chipFill(context, selected: selected),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: MealLogColors.chipBorder(context, selected: selected),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: MealLogColors.chipText(context, selected: selected),
            ),
          ),
        ),
      ),
    );
  }
}

class _DigitTile extends StatelessWidget {
  const _DigitTile({
    required this.value,
    required this.placeholder,
    required this.suffix,
    required this.active,
    required this.replaceArmed,
    required this.onTap,
  });

  final String value;
  final String placeholder;
  final String suffix;
  final bool active;
  final bool replaceArmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = MealLogColors.accent(context);
    final empty = value.isEmpty;

    return Material(
      color: MealLogColors.inputFill(context),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: active
                  ? MealLogColors.inputBorderFocused(context)
                  : MealLogColors.inputBorder(context),
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  empty
                      ? placeholder
                      : MealLogUtils.convertToPersianNumbers(value),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: empty
                        ? MealLogColors.hintText(context)
                        : replaceArmed
                        ? accent
                        : MealLogColors.primaryText(context),
                  ),
                ),
              ),
              Text(suffix, style: MealLogTypography.caption(context)),
              SizedBox(width: 8.w),
              Icon(
                LucideIcons.keyboard,
                size: 16.sp,
                color: active ? accent : MealLogColors.mutedText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Inline keypad (no system keyboard) ──────────────────────────────────────

class _InlineKeypad extends StatelessWidget {
  const _InlineKeypad({
    required this.allowDecimal,
    required this.title,
    required this.onKey,
    required this.onDone,
    super.key,
  });

  final bool allowDecimal;
  final String title;
  final ValueChanged<String> onKey;
  final VoidCallback onDone;

  List<List<String>> get _rows => [
    const ['1', '2', '3'],
    const ['4', '5', '6'],
    const ['7', '8', '9'],
    [if (allowDecimal) '.' else '', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: MealLogColors.panelBackground(context),
        border: Border(
          top: BorderSide(color: MealLogColors.inputBorder(context)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: MealLogTypography.caption(
                    context,
                    color: MealLogColors.primaryText(context),
                    fontWeight: FontWeight.w800,
                  ).copyWith(fontSize: 12.sp),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onDone,
                  style: TextButton.styleFrom(
                    foregroundColor: MealLogColors.accent(context),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  child: Text(
                    'تمام',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            RepaintBoundary(
              child: Column(
                children: [
                  for (final row in _rows)
                    Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Row(
                        children: [
                          for (final keyLabel in row)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 3.w),
                                child: keyLabel.isEmpty
                                    ? SizedBox(height: 46.h)
                                    : _PadKey(
                                        label: keyLabel,
                                        onTap: () => onKey(keyLabel),
                                      ),
                              ),
                            ),
                        ],
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
}

class _PadKey extends StatelessWidget {
  const _PadKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBack = label == '⌫';
    return Material(
      color: MealLogColors.sectionBackground(context),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: SizedBox(
          height: 46.h,
          child: Center(
            child: isBack
                ? Icon(
                    Icons.backspace_outlined,
                    size: 18.sp,
                    color: MealLogColors.secondaryText(context),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: MealLogColors.primaryText(context),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Result card ─────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.preview,
    required this.mode,
    required this.weeklyRate,
  });

  final NutritionGoalPreview preview;
  final NutritionGoalMode mode;
  final double weeklyRate;

  @override
  Widget build(BuildContext context) {
    final goal = preview.goalKcal ?? preview.maintenanceKcal;
    final need = preview.maintenanceKcal;
    final delta = preview.dailyDeltaKcal;
    final accent = MealLogColors.accent(context);

    String headline;
    String? deltaLabel;
    Color? deltaColor;

    switch (mode) {
      case NutritionGoalMode.maintain:
        headline = 'همین مقدار برای ثابت ماندن وزن';
      case NutritionGoalMode.custom:
        if (delta == 0) {
          headline = 'تقریباً برابر نیاز حفظ وزن';
        } else if (delta < 0) {
          headline = 'کمتر از نیاز حفظ وزن';
          deltaLabel = MealLogUtils.convertToPersianNumbers(
            '${delta.abs()} کالری کمتر',
          );
          deltaColor = MealLogColors.warningText(context);
        } else {
          headline = 'بیشتر از نیاز حفظ وزن';
          deltaLabel = MealLogUtils.convertToPersianNumbers(
            '$delta کالری بیشتر',
          );
          deltaColor = MealLogColors.successText(context);
        }
      case NutritionGoalMode.lose:
        headline = MealLogUtils.convertToPersianNumbers(
          'روزانه ${delta.abs()} کالری کمتر از نیاز',
        );
        deltaLabel = MealLogUtils.convertToPersianNumbers(
          'حدود ${weeklyRate.toStringAsFixed(weeklyRate == weeklyRate.roundToDouble() ? 0 : 2)} کیلو در هفته',
        );
        deltaColor = MealLogColors.warningText(context);
      case NutritionGoalMode.gain:
        headline = MealLogUtils.convertToPersianNumbers(
          'روزانه $delta کالری بیشتر از نیاز',
        );
        deltaLabel = MealLogUtils.convertToPersianNumbers(
          'حدود ${weeklyRate.toStringAsFixed(weeklyRate == weeklyRate.roundToDouble() ? 0 : 2)} کیلو در هفته',
        );
        deltaColor = MealLogColors.successText(context);
      case NutritionGoalMode.none:
        headline = 'نیاز تقریبی روزانه';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.flame, size: 16.sp, color: accent),
              SizedBox(width: 6.w),
              Text(
                'هدف روزانه تو',
                style: MealLogTypography.caption(
                  context,
                  color: accent,
                  fontWeight: FontWeight.w800,
                ).copyWith(fontSize: 12.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MealLogUtils.convertToPersianNumbers('$goal'),
                style: MealLogTypography.statValue(
                  context,
                ).copyWith(fontSize: 36.sp, height: 1),
              ),
              SizedBox(width: 6.w),
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  'کالری / روز',
                  style: MealLogTypography.statLabel(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            headline,
            style: MealLogTypography.caption(
              context,
              color: MealLogColors.primaryText(context),
              fontWeight: FontWeight.w700,
            ).copyWith(fontSize: 12.5.sp, height: 1.4),
          ),
          if (deltaLabel != null) ...[
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _MiniChip(
                  text: deltaLabel,
                  color: deltaColor ?? MealLogColors.secondaryText(context),
                ),
                _MiniChip(
                  text: MealLogUtils.convertToPersianNumbers(
                    'نیاز حفظ وزن: $need',
                  ),
                  color: MealLogColors.secondaryText(context),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: 8.h),
            _MiniChip(
              text: MealLogUtils.convertToPersianNumbers(
                'نیاز حفظ وزن: $need کالری',
              ),
              color: MealLogColors.secondaryText(context),
            ),
          ],
          if (preview.estimatedWeeks != null) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: MealLogColors.sectionBackground(
                  context,
                ).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: MealLogColors.chipBorder(context, selected: false),
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendarClock, size: 16.sp, color: accent),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      MealLogUtils.convertToPersianNumbers(
                        'تقریباً ${preview.estimatedWeeks} هفته تا وزن هدف',
                      ),
                      style: MealLogTypography.caption(
                        context,
                        color: MealLogColors.primaryText(context),
                        fontWeight: FontWeight.w700,
                      ).copyWith(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (preview.usedSafetyFloor) ...[
            SizedBox(height: 8.h),
            const _InfoNote(
              icon: LucideIcons.shieldAlert,
              text: 'کالری هدف روی حداقل ایمن تنظیم شد تا خیلی پایین نیاید.',
              tone: _InfoNoteTone.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Shared bits ─────────────────────────────────────────────────────────────

enum _InfoNoteTone { neutral, warning }

class _InfoNote extends StatelessWidget {
  const _InfoNote({
    required this.icon,
    required this.text,
    this.tone = _InfoNoteTone.neutral,
  });

  final IconData icon;
  final String text;
  final _InfoNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final isWarning = tone == _InfoNoteTone.warning;
    final color = isWarning
        ? MealLogColors.warningText(context)
        : MealLogColors.secondaryText(context);
    final bg = isWarning
        ? MealLogColors.warningBackground(context)
        : MealLogColors.chipFill(context, selected: false);
    final border = isWarning
        ? MealLogColors.warningBorder(context)
        : MealLogColors.chipBorder(context, selected: false);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: MealLogTypography.caption(
                context,
                color: color,
              ).copyWith(fontSize: 12.sp, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.saving,
    required this.showClear,
    required this.onSave,
    required this.onClear,
    super.key,
  });

  final bool saving;
  final bool showClear;
  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: MealLogColors.inputBorder(context)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              gradient: const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [AppTheme.darkGold, AppTheme.goldColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: saving ? null : onSave,
                borderRadius: BorderRadius.circular(14.r),
                child: SizedBox(
                  height: 52.h,
                  child: Center(
                    child: saving
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppTheme.onGoldColor,
                            ),
                          )
                        : Text(
                            'ثبت هدف',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 15.5.sp,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onGoldColor,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (showClear)
            TextButton(
              onPressed: saving ? null : onClear,
              child: Text(
                'حذف هدف',
                style: MealLogTypography.caption(
                  context,
                  color: MealLogColors.mutedText(context),
                  fontWeight: FontWeight.w700,
                ).copyWith(fontSize: 13.sp),
              ),
            ),
        ],
      ),
    );
  }
}
