import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/guide/data/drawer_guide_data.dart';
import 'package:gymaipro/guide/guide.dart';
import 'package:gymaipro/notification/screens/notification_settings_screen.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/referral/screens/referral_guide_screen.dart';
import 'package:gymaipro/screens/help_screen.dart';
import 'package:gymaipro/screens/settings_screen.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/admin/screens/admin_dashboard_screen.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_dashboard_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardDrawer extends StatefulWidget {
  const DashboardDrawer({
    required this.username,
    required this.userRole,
    required this.walletBalance,
    required this.onSignOut,
    super.key,
  });

  final String? username;
  final String? userRole;
  final int? walletBalance;
  final VoidCallback onSignOut;

  @override
  State<DashboardDrawer> createState() => _DashboardDrawerState();
}

class _DashboardDrawerState extends State<DashboardDrawer>
    with AutomaticKeepAliveClientMixin {
  String? _avatarUrl;
  bool _isLoadingAvatar = true;
  static String? _cachedAvatarUrl;
  static String? _cachedUserId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAvatarUrl();
    _checkAndShowDrawerGuide();
  }

  void _checkAndShowDrawerGuide() {
    // تاخیر برای اطمینان از render شدن drawer
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        final guideService = Provider.of<GuideService>(context, listen: false);
        // ثبت راهنما
        registerGuide(context, DrawerGuideData.getDrawerGuide());
        // نمایش راهنما اگر باید نمایش داده شود
        if (guideService.shouldShowGuide('drawer_guide')) {
          await startGuide(context, 'drawer_guide');
        }
      }
    });
  }

  Future<void> _loadAvatarUrl() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    // اگر عکس قبلاً کش شده و کاربر همان است، از کش استفاده کن
    if (_cachedAvatarUrl != null && _cachedUserId == userId) {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _avatarUrl = _cachedAvatarUrl;
          _isLoadingAvatar = false;
        });
      }
      return;
    }

    try {
      final result = await SimpleProfileService.queryCurrentUserProfile(
        select: 'avatar_url',
      );

      if (mounted) {
        final avatarUrl = (result != null)
            ? (result['avatar_url'] as String?)
            : null;
        WidgetSafetyUtils.safeSetState(this, () {
          _avatarUrl = avatarUrl;
          _isLoadingAvatar = false;
        });
        // ذخیره در کش static
        _cachedAvatarUrl = avatarUrl;
        _cachedUserId = userId;
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoadingAvatar = false;
        });
      }
    }
  }

  String _getSafeInitial() {
    if (widget.username == null || widget.username!.isEmpty) {
      return 'U';
    }
    return widget.username!.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // برای AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FeatureTourWidget(
      guideId: 'drawer_guide', // فقط راهنمای drawer رو نمایش بده
      child: Drawer(
        backgroundColor: isDark
            ? AppTheme.darkCardColor
            : AppTheme.lightCardColor,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildMenuItems(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: DrawerGuideData.keys['drawer_header'],
      padding: EdgeInsets.all(20.w),
      color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
      child: Column(
        children: [
          _buildAvatar(context),
          SizedBox(height: 12.h),
          _buildUserInfo(context),
          SizedBox(height: 12.h),
          _buildWalletButton(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (_isLoadingAvatar) {
      return CircleAvatar(
        radius: 40.r,
        backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
        child: CircularProgressIndicator(
          color: AppTheme.goldColor,
          strokeWidth: 2,
        ),
      );
    }

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: _avatarUrl!,
          cacheKey: 'avatar_$userId',
          width: 80.r,
          height: 80.r,
          fit: BoxFit.cover,
          memCacheWidth: 160,
          memCacheHeight: 160,
          maxWidthDiskCache: 320,
          maxHeightDiskCache: 320,
          fadeInDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          placeholder: (context, url) => CircleAvatar(
            radius: 40.r,
            backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
            child: CircularProgressIndicator(
              color: AppTheme.goldColor,
              strokeWidth: 2,
            ),
          ),
          errorWidget: (context, url, error) => CircleAvatar(
            radius: 40.r,
            backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
            child: Text(
              _getSafeInitial(),
              style: TextStyle(
                color: AppTheme.goldColor,
                fontWeight: FontWeight.bold,
                fontSize: 24.sp,
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 40.r,
      backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
      child: Text(
        _getSafeInitial(),
        style: TextStyle(
          color: AppTheme.goldColor,
          fontWeight: FontWeight.bold,
          fontSize: 24.sp,
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          widget.username ?? 'کاربر عزیز',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _getRoleDisplayName(widget.userRole),
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                : AppTheme.lightTextSecondary,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(String? role) {
    if (role == null || role.isEmpty) {
      return 'ورزشکار';
    }

    final roleLower = role.toLowerCase();

    switch (roleLower) {
      case 'trainer':
        return 'مربی';
      case 'admin':
        return 'مدیر';
      case 'athlete':
      default:
        return 'ورزشکار';
    }
  }

  Widget _buildWalletButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/wallet');
        },
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.wallet,
                  color: context.textColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                PaymentConstants.formatAmount(widget.walletBalance ?? 0),
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextColor.withValues(alpha: 0.9)
                      : AppTheme.lightTextColor.withValues(alpha: 0.9),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildMenuItem(
          context,
          key: DrawerGuideData.keys['menu_home'],
          icon: LucideIcons.home,
          title: 'خانه',
          isActive: true,
          onTap: () {
            // بستن drawer
            Navigator.pop(context);

            // اجرای navigation بعد از بستن drawer
            SchedulerBinding.instance.addPostFrameCallback((_) {
              // استفاده از Navigator اصلی برای دسترسی به navigation stack
              final navigator = Navigator.of(context, rootNavigator: false);

              // اگر در صفحه دیگری هستیم (مثل FoodLogScreen)، به داشبورد برگرد
              // با pop کردن تا به داشبورد برسیم
              if (navigator.canPop()) {
                // به صفحه قبلی برگرد (که باید داشبورد باشد)
                navigator.pop();
              }
            });
          },
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
        _buildMenuItem(
          context,
          key: DrawerGuideData.keys['menu_my_club'],
          icon: LucideIcons.users,
          title: 'باشگاه من',
          onTap: () {
            // اگر راهنما فعال است، drawer نباید بسته شود
            final guideService = Provider.of<GuideService>(
              context,
              listen: false,
            );
            if (guideService.hasActiveGuide &&
                guideService.activeGuide?.id == 'drawer_guide') {
              return;
            }

            Navigator.pop(context);
            Navigator.pushNamed(context, '/my-club');
          },
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
        _buildMenuItem(
          context,
          key: DrawerGuideData.keys['menu_trainer_dashboard'],
          icon: LucideIcons.users,
          title: 'میز کار مربی',
          isLocked: widget.userRole != 'trainer' && widget.userRole != 'admin',
          onTap: (widget.userRole == 'trainer' || widget.userRole == 'admin')
              ? () {
                  // اگر راهنما فعال است، drawer نباید بسته شود
                  final guideService = Provider.of<GuideService>(
                    context,
                    listen: false,
                  );
                  if (guideService.hasActiveGuide &&
                      guideService.activeGuide?.id == 'drawer_guide') {
                    return;
                  }

                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const TrainerDashboardScreen(),
                    ),
                  );
                }
              : null,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
        _buildMenuItem(
          context,
          icon: LucideIcons.shield,
          title: 'میز کار ادمین',
          isLocked: widget.userRole != 'admin',
          onTap: widget.userRole == 'admin'
              ? () {
                  // اگر راهنما فعال است، drawer نباید بسته شود
                  final guideService = Provider.of<GuideService>(
                    context,
                    listen: false,
                  );
                  if (guideService.hasActiveGuide &&
                      guideService.activeGuide?.id == 'drawer_guide') {
                    return;
                  }

                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                }
              : null,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
        _buildMenuItem(
          context,
          key: DrawerGuideData.keys['menu_notifications'],
          icon: LucideIcons.bell,
          title: 'تنظیمات اعلان‌ها',
          onTap: () {
            // اگر راهنما فعال است، drawer نباید بسته شود
            final guideService = Provider.of<GuideService>(
              context,
              listen: false,
            );
            if (guideService.hasActiveGuide &&
                guideService.activeGuide?.id == 'drawer_guide') {
              return;
            }

            WidgetSafetyUtils.safePop(context);
            WidgetSafetyUtils.safeNavigate(
              context,
              () => const NotificationSettingsScreen(),
            );
          },
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
        _buildMenuItem(
          context,
          key: DrawerGuideData.keys['menu_settings'],
          icon: LucideIcons.settings,
          title: 'تنظیمات عمومی',
          onTap: () {
            // اگر راهنما فعال است، drawer نباید بسته شود
            final guideService = Provider.of<GuideService>(
              context,
              listen: false,
            );
            if (guideService.hasActiveGuide &&
                guideService.activeGuide?.id == 'drawer_guide') {
              return;
            }

            WidgetSafetyUtils.safePop(context);
            WidgetSafetyUtils.safeNavigate(
              context,
              () => const SettingsScreen(),
            );
          },
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
        _buildMenuItem(
          context,
          key: DrawerGuideData.keys['menu_referral'],
          icon: LucideIcons.gift,
          title: 'دعوت دوستان',
          onTap: () {
            // اگر راهنما فعال است، drawer نباید بسته شود
            final guideService = Provider.of<GuideService>(
              context,
              listen: false,
            );
            if (guideService.hasActiveGuide &&
                guideService.activeGuide?.id == 'drawer_guide') {
              return;
            }

            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const ReferralGuideScreen(),
              ),
            );
          },
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
        _buildMenuItem(
          context,
          key: DrawerGuideData.keys['menu_help'],
          icon: LucideIcons.helpCircle,
          title: 'راهنما',
          onTap: () {
            // اگر راهنما فعال است، drawer نباید بسته شود
            final guideService = Provider.of<GuideService>(
              context,
              listen: false,
            );
            if (guideService.hasActiveGuide &&
                guideService.activeGuide?.id == 'drawer_guide') {
              return;
            }

            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (context) => const HelpScreen()),
            );
          },
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
        _buildMenuItem(
          context,
          key: DrawerGuideData.keys['menu_guide_tour'],
          icon: LucideIcons.router,
          title: 'تور راهنمای داشبورد',
          onTap: () async {
            // اگر راهنما فعال است، drawer نباید بسته شود
            final guideService = Provider.of<GuideService>(
              context,
              listen: false,
            );
            if (guideService.hasActiveGuide &&
                guideService.activeGuide?.id == 'drawer_guide') {
              return;
            }

            Navigator.pop(context);
            try {
              // ریست راهنمای داشبورد برای نمایش مجدد
              await guideService.resetGuide('dashboard_main_tour');
              // تاخیر کوتاه برای اطمینان از بسته شدن drawer
              await Future<void>.delayed(const Duration(milliseconds: 300));
              // شروع راهنما
              await startGuide(context, 'dashboard_main_tour');
            } catch (e) {
              debugPrint('Error starting guide: $e');
            }
          },
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
        _buildMenuItem(
          context,
          key: DrawerGuideData.keys['menu_logout'],
          icon: LucideIcons.logOut,
          title: 'خروج از حساب',
          onTap: () {
            // اگر راهنما فعال است، drawer نباید بسته شود
            final guideService = Provider.of<GuideService>(
              context,
              listen: false,
            );
            if (guideService.hasActiveGuide &&
                guideService.activeGuide?.id == 'drawer_guide') {
              return;
            }

            Navigator.pop(context);
            widget.onSignOut();
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool isLocked = false,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isActive
        ? (isDark ? AppTheme.goldColor : context.textColor)
        : (isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor);
    final textColor = isActive
        ? (isDark ? AppTheme.goldColor : context.textColor)
        : (isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor);

    return ListTile(
      key: key,
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      leading: Icon(
        isLocked ? LucideIcons.lock : icon,
        color: isLocked
            ? (isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                  : AppTheme.lightTextSecondary)
            : iconColor,
        size: 24.sp,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLocked
              ? (isDark
                    ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                    : AppTheme.lightTextSecondary)
              : textColor,
          fontWeight: FontWeight.w600,
          fontSize: 16.sp,
        ),
      ),
      onTap: isLocked ? null : onTap,
    );
  }
}
