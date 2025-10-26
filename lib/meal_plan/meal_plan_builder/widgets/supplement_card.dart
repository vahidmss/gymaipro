import 'package:flutter/material.dart';
// کارت مکمل/دارو (Supplement Card) مخصوص صفحه ساخت برنامه غذایی
// استفاده در MealPlanBuilderScreen
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SupplementCardMealPlanBuilder extends StatelessWidget {
  const SupplementCardMealPlanBuilder({
    required this.supplement,
    required this.itemIdx,
    required this.theme,
    required this.onDelete,
    super.key,
  });
  final SupplementEntry supplement;
  final int itemIdx;
  final ThemeData theme;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDrug = supplement.supplementType == 'دارو';
    final primaryColor = isDrug ? Colors.red[600]! : Colors.purple[600]!;
    final backgroundColor = isDrug ? Colors.red[50]! : Colors.purple[50]!;
    final borderColor = isDrug ? Colors.red[200]! : Colors.purple[200]!;
    return Column(
      key: ValueKey('supplement_${supplement.id}_$itemIdx'),
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [backgroundColor, backgroundColor.withValues(alpha: 0.1)],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.1),
                blurRadius: 12.r,
                offset: Offset(0.w, 4.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Drag handle (اختیاری: اگر نیاز به reorder دارید)
                    // ...
                    const SizedBox(width: 16),
                    // Icon
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(
                        isDrug ? LucideIcons.heartPulse : LucideIcons.pill,
                        color: primaryColor,
                        size: 28.sp,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and amount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplement.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                              fontSize: 13.sp,
                            ),
                          ),
                          if (supplement.amount != null)
                            const SizedBox(height: 4),
                          if (supplement.amount != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(7.r),
                                border: Border.all(color: Colors.amber[300]!),
                              ),
                              child: Text(
                                '${supplement.amount!.toStringAsFixed(0)} ${supplement.unit ?? ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Delete button
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          color: Colors.red[600],
                          size: 20.sp,
                        ),
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
                // Nutrition info
                if (supplement.protein != null || supplement.carbs != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.activity,
                          color: Colors.green[600],
                          size: 20.sp,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              if (supplement.protein != null)
                                Text(
                                  'پروتئین: ${supplement.protein!.toStringAsFixed(1)}g',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              if (supplement.carbs != null)
                                Text(
                                  'کربوهیدرات: ${supplement.carbs!.toStringAsFixed(1)}g',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Time and note info
                if ((supplement.time != null && supplement.time!.isNotEmpty) ||
                    (supplement.note != null &&
                        supplement.note!.isNotEmpty)) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (supplement.time != null &&
                            supplement.time!.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                color: Colors.orange[600],
                                size: 18.sp,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'زمان مصرف:',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  supplement.time!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[800],
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (supplement.note != null &&
                            supplement.note!.isNotEmpty) ...[
                          if (supplement.time != null &&
                              supplement.time!.isNotEmpty)
                            const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                LucideIcons.fileText,
                                color: Colors.blue[600],
                                size: 18.sp,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'توضیحات:',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  supplement.note!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[800],
                                    fontSize: 14.sp,
                                    height: 1.4.h,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
