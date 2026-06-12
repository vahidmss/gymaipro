import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExerciseListSearchBar extends StatelessWidget {
  const ExerciseListSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        textDirection: TextDirection.rtl,
        enableSuggestions: false,
        autocorrect: false,
        style: TextStyle(
          color: isDark ? AppTheme.goldColor : context.textColor,
          fontSize: 14.sp,
          fontFamily: AppTheme.fontFamily,
        ),
        decoration: InputDecoration(
          hintText: 'جستجوی نام تمرین یا عضله...',
          hintStyle: TextStyle(
            color: context.textSecondary,
            fontSize: 13.sp,
            fontFamily: AppTheme.fontFamily,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: AppTheme.goldColor,
            size: 20.sp,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'پاک کردن',
                onPressed: onClear,
                icon: Icon(
                  LucideIcons.x,
                  color: context.textSecondary,
                  size: 18.sp,
                ),
              );
            },
          ),
          filled: true,
          fillColor: context.cardColor,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 12.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.25),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.25),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
