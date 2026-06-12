import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    this.navKeys,
    this.userRole,
    super.key,
  });
  final int currentIndex;
  final void Function(int) onTap;
  final Map<int, GlobalKey>? navKeys;
  final String? userRole; // 'athlete' یا 'trainer'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: NavigationConstants.bottomNavHeight,
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.lightGradientStart.withValues(alpha: 0.15),
                  AppTheme.lightCardColor,
                  AppTheme.lightGradientEnd.withValues(alpha: 0.1),
                ],
              ),
        color: isDark ? context.backgroundColor : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : AppTheme.goldColor.withValues(alpha: 0.1),
            blurRadius: 15.r,
            offset: const Offset(0, -3),
            spreadRadius: 1,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.transparent
                : AppTheme.goldColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none, // اجازه overflow برای دکمه مرکزی
        children: [
          // Bottom Navigation Bar
          Padding(
            padding: EdgeInsets.only(
              top: 12.h,
            ), // کاهش فاصله از بالا برای جلوگیری از overflow
            child: LayoutBuilder(
              builder: (context, constraints) {
                // محاسبه عرض فضای خالی برای دکمه مرکزی بر اساس عرض موجود
                final availableWidth = constraints.maxWidth;
                final centralButtonSpace =
                    (NavigationConstants.centralButtonSize * 0.8).w.clamp(
                      50.0,
                      70.0,
                    );
                final itemWidth = (availableWidth - centralButtonSpace) / 4;

                return Row(
                  children: [
                    // چت
                    Container(
                      key: navKeys?[NavigationConstants.chatIndex],
                      width: itemWidth,
                      height: NavigationConstants.bottomNavHeight,
                      alignment: Alignment.center,
                      child: _buildNavItem(
                        icon: NavigationConstants.chatIcon,
                        label: NavigationConstants.chatLabel,
                        index: NavigationConstants.chatIndex,
                        isSelected:
                            currentIndex == NavigationConstants.chatIndex,
                      ),
                    ),
                    // آکادمی
                    Container(
                      key: navKeys?[NavigationConstants.academyIndex],
                      width: itemWidth,
                      height: NavigationConstants.bottomNavHeight,
                      alignment: Alignment.center,
                      child: _buildNavItem(
                        icon: NavigationConstants.academyIcon,
                        label: NavigationConstants.academyLabel,
                        index: NavigationConstants.academyIndex,
                        isSelected:
                            currentIndex == NavigationConstants.academyIndex,
                      ),
                    ),
                    // فضای خالی برای دکمه مرکزی
                    SizedBox(width: centralButtonSpace),
                    // باشگاه من / داشبورد مربی
                    Container(
                      key: navKeys?[NavigationConstants.myClubIndex],
                      width: itemWidth,
                      height: NavigationConstants.bottomNavHeight,
                      alignment: Alignment.center,
                      child: _buildNavItem(
                        icon: userRole == 'trainer'
                            ? LucideIcons.barChart3
                            : NavigationConstants.myClubIcon,
                        label: userRole == 'trainer'
                            ? 'میز کار'
                            : NavigationConstants.myClubLabel,
                        index: NavigationConstants.myClubIndex,
                        isSelected:
                            currentIndex == NavigationConstants.myClubIndex,
                      ),
                    ),
                    // اجتماعی
                    Container(
                      key: navKeys?[NavigationConstants.socialIndex],
                      width: itemWidth,
                      height: NavigationConstants.bottomNavHeight,
                      alignment: Alignment.center,
                      child: _buildNavItem(
                        icon: NavigationConstants.socialIcon,
                        label: NavigationConstants.socialLabel,
                        index: NavigationConstants.socialIndex,
                        isSelected:
                            currentIndex == NavigationConstants.socialIndex,
                      ),
                    ),
                  ],
                );
              },
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
                  key:
                      navKeys?[NavigationConstants
                          .dashboardIndex], // انتقال key به Container
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
                        color: isDark
                            ? context.backgroundColor
                            : context.cardColor,
                        width: 4.w,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(22.5.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22.5.r),
                          child: Image.asset(
                            'images/GYMAI_logo_transparent.png',
                            width: NavigationConstants.centralLogoSize,
                            height: NavigationConstants.centralLogoSize,
                            fit: BoxFit.contain,
                          ),
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
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GestureDetector(
          onTap: () => onTap(index),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 8.h,
            ), // کاهش padding برای جلوگیری از overflow
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // برای جلوگیری از overflow
              children: [
                Container(
                  padding: const EdgeInsets.all(
                    NavigationConstants.navItemPadding,
                  ), // کاهش padding
                  decoration: BoxDecoration(
                    gradient: isSelected && !isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldColor.withValues(alpha: 0.25),
                              AppTheme.goldColor.withValues(alpha: 0.15),
                            ],
                          )
                        : null,
                    color: isSelected && isDark
                        ? AppTheme.goldColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppTheme.goldColor
                        : isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : context.textSecondary,
                    size: NavigationConstants
                        .navItemIconSize, // کاهش اندازه آیکون
                  ),
                ),
                SizedBox(
                  height: NavigationConstants
                      .navItemSpacing
                      .h, // استفاده از responsive
                ),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.goldColor
                          : isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : context.textSecondary,
                      fontSize: NavigationConstants
                          .navItemFontSize
                          .sp, // استفاده از responsive
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
