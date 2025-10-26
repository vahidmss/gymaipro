import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/ai/screens/ai_programs_screen.dart';
import 'package:gymaipro/ai/screens/chat_screen.dart';
import 'package:gymaipro/ai/widgets/ai_feature_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                _buildWelcomeSection(),
                _buildQuickActions(),
                _buildAIFeatures(),
                _buildStatsSection(),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppTheme.goldColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'جیم‌آی هوشمند',
          style: GoogleFonts.vazirmatn(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.goldColor, AppTheme.darkGold],
            ),
          ),
          child: Center(
            child: Icon(LucideIcons.bot, size: 40.sp, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.goldColor.withValues(alpha: 0.1),
              AppTheme.darkGold.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'خوش آمدید!',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'من جیم‌آی هستم، مربی هوشمند شما',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 16.sp,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'با استفاده از هوش مصنوعی پیشرفته، برنامه‌های شخصی‌سازی شده برای شما طراحی می‌کنم. از تمرین تا تغذیه، در کنار شما هستم!',
              style: GoogleFonts.vazirmatn(
                fontSize: 16.sp,
                color: Colors.black.withValues(alpha: 0.9),
                height: 1.5.h,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'دسترسی سریع',
              style: GoogleFonts.vazirmatn(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
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
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: LucideIcons.dumbbell,
                    title: 'برنامه تمرینی',
                    subtitle: 'درخواست برنامه جدید',
                    color: AppTheme.accentColor,
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.vazirmatn(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.vazirmatn(
                fontSize: 14.sp,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIFeatures() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'قابلیت‌های هوش مصنوعی',
              style: GoogleFonts.vazirmatn(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            AIFeatureCard(
              icon: LucideIcons.apple,
              title: 'برنامه‌ریزی غذایی',
              description: 'برنامه‌های غذایی متعادل و متناسب با نیازهای شما',
              color: AppTheme.accentColor,
              onTap: () {
                // TODO: Navigate to meal planning
              },
            ),
            const SizedBox(height: 12),
            AIFeatureCard(
              icon: LucideIcons.barChart3,
              title: 'تحلیل پیشرفت',
              description: 'تحلیل و بررسی پیشرفت شما با ارائه راهکارهای بهبود',
              color: Colors.orange,
              onTap: () {
                // TODO: Navigate to progress analysis
              },
            ),
            const SizedBox(height: 12),
            AIFeatureCard(
              icon: LucideIcons.heart,
              title: 'مشاوره سلامتی',
              description: 'مشاوره‌های تخصصی در زمینه سلامت و تناسب اندام',
              color: Colors.red,
              onTap: () {
                // TODO: Navigate to health consultation
              },
            ),
            const SizedBox(height: 12),
            AIFeatureCard(
              icon: LucideIcons.target,
              title: 'تعیین اهداف',
              description: 'کمک در تعیین و دستیابی به اهداف فیتنس شما',
              color: Colors.green,
              onTap: () {
                // TODO: Navigate to goal setting
              },
            ),
            const SizedBox(height: 12),
            AIFeatureCard(
              icon: LucideIcons.bookOpen,
              title: 'آموزش و راهنمایی',
              description: 'آموزش تکنیک‌های صحیح تمرین و تغذیه',
              color: Colors.purple,
              onTap: () {
                // TODO: Navigate to education
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.goldColor.withValues(alpha: 0.1),
              AppTheme.darkGold.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'آمار فعالیت‌های من',
              style: GoogleFonts.vazirmatn(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'برنامه‌های ایجاد شده',
                  '24',
                  LucideIcons.dumbbell,
                ),
                _buildStatItem('کاربران راضی', '156', LucideIcons.users),
                _buildStatItem(
                  'سوالات پاسخ داده',
                  '1.2K',
                  LucideIcons.messageCircle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppTheme.goldColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.vazirmatn(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.vazirmatn(
            fontSize: 14.sp,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
