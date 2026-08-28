import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/features/coach/presentation/screens/coach_home_screen.dart';
import 'package:gymaipro/meal_log/screens/meal_log_screen.dart';
import 'package:gymaipro/meal_log/services/meal_log_service.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/utils/meal_nutrition_targets.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// هیرو ثانویه: کالری‌شماری با داده واقعی امروز.
class DashboardCalorieHero extends StatefulWidget {
  const DashboardCalorieHero({super.key});

  @override
  State<DashboardCalorieHero> createState() => _DashboardCalorieHeroState();
}

class _DashboardCalorieHeroState extends State<DashboardCalorieHero> {
  bool _busy = false;
  bool _loadingStats = true;
  String _subtitle = 'اولین وعده امروز رو ثبت کن';

  @override
  void initState() {
    super.initState();
    unawaited(_loadCalorieSummary());
  }

  Future<void> _loadCalorieSummary() async {
    try {
      final cache = DashboardCacheService();
      final profile = Map<String, dynamic>.from(
        cache.getProfileData() ?? const <String, dynamic>{},
      );
      final latestWeight = cache.getLatestWeight();
      if (latestWeight != null) {
        profile['latest_weight'] = latestWeight;
      }

      final targets = MealNutritionTargets.fromProfile(
        profile.isEmpty ? null : profile,
      );
      final target = targets.calorieTarget.round();

      final log = await MealLogService().getLogForDate(DateTime.now());
      if (!mounted) return;

      if (log == null || log.meals.every((m) => m.foods.isEmpty)) {
        setState(() {
          _subtitle = 'اولین وعده امروز رو ثبت کن';
          _loadingStats = false;
        });
        return;
      }

      var foods = cache.getFoods();
      foods ??= await FoodService().getFoodsFromCache();
      foods ??= await FoodService().getFoods();

      final totals = MealLogUtils.calculateTotals(log.meals, foods);
      final consumed = (totals['calories'] ?? 0).round();
      final remaining = target - consumed;

      if (!mounted) return;
      setState(() {
        final hasGoal = targets.hasActiveGoal;
        if (remaining > 40) {
          _subtitle = hasGoal
              ? '$remaining کالری از سقف جا داری'
              : '$remaining کالری تا نیاز روزانه جا داری';
        } else if (remaining > 0) {
          _subtitle = hasGoal
              ? 'نزدیک سقف · $remaining کالری جا داری'
              : 'نزدیک نیاز روزانه · $remaining کالری جا داری';
        } else if (remaining == 0) {
          _subtitle = hasGoal
              ? 'بودجه امروز تموم شد'
              : 'امروز با نیاز روزانه برابر شد';
        } else if (remaining > -150) {
          _subtitle = hasGoal
              ? 'یه کم از سقف رد شدی'
              : 'یه کم از نیاز روزانه رد شدی';
        } else {
          _subtitle = hasGoal
              ? '${-remaining} کالری بیش از سقف'
              : '${-remaining} کالری بیش از نیاز روزانه';
        }
        if (consumed > 0 && remaining > 40 && consumed < target * 0.25) {
          _subtitle = hasGoal
              ? 'شروع خوبی بود · $remaining کالری از سقف جا داری'
              : 'شروع خوبی بود · $remaining کالری تا نیاز روزانه جا داری';
        }
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _subtitle = 'وعده‌هات رو اینجا ثبت کن';
        _loadingStats = false;
      });
    }
  }

  Future<void> _open() async {
    if (_busy) return;
    WidgetSafetyUtils.safeSetState(this, () => _busy = true);
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const FoodLogScreen()),
    );
    if (!mounted) return;
    WidgetSafetyUtils.safeSetState(this, () => _busy = false);
    unawaited(_loadCalorieSummary());
  }

  @override
  Widget build(BuildContext context) {
    return _DashboardMediaHero(
      busy: _busy,
      height: 104.h,
      imagePath: 'images/calorymeter.jpg',
      imageAlignment: const Alignment(-0.55, 0),
      fallbackIcon: LucideIcons.utensils,
      title: 'تغذیه امروز',
      subtitle: _loadingStats ? '...' : _subtitle,
      actionIcon: LucideIcons.plus,
      titleSize: 15.5.sp,
      subtitleSize: 11.5.sp,
      actionSize: 36.w,
      onTap: _open,
    );
  }
}

/// بنر عریض مربی AI — ورود مستقیم به صفحه مربی (تب پایین نیست).
class DashboardAiBanner extends StatelessWidget {
  const DashboardAiBanner({super.key});

  void _openAiCoach(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const CoachHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DashboardMediaHero(
      busy: false,
      height: 92.h,
      imagePath: 'images/gymaicoach.jpg',
      imageAlignment: const Alignment(0, -0.6),
      fallbackIcon: LucideIcons.bot,
      title: 'مربی هوش مصنوعی',
      subtitle: 'برنامه، تغذیه و سوالات تمرینی',
      actionIcon: LucideIcons.sparkles,
      goldAction: true,
      titleSize: 14.5.sp,
      subtitleSize: 11.sp,
      actionSize: 34.w,
      onTap: () => _openAiCoach(context),
    );
  }
}

class _DashboardMediaHero extends StatelessWidget {
  const _DashboardMediaHero({
    required this.busy,
    required this.height,
    required this.imagePath,
    required this.imageAlignment,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.actionIcon,
    required this.onTap,
    this.goldAction = false,
    this.titleSize,
    this.subtitleSize,
    this.actionSize,
  });

  final bool busy;
  final double height;
  final String imagePath;
  final Alignment imageAlignment;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  final IconData actionIcon;
  final VoidCallback onTap;
  final bool goldAction;
  final double? titleSize;
  final double? subtitleSize;
  final double? actionSize;

  @override
  Widget build(BuildContext context) {
    final resolvedTitleSize = titleSize ?? 17.sp;
    final resolvedSubtitleSize = subtitleSize ?? 12.sp;
    final resolvedActionSize = actionSize ?? 38.w;

    return AbsorbPointer(
      absorbing: busy,
      child: Opacity(
        opacity: busy ? 0.7 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Ink(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: context.separatorColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      alignment: imageAlignment,
                      errorBuilder: (context, error, stackTrace) {
                        return ColoredBox(
                          color: context.surfaceElevated,
                          child: Icon(
                            fallbackIcon,
                            size: 32.sp,
                            color: context.textSecondary,
                          ),
                        );
                      },
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors:
                              Theme.of(context).brightness == Brightness.dark
                              ? const [
                                  Color(0xF0000000),
                                  Color(0x99000000),
                                  Color(0x22000000),
                                ]
                              : const [
                                  Color(0x99000000),
                                  Color(0x33000000),
                                  Color(0x00000000),
                                ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12.w,
                      right: 14.w,
                      bottom: 12.h,
                      top: 12.h,
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w800,
                                    fontSize: resolvedTitleSize,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w500,
                                    fontSize: resolvedSubtitleSize,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    height: 1.25,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Container(
                            width: resolvedActionSize,
                            height: resolvedActionSize,
                            decoration: BoxDecoration(
                              color: goldAction
                                  ? context.actionFill
                                  : Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: goldAction
                                  ? null
                                  : Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                            ),
                            child: Icon(
                              actionIcon,
                              color: goldAction
                                  ? context.actionOnFill
                                  : Colors.white,
                              size: (resolvedActionSize * 0.48).clamp(14, 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
