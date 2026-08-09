import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// شیت ویرایش دستی نقشه عضلانی — شدت دقیق ۰ تا ۱۰۰.
Future<Map<String, int>?> showMuscleTargetsEditorSheet({
  required BuildContext context,
  Map<String, int>? initial,
}) {
  return showModalBottomSheet<Map<String, int>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => MuscleTargetsEditorSheet(
      initial: initial ?? const {},
    ),
  );
}

class MuscleTargetsEditorSheet extends StatefulWidget {
  const MuscleTargetsEditorSheet({
    required this.initial,
    super.key,
  });

  final Map<String, int> initial;

  @override
  State<MuscleTargetsEditorSheet> createState() =>
      _MuscleTargetsEditorSheetState();
}

class _MuscleTargetsEditorSheetState extends State<MuscleTargetsEditorSheet> {
  late final Map<String, int> _intensities;

  @override
  void initState() {
    super.initState();
    _intensities = {
      for (final key in MuscleTargets.allKeys)
        key: (widget.initial[key] ?? 0).clamp(0, 100),
    };
  }

  Map<String, int> _toTargets() {
    final out = <String, int>{};
    for (final e in _intensities.entries) {
      if (e.value > 0) out[e.key] = e.value;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final selectedCount = _intensities.values.where((v) => v > 0).length;
    final muted = isDark ? Colors.grey[400]! : const Color(0xFF5A5A5A);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.activity,
                        color: AppTheme.goldColor,
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نقشه عضلانی',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'شدت هر عضله: ۰ تا ۱۰۰',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
                    itemCount: MuscleTargets.allKeys.length,
                    itemBuilder: (context, index) {
                      final key = MuscleTargets.allKeys[index];
                      final value = _intensities[key]!;
                      return _MuscleIntensityEditorRow(
                        label: MuscleTargets.label(key),
                        value: value,
                        isDark: isDark,
                        onChanged: (next) {
                          setState(() => _intensities[key] = next);
                        },
                      );
                    },
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
                          onPressed: selectedCount == 0
                              ? null
                              : () => Navigator.pop(context, _toTargets()),
                          icon: Icon(LucideIcons.check, size: 18.sp),
                          label: Text(
                            selectedCount == 0
                                ? 'حداقل یک عضله'
                                : 'تأیید ($selectedCount)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldColor,
                            foregroundColor: AppTheme.veryDarkBackground,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
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
}

class _MuscleIntensityEditorRow extends StatelessWidget {
  const _MuscleIntensityEditorRow({
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
              : AppTheme.goldColor.withValues(alpha: 0.12),
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
                    color: isDark
                        ? AppTheme.darkTextColor
                        : AppTheme.veryDarkBackground,
                  ),
                ),
              ),
              _chip('۰', value == 0, () => onChanged(0)),
              SizedBox(width: 4.w),
              _chip('۴۰', value == 40, () => onChanged(40)),
              SizedBox(width: 4.w),
              _chip('۸۵', value == 85, () => onChanged(85)),
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

  Widget _chip(String label, bool selected, VoidCallback onTap) {
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

/// گروه عضلانی درشت از روی قوی‌ترین کلید هیت‌مپ.
String? mainMuscleGroupFromTargets(Map<String, int> targets) {
  final sorted = MuscleTargets.sortedEntries(targets);
  if (sorted.isEmpty) return null;
  return _groupForKey(sorted.first.key);
}

/// متن عضلات فرعی از روی کلیدهای غیر اصلی.
String secondaryMusclesTextFromTargets(Map<String, int> targets) {
  final sorted = MuscleTargets.sortedEntries(targets);
  if (sorted.length <= 1) return '';
  return sorted.skip(1).map((e) => MuscleTargets.label(e.key)).join('، ');
}

String? _groupForKey(String key) {
  const map = <String, String>{
    'chest_upper': 'سینه',
    'chest_middle': 'سینه',
    'chest_lower': 'سینه',
    'shoulder_anterior': 'شانه',
    'shoulder_lateral': 'شانه',
    'shoulder_posterior': 'شانه',
    'triceps': 'بازو',
    'biceps': 'بازو',
    'forearms': 'ساعد',
    'back_lat': 'پشت',
    'back_trap': 'پشت',
    'lower_back': 'پشت',
    'quads': 'پا',
    'hamstrings': 'پا',
    'glutes': 'سرینی',
    'calf': 'پا',
    'abs': 'شکم',
  };
  return map[key];
}
