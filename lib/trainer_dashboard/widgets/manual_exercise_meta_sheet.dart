import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';
import 'package:gymaipro/models/exercise_meta_normalizer.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نتیجهٔ ویرایش دستی کامل هسته + نقشه.
class ManualExerciseMetaResult {
  const ManualExerciseMetaResult({
    required this.muscleTargets,
    required this.met,
    required this.typicalRpe,
    required this.movementPattern,
    required this.bodyEngagement,
    required this.mechanicsType,
    required this.forceType,
    required this.caloriesPer1000kg,
    this.secondaryMuscles = '',
  });

  final Map<String, int> muscleTargets;
  final double met;
  final double typicalRpe;
  final String movementPattern;
  final String bodyEngagement;
  final String mechanicsType;
  final String forceType;
  final int caloriesPer1000kg;
  final String secondaryMuscles;
}

/// شیت ثبت/ویرایش دستی همهٔ فیلدهای علمی تمرین.
Future<ManualExerciseMetaResult?> showManualExerciseMetaSheet({
  required BuildContext context,
  Map<String, int>? initialMuscleTargets,
  double? met,
  double? typicalRpe,
  String movementPattern = '',
  String bodyEngagement = '',
  String mechanicsType = '',
  String forceType = '',
  int? caloriesPer1000kg,
  String secondaryMuscles = '',
}) {
  return showModalBottomSheet<ManualExerciseMetaResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ManualExerciseMetaSheet(
      initialMuscleTargets: initialMuscleTargets ?? const {},
      met: met,
      typicalRpe: typicalRpe,
      movementPattern: movementPattern,
      bodyEngagement: bodyEngagement,
      mechanicsType: mechanicsType,
      forceType: forceType,
      caloriesPer1000kg: caloriesPer1000kg,
      secondaryMuscles: secondaryMuscles,
    ),
  );
}

class ManualExerciseMetaSheet extends StatefulWidget {
  const ManualExerciseMetaSheet({
    required this.initialMuscleTargets,
    this.met,
    this.typicalRpe,
    this.movementPattern = '',
    this.bodyEngagement = '',
    this.mechanicsType = '',
    this.forceType = '',
    this.caloriesPer1000kg,
    this.secondaryMuscles = '',
    super.key,
  });

  final Map<String, int> initialMuscleTargets;
  final double? met;
  final double? typicalRpe;
  final String movementPattern;
  final String bodyEngagement;
  final String mechanicsType;
  final String forceType;
  final int? caloriesPer1000kg;
  final String secondaryMuscles;

  @override
  State<ManualExerciseMetaSheet> createState() =>
      _ManualExerciseMetaSheetState();
}

class _ManualExerciseMetaSheetState extends State<ManualExerciseMetaSheet> {
  late final TextEditingController _metCtrl;
  late final TextEditingController _rpeCtrl;
  late final TextEditingController _calCtrl;
  late final TextEditingController _secondaryCtrl;
  late final Map<String, int> _intensities;

  late String _pattern;
  late String _engagement;
  late String _mechanicsType;
  late String _force;

  String? _metError;
  String? _rpeError;
  String? _calError;
  String? _patternError;
  String? _engagementError;
  String? _mechanicsError;
  String? _forceError;
  String? _mapError;

  List<String> get _patterns => ExerciseMetaNormalizer.movementPatterns;
  List<String> get _engagements => ExerciseMetaNormalizer.bodyEngagements;
  List<String> get _mechanics => ExerciseMetaNormalizer.mechanicsTypes;
  List<String> get _forces => ExerciseMetaNormalizer.forceTypes;

  @override
  void initState() {
    super.initState();
    _metCtrl = TextEditingController(
      text: widget.met?.toStringAsFixed(1) ?? '',
    );
    _rpeCtrl = TextEditingController(
      text: widget.typicalRpe?.toStringAsFixed(1) ?? '',
    );
    _calCtrl = TextEditingController(
      text: widget.caloriesPer1000kg?.toString() ?? '',
    );
    _secondaryCtrl = TextEditingController(text: widget.secondaryMuscles);
    _intensities = {
      for (final key in MuscleTargets.allKeys)
        key: (widget.initialMuscleTargets[key] ?? 0).clamp(0, 100),
    };
    _pattern = widget.movementPattern.trim().isEmpty
        ? ''
        : ExerciseMetaNormalizer.movementPattern(widget.movementPattern);
    _engagement = widget.bodyEngagement.trim().isEmpty
        ? ''
        : ExerciseMetaNormalizer.bodyEngagement(widget.bodyEngagement);
    _mechanicsType = widget.mechanicsType.trim().isEmpty
        ? ''
        : ExerciseMetaNormalizer.mechanicsType(widget.mechanicsType);
    _force = widget.forceType.trim().isEmpty
        ? ''
        : ExerciseMetaNormalizer.forceType(widget.forceType);
  }

