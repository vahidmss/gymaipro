import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';

class ExerciseShimmerGrid extends StatelessWidget {
  const ExerciseShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final base = context.cardColor;
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.grey[300]!;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }
}
