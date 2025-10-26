// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/notification/services/notification_data_service.dart';
// App imports
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/notification_icon.dart';
import 'package:responsive_framework/responsive_framework.dart';

// Welcome Card Widget
class WelcomeCard extends StatefulWidget {
  const WelcomeCard({
    required this.username,
    required this.welcomeMessage,
    required this.welcomeIcon,
    super.key,
    this.profileData,
  });
  final String username;
  final String welcomeMessage;
  final IconData welcomeIcon;
  final Map<String, dynamic>? profileData;

  @override
  State<WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<WelcomeCard> {
  bool _hasUnreadNotifications = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    try {
      if (!mounted) return;

      final hasUnread = await NotificationDataService.hasUnreadNotifications();
      final count = await NotificationDataService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        _hasUnreadNotifications = hasUnread;
        _unreadCount = count;
      });
    } catch (e) {
      // Handle error silently - never crash the app
      print('Error loading notification status: $e');

      // Set default values to prevent crashes
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = false;
          _unreadCount = 0;
        });
      }
    }
  }

  /// Refresh notification status - called when returning from notifications screen
  Future<void> refreshNotificationStatus() async {
    if (!mounted) return;
    await _loadNotificationStatus();
  }

  /// Manual refresh for notification status
  Future<void> manualRefresh() async {
    if (!mounted) return;
    await _loadNotificationStatus();
  }

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
      print('🖼️ Avatar URL: ${widget.profileData!['avatar_url']}');

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
            color: Colors.white.withValues(alpha: 0.1),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading avatar: $error');
          return _buildInitialAvatar(size: imageSize);
        },
      );
    }

    print('🖼️ No avatar URL found');
    // اگر عکس پروفایل نباشد، حرف اول نام را نمایش ده
    return _buildInitialAvatar(size: imageSize);
  }

  Widget _buildInitialAvatar({double? size}) {
    final avatarSize = size ?? 60.0;
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(avatarSize / 2),
      ),
      child: Center(
        child: Text(
          _getUserInitial(),
          style: TextStyle(
            color: Colors.white,
            fontSize: avatarSize * 0.4,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black38,
                blurRadius: 3.r,
                offset: Offset(0.w, 1.h),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: EdgeInsets.all(20.w),
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
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGold.withValues(alpha: 0.3),
            blurRadius: 15.r,
            offset: Offset(0.w, 5.h),
            spreadRadius: 2.r,
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8.r,
                      offset: Offset(0.w, 2.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28.r),
                  child: _buildProfileImage(),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.welcomeMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 3.r,
                            offset: Offset(0.w, 1.h),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getDisplayName(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: ResponsiveValue(
                          context,
                          defaultValue: 16.sp,
                          conditionalValues: [
                            Condition.smallerThan(name: MOBILE, value: 14.sp),
                            Condition.largerThan(name: TABLET, value: 18.sp),
                          ],
                        ).value,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 2.r,
                            offset: Offset(0.w, 1.h),
                          ),
                        ],
                      ),
                    ),
                    // نمایش قد و وزن
                    if (widget.profileData != null) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Flexible(
                            child: _buildMinimalMetricChip(
                              '${widget.profileData!['height'] ?? '0'} cm',
                              Icons.height,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: _buildMinimalMetricChip(
                              '${widget.profileData!['weight'] ?? '0'} kg',
                              Icons.monitor_weight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              NotificationIcon(
                hasUnreadNotifications: _hasUnreadNotifications,
                unreadCount: _unreadCount,
                onTap: () async {
                  await Navigator.pushNamed(context, '/notifications');
                  // Refresh notification status when returning
                  await refreshNotificationStatus();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalMetricChip(String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: ResponsiveValue(
              context,
              defaultValue: 12.sp,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 10.sp),
                Condition.largerThan(name: TABLET, value: 14.sp),
              ],
            ).value,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveValue(
                  context,
                  defaultValue: 10.sp,
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 8.sp),
                    Condition.largerThan(name: TABLET, value: 12.sp),
                  ],
                ).value,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
        Expanded(flex: 2, child: Column(children: stats)),
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
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.goldColor,
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
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: ResponsiveValue(
                    context,
                    defaultValue: 14.sp,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 12.sp),
                      Condition.largerThan(name: TABLET, value: 16.sp),
                    ],
                  ).value,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveValue(
                    context,
                    defaultValue: 15.sp,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 13.sp),
                      Condition.largerThan(name: TABLET, value: 17.sp),
                    ],
                  ).value,
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
