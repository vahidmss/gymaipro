import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.average,
    required this.count,
    super.key,
    this.myRating,
    this.onRate,
  });
  final double average;
  final int count;
  final int? myRating;
  final ValueChanged<int>? onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: onRate != null ? () => onRate!(i) : null,
            child: Icon(
              i <= (myRating ?? average.round())
                  ? Icons.star
                  : Icons.star_border,
              color: AppTheme.goldColor,
              size: 20.sp,
            ),
          ),
        const SizedBox(width: 8),
        Text(
          '${average.toStringAsFixed(1)} ($count)',
          style: AppTheme.bodyStyle.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
