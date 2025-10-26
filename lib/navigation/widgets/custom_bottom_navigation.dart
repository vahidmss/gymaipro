import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/widgets/gymai_logo.dart';
import 'package:gymaipro/theme/app_theme.dart';

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });
  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: NavigationConstants.bottomNavHeight,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15.r,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none, // اجازه overflow برای دکمه مرکزی
        children: [
          // Bottom Navigation Bar
          Padding(
            padding: const EdgeInsets.only(top: 15), // کاهش فاصله از بالا
            child: Row(
              children: [
                // چت
                Expanded(
                  child: _buildNavItem(
                    icon: NavigationConstants.chatIcon,
                    label: NavigationConstants.chatLabel,
                    index: NavigationConstants.chatIndex,
                    isSelected: currentIndex == NavigationConstants.chatIndex,
                  ),
                ),
                // آکادمی
                Expanded(
                  child: _buildNavItem(
                    icon: NavigationConstants.academyIcon,
                    label: NavigationConstants.academyLabel,
                    index: NavigationConstants.academyIndex,
                    isSelected:
                        currentIndex == NavigationConstants.academyIndex,
                  ),
                ),
                // فضای خالی برای دکمه مرکزی
                const SizedBox(width: 70), // کاهش فضای خالی
                // نقش‌-محور (رتبه‌بندی مربیان/میز کار مربی)
                Expanded(
                  child: _buildNavItem(
                    icon: NavigationConstants.roleIcon,
                    label: NavigationConstants.roleLabel,
                    index: NavigationConstants.roleIndex,
                    isSelected: currentIndex == NavigationConstants.roleIndex,
                  ),
                ),
                // پروفایل
                Expanded(
                  child: _buildNavItem(
                    icon: NavigationConstants.profileIcon,
                    label: NavigationConstants.profileLabel,
                    index: NavigationConstants.profileIndex,
                    isSelected:
                        currentIndex == NavigationConstants.profileIndex,
                  ),
                ),
              ],
            ),
          ),
          // دکمه مرکزی برجسته (داشبورد)
          Positioned(
            top: -15,
            left: 0.w,
            right: 0.w,
            child: Center(
              child: GestureDetector(
                onTap: () => onTap(NavigationConstants.dashboardIndex),
                child: Container(
                  width: NavigationConstants.centralButtonSize,
                  height: NavigationConstants.centralButtonSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.goldColor,
                        AppTheme.goldColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      NavigationConstants.centralButtonSize / 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.4),
                        blurRadius: 15.r,
                        offset: Offset(0.w, 5.h),
                      ),
                    ],
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35.r),
                      border: Border.all(
                        color: AppTheme.backgroundColor,
                        width: 4.w,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(22.5.r),
                        ),
                        child: const GymaiLogo(
                          size: NavigationConstants.centralLogoSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10), // کاهش padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(
                NavigationConstants.navItemPadding,
              ), // کاهش padding
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.goldColor.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppTheme.goldColor
                    : Colors.white.withValues(alpha: 0.6),
                size: NavigationConstants.navItemIconSize, // کاهش اندازه آیکون
              ),
            ),
            const SizedBox(
              height: NavigationConstants.navItemSpacing,
            ), // کاهش فاصله
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.goldColor
                    : Colors.white.withValues(alpha: 0.6),
                fontSize:
                    NavigationConstants.navItemFontSize, // کاهش اندازه فونت
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
