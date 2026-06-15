// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// App imports
import 'package:gymaipro/notification/providers/notification_provider.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/theme/theme_provider.dart';
import 'package:gymaipro/widgets/notification_icon.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Welcome Card Widget
class WelcomeCard extends StatefulWidget {
  const WelcomeCard({
    required this.username,
    required this.welcomeMessage,
    required this.welcomeIcon,
    super.key,
    this.profileData,
    this.streak,
  });
  final String username;
  final String welcomeMessage;
  final IconData welcomeIcon;
  final Map<String, dynamic>? profileData;
  final int? streak;

  @override
  State<WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<WelcomeCard> {
  String _getDisplayName() {
    if (widget.profileData != null) {
      final firstName = widget.profileData!['first_name']?.toString() ?? '';
      final lastName = widget.profileData!['last_name']?.toString() ?? '';
      final userUsername = widget.profileData!['username']?.toString() ?? '';

      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
      // اگر نام و نام خانوادگی نبود، یوزرنیم نمایش داده شود
      if (userUsername.isNotEmpty) {
        return userUsername;
      }
    }
    return widget.username.isNotEmpty ? widget.username : 'کاربر عزیز';
  }

  String _getUserInitial() {
    final displayName = _getDisplayName();
    if (displayName.isEmpty) return 'U';
    return displayName.substring(0, 1).toUpperCase();
  }

  Widget _buildProfileImage({double? size}) {
    final imageSize = size ?? 60.w;
    // اگر عکس پروفایل موجود باشد، آن را نمایش ده
    if (widget.profileData != null &&
        widget.profileData!['avatar_url'] != null &&
        widget.profileData!['avatar_url'].toString().isNotEmpty) {
      // Avatar URL loaded successfully

      return Image.network(
        widget.profileData!['avatar_url'] as String,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: imageSize,
            height: imageSize,
            color: context.cardColor,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.goldColor,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Error loading avatar handled silently
          return _buildInitialAvatar(size: imageSize, buildContext: context);
        },
      );
    }

    // No avatar URL found, using initial avatar
    // اگر عکس پروفایل نباشد، حرف اول نام را نمایش ده
    return _buildInitialAvatar(size: imageSize, buildContext: context);
  }

