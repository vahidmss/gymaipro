import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/logged_supplement.dart';

class SupplementCard extends StatelessWidget {
  final LoggedSupplement supplement;
  final int index;
  final bool isFromPlan;
  final bool followedPlan;
  final ValueChanged<bool?>? onToggleFollowedPlan;

  const SupplementCard({
    super.key,
    required this.supplement,
    required this.index,
    this.isFromPlan = false,
    this.followedPlan = false,
    this.onToggleFollowedPlan,
  });

  @override
  Widget build(BuildContext context) {
    final isDrug = supplement.supplementType == 'دارو';
    final primaryColor = isDrug ? Colors.red[600]! : Colors.purple[600]!;
    final backgroundColor = isDrug ? Colors.red[50]! : Colors.purple[50]!;
    final borderColor = isDrug ? Colors.red[200]! : Colors.purple[200]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, backgroundColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isDrug ? LucideIcons.heartPulse : LucideIcons.pill,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplement.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 18,
                        ),
                      ),
                      if (supplement.amount != null) const SizedBox(height: 4),
                      if (supplement.amount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.amber[300]!, width: 1),
                          ),
                          child: Text(
                            '${supplement.amount!.toStringAsFixed(0)} ${supplement.unit ?? ''}',
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isFromPlan && onToggleFollowedPlan != null)
                  Row(
                    children: [
                      Checkbox(
                        value: followedPlan,
                        onChanged: onToggleFollowedPlan,
                        activeColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      const Text(
                        'طبق برنامه',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
            if (supplement.protein != null || supplement.carbs != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(LucideIcons.activity,
                      color: Colors.green[600], size: 20),
                  const SizedBox(width: 12),
                  if (supplement.protein != null)
                    _buildNutritionTag(
                        'پروتئین',
                        '${supplement.protein!.toStringAsFixed(1)}g',
                        Colors.green),
                  if (supplement.carbs != null)
                    _buildNutritionTag(
                        'کربوهیدرات',
                        '${supplement.carbs!.toStringAsFixed(1)}g',
                        Colors.blue),
                ],
              ),
            ],
            if ((supplement.time != null && supplement.time!.isNotEmpty) ||
                (supplement.note != null && supplement.note!.isNotEmpty)) ...[
              const SizedBox(height: 16),
              if (supplement.time != null && supplement.time!.isNotEmpty)
                Row(
                  children: [
                    Icon(LucideIcons.clock,
                        color: Colors.orange[600], size: 18),
                    const SizedBox(width: 8),
                    Text('زمان مصرف:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700])),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(supplement.time!,
                            style: TextStyle(
                                color: Colors.grey[800], fontSize: 14))),
                  ],
                ),
              if (supplement.note != null && supplement.note!.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.fileText,
                        color: Colors.blue[600], size: 18),
                    const SizedBox(width: 8),
                    Text('توضیحات:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700])),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(supplement.note!,
                            style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                                height: 1.4))),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTag(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
