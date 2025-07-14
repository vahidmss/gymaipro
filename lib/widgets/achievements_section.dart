import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

    // شروع انیمیشن بدون تأخیر
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                color: isUnlocked ? Colors.green : color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isUnlocked ? 'شما این دستاورد را باز کرده‌اید!' : tip,
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
    final achievements = [
      {
        'title': 'تازه‌کار',
        'description': 'ثبت اولین تمرین',
        'icon': LucideIcons.trophy,
        'isUnlocked': true,
        'progress': 1.0,
        'color': Colors.green,
        'tip': 'شما اولین تمرین خود را با موفقیت ثبت کرده‌اید!',
      },
      {
        'title': 'پرتلاش',
        'description': 'تکمیل ۱۰ جلسه تمرین',
        'icon': LucideIcons.medal,
        'isUnlocked': true,
        'progress': 1.0,
        'color': Colors.blue,
        'tip': 'شما ۱۰ جلسه تمرین را با موفقیت تکمیل کرده‌اید!',
      },
      {
        'title': 'ورزشکار',
        'description': 'تکمیل ۳۰ جلسه تمرین',
        'icon': LucideIcons.star,
        'isUnlocked': false,
        'progress': 0.63,
        'color': Colors.orange,
        'tip': 'شما ۱۹ جلسه از ۳۰ جلسه تمرین را تکمیل کرده‌اید.',
      },
      {
        'title': 'قهرمان',
        'description': 'تکمیل ۵۰ جلسه تمرین',
        'icon': LucideIcons.award,
        'isUnlocked': false,
        'progress': 0.38,
        'color': Colors.amber,
        'tip': 'شما ۱۹ جلسه از ۵۰ جلسه تمرین را تکمیل کرده‌اید.',
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

    // طراحی جدید و ساده برای دستاوردها
    return Opacity(
      opacity: _animation.value,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - _animation.value)),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return AchievementBadge(
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
            );
          },
        ),
      ),
    );
  }
}
