import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/screens/ai_programs_screen.dart';
import 'package:gymaipro/ai/screens/ai_progress_analysis_screen.dart';
import 'package:gymaipro/ai/screens/chat_screen.dart';
import 'package:gymaipro/ai/widgets/ai_feature_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0.w, 0.3.h), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.safeForward();
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
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                _buildWelcomeSection(context, isDark),
                _buildQuickActions(context, isDark),
                _buildAIFeatures(context, isDark),
                _buildStatsSection(context, isDark),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      pinned: false,
      floating: false,
      backgroundColor: isDark ? context.backgroundColor : Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'جیم‌آی هوشمند',
        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 20.sp,
          color: isDark ? AppTheme.goldColor : context.textColor,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildWelcomeSection(BuildContext context, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.goldGradientColors[0].withValues(alpha: 0.15),
                    context.cardColor,
                    context.goldGradientColors[1].withValues(alpha: 0.1),
                  ],
                ),
          color: isDark ? context.cardColor : null,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.35),
              blurRadius: 16.r,
              offset: Offset(0.w, 6.h),
              spreadRadius: 1.r,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : context.textColor.withValues(alpha: 0.08),
              blurRadius: 8.r,
              offset: Offset(0.w, 2.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        blurRadius: 8.r,
                        offset: Offset(0.w, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Flexible(
                  fit: FlexFit.loose,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'خوش آمدید!',
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'من جیم‌آی هستم، مربی هوشمند شما',
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          fontSize: 16.sp,
                          color: context.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'با استفاده از هوش مصنوعی پیشرفته، برنامه‌های شخصی‌سازی شده برای شما طراحی می‌کنم. از تمرین تا تغذیه، در کنار شما هستم!',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 15.sp,
                color: context.textSecondary,
                height: 1.6.h,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'دسترسی سریع',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    isDark: isDark,
                    icon: LucideIcons.messageCircle,
                    title: 'چت با من',
                    subtitle: 'سوالات خود را بپرسید',
                    color: AppTheme.goldColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const ChatScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    isDark: isDark,
                    icon: LucideIcons.dumbbell,
                    title: 'برنامه تمرینی',
                    subtitle: 'درخواست برنامه جدید',
                    color: AppTheme.goldColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const AIProgramsScreen(),
                        ),
                      );
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.15),
                    context.cardColor,
                    color.withValues(alpha: 0.1),
                  ],
                ),
          color: isDark ? context.cardColor : null,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.5),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.15 : 0.25),
              blurRadius: 12.r,
              offset: Offset(0.w, 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8.r,
                    offset: Offset(0.w, 2.h),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIFeatures(BuildContext context, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'قابلیت‌های هوش مصنوعی',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16.h),
            AIFeatureCard(
              icon: LucideIcons.dumbbell,
              title: 'برنامه‌ریزی تمرینی',
              description:
                  'برنامه‌های تمرینی شخصی‌سازی شده بر اساس اهداف و سطح شما',
              color: AppTheme.goldColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const AIProgramsScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 12.h),
            AIFeatureCard(
              icon: LucideIcons.apple,
              title: 'برنامه‌ریزی غذایی',
              description: 'برنامه‌های غذایی متعادل و متناسب با نیازهای شما',
              color: AppTheme.goldColor,
              onTap: () {
                // TODO: Navigate to meal planning
              },
            ),
            SizedBox(height: 12.h),
            AIFeatureCard(
              icon: LucideIcons.barChart3,
              title: 'تحلیل پیشرفت',
              description: 'تحلیل و بررسی پیشرفت شما با ارائه راهکارهای بهبود',
              color: AppTheme.goldColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const AIProgressAnalysisScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.goldGradientColors[0].withValues(alpha: 0.15),
                    context.cardColor,
                    context.goldGradientColors[1].withValues(alpha: 0.1),
                  ],
                ),
          color: isDark ? context.cardColor : null,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.35),
              blurRadius: 16.r,
              offset: Offset(0.w, 6.h),
              spreadRadius: 1.r,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : context.textColor.withValues(alpha: 0.08),
              blurRadius: 8.r,
              offset: Offset(0.w, 2.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'آمار فعالیت‌های من',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context: context,
                  label: 'برنامه‌های ایجاد شده',
                  value: '24',
                  icon: LucideIcons.dumbbell,
                ),
                _buildStatItem(
                  context: context,
                  label: 'کاربران راضی',
                  value: '156',
                  icon: LucideIcons.users,
                ),
                _buildStatItem(
                  context: context,
                  label: 'سوالات پاسخ داده',
                  value: '1.2K',
                  icon: LucideIcons.messageCircle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
                blurRadius: 6.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.goldColor, size: 24.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
