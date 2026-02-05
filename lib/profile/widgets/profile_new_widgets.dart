import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ranking/models/ranking_score_breakdown.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ModernProfileHeader extends StatelessWidget {
  final Map<String, dynamic> profileData;
  final File? avatarFile;
  final VoidCallback onImageTap;
  final VoidCallback onEditTap;
  final VoidCallback onSettingsTap;
  final UserRanking? ranking;

  const ModernProfileHeader({
    super.key,
    required this.profileData,
    this.avatarFile,
    required this.onImageTap,
    required this.onEditTap,
    required this.onSettingsTap,
    this.ranking,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String fullName =
        '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'
            .trim();
    final String username = (profileData['username'] ?? 'کاربر').toString();
    final String? avatarUrl = profileData['avatar_url']?.toString();
    final league = ranking != null
        ? League.getLeagueByScore(ranking!.totalScore)
        : League.bronze; // Default

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
              // Avatar
              GestureDetector(
                onTap: onImageTap,
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(league.color), width: 2.w),
                    boxShadow: [
                      BoxShadow(
                        color: Color(league.color).withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: avatarFile != null
                        ? Image.file(avatarFile!, fit: BoxFit.cover)
                        : (avatarUrl != null && avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildPlaceholder(context),
                                )
                              : _buildPlaceholder(context)),
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
                        color: Color(league.color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Color(league.color).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.trophy,
                            size: 14.sp,
                            color: Color(league.color),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            league.nameFa,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(league.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: context.cardColor,
      child: Icon(LucideIcons.user, size: 40.sp, color: context.textSecondary),
    );
  }
}

class ModernProfileActions extends StatelessWidget {
  final VoidCallback onFriendsTap;
  final VoidCallback onMessagesTap;
  final VoidCallback onRequestsTap;

  const ModernProfileActions({
    super.key,
    required this.onFriendsTap,
    required this.onMessagesTap,
    required this.onRequestsTap,
  });

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
            width: 1,
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
  final RankingScoreBreakdown? breakdown;
  final UserRanking? ranking;
  final VoidCallback onViewLeaderboard;

  const ModernGamificationStats({
    super.key,
    this.breakdown,
    this.ranking,
    required this.onViewLeaderboard,
  });

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (breakdown == null) return const SizedBox.shrink();

    final totalScore = breakdown!.totalScore;
    final league = League.getLeagueByScore(totalScore);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Color(league.color).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Color(league.color).withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 0,
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
                '${breakdown!.currentStreak}',
                'زنجیره فعلی',
                Colors.orange,
                width: 80.w,
              ),
              _buildStatItem(
                context,
                LucideIcons.calendarCheck,
                '${breakdown!.activeDays}',
                'روزهای فعال',
                Colors.purple,
                width: 80.w,
              ),
              _buildStatItem(
                context,
                LucideIcons.dumbbell,
                '${breakdown!.totalWorkouts}',
                'تمرین‌ها',
                Colors.blue,
                width: 80.w,
              ),
              _buildStatItem(
                context,
                LucideIcons.utensilsCrossed,
                '${breakdown!.totalMeals}',
                'وعده‌ها',
                Colors.green,
                width: 80.w,
              ),
              _buildStatItem(
                context,
                LucideIcons.trophy,
                '${breakdown!.longestStreak}',
                'رکورد زنجیره',
                Colors.red,
                width: 80.w,
              ),
              _buildStatItem(
                context,
                LucideIcons.star,
                _formatNumber(totalScore),
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
                    '${((league.getProgressToNextLeague(totalScore)) * 100).toInt()}%',
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
                  value: league.getProgressToNextLeague(totalScore),
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
  final Map<String, dynamic> profileData;

  const ModernPhysicalStats({super.key, required this.profileData});

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
