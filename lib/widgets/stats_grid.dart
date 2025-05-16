import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/percent_indicator.dart';

class StatsGrid extends StatelessWidget {
  final Map<String, dynamic> profileData;

  const StatsGrid({
    Key? key,
    required this.profileData,
  }) : super(key: key);

  static const Color goldColor = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final weight = double.tryParse(profileData['weight'] ?? '') ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildEnhancedStatCard('تمرینات انجام شده', '48', LucideIcons.dumbbell,
            'جلسه', '۸۰٪ از هدف ماهانه', 0.8, Colors.teal),
        _buildEnhancedStatCard('ساعات تمرین هفتگی', '12', LucideIcons.clock,
            'ساعت', '۶۰٪ از هدف هفتگی', 0.6, Colors.blue),
        _buildEnhancedStatCard(
            'وزن فعلی',
            weight > 0 ? weight.toString() : '0',
            LucideIcons.scale,
            'کیلوگرم',
            weight > 0 ? 'آخرین به‌روزرسانی امروز' : 'وزن خود را ثبت کنید',
            weight > 0 ? 1.0 : 0.0,
            goldColor),
        _buildEnhancedStatCard('روزهای متوالی', '7', LucideIcons.flame, 'روز',
            'ادامه بدهید!', 0.7, Colors.orange),
      ],
    );
  }

  Widget _buildEnhancedStatCard(String title, String value, IconData icon,
      String unit, String subtitle, double progress, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 30, 30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: LinearPercentIndicator(
                    lineHeight: 4.0,
                    percent: progress,
                    animation: true,
                    animationDuration: 1000,
                    backgroundColor: color.withOpacity(0.1),
                    progressColor: color,
                    padding: EdgeInsets.zero,
                    barRadius: const Radius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
