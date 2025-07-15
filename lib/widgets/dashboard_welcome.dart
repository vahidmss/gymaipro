import 'package:flutter/material.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/chat_notification_badge.dart';

// Welcome Card Widget
class WelcomeCard extends StatelessWidget {
  final String username;
  final String welcomeMessage;
  final IconData welcomeIcon;
  final Widget dailyProgressBar;

  const WelcomeCard({
    Key? key,
    required this.username,
    required this.welcomeMessage,
    required this.welcomeIcon,
    required this.dailyProgressBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkGold.withValues(alpha: 0.9),
            AppTheme.goldColor.withValues(alpha: 0.7),
            AppTheme.accentColor.withValues(alpha: 0.5),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGold.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      welcomeMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      username,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        shadows: const [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const ChatNotificationBadge(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      welcomeIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          dailyProgressBar,
        ],
      ),
    );
  }
}

// Daily Progress Bar Widget
class DailyProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0

  const DailyProgressBar({Key? key, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'پیشرفت امروز',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation(AppTheme.goldColor),
          ),
        ),
      ],
    );
  }
}

// Achievements & Stats Section
class AchievementsAndStats extends StatelessWidget {
  final List<Widget> achievements;
  final List<Widget> stats;

  const AchievementsAndStats(
      {Key? key, required this.achievements, required this.stats})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: stats,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: achievements,
          ),
        ),
      ],
    );
  }
}

// Simple Stats List
class SimpleStatsList extends StatelessWidget {
  final List<SimpleStatItem> items;

  const SimpleStatsList({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items,
    );
  }
}

class SimpleStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const SimpleStatItem(
      {Key? key, required this.label, required this.value, required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.goldColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
