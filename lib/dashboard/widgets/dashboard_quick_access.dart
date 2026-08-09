import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';
import 'package:gymaipro/profile/widgets/weight_widgets.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_ranking_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// میانبرهایی که روی هیروهای خانه نیستند.
/// ثبت تمرین / وعده / مربی AI اینجا نمی‌آیند — آن‌ها هیرو دارند؛ پیام‌ها تب است.
class DashboardQuickAccess extends StatelessWidget {
  const DashboardQuickAccess({super.key});

  Future<void> _logWeight(BuildContext context) async {
    WeightWidgets.showWeightGuidanceDialog(context, (weightStr) async {
      final weight = WeeklyWeightService.parseWeightInput(weightStr);
      if (weight == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'وزن واردشده معتبر نیست (مثلاً ۷۵.۵)',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
          ),
        );
        return;
      }
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id']?.toString();
      if (userId == null || userId.isEmpty) return;
      final result = await WeeklyWeightService.recordWeeklyWeightDetailed(
        userId,
        weight,
      );
      if (!context.mounted) return;
      if (result.success) {
        DashboardCacheService().invalidateDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'وزن با موفقیت ثبت شد',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'ثبت وزن انجام نشد. دوباره تلاش کنید.',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<ChatUnreadNotifier>().unreadCount;

    final items = <_QuickItem>[
      _QuickItem(
        icon: LucideIcons.scale,
        label: 'ثبت وزن',
        onTap: () => _logWeight(context),
      ),
      _QuickItem(
        icon: LucideIcons.users,
        label: 'مربیان',
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const TrainerRankingScreen(),
            ),
          );
        },
      ),
      _QuickItem(
        icon: LucideIcons.school,
        label: 'آکادمی',
        onTap: () => MainNavigationScreen.openAcademy(),
      ),
      if (unread > 0)
        _QuickItem(
          icon: LucideIcons.messageCircle,
          label: 'پیام‌ها',
          badge: unread > 99 ? '99+' : unread.toString(),
          onTap: () => MainNavigationScreen.navigateToSocial(),
        )
      else
        _QuickItem(
          icon: LucideIcons.wallet,
          label: 'کیف پول',
          onTap: () => openMainMyClub(initialTab: MyClubTabs.wallet),
        ),
    ];

    return Column(
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                'دسترسی سریع',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                  color: context.textColor,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => MainNavigationScreen.navigateToTab(
                NavigationConstants.moreIndex,
              ),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      'همه',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronLeft,
                      size: 14.sp,
                      color: context.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(width: 6.w),
              Expanded(child: _QuickTile(item: items[i])),
            ],
          ],
        ),
      ],
    );
  }
}

class _QuickItem {
  const _QuickItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.item});

  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.separatorColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(item.icon, size: 18.sp, color: context.textColor),
                  if (item.badge != null)
                    Positioned(
                      right: -10.w,
                      top: -6.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53E3E),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          item.badge!,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                item.label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 9.5.sp,
                  color: context.textSecondary,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
