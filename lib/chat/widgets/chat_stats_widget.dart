import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class ChatStatsWidget extends StatelessWidget {
  final int totalMessages;
  final int unreadMessages;
  final int activeConversations;
  final VoidCallback? onTap;

  const ChatStatsWidget({
    Key? key,
    this.totalMessages = 0,
    this.unreadMessages = 0,
    this.activeConversations = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.barChart3,
                color: AppTheme.goldColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'آمار چت',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatItem(
                        icon: LucideIcons.messageSquare,
                        label: 'کل پیام‌ها',
                        value: totalMessages.toString(),
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        icon: LucideIcons.bell,
                        label: 'نخوانده',
                        value: unreadMessages.toString(),
                        color: Colors.red,
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        icon: LucideIcons.users,
                        label: 'گفتگوها',
                        value: activeConversations.toString(),
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                LucideIcons.chevronLeft,
                color: Colors.white70,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
