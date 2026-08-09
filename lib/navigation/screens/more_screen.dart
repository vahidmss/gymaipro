import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/screens/admin_dashboard_screen.dart';
import 'package:gymaipro/achievements/screens/achievements_screen.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/core/gamification_labels.dart';
import 'package:gymaipro/debug/debug_account_switcher_sheet.dart';
import 'package:gymaipro/features/coach/presentation/screens/coach_home_screen.dart';
import 'package:gymaipro/features/legal/navigation/legal_routes.dart';
import 'package:gymaipro/features/product_experience/navigation/workout_program_request_navigation.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/ranking/screens/leaderboard_screen.dart';
import 'package:gymaipro/referral/screens/referral_guide_screen.dart';
import 'package:gymaipro/screens/settings_screen.dart';
import 'package:gymaipro/services/app_state.dart';
import 'package:gymaipro/services/logout_cache_clear_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/screens/trainer_channel_manage_screen.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_ranking_screen.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// تب «بیشتر» — صفحهٔ واقعی، گروه‌بندی نقش‌محور، بدون تکرار تنظیمات در لیست.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  Map<String, dynamic>? _profile;
  int? _walletBalance;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHeader());
  }

  Future<void> _loadHeader() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final wallet = await WalletService().getUserWallet();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _walletBalance = wallet?.availableBalance ?? wallet?.balance;
      });
    } catch (_) {}
  }

  String get _role => (_profile?['role'] as String?) ?? 'athlete';
  bool get _isTrainer => _role == 'trainer' || _role == 'admin';
  bool get _isAdmin => _role == 'admin';

  String get _displayName {
    final first = _profile?['first_name']?.toString() ?? '';
    final last = _profile?['last_name']?.toString() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    final username = _profile?['username']?.toString();
    if (username != null && username.isNotEmpty) return username;
    return 'کاربر';
  }

  String? get _avatarUrl {
    final url = _profile?['avatar_url']?.toString();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  String get _roleLabel {
    return switch (_role) {
      'trainer' => 'مربی',
      'admin' => 'ادمین',
      _ => 'ورزشکار',
    };
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      final rootNav = Navigator.of(context, rootNavigator: true);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      await LogoutCacheClearService.clearAllUserData(previousUserId: userId);
      await AppState().logout();
      await AuthStateService().clearAuthState();
      unawaited(
        rootNav.pushNamedAndRemoveUntil('/welcome', (route) => false),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در خروج از حساب کاربری')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: context.pageDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor:
              isDark ? context.backgroundColor : Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            NavigationConstants.moreLabel,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 18.sp,
              color: isDark ? AppTheme.goldColor : context.textColor,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تنظیمات',
              onPressed: () => unawaited(_openSettings()),
              icon: Icon(
                LucideIcons.settings,
                color: context.textColor,
                size: 22.sp,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
          children: [
            _ProfileCard(
              name: _displayName,
              roleLabel: _roleLabel,
              avatarUrl: _avatarUrl,
              onTap: () {
                final id = Supabase.instance.client.auth.currentUser?.id;
                if (id != null && id.isNotEmpty) {
                  Navigator.pushNamed(context, '/profile');
                }
              },
            ),
            SizedBox(height: 18.h),
            if (!_isTrainer) ...[
              _sectionLabel(context, 'مربی و هوش مصنوعی'),
              _MoreTile(
                icon: LucideIcons.bot,
                title: 'مربی AI',
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CoachHomeScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 8.h),
            ],
            if (_isTrainer) ...[
              _sectionLabel(context, 'ابزار مربی'),
              if (!_isAdmin)
                _MoreTile(
                  icon: LucideIcons.radio,
                  title: 'کانال من',
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const TrainerChannelManageScreen(),
                      ),
                    );
                  },
                ),
              _MoreTile(
                icon: LucideIcons.bot,
                title: 'مربی AI',
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CoachHomeScreen(),
                    ),
                  );
                },
              ),
              if (_isAdmin)
                _MoreTile(
                  icon: LucideIcons.shield,
                  title: 'میز کار ادمین',
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
              SizedBox(height: 8.h),
            ],
            if (!_isTrainer) ...[
              _sectionLabel(context, 'پیشرفت'),
              _MoreTile(
                icon: GamificationLabels.pointsIcon,
                title: GamificationLabels.points,
                onTap: () =>
                    MainNavigationScreen.navigateToMyClub(initialTab: 3),
              ),
              _MoreTile(
                icon: GamificationLabels.achievementsIcon,
                title: GamificationLabels.achievements,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AchievementsScreen(),
                    ),
                  );
                },
              ),
              _MoreTile(
                icon: GamificationLabels.rankingIcon,
                title: GamificationLabels.ranking,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  );
                },
              ),
              _MoreTile(
                icon: LucideIcons.shield,
                title: 'اطلاعات محرمانه',
                onTap: () =>
                    MainNavigationScreen.navigateToMyClub(initialTab: 5),
              ),
              SizedBox(height: 8.h),
            ],
            _sectionLabel(context, 'تمرین و تغذیه'),
            if (!_isTrainer)
              _MoreTile(
                icon: LucideIcons.users,
                title: 'دوستان',
                onTap: () =>
                    MainNavigationScreen.navigateToMyClub(initialTab: 2),
              ),
            _MoreTile(
              icon: LucideIcons.list,
              title: 'لیست حرکات',
              onTap: () => Navigator.pushNamed(
                context,
                NavigationConstants.exerciseListRoute,
              ),
            ),
            _MoreTile(
              icon: LucideIcons.utensils,
              title: 'لیست غذاها',
              onTap: () => Navigator.pushNamed(
                context,
                NavigationConstants.foodListRoute,
              ),
            ),
            if (!_isTrainer)
              _MoreTile(
                icon: LucideIcons.clipboardList,
                title: 'درخواست برنامه',
                onTap: () => unawaited(
                  WorkoutProgramRequestNavigation.open(context),
                ),
              ),
            SizedBox(height: 8.h),
            _sectionLabel(context, 'کشف و اجتماع'),
            _MoreTile(
              icon: LucideIcons.trophy,
              title: 'لیست مربیان',
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const TrainerRankingScreen(),
                  ),
                );
              },
            ),
            _MoreTile(
              icon: LucideIcons.school,
              title: 'آکادمی',
              onTap: () => MainNavigationScreen.openAcademy(),
            ),
            _MoreTile(
              icon: LucideIcons.gift,
              title: 'دعوت دوستان',
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ReferralGuideScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 8.h),
            _sectionLabel(context, 'مالی و اشتراک'),
            _MoreTile(
              icon: LucideIcons.wallet,
              title: 'کیف پول',
              subtitle: _walletBalance == null
                  ? null
                  : PaymentConstants.formatAmount(_walletBalance!),
              onTap: () {
                if (_isTrainer) {
                  Navigator.pushNamed(context, '/wallet');
                } else {
                  openMainMyClub(initialTab: MyClubTabs.wallet);
                }
              },
            ),
            _MoreTile(
              icon: LucideIcons.crown,
              title: 'اشتراک ویژه',
              onTap: () => Navigator.pushNamed(context, '/subscriptions'),
            ),
            SizedBox(height: 8.h),
            _sectionLabel(context, 'پشتیبانی'),
            _MoreTile(
              icon: LucideIcons.messageSquarePlus,
              title: 'بازخورد و پیشنهاد',
              subtitle: 'انتقاد، باگ، ایده — نسخه دمو',
              onTap: () => Navigator.pushNamed(context, LegalRoutes.about),
            ),
            _MoreTile(
              icon: LucideIcons.info,
              title: 'درباره ما',
              subtitle: '۰۹۹۱ ۶۳۹ ۰۷۶۷',
              onTap: () => Navigator.pushNamed(context, LegalRoutes.about),
            ),
            if (kDebugMode) ...[
              SizedBox(height: 8.h),
              _sectionLabel(context, 'ابزارهای دیباگ'),
              _MoreTile(
                icon: LucideIcons.refreshCw,
                title: 'سوییچ اکانت تستی',
                subtitle: 'بدون OTP · athlete / trainer / admin',
                onTap: () => unawaited(showDebugAccountSwitcherSheet(context)),
              ),
            ],
            SizedBox(height: 16.h),
            _PremiumPromoCard(
              onUpgrade: () => Navigator.pushNamed(context, '/subscriptions'),
            ),
            SizedBox(height: 12.h),
            _MoreTile(
              icon: LucideIcons.logOut,
              title: _signingOut ? 'در حال خروج...' : 'خروج از حساب',
              destructive: true,
              onTap: _signingOut ? null : () => unawaited(_signOut()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 6.h, 4.w, 8.h),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 12.sp,
          color: context.textSecondary,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.roleLabel,
    required this.onTap,
    this.avatarUrl,
  });

  final String name;
  final String roleLabel;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: context.separatorColor),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 52.w,
                  height: 52.w,
                  child: avatarUrl != null
                      ? GymaiNetworkImage(
                          imageUrl: avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: context.actionFill.withValues(alpha: 0.15),
                          child: Icon(
                            LucideIcons.user,
                            color: context.inkAccent,
                            size: 24.sp,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp,
                        color: context.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronLeft,
                size: 18.sp,
                color: context.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumPromoCard extends StatelessWidget {
  const _PremiumPromoCard({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(LucideIcons.crown, color: AppTheme.goldColor, size: 22.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'مربی هوشمند قوی‌تر، سقف بالاتر گفتگو',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                    color: context.textColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Coach Pro برای استفاده روزمره · Ultimate AI برای سقف بیشتر و اولویت پشتیبانی. در نسخه دمو خرید ممکن است محدود باشد.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              height: 1.45,
              color: context.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          FilledButton(
            onPressed: onUpgrade,
            style: FilledButton.styleFrom(
              backgroundColor: context.actionFill,
              foregroundColor: context.actionOnFill,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'مشاهده پلن‌ها',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFE05353) : context.textColor;
    final secondary = destructive
        ? const Color(0xFFE05353).withValues(alpha: 0.75)
        : context.textSecondary;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
      leading: Icon(icon, size: 20.sp, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
          color: color,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                color: secondary,
              ),
            ),
      trailing: trailing ??
          Icon(
            LucideIcons.chevronLeft,
            size: 16.sp,
            color: context.textSecondary,
          ),
    );
  }
}
