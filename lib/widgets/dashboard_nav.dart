import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gymaipro/theme/app_theme.dart';

// Bottom Navigation Bar Widget
class DashboardBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTapped;

  const DashboardBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTabTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, LucideIcons.home, 'خانه'),
              _buildNavItem(1, LucideIcons.dumbbell, 'تمرینات'),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(2, LucideIcons.activity, 'آنالیز'),
              _buildNavItem(3, LucideIcons.user, 'پروفایل'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.goldColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.goldColor
                  : Colors.white.withValues(alpha: 0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.goldColor
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Floating Action Button Widget
class DashboardFAB extends StatefulWidget {
  final VoidCallback onWorkoutLog;
  final VoidCallback onNewProgram;
  final VoidCallback onTrainers;
  final VoidCallback onChat;

  const DashboardFAB({
    Key? key,
    required this.onWorkoutLog,
    required this.onNewProgram,
    required this.onTrainers,
    required this.onChat,
  }) : super(key: key);

  @override
  State<DashboardFAB> createState() => _DashboardFABState();
}

class _DashboardFABState extends State<DashboardFAB>
    with SingleTickerProviderStateMixin {
  bool _isFabExpanded = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });

    if (_isFabExpanded) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expanded FAB options
        if (_isFabExpanded) ...[
          AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _fabAnimation.value,
                child: Opacity(
                  opacity: _fabAnimation.value,
                  child: Column(
                    children: [
                      _buildFabOption(
                        LucideIcons.plus,
                        'ثبت تمرین',
                        Colors.green,
                        () {
                          _toggleFab();
                          widget.onWorkoutLog();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFabOption(
                        LucideIcons.clipboardList,
                        'برنامه جدید',
                        Colors.blue,
                        () {
                          _toggleFab();
                          widget.onNewProgram();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFabOption(
                        LucideIcons.users,
                        'مربیان',
                        Colors.purple,
                        () {
                          _toggleFab();
                          widget.onTrainers();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFabOption(
                        LucideIcons.messageCircle,
                        'چت',
                        Colors.orange,
                        () {
                          _toggleFab();
                          widget.onChat();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        // Main FAB
        FloatingActionButton(
          onPressed: _toggleFab,
          backgroundColor: AppTheme.goldColor,
          child: AnimatedRotation(
            turns: _isFabExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isFabExpanded ? LucideIcons.x : LucideIcons.plus,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFabOption(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
