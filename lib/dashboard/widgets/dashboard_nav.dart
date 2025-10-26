import 'package:flutter/material.dart';
// Flutter imports
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Bottom Navigation Bar Widget
class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({
    required this.currentIndex,
    required this.onTabTapped,
    super.key,
  });
  final int currentIndex;
  final void Function(int) onTabTapped;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildNavItem(0, LucideIcons.home, 'خانه')),
              Expanded(
                child: _buildNavItem(1, LucideIcons.dumbbell, 'تمرینات'),
              ),
              Expanded(child: _buildNavItem(2, LucideIcons.users, 'شاگردان')),
              const SizedBox(width: 60), // Space for FAB
              Expanded(child: _buildNavItem(3, LucideIcons.activity, 'آنالیز')),
              Expanded(child: _buildNavItem(4, LucideIcons.user, 'پروفایل')),
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
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.goldColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.goldColor
                  : Colors.white.withValues(alpha: 0.7),
              size: 22.sp,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.goldColor
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Floating Action Button Widget
class DashboardFAB extends StatefulWidget {
  const DashboardFAB({
    required this.onWorkoutLog,
    required this.onTrainers,
    required this.onChat,
    super.key,
  });
  final VoidCallback onWorkoutLog;
  final VoidCallback onTrainers;
  final VoidCallback onChat;

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
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
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
              size: 24.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFabOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8.r,
              offset: Offset(0.w, 2.h),
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
