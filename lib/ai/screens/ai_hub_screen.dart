import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/screens/ai_progress_analysis_screen.dart';
import 'package:gymaipro/ai/widgets/ai_feature_card.dart';
import 'package:gymaipro/ai/widgets/ai_hub_ui.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/features/coach_chat/navigation/coach_chat_navigation.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AIHubScreen extends StatefulWidget {
  const AIHubScreen({super.key});

  @override
  State<AIHubScreen> createState() => _AIHubScreenState();
}

class _AIHubScreenState extends State<AIHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 780),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.04.h), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    unawaited(_animationController.safeForward());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHero(context, isDark)),
                SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                _buildQuickActions(context, isDark),
                SliverToBoxAdapter(child: SizedBox(height: 8.h)),
                SliverToBoxAdapter(
                  child: _buildHighlightsStrip(context, isDark),
                ),
                _buildAIFeatures(context, isDark),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isDark) {
    const name = AppConfig.gymAiDisplayName;
    final card = context.cardColor;
    final cg = context.goldGradientColors;
    final sep = context.separatorColor;

    final borderTint = Color.lerp(sep, AppTheme.goldColor, isDark ? 0.5 : 0.38)!;
    final surfaceGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(AppTheme.veryDarkBackground, card, 0.5)!,
              card,
              Color.lerp(card, AppTheme.goldColor, 0.04)!,
            ],
            stops: const [0.0, 0.58, 1.0],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(card, Colors.white, 0.35)!,
              card,
              Color.lerp(card, cg[0], 0.1)!,
            ],
            stops: const [0.0, 0.52, 1.0],
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          gradient: surfaceGradient,
          border: Border.all(
            color: borderTint.withValues(alpha: isDark ? 0.9 : 0.75),
          ),
          boxShadow: [
            BoxShadow(
              color: context.headerShadowColor,
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.06 : 0.08),
              blurRadius: 26.r,
              spreadRadius: -6,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: Stack(
            children: [
              Positioned(
                top: -36.h,
                right: -28.w,
                child: IgnorePointer(
                  child: Container(
                    width: 150.w,
                    height: 150.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isDark ? AppTheme.goldColor : cg[1]).withValues(
                            alpha: isDark ? 0.07 : 0.11,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -32.h,
                left: -24.w,
                child: IgnorePointer(
                  child: Container(
                    width: 110.w,
                    height: 110.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          cg[0].withValues(alpha: isDark ? 0.05 : 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.52],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                cg[0].withValues(alpha: isDark ? 0.22 : 0.4),
                                cg[1].withValues(alpha: isDark ? 0.1 : 0.18),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppTheme.goldColor.withValues(
                                alpha: isDark ? 0.28 : 0.26,
                              ),
                            ),
                          ),
                          child: Icon(
                            LucideIcons.sparkles,
                            color: isDark
                                ? AppTheme.goldColor
                                : AppTheme.darkGold,
                            size: 25.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: AppTheme.goldColor.withValues(
                                    alpha: isDark ? 0.1 : 0.07,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.goldColor.withValues(
                                      alpha: isDark ? 0.24 : 0.18,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  child: Text(
                                    'هوش مصنوعی · مربی آنلاین',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.textSecondary,
                                      letterSpacing: 0.15,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                name,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                  color: context.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      width: 44.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.goldColor.withValues(alpha: 0.45),
                            AppTheme.goldColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'من $name هستم — از چت و برنامهٔ تمرین تا تحلیل پیشرفت، همراهت هستم.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        height: 1.55,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiHubSectionTitle(title: 'شروع سریع'),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    isDark: isDark,
                    icon: LucideIcons.messageCircle,
                    title: 'چت با مربی',
                    subtitle: 'سؤال بپرس',
                    accent: AppTheme.carbsColor,
                    onTap: () {
                      unawaited(Navigator.pushNamed(context, '/coach-chat'));
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    isDark: isDark,
                    icon: LucideIcons.calendarCheck,
                    title: 'تمرین امروز',
                    subtitle: 'برنامهٔ روز',
                    accent: AppTheme.goldColor,
                    onTap: () {
                      unawaited(Navigator.pushNamed(context, '/workout-today'));
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    isDark: isDark,
                    icon: LucideIcons.play,
                    title: 'شروع جلسه',
                    subtitle: 'تمرین زنده',
                    accent: AppTheme.proteinColor,
                    onTap: () {
                      unawaited(Navigator.pushNamed(context, '/live-workout'));
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    isDark: isDark,
                    icon: LucideIcons.sparkles,
                    title: 'پنل مربی',
                    subtitle: 'خلاصه وضعیت',
                    accent: AppTheme.darkGold,
                    onTap: () {
                      unawaited(Navigator.pushNamed(context, '/coach'));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    final radius = BorderRadius.circular(18.r);
    final borderColor = Color.lerp(context.separatorColor, accent, 0.42)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          width: fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: fullWidth ? 16.w : 12.w,
            vertical: fullWidth ? 14.h : 16.h,
          ),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: radius,
            border: Border.all(
              color: borderColor.withValues(alpha: isDark ? 0.72 : 0.62),
            ),
            boxShadow: [
              BoxShadow(
                color: context.headerShadowColor,
                blurRadius: 10.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: fullWidth
              ? Row(
                  children: [
                    AiHubIconBadge(
                      icon: icon,
                      gradientColors: aiHubAccentGradient(accent),
                      size: 48.w,
                      iconSize: 22.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: context.textColor,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.5.sp,
                              height: 1.35,
                              color: context.textSecondary.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronLeft,
                      color: accent.withValues(alpha: 0.7),
                      size: 20.sp,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AiHubIconBadge(
                      icon: icon,
                      gradientColors: aiHubAccentGradient(accent),
                      size: 46.w,
                      iconSize: 22.sp,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: context.textColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5.sp,
                        height: 1.35,
                        color: context.textSecondary.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHighlightsStrip(BuildContext context, bool isDark) {
    final items = <(IconData, String, String, Color)>[
      (LucideIcons.messageCircle, 'گفتگو', 'چت مربی', AppTheme.carbsColor),
      (LucideIcons.dumbbell, 'تمرین', 'امروز و زنده', AppTheme.goldColor),
      (LucideIcons.lineChart, 'تحلیل', 'پیشرفت', AppTheme.proteinColor),
    ];
    final stripBorder = Color.lerp(
      context.separatorColor,
      AppTheme.goldColor,
      isDark ? 0.4 : 0.32,
    )!;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        color: context.cardColor,
        border: Border.all(
          color: stripBorder.withValues(alpha: isDark ? 0.85 : 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: context.headerShadowColor,
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 36.h,
                color: context.textSecondary.withValues(alpha: 0.15),
              ),
            Expanded(
              child: _HighlightCell(
                icon: items[i].$1,
                title: items[i].$2,
                caption: items[i].$3,
                accent: items[i].$4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIFeatures(BuildContext context, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiHubSectionTitle(title: 'همهٔ ابزارها'),
            AIFeatureCard(
              icon: LucideIcons.sparkles,
              title: 'پنل مربی',
              description: 'خلاصه روزانه، ریکاوری و پیشنهاد تمرین',
              color: AppTheme.goldColor,
              onTap: () {
                unawaited(Navigator.pushNamed(context, '/coach'));
              },
            ),
            SizedBox(height: 10.h),
            AIFeatureCard(
              icon: LucideIcons.messageCircle,
              title: 'چت با مربی',
              description: 'سؤال بپرس، برنامه را اصلاح کن یا تحلیل بگیر',
              color: AppTheme.carbsColor,
              onTap: () {
                unawaited(Navigator.pushNamed(context, '/coach-chat'));
              },
            ),
            SizedBox(height: 10.h),
            AIFeatureCard(
              icon: LucideIcons.calendarCheck,
              title: 'تمرین امروز',
              description: 'برنامهٔ امروز با جزئیات حرکات و ست‌ها',
              color: AppTheme.goldColor,
              onTap: () {
                unawaited(Navigator.pushNamed(context, '/workout-today'));
              },
            ),
            SizedBox(height: 10.h),
            AIFeatureCard(
              icon: LucideIcons.play,
              title: 'تمرین زنده',
              description: 'ثبت ست‌ها، تایمر استراحت و پایان جلسه',
              color: AppTheme.proteinColor,
              onTap: () {
                unawaited(Navigator.pushNamed(context, '/live-workout'));
              },
            ),
            SizedBox(height: 10.h),
            AIFeatureCard(
              icon: LucideIcons.clipboardList,
              title: 'ساخت برنامه',
              description: 'مربی هوش مصنوعی بر اساس هدف و تجهیزاتت برنامه می‌سازد',
              color: AppTheme.darkGold,
              onTap: () {
                unawaited(
                  CoachChatNavigation.open(
                    context,
                    quickActionId: 'build_program',
                  ),
                );
              },
            ),
            SizedBox(height: 10.h),
            AIFeatureCard(
              icon: LucideIcons.barChart3,
              title: 'تحلیل پیشرفت',
              description: 'مرور روند تمرین و پیشنهادهای عملی برای بهبود',
              color: AppTheme.proteinColor,
              onTap: () {
                unawaited(
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const AIProgressAnalysisScreen(),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 10.h),
            AIFeatureCard(
              icon: LucideIcons.apple,
              title: 'برنامه غذایی',
              description: 'رژیم متعادل بر اساس نیازت — به‌زودی',
              color: AppTheme.fatColor,
              isComingSoon: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightCell extends StatelessWidget {
  const _HighlightCell({
    required this.icon,
    required this.title,
    required this.caption,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String caption;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AiHubIconBadge(
            icon: icon,
            gradientColors: aiHubAccentGradient(accent),
            size: 36.w,
            iconSize: 17.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.5.sp,
              height: 1.25,
              color: context.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