  @override
  void dispose() {
    _metCtrl.dispose();
    _rpeCtrl.dispose();
    _calCtrl.dispose();
    _secondaryCtrl.dispose();
    super.dispose();
  }

  Map<String, int> _targets() {
    final out = <String, int>{};
    for (final e in _intensities.entries) {
      if (e.value > 0) out[e.key] = e.value;
    }
    return out;
  }

  bool _validate() {
    final met = double.tryParse(_metCtrl.text.trim().replaceAll(',', '.'));
    final rpe = double.tryParse(_rpeCtrl.text.trim().replaceAll(',', '.'));
    final cal = int.tryParse(_calCtrl.text.trim());

    setState(() {
      _metError = (met == null || met < 1 || met > 20)
          ? 'بین ۱ تا ۲۰'
          : null;
      _rpeError = (rpe == null || rpe < 1 || rpe > 10)
          ? 'بین ۱ تا ۱۰'
          : null;
      _calError = (cal == null || cal < 1 || cal > 300)
          ? 'بین ۱ تا ۳۰۰'
          : null;
      _patternError = _pattern.isEmpty ? 'انتخاب کنید' : null;
      _engagementError = _engagement.isEmpty ? 'انتخاب کنید' : null;
      _mechanicsError = _mechanicsType.isEmpty ? 'انتخاب کنید' : null;
      _forceError = _force.isEmpty ? 'انتخاب کنید' : null;
      _mapError = !MuscleTargets.hasData(_targets())
          ? 'حداقل یک عضله با شدت > ۰'
          : null;
    });

    return _metError == null &&
        _rpeError == null &&
        _calError == null &&
        _patternError == null &&
        _engagementError == null &&
        _mechanicsError == null &&
        _forceError == null &&
        _mapError == null;
  }

