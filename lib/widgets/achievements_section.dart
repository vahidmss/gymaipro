import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../utils/animation_utils.dart';
import 'achievement_badge.dart';
import 'gold_dialog.dart';

class AchievementsSection extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const AchievementsSection({
    Key? key,
    required this.profileData,
  }) : super(key: key);

  @override
  State<AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends State<AchievementsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // تنظیم مقدار اولیه به 0.0 برای اطمینان از شروع صحیح
    _controller.value = 0.0;

    // Using Tween with ClampedSimulation to ensure animation values stay within bounds
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // با تأخیر انیمیشن را شروع می‌کنیم تا از تکمیل سایر کارها مطمئن شویم
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showBadgeDetails(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isUnlocked,
    required Color color,
    required String tip,
  }) {
    GoldDialog.show(
      context: context,
      title: title,
      message: description,
      icon: icon,
      accentColor: color,
      additionalContent: [
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                isUnlocked ? LucideIcons.trophy : LucideIcons.info,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tip,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: color),
          child: const Text('بستن'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // شبیه‌سازی داده‌های پیشرفت و دستاوردها
    final List<Map<String, dynamic>> achievements = [
      {
        'title': 'مبتدی',
        'description': 'ثبت اولین تمرین',
        'icon': LucideIcons.dumbbell,
        'isUnlocked': true,
        'progress': 1.0,
        'color': Colors.green,
        'tip': 'شما اولین تمرین خود را ثبت کرده‌اید. ادامه دهید!',
      },
      {
        'title': 'متوالی',
        'description': 'ثبت تمرین برای ۷ روز متوالی',
        'icon': LucideIcons.flame,
        'isUnlocked': false,
        'progress': 0.7,
        'color': Colors.orange,
        'tip': 'برای باز کردن این دستاورد، باید ۷ روز متوالی تمرین کنید.',
      },
      {
        'title': 'قهرمان',
        'description': 'تکمیل ۳۰ جلسه تمرین',
        'icon': LucideIcons.medal,
        'isUnlocked': false,
        'progress': 0.5,
        'color': AppTheme.goldColor,
        'tip': 'شما ۱۵ جلسه از ۳۰ جلسه تمرین را تکمیل کرده‌اید.',
      },
      {
        'title': 'کوهنورد',
        'description': 'افزایش ۱۰ درصدی وزنه‌ها',
        'icon': LucideIcons.mountain,
        'isUnlocked': false,
        'progress': 0.3,
        'color': Colors.blue,
        'tip': 'شما ۳ درصد از هدف افزایش ۱۰ درصدی وزنه‌ها را پیشرفت کرده‌اید.',
      },
      {
        'title': 'متعادل',
        'description': 'رسیدن به BMI سالم',
        'icon': LucideIcons.heartPulse,
        'isUnlocked': false,
        'progress': 0.8,
        'color': Colors.red,
        'tip': 'شما خیلی نزدیک به محدوده BMI سالم هستید. ادامه دهید!',
      },
      {
        'title': 'حرفه‌ای',
        'description': 'تکمیل ۱۰۰ جلسه تمرین',
        'icon': LucideIcons.crown,
        'isUnlocked': false,
        'progress': 0.48,
        'color': Colors.purple,
        'tip': 'شما ۴۸ جلسه از ۱۰۰ جلسه تمرین را تکمیل کرده‌اید.',
      },
    ];

    return Opacity(
      opacity: _animation.value,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - _animation.value)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppTheme.goldColor, width: 2),
                  ),
                ),
                child: const Text(
                  'دستاوردهای شما',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AchievementBadge(
                      title: achievement['title'] as String,
                      description: achievement['description'] as String,
                      icon: achievement['icon'] as IconData,
                      isUnlocked: achievement['isUnlocked'] as bool,
                      progress: achievement['progress'] as double,
                      color: achievement['color'] as Color,
                      onTap: () => _showBadgeDetails(
                        context,
                        title: achievement['title'] as String,
                        description: achievement['description'] as String,
                        icon: achievement['icon'] as IconData,
                        isUnlocked: achievement['isUnlocked'] as bool,
                        color: achievement['color'] as Color,
                        tip: achievement['tip'] as String,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