  Widget _buildInitialAvatar({double? size, BuildContext? buildContext}) {
    final avatarSize = size ?? 60.0;
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.goldColor.withValues(alpha: 0.3),
                      AppTheme.goldColor.withValues(alpha: 0.1),
                    ]
                  : [
                      context.goldGradientColors[0],
                      context.goldGradientColors[1],
                    ],
            ),
            borderRadius: BorderRadius.circular(avatarSize / 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getUserInitial(),
              style: TextStyle(
                color: isDark ? AppTheme.darkTextColor : context.textColor,
                fontSize: avatarSize * 0.4,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
                shadows: [
                  Shadow(
                    color: isDark
                        ? context.backgroundColor.withValues(alpha: 0.5)
                        : context.cardColor.withValues(alpha: 0.3),
                    blurRadius: 3.r,
                    offset: Offset(0.w, 1.h),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStreak(BuildContext context) {
    if (widget.streak == null || widget.streak! < 1) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = widget.streak == 1 ? '۱' : '${widget.streak}';

    return Container(
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFFFF6B35).withValues(alpha: 0.5),
                  AppTheme.goldColor.withValues(alpha: 0.5),
                ]
              : [
                  const Color(0xFFFF6B35).withValues(alpha: 0.7),
                  AppTheme.goldColor.withValues(alpha: 0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(
            alpha: isDark ? 0.5 : 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(
              alpha: isDark ? 0.15 : 0.2,
            ),
            blurRadius: 4.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            LucideIcons.flame,
            color: isDark ? Colors.white : Colors.white,
            size: 12.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 10.sp,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.3 : 0.2,
                  ),
                  blurRadius: 1,
                  offset: const Offset(0, 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        final currentIsDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: () => themeProvider.toggleTheme(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: 32.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: currentIsDark
                    ? [
                        AppTheme.goldColor.withValues(alpha: 0.15),
                        AppTheme.goldColor.withValues(alpha: 0.1),
                      ]
                    : [
                        context.goldGradientColors[0].withValues(alpha: 0.2),
                        context.goldGradientColors[1].withValues(alpha: 0.15),
                      ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                  blurRadius: 4.r,
                  offset: Offset(0.w, 2.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // آیکون ماه (Dark Mode)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldColor.withValues(alpha: 0.4),
                              AppTheme.goldColor.withValues(alpha: 0.25),
                            ],
                          )
                        : null,
                    color: isDark ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.dark_mode,
                    size: 14.sp,
                    color: isDark ? AppTheme.goldColor : context.textSecondary,
                  ),
                ),
                SizedBox(width: 4.w),
                // آیکون خورشید (Light Mode)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    gradient: !isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldColor.withValues(alpha: 0.4),
                              AppTheme.goldColor.withValues(alpha: 0.25),
                            ],
                          )
                        : null,
                    color: !isDark ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.light_mode,
                    size: 14.sp,
                    color: !isDark ? context.textColor : context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600.w),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [context.backgroundColor, context.backgroundColor]
                  : [
                      context.goldGradientColors[0].withValues(alpha: 0.15),
                      context.cardColor,
                      context.goldGradientColors[1].withValues(alpha: 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.4
                    : 0.5,
              ),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.15
                      : 0.35,
                ),
                blurRadius: 16.r,
                offset: Offset(0.w, 6.h),
                spreadRadius: 1.r,
              ),
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? context.backgroundColor.withValues(alpha: 0.3)
                    : AppTheme.lightTextColor.withValues(alpha: 0.08),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              // تصویر پروفایل کاربر
              GestureDetector(
                onTap: () {
                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id;
                  // Open **my** profile using the dedicated screen.
                  // `/user-profile` is for viewing other users and expects a profiles.id in many tables.
                  if (currentUserId != null && currentUserId.isNotEmpty) {
                    Navigator.pushNamed(context, '/profile');
                  }
                },
                child: Container(
                  width: ResponsiveValue(
                    context,
                    defaultValue: 60.w,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 50.w),
                      Condition.largerThan(name: TABLET, value: 70.w),
                    ],
                  ).value,
                  height: ResponsiveValue(
                    context,
                    defaultValue: 60.h,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 50.h),
                      Condition.largerThan(name: TABLET, value: 70.h),
                    ],
                  ).value,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [context.cardColor, context.cardColor]
                          : [
                              context.goldGradientColors[0].withValues(
                                alpha: 0.2,
                              ),
                              context.goldGradientColors[1].withValues(
                                alpha: 0.15,
                              ),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.3
                            : 0.6,
                      ),
                      width: 2.5.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.2
                              : 0.4,
                        ),
                        blurRadius: 12.r,
                        offset: Offset(0.w, 4.h),
                        spreadRadius: 1.r,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28.r),
                    child: _buildProfileImage(),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [context.textColor, AppTheme.goldColor]
                              : [context.textColor, AppTheme.goldColor],
                        ).createShader(bounds);
                      },
                      child: Text(
                        widget.welcomeMessage,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTheme.fontFamily,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getDisplayName(),
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: ResponsiveValue(
                          context,
                          defaultValue: 11.sp,
                          conditionalValues: [
                            Condition.smallerThan(name: MOBILE, value: 10.sp),
                            Condition.largerThan(name: TABLET, value: 13.sp),
                          ],
                        ).value,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.fontFamily,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    // Streak و Theme Selector کنار هم
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _buildThemeSelector(context),
                        if (widget.streak != null && widget.streak! > 0) ...[
                          SizedBox(width: 8.w),
                          _buildMiniStreak(context),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              NotificationIcon(
                onTap: () async {
                  await Navigator.pushNamed(context, '/notifications');
                  // Refresh notification status when returning
                  if (context.mounted) {
                    context.read<NotificationProvider>().refreshUnreadCount();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Achievements & Stats Section
class AchievementsAndStats extends StatelessWidget {
  const AchievementsAndStats({
    required this.achievements,
    required this.stats,
    super.key,
  });
  final List<Widget> achievements;
  final List<Widget> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: stats,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 3,
          child: Wrap(spacing: 8.w, runSpacing: 8.h, children: achievements),
        ),
      ],
    );
  }
}

// Simple Stats List
class SimpleStatsList extends StatelessWidget {
  const SimpleStatsList({required this.items, super.key});
  final List<SimpleStatItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(children: items);
  }
}

class SimpleStatItem extends StatelessWidget {
  const SimpleStatItem({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: context.textColor,
              size: ResponsiveValue(
                context,
                defaultValue: 20.sp,
                conditionalValues: [
                  Condition.smallerThan(name: MOBILE, value: 18.sp),
                  Condition.largerThan(name: TABLET, value: 22.sp),
                ],
              ).value,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: ResponsiveValue(
                    context,
                    defaultValue: 14.sp,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 12.sp),
                      Condition.largerThan(name: TABLET, value: 16.sp),
                    ],
                  ).value,
                  fontFamily: AppTheme.fontFamily,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: context.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveValue(
                    context,
                    defaultValue: 15.sp,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 13.sp),
                      Condition.largerThan(name: TABLET, value: 17.sp),
                    ],
                  ).value,
                  fontFamily: AppTheme.fontFamily,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
