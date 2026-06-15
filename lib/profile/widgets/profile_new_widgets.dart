import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ranking/models/ranking_score_breakdown.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_kpi_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/format_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ModernProfileHeader extends StatelessWidget {

  const ModernProfileHeader({
    required this.profileData, required this.onImageTap, required this.onEditTap, required this.onSettingsTap, super.key,
    this.avatarFile,
    this.ranking,
    this.avatarUploading = false,
    this.avatarSuccess = false,
    this.avatarError,
    this.onRetryAvatar,
  });
  final Map<String, dynamic> profileData;
  final File? avatarFile;
  final VoidCallback onImageTap;
  final VoidCallback onEditTap;
  final VoidCallback onSettingsTap;
  final UserRanking? ranking;
  final bool avatarUploading;
  final bool avatarSuccess;
  final String? avatarError;
  final VoidCallback? onRetryAvatar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String fullName =
        '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'
            .trim();
    final String username = (profileData['username'] ?? 'کاربر').toString();
    final String? avatarUrl = profileData['avatar_url']?.toString();
    final role = (profileData['role'] ?? 'athlete').toString();
    final isAthlete = role == 'athlete';

    // لیگ فقط برای ورزشکاران
    final totalScore = isAthlete ? (ranking?.totalScore ?? 0) : 0;
    final league = isAthlete ? League.getLeagueByScore(totalScore) : null;
    final accentColor = isAthlete ? Color(league!.color) : AppTheme.goldColor;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.goldColor.withValues(alpha: 0.15),
                  context.backgroundColor,
                ]
              : [AppTheme.lightGradientStart, AppTheme.lightCardColor],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onSettingsTap,
                icon: Icon(
                  LucideIcons.settings,
                  color: context.textColor,
                  size: 24.sp,
                ),
              ),
              const Spacer(),
              Text(
                'پروفایل من',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEditTap,
                icon: Icon(
                  LucideIcons.edit3,
                  color: context.textColor,
                  size: 24.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              // Avatar با وضعیت آپلود / موفقیت / خطا
              GestureDetector(
                onTap: avatarUploading ? null : onImageTap,
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2.w),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (avatarFile != null) Image.file(avatarFile!, fit: BoxFit.cover) else avatarUrl != null && avatarUrl.isNotEmpty
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildPlaceholder(context),
                                    )
                                  : _buildPlaceholder(context),
                        if (avatarUploading) _buildAvatarOverlay(context, accentColor, loading: true),
                        if (avatarSuccess && !avatarUploading)
                          _buildAvatarOverlay(context, accentColor, success: true),
                        if (avatarError != null && avatarError!.isNotEmpty && !avatarUploading)
                          _buildAvatarOverlay(
                            context,
                            accentColor,
                            error: avatarError,
                            onRetry: onRetryAvatar,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Name & League
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : username,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fullName.isNotEmpty)
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14.sp,
                          color: context.textSecondary,
                        ),
                      ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAthlete
                                ? LucideIcons.trophy
                                : LucideIcons.badgeCheck,
                            size: 14.sp,
                            color: accentColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            isAthlete ? league!.nameFa : 'مربی',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isAthlete) ...[
                      SizedBox(height: 8.h),
                      _buildTrainerMeta(context, accentColor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerMeta(BuildContext context, Color accentColor) {
    final rating = (profileData['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (profileData['review_count'] as num?)?.toInt() ?? 0;
    final rankingValue = (profileData['ranking'] as num?)?.toInt();

    if (rating <= 0 &&
        reviewCount <= 0 &&
        (rankingValue == null || rankingValue <= 0)) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10.w,
      runSpacing: 6.h,
      children: [
        if (rating > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.star, size: 14.sp, color: Colors.amber),
              SizedBox(width: 4.w),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                ),
              ),
              if (reviewCount > 0) ...[
                SizedBox(width: 4.w),
                Text(
                  '($reviewCount)',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        if (rankingValue != null && rankingValue > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.trophy, size: 14.sp, color: accentColor),
              SizedBox(width: 4.w),
              Text(
                '#$rankingValue',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return ColoredBox(
      color: context.cardColor,
      child: Icon(LucideIcons.user, size: 40.sp, color: context.textSecondary),
    );
  }

  Widget _buildAvatarOverlay(
    BuildContext context,
    Color accentColor, {
    bool loading = false,
    bool success = false,
    String? error,
    VoidCallback? onRetry,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.black.withValues(alpha: 0.65)
        : Colors.black.withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : (error != null ? onRetry : null),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) ...[
                  SizedBox(
                    width: 28.w,
                    height: 28.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        accentColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'در حال آپلود...',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (success && !loading) ...[
                  Icon(
                    LucideIcons.checkCircle,
                    size: 36.sp,
                    color: Colors.greenAccent,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'ذخیره شد',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (error != null && error.isNotEmpty && !loading) ...[
                  Icon(
                    LucideIcons.alertCircle,
                    size: 28.sp,
                    color: Colors.orangeAccent,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'خطا',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onRetry != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'برای تلاش مجدد لمس کنید',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 9.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModernProfileActions extends StatelessWidget {

  const ModernProfileActions({
    required this.onFriendsTap, required this.onMessagesTap, required this.onRequestsTap, super.key,
  });
  final VoidCallback onFriendsTap;
  final VoidCallback onMessagesTap;
  final VoidCallback onRequestsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionItem(context, LucideIcons.users, 'دوستان', onFriendsTap),
          _buildActionItem(
            context,
            LucideIcons.messageCircle,
            'پیام‌ها',
            onMessagesTap,
          ),
          _buildActionItem(
            context,
            LucideIcons.userPlus,
            'درخواست‌ها',
            onRequestsTap,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100.w,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? context.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.goldColor, size: 24.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernGamificationStats extends StatelessWidget {

  const ModernGamificationStats({
    required this.onViewLeaderboard, super.key,
    this.breakdown,
    this.ranking,
  });
  final RankingScoreBreakdown? breakdown;
  final UserRanking? ranking;
  final VoidCallback onViewLeaderboard;

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    // اگر داده هنوز نیامده باشد، کارت را با حالت لودینگ ظریف نشان می‌دهیم
    final bool isLoading = breakdown == null;

    // در حالت لودینگ، یک مدل خالی با مقادیر صفر می‌سازیم تا ساختار کارت ثابت بماند
    final RankingScoreBreakdown effectiveBreakdown = breakdown ??
        RankingScoreBreakdown(
          totalScore: ranking?.totalScore ?? 0,
          dailyActivitiesScore: 0,
          currentStreak: 0,
          currentStreakScore: 0,
          longestStreak: 0,
          longestStreakScore: 0,
          activeDays: 0,
          activeDaysScore: 0,
          totalWorkouts: 0,
          totalWorkoutsScore: 0,
          totalMeals: 0,
          totalMealsScore: 0,
        );

    final totalScore = ranking?.totalScore ?? effectiveBreakdown.totalScore;
    final league = League.getLeagueByScore(totalScore);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Color(league.color).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Color(league.color).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عملکرد من',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              InkWell(
                onTap: onViewLeaderboard,
                child: Row(
                  children: [
                    Text(
                      'رتبه‌بندی',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: AppTheme.goldColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16.sp,
                      color: AppTheme.goldColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 20.h,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context,
                LucideIcons.flame,
                isLoading ? '—' : '${effectiveBreakdown.currentStreak}',
                'زنجیره فعلی',
                Colors.orange,
                width: 80.w,
              ),
              _buildStatItem(
                context,
                LucideIcons.calendarCheck,
                isLoading ? '—' : '${effectiveBreakdown.activeDays}',
                'روزهای فعال',
                Colors.purple,
                width: 80.w,
              ),
              _buildStatItem(
                context,
                LucideIcons.dumbbell,
                isLoading ? '—' : '${effectiveBreakdown.totalWorkouts}',
                'تمرین‌ها',
                Colors.blue,
                width: 80.w,
              ),
              _buildStatItem(
                context,
                LucideIcons.utensilsCrossed,
                isLoading ? '—' : '${effectiveBreakdown.totalMeals}',
                'وعده‌ها',
                Colors.green,
                width: 80.w,
              ),
              _buildStatItem(
                context,
                LucideIcons.trophy,
                isLoading ? '—' : '${effectiveBreakdown.longestStreak}',
                'رکورد زنجیره',
                Colors.red,
                width: 80.w,
              ),
              _buildStatItem(
                context,
                LucideIcons.star,
                isLoading ? '—' : _formatNumber(totalScore),
                'امتیاز کل',
                Colors.amber,
                width: 80.w,
              ),
            ],
          ),
          SizedBox(height: 24.h),
          // Progress Bar for League
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'پیشرفت لیگ',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: context.textSecondary,
                    ),
                  ),
                  Text(
                    isLoading
                        ? '...'
                        : '${((league.getProgressToNextLeague(totalScore)) * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: Color(league.color),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value:
                      isLoading ? null : league.getProgressToNextLeague(totalScore),
                  backgroundColor: Theme.of(
                    context,
                  ).dividerColor.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(Color(league.color)),
                  minHeight: 6.h,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color, {
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.sp, // Slightly smaller font for labels
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ModernPhysicalStats extends StatelessWidget {

  const ModernPhysicalStats({required this.profileData, super.key});
  final Map<String, dynamic> profileData;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'وضعیت جسمانی',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  context,
                  'قد',
                  '${profileData['height'] ?? '--'}',
                  'cm',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoCard(
                  context,
                  'وزن',
                  '${profileData['weight'] ?? '--'}',
                  'kg',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoCard(context, 'BMI', _calculateBMI(), ''),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateBMI() {
    final height = double.tryParse(profileData['height']?.toString() ?? '');
    final weight = double.tryParse(profileData['weight']?.toString() ?? '');
    if (height != null && weight != null && height > 0) {
      final bmi = weight / ((height / 100) * (height / 100));
      return bmi.toStringAsFixed(1);
    }
    return '--';
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    String unit,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              color: context.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10.sp,
                      color: context.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// داشبورد KPI برای نقش مربی (شبیه ModernGamificationStats ولی برای مربی)
class ModernTrainerKpiDashboard extends StatelessWidget {
  const ModernTrainerKpiDashboard({
    required this.profileData,
    required this.kpis,
    this.onOpenTrainerRanking,
    this.onOpenTrainerDashboard,
    this.isSelfView = true,
    super.key,
  });

  final Map<String, dynamic> profileData;
  final TrainerKpis? kpis;
  final VoidCallback? onOpenTrainerRanking;
  final VoidCallback? onOpenTrainerDashboard;

  /// اگر true باشد یعنی این داشبورد در «پروفایل خودم» نمایش داده می‌شود.
  /// اگر false باشد یعنی در صفحه پروفایل عمومی یک مربی نمایش داده می‌شود.
  final bool isSelfView;

  @override
  Widget build(BuildContext context) {
    final role = (profileData['role'] ?? 'athlete').toString();
    if (role != 'trainer') return const SizedBox.shrink();

    final experienceYears =
        (profileData['experience_years'] as num?)?.toInt() ?? 0;
    final certificates =
        (profileData['certificates'] as List<dynamic>?)?.cast<String>() ??
        <String>[];

    // عنوان را بسته به اینکه پروفایل خود کاربر است یا پروفایل یک مربی دیگر تنظیم می‌کنیم
    final firstName = (profileData['first_name'] ?? '').toString();
    final lastName = (profileData['last_name'] ?? '').toString();
    final fullName = '$firstName $lastName'.trim();
    final hasName = fullName.isNotEmpty;
    final titleText = isSelfView
        ? 'عملکرد من'
        : (hasName ? 'عملکرد $fullName' : 'عملکرد مربی');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان بخش
        Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.trophy,
                    size: 20.sp,
                    color: AppTheme.goldColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    titleText,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
              if (onOpenTrainerRanking != null)
                InkWell(
                  onTap: onOpenTrainerRanking,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'رنکینگ مربیان',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            color: AppTheme.goldColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16.sp,
                          color: AppTheme.goldColor,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // کارت امتیاز کلی حذف شد - رتبه حالا در هدر نمایش داده می‌شود

        // آمارهای عملکرد (شبیه ورزشکار با Wrap)
        Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: context.separatorColor),
            ),
            child: Wrap(
              spacing: 12.w,
              runSpacing: 20.h,
              alignment: WrapAlignment.spaceBetween,
              children: [
                // کل شاگردان
                _buildStatItem(
                  context,
                  LucideIcons.users,
                  kpis == null
                      ? '—'
                      : FormatUtils.formatNumber(kpis!.totalStudents),
                  'کل شاگردان',
                  const Color(0xFF4CAF50),
                  width: 80.w,
                ),
                // شاگردان فعال
                _buildStatItem(
                  context,
                  LucideIcons.userCheck,
                  kpis == null
                      ? '—'
                      : FormatUtils.formatNumber(kpis!.activeStudents),
                  'شاگرد فعال',
                  const Color(0xFF4CAF50),
                  width: 80.w,
                ),
                // کل برنامه‌های ارائه شده
                _buildStatItem(
                  context,
                  LucideIcons.clipboardList,
                  kpis == null
                      ? '—'
                      : FormatUtils.formatNumber(kpis!.totalWorkoutPrograms),
                  'کل برنامه‌ها',
                  const Color(0xFF2196F3),
                  width: 80.w,
                ),
                // برنامه‌های فعال
                _buildStatItem(
                  context,
                  LucideIcons.dumbbell,
                  kpis == null
                      ? '—'
                      : FormatUtils.formatNumber(kpis!.activeWorkoutPrograms),
                  'برنامه فعال',
                  const Color(0xFF2196F3),
                  width: 80.w,
                ),
                _buildStatItem(
                  context,
                  LucideIcons.music,
                  kpis == null
                      ? '—'
                      : FormatUtils.formatNumber(kpis!.totalCustomMusics),
                  'موزیک‌ها',
                  const Color(0xFF9C27B0),
                  width: 80.w,
                ),
                _buildStatItem(
                  context,
                  LucideIcons.thumbsUp,
                  kpis == null ? '—' : '${kpis!.satisfactionPercent}%',
                  'رضایت',
                  const Color(0xFFFF9800),
                  width: 80.w,
                ),
                if (experienceYears > 0)
                  _buildStatItem(
                    context,
                    LucideIcons.calendar,
                    '$experienceYears',
                    'سال تجربه',
                    const Color(0xFF00BCD4),
                    width: 80.w,
                  ),
                if (certificates.isNotEmpty)
                  _buildStatItem(
                    context,
                    LucideIcons.award,
                    '${certificates.length}',
                    'گواهینامه',
                    const Color(0xFFFF9800),
                    width: 80.w,
                  ),
              ],
            ),
          ),
        ),

        // دکمه میز کار (فقط برای خود مربی)
        if (onOpenTrainerDashboard != null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenTrainerDashboard,
              icon: Icon(LucideIcons.layoutDashboard, size: 18.sp),
              label: Text(
                'رفتن به میز کار مربی',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.goldColor,
                side: BorderSide(
                  color: AppTheme.goldColor.withValues(alpha: 0.7),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color, {
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.sp,
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
