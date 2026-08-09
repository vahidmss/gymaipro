import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/features/product_experience/navigation/workout_program_request_navigation.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/profile/widgets/weight_widgets.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// شیت اکشن مرکزی (+) — نقش‌محور، فقط ساخت/ثبت.
Future<void> showPlusActionSheet(
  BuildContext context, {
  String? userRole,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _PlusActionSheet(userRole: userRole),
  );
}

class _PlusActionSheet extends StatelessWidget {
  const _PlusActionSheet({this.userRole});

  final String? userRole;

  bool get _isTrainer => userRole == 'trainer' || userRole == 'admin';

  Future<void> _closeThen(
    BuildContext sheetContext,
    FutureOr<void> Function(BuildContext navContext) action,
  ) async {
    final navContext = Navigator.of(sheetContext, rootNavigator: true).context;
    Navigator.of(sheetContext).pop();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!navContext.mounted) return;
    await action(navContext);
  }

  Future<void> _logWeight(BuildContext navContext) async {
    WeightWidgets.showWeightGuidanceDialog(navContext, (weightStr) async {
      final weight = WeeklyWeightService.parseWeightInput(weightStr);
      if (weight == null) {
        if (!navContext.mounted) return;
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
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
      if (!navContext.mounted) return;
      if (result.success) {
        DashboardCacheService().invalidateDashboard();
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text(
              'وزن با موفقیت ثبت شد',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'ثبت وزن انجام نشد. دوباره تلاش کنید.',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final actions = _isTrainer
        ? <_PlusAction>[
            _PlusAction(
              icon: LucideIcons.dumbbell,
              title: 'ساخت برنامه',
              onTap: () => unawaited(
                _closeThen(context, (nav) {
                  Navigator.pushNamed(
                    nav,
                    NavigationConstants.workoutProgramBuilderRoute,
                  );
                }),
              ),
            ),
            _PlusAction(
              icon: LucideIcons.utensils,
              title: 'ساخت برنامه غذایی',
              onTap: () => unawaited(
                _closeThen(context, (nav) {
                  Navigator.pushNamed(
                    nav,
                    NavigationConstants.mealPlanBuilderRoute,
                  );
                }),
              ),
            ),
            _PlusAction(
              icon: LucideIcons.userPlus,
              title: 'مدیریت شاگردان',
              onTap: () => unawaited(
                _closeThen(context, (_) {
                  openMainTrainerDashboard(initialTab: 0);
                }),
              ),
            ),
          ]
        : <_PlusAction>[
            _PlusAction(
              icon: LucideIcons.clipboardCheck,
              title: 'ثبت تمرین',
              onTap: () => unawaited(
                _closeThen(context, (nav) {
                  Navigator.pushNamed(nav, NavigationConstants.workoutLogRoute);
                }),
              ),
            ),
            _PlusAction(
              icon: LucideIcons.utensils,
              title: 'ثبت وعده',
              onTap: () => unawaited(
                _closeThen(context, (nav) {
                  Navigator.pushNamed(nav, NavigationConstants.mealLogRoute);
                }),
              ),
            ),
            _PlusAction(
              icon: LucideIcons.clipboardList,
              title: 'درخواست برنامه',
              onTap: () => unawaited(
                _closeThen(context, (nav) {
                  unawaited(WorkoutProgramRequestNavigation.open(nav));
                }),
              ),
            ),
            _PlusAction(
              icon: LucideIcons.scale,
              title: 'ثبت وزن',
              onTap: () => unawaited(
                _closeThen(context, _logWeight),
              ),
            ),
          ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: context.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: context.separatorColor,
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                ),
                SizedBox(height: 14.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'افزودن سریع',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp,
                      color: context.textColor,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                for (final action in actions)
                  ListTile(
                    onTap: action.onTap,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
                    leading: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: context.actionFill.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        action.icon,
                        size: 20.sp,
                        color: context.inkAccent,
                      ),
                    ),
                    title: Text(
                      action.title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: context.textColor,
                      ),
                    ),
                    trailing: Icon(
                      LucideIcons.chevronLeft,
                      size: 16.sp,
                      color: context.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlusAction {
  const _PlusAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}
