// Flutter imports
import 'package:flutter/material.dart';

// App imports
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/chat_notification_badge.dart';

// Welcome Card Widget
class WelcomeCard extends StatelessWidget {
  final String username;
  final String welcomeMessage;
  final IconData welcomeIcon;
  final Map<String, dynamic>? profileData;

  const WelcomeCard({
    Key? key,
    required this.username,
    required this.welcomeMessage,
    required this.welcomeIcon,
    this.profileData,
  }) : super(key: key);

  String _getDisplayName() {
    if (profileData != null) {
      final firstName = profileData!['first_name']?.toString() ?? '';
      final lastName = profileData!['last_name']?.toString() ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    }
    return username.isNotEmpty ? username : 'کاربر عزیز';
  }

  String _getUserInitial() {
    final displayName = _getDisplayName();
    if (displayName.isEmpty) return 'U';
    return displayName.substring(0, 1).toUpperCase();
  }

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
              // تصویر پروفایل کاربر
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getUserInitial(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
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
                ),
              ),
              const SizedBox(width: 16),
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
                      _getDisplayName(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    if (profileData != null &&
                        profileData!['phone_number'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        profileData!['phone_number'],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          shadows: const [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // نمایش قد و وزن
                    if (profileData != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMinimalMetricChip(
                            '${profileData!['height'] ?? '0'} cm',
                            Icons.height,
                          ),
                          const SizedBox(width: 8),
                          _buildMinimalMetricChip(
                            '${profileData!['weight'] ?? '0'} kg',
                            Icons.monitor_weight,
                          ),
                        ],
                      ),
                    ],
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
        ],
      ),
    );
  }

  Widget _buildMinimalMetricChip(String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
