// کارت مکمل/دارو (Supplement Card) مخصوص صفحه ساخت برنامه غذایی
// استفاده در MealPlanBuilderScreen

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../models/meal_plan.dart';

class SupplementCardMealPlanBuilder extends StatelessWidget {
  final SupplementEntry supplement;
  final int itemIdx;
  final ThemeData theme;
  final VoidCallback onDelete;

  const SupplementCardMealPlanBuilder({
    Key? key,
    required this.supplement,
    required this.itemIdx,
    required this.theme,
    required this.onDelete,
  }) : super(key: key);

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
              colors: [
                backgroundColor,
                backgroundColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isDrug ? LucideIcons.heartPulse : LucideIcons.pill,
                        color: primaryColor,
                        size: 28,
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
                              fontSize: 13,
                            ),
                          ),
                          if (supplement.amount != null)
                            const SizedBox(height: 4),
                          if (supplement.amount != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: Colors.amber[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${supplement.amount!.toStringAsFixed(0)} ${supplement.unit ?? ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Delete button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red[200]!,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          color: Colors.red[600],
                          size: 20,
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.activity,
                          color: Colors.green[600],
                          size: 20,
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
                                    style: TextStyle(color: Colors.green)),
                              if (supplement.carbs != null)
                                Text(
                                    'کربوهیدرات: ${supplement.carbs!.toStringAsFixed(1)}g',
                                    style: TextStyle(color: Colors.blue)),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
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
                                size: 18,
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
                                    fontSize: 14,
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
                                size: 18,
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
                                    fontSize: 14,
                                    height: 1.4,
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
