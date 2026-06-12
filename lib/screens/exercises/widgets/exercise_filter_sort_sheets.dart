import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/screens/exercises/exercise_catalog_logic.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<ExerciseCatalogFilters?> showExerciseFilterSheet({
  required BuildContext context,
  required ExerciseCatalogFilters current,
  required Map<String, List<String>> availableFilters,
}) {
  var draft = current;

  return showModalBottomSheet<ExerciseCatalogFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.cardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.85;
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 16.h,
              bottom: bottomInset + 20.h,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: context.textSecondary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(LucideIcons.filter, color: AppTheme.goldColor, size: 22.sp),
                        SizedBox(width: 10.w),
                        Text(
                          'فیلتر تمرینات',
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _FilterDropdown(
                      label: 'سطح دشواری',
                      value: draft.difficulty,
                      options: availableFilters['difficulties'] ?? const [],
                      onChanged: (v) =>
                          setModalState(() => draft = draft.copyWith(difficulty: v)),
                    ),
                    _FilterDropdown(
                      label: 'تجهیزات',
                      value: draft.equipment,
                      options: availableFilters['equipments'] ?? const [],
                      onChanged: (v) =>
                          setModalState(() => draft = draft.copyWith(equipment: v)),
                    ),
                    _FilterDropdown(
                      label: 'نوع تمرین',
                      value: draft.exerciseType,
                      options: availableFilters['exerciseTypes'] ?? const [],
                      onChanged: (v) => setModalState(
                        () => draft = draft.copyWith(exerciseType: v),
                      ),
                    ),
                    _FilterDropdown(
                      label: 'عضله هدف',
                      value: draft.muscleGroup,
                      options: availableFilters['muscleGroups'] ?? const [],
                      onChanged: (v) => setModalState(
                        () => draft = draft.copyWith(muscleGroup: v),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.textSecondary,
                              side: BorderSide(color: context.separatorColor),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: const Text('انصراف'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, draft),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.goldColor,
                              foregroundColor: AppTheme.onGoldColor,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: const Text('اعمال فیلتر'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<ExerciseCatalogFilters?> showExerciseSortSheet({
  required BuildContext context,
  required ExerciseCatalogFilters current,
}) {
  var sortBy = current.sortBy;
  var ascending = current.sortAscending;

  const options = <String, String>{
    'popularity': 'محبوبیت',
    'name': 'نام تمرین',
    'difficulty': 'سطح دشواری',
    'duration': 'مدت زمان',
    'equipment': 'تجهیزات',
    'type': 'نوع تمرین',
  };

  return showModalBottomSheet<ExerciseCatalogFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.cardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.85;
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 16.h,
              bottom: bottomInset + 20.h,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: context.textSecondary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.arrowUpDown,
                          color: AppTheme.goldColor,
                          size: 22.sp,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'مرتب‌سازی',
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    ...options.entries.map(
                      (e) => RadioListTile<String>(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
                        title: Text(
                          e.value,
                          style: TextStyle(
                            color: sortBy == e.key
                                ? AppTheme.goldColor
                                : context.textColor,
                            fontWeight: sortBy == e.key
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        value: e.key,
                        groupValue: sortBy,
                        activeColor: AppTheme.goldColor,
                        onChanged: (v) => setModalState(() => sortBy = v!),
                      ),
                    ),
                    SwitchListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
                      title: Text(
                        'صعودی (الف → ی)',
                        style: TextStyle(color: context.textColor),
                      ),
                      value: ascending,
                      activeThumbColor: AppTheme.goldColor,
                      onChanged: (v) => setModalState(() => ascending = v),
                    ),
                    SizedBox(height: 8.h),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        ctx,
                        current.copyWith(sortBy: sortBy, sortAscending: ascending),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: AppTheme.onGoldColor,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: const Text('اعمال'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.textColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            initialValue: value.isEmpty ? null : value,
            decoration: InputDecoration(
              filled: true,
              fillColor: context.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 12.h,
              ),
            ),
            dropdownColor: context.cardColor,
            style: TextStyle(color: context.textColor, fontSize: 14.sp),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(
                  'همه',
                  style: TextStyle(color: context.textSecondary),
                ),
              ),
              ...options.map(
                (o) => DropdownMenuItem(value: o, child: Text(o)),
              ),
            ],
            onChanged: (v) => onChanged(v ?? ''),
          ),
        ],
      ),
    );
  }
}