  void _submit() {
    if (!_validate()) return;

    Navigator.pop(
      context,
      ManualExerciseMetaResult(
        muscleTargets: _targets(),
        met: double.parse(
          double.parse(_metCtrl.text.trim().replaceAll(',', '.'))
              .toStringAsFixed(1),
        ),
        typicalRpe: double.parse(
          double.parse(_rpeCtrl.text.trim().replaceAll(',', '.'))
              .toStringAsFixed(1),
        ),
        movementPattern: _pattern,
        bodyEngagement: _engagement,
        mechanicsType: _mechanicsType,
        forceType: _force,
        caloriesPer1000kg: int.parse(_calCtrl.text.trim()),
        secondaryMuscles: _secondaryCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final muted = isDark ? Colors.grey[400]! : const Color(0xFF5A5A5A);
    final activeMuscles = _intensities.values.where((v) => v > 0).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.pencil,
                        color: AppTheme.goldColor,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'ثبت دستی نقشه عضلانی',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                    children: [
                      _sectionHeader('اطلاعات عددی'),
                      SizedBox(height: 4.h),
                      Text(
                        'شدت متابولیک، سختی ادراک‌شده و مصرف انرژی',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11.5.sp,
                          color: muted,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _numField(
                              controller: _metCtrl,
                              label: 'MET',
                              hint: '۵.۰',
                              helper: 'شدت متابولیک',
                              error: _metError,
                              isDark: isDark,
                              decimal: true,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _numField(
                              controller: _rpeCtrl,
                              label: 'RPE',
                              hint: '۷.۵',
                              helper: 'سختی احساس‌شده',
                              error: _rpeError,
                              isDark: isDark,
                              decimal: true,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _numField(
                              controller: _calCtrl,
                              label: 'کالری',
                              hint: '۳۵',
                              helper: 'به ازای ۱۰۰۰kg',
                              error: _calError,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      _dropdown(
                        label: 'الگوی حرکت',
                        value: _pattern.isEmpty ? null : _pattern,
                        items: _patterns,
                        labelOf: ExerciseDisplayLabels.movement,
                        error: _patternError,
                        isDark: isDark,
                        onChanged: (v) => setState(() {
                          _pattern = v ?? '';
                          _patternError = null;
                        }),
                      ),
                      SizedBox(height: 10.h),
                      _dropdown(
                        label: 'درگیری بدن',
                        value: _engagement.isEmpty ? null : _engagement,
                        items: _engagements,
                        labelOf: ExerciseDisplayLabels.engagement,
                        error: _engagementError,
                        isDark: isDark,
                        onChanged: (v) => setState(() {
                          _engagement = v ?? '';
                          _engagementError = null;
                        }),
                      ),
                      SizedBox(height: 10.h),
                      _dropdown(
                        label: 'مکانیک',
                        value: _mechanicsType.isEmpty ? null : _mechanicsType,
                        items: _mechanics,
                        labelOf: ExerciseDisplayLabels.mechanics,
                        error: _mechanicsError,
                        isDark: isDark,
                        onChanged: (v) => setState(() {
                          _mechanicsType = v ?? '';
                          _mechanicsError = null;
                        }),
                      ),
                      SizedBox(height: 10.h),
                      _dropdown(
                        label: 'نوع نیرو',
                        value: _force.isEmpty ? null : _force,
                        items: _forces,
                        labelOf: ExerciseDisplayLabels.force,
                        error: _forceError,
                        isDark: isDark,
                        onChanged: (v) => setState(() {
                          _force = v ?? '';
                          _forceError = null;
                        }),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: _secondaryCtrl,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.darkTextColor
                              : AppTheme.veryDarkBackground,
                        ),
                        decoration: InputDecoration(
                          labelText: 'عضلات فرعی (متن)',
                          hintText: 'مثلاً پشت‌بازو، سرشانه قدامی',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          _sectionHeader('نقشه عضلانی'),
                          const Spacer(),
                          Text(
                            '$activeMuscles فعال',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'شدت هر عضله از ۰ تا ۱۰۰',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11.5.sp,
                          color: muted,
                        ),
                      ),
                      if (_mapError != null) ...[
                        SizedBox(height: 6.h),
                        Text(
                          _mapError!,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.5.sp,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                      SizedBox(height: 8.h),
                      ...MuscleTargets.allKeys.map((key) {
                        return _MuscleIntensityRow(
                          label: MuscleTargets.label(key),
                          value: _intensities[key]!,
                          isDark: isDark,
                          onChanged: (v) {
                            setState(() {
                              _intensities[key] = v;
                              if (v > 0) _mapError = null;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h + bottom),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('انصراف'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: Icon(LucideIcons.check, size: 18.sp),
                          label: const Text('اعمال'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldColor,
                            foregroundColor: AppTheme.veryDarkBackground,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            elevation: 0,
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
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: AppTheme.goldColor,
      ),
    );
  }

  Widget _numField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String helper,
    required String? error,
    required bool isDark,
    bool decimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            if (decimal)
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (_) {
            if (error != null) setState(() {});
          },
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13.sp,
            color:
                isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground,
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            helperText: helper,
            helperMaxLines: 1,
            errorText: error,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String Function(String) labelOf,
    required String? error,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            errorText: error,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(
                'انتخاب کنید',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  color: Colors.grey,
                ),
              ),
              items: items
                  .map(
                    (k) => DropdownMenuItem(
                      value: k,
                      child: Text(
                        labelOf(k),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.sp,
                          color: isDark
                              ? AppTheme.darkTextColor
                              : AppTheme.veryDarkBackground,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _MuscleIntensityRow extends StatelessWidget {
  const _MuscleIntensityRow({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final String label;
  final int value;
  final bool isDark;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final active = value > 0;
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 4.h),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.07)
            : (isDark
                ? AppTheme.veryDarkBackground.withValues(alpha: 0.25)
                : Colors.grey[50]),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: active
              ? AppTheme.goldColor.withValues(alpha: 0.4)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _presetChip('۰', value == 0, () => onChanged(0)),
              SizedBox(width: 4.w),
              _presetChip('۴۰', value == 40, () => onChanged(40)),
              SizedBox(width: 4.w),
              _presetChip('۸۵', value == 85, () => onChanged(85)),
              SizedBox(width: 8.w),
              SizedBox(
                width: 36.w,
                child: Text(
                  '$value',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldColor,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
            ),
            child: Slider(
              value: value.toDouble(),
              max: 100,
              divisions: 20,
              activeColor: AppTheme.goldColor,
              inactiveColor: AppTheme.goldColor.withValues(alpha: 0.2),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: selected ? AppTheme.goldColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: selected
                ? AppTheme.goldColor
                : AppTheme.goldColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.veryDarkBackground : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
