import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ExerciseMuscleChips extends StatelessWidget {
  const ExerciseMuscleChips({
    required this.muscles,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> muscles;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (muscles.isEmpty) return const SizedBox.shrink();

    final display = muscles.take(14).toList();

    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: display.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Chip(
              label: 'همه',
              selected: selected.isEmpty,
              onTap: () => onSelected(''),
            );
          }
          final muscle = display[index - 1];
          return _Chip(
            label: muscle,
            selected: selected == muscle,
            onTap: () => onSelected(selected == muscle ? '' : muscle),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
          ? AppTheme.goldColor.withValues(alpha: 0.2)
          : context.cardColor,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected
                  ? AppTheme.goldColor
                  : AppTheme.goldColor.withValues(alpha: 0.25),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.goldColor : context.textSecondary,
              fontSize: 12.sp,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
