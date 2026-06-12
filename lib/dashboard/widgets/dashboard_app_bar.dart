import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/guide/data/dashboard_guide_data.dart';
import 'package:gymaipro/services/avatar_refresh_notifier.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? context.backgroundColor : Colors.transparent,
      elevation: 0,
      title: _buildLogoWidget(context),
      centerTitle: true,
      leading: Builder(builder: _buildMenuButton),
      actions: [
        _buildProfileButton(context),
        SizedBox(width: 8.w),
        _buildScoreWidget(context),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildScoreWidget(BuildContext context) {
    return Consumer<ScoreService>(
      builder: (context, scoreService, child) {
        return Container(
          margin: EdgeInsets.symmetric(vertical: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.2),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: 0.15),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                LucideIcons.star,
                color: context.textColor,
                size: ResponsiveValue(
                  context,
                  defaultValue: 18.sp,
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 16.sp),
                    Condition.largerThan(name: TABLET, value: 20.sp),
                  ],
                ).value,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  _formatScore(scoreService.score),
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
                    letterSpacing: 0.3,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }

  Widget _buildLogoWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.goldColor, AppTheme.darkGold],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Text(
        'GYMAI',
        style: TextStyle(
          color: AppTheme.onGoldColor,
          fontWeight: FontWeight.bold,
          fontSize: ResponsiveValue(
            context,
            defaultValue: 14.sp,
            conditionalValues: [
              Condition.smallerThan(name: MOBILE, value: 12.sp),
              Condition.largerThan(name: TABLET, value: 16.sp),
            ],
          ).value,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return Builder(
      builder: (context) => IconButton(
        key: DashboardGuideData.keys['drawer_menu'], // Key برای guide overlay
        icon: Icon(
          LucideIcons.menu,
          color: context.textColor,
          size: ResponsiveValue(
            context,
            defaultValue: 32.sp,
            conditionalValues: [
              Condition.smallerThan(name: MOBILE, value: 28.sp),
              Condition.largerThan(name: TABLET, value: 36.sp),
            ],
          ).value,
        ),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return const _AppBarAvatarButton();
  }
}

/// دکمه آواتار در اپ‌بار که با [AvatarRefreshNotifier] به‌روز می‌شود.
class _AppBarAvatarButton extends StatefulWidget {
  const _AppBarAvatarButton();

  @override
  State<_AppBarAvatarButton> createState() => _AppBarAvatarButtonState();
}

class _AppBarAvatarButtonState extends State<_AppBarAvatarButton> {
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    AvatarRefreshNotifier.instance.addListener(_onAvatarUpdated);
  }

  @override
  void dispose() {
    AvatarRefreshNotifier.instance.removeListener(_onAvatarUpdated);
    super.dispose();
  }

  void _onAvatarUpdated() {
    if (mounted) setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      key: ValueKey<int>(_refreshKey),
      future: SimpleProfileService.queryCurrentUserProfile(
        select: 'avatar_url',
      ),
      builder: (context, snapshot) {
        final avatarUrl = snapshot.data?['avatar_url'] as String?;
        final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

        return GestureDetector(
          onTap: () {
            if (userId.isNotEmpty) {
              Navigator.pushNamed(context, '/profile');
            }
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8.h),
            width: ResponsiveValue(
              context,
              defaultValue: 40.w,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 36.w),
                Condition.largerThan(name: TABLET, value: 44.w),
              ],
            ).value,
            height: ResponsiveValue(
              context,
              defaultValue: 40.h,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 36.h),
                Condition.largerThan(name: TABLET, value: 44.h),
              ],
            ).value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.4),
                width: 2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  blurRadius: 6.r,
                  offset: Offset(0.w, 2.h),
                ),
              ],
            ),
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      cacheKey: 'avatar_appbar_${userId}_${avatarUrl.hashCode}',
                      fit: BoxFit.cover,
                      memCacheWidth: 80,
                      memCacheHeight: 80,
                      placeholder: (context, url) => Container(
                        color: AppTheme.goldColor.withValues(alpha: 0.1),
                        child: Icon(
                          LucideIcons.user,
                          color: AppTheme.goldColor,
                          size: 20.sp,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.goldColor.withValues(alpha: 0.1),
                        child: Icon(
                          LucideIcons.user,
                          color: AppTheme.goldColor,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.goldColor.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      LucideIcons.user,
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
                  ),
          ),
        );
      },
    );
  }
}
