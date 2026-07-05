import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/friendship_models.dart';
import 'package:gymaipro/my_club/services/friendship_service.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/ranking/models/ranking_score_breakdown.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/services/ranking_score_service.dart';
import 'package:gymaipro/ranking/services/ranking_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:gymaipro/user_profile/widgets/progress_metrics_widget.dart';
import 'package:gymaipro/user_profile/widgets/streak_calendar_widget.dart';
import 'package:gymaipro/utils/format_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// اسکرین پروفایل ورزشکار (عمومی)
class AthleteProfileScreen extends StatefulWidget {
  const AthleteProfileScreen({
    required this.userId,
    this.trainerOnlySection,
    super.key,
  });

  final String userId;
  /// بخش اختیاری فقط برای مربی (بالای پروفایل، در همان اسکرول)
  final Widget? trainerOnlySection;

  @override
  State<AthleteProfileScreen> createState() => _AthleteProfileScreenState();
}

class _AthleteProfileScreenState extends State<AthleteProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, int> _userStats = {};
  bool _loading = true;
  UserRanking? _userRanking;
  RankingScoreBreakdown? _scoreBreakdown;
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  bool _actionLoading = false;
  List<DateTime> _streakDates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _profile = await UserProfileService.fetchProfile(widget.userId);
      final profileId = (_profile?['id'] ?? '').toString();
      final targetId = profileId.isNotEmpty ? profileId : widget.userId;

      if (targetId.isNotEmpty) {
        // Load Stats
        _userStats = await UserProfileService.getUserStats(targetId);

        // Load Ranking
        try {
          final rankingService = RankingService();
          final scoreService = RankingScoreService();

          final ranking = await rankingService.getUserRanking(targetId);
          final breakdown = await scoreService.getScoreBreakdown(targetId);
          _userRanking = ranking;
          _scoreBreakdown = breakdown;

          if (breakdown != null) {
            debugPrint(
              '=== STREAK DEBUG: profile=$targetId current_streak=${breakdown.currentStreak} '
              'longest_streak=${breakdown.longestStreak} last_login=${_profile?['last_login_date']} ===',
            );
          }

          // Calculate streak dates
          final currentStreak = breakdown?.currentStreak ?? 0;
          if (currentStreak > 0) {
            final lastLoginDateStr = _profile?['last_login_date'] as String?;
            DateTime? lastLoginDate;
            if (lastLoginDateStr != null && lastLoginDateStr.isNotEmpty) {
              try {
                final parsed = DateTime.parse(lastLoginDateStr);
                lastLoginDate = DateTime(parsed.year, parsed.month, parsed.day);
              } catch (_) {}
            }
            if (lastLoginDate == null) {
              final now = DateTime.now();
              lastLoginDate = DateTime(now.year, now.month, now.day);
            }
            _streakDates = _calculateStreakDates(lastLoginDate, currentStreak);
          } else {
            _streakDates = [];
          }
        } catch (_) {}

        // Check Friendship Status
        final viewerProfile = await SimpleProfileService.getCurrentProfile();
        final viewerProfileId = (viewerProfile?['id'] ?? '').toString();

        if (viewerProfileId.isNotEmpty) {
          final targetAuthId =
              _profile?['auth_user_id']?.toString() ??
              _profile?['id']?.toString() ??
              widget.userId;

          if (targetAuthId.isNotEmpty) {
            try {
              _friendshipStatus = await FriendshipService.getFriendshipStatus(
                targetAuthId,
              );
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleFriendAction() async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);

    try {
      final targetAuthId =
          _profile?['auth_user_id']?.toString() ??
          _profile?['id']?.toString() ??
          widget.userId;

      switch (_friendshipStatus) {
        case FriendshipStatus.none:
        case FriendshipStatus.requestRejected:
          await FriendshipService.sendFriendRequest(targetAuthId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('درخواست دوستی ارسال شد')),
            );
            setState(() => _friendshipStatus = FriendshipStatus.requestSent);
          }
        case FriendshipStatus.requestReceived:
          final requests = await FriendshipService.getReceivedRequests();
          final request = requests.firstWhere(
            (r) => r.requesterId == targetAuthId,
          );
          await FriendshipService.acceptFriendRequest(request.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('درخواست دوستی پذیرفته شد')),
            );
            setState(() => _friendshipStatus = FriendshipStatus.friends);
          }
        case FriendshipStatus.friends:
          break;
        default:
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: ${e.toString().replaceAll('Exception:', '')}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    if (_profile == null) {
      return const Center(
        child: Text(
          'پروفایل یافت نشد',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.trainerOnlySection != null) ...[
            widget.trainerOnlySection!,
            SizedBox(height: 12.h),
          ],
          _buildModernHeader(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SizedBox(height: 70.h),
                _buildQuickActions(),
                SizedBox(height: 20.h),
                _buildSocialStats(),
                SizedBox(height: 20.h),
                _buildGamificationStats(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = (_profile?['first_name'] ?? '').toString();
    final lastName = (_profile?['last_name'] ?? '').toString();
    final username = (_profile?['username'] ?? '').toString();
    final bio = (_profile?['bio'] ?? '').toString();
    String avatarUrl = (_profile?['avatar_url'] ?? '').toString();
    if (avatarUrl.toLowerCase() == 'null') avatarUrl = '';

    final displayName = [firstName, lastName].join(' ').trim().isNotEmpty
        ? [firstName, lastName].join(' ')
        : (username.isNotEmpty ? username : 'کاربر');

    // League info
    final totalScore =
        _userRanking?.totalScore ?? _scoreBreakdown?.totalScore ?? 0;
    final league = League.getLeagueByScore(totalScore);
    final progressToNext = league.getProgressToNextLeague(totalScore);
    final nextLeague = league.nextLeague;
    final leagueAccentColor = Color(league.color);
    final leagueLabel = league.nameFa;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 240.h,
          width: double.infinity,
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
              bottomLeft: Radius.circular(32.r),
              bottomRight: Radius.circular(32.r),
            ),
          ),
        ),
        Positioned(
          bottom: -60.h,
          left: 16.w,
          right: 16.w,
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (avatarUrl.isNotEmpty) _showAvatar(avatarUrl);
                      },
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: leagueAccentColor,
                            width: 3.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: leagueAccentColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: ClipOval(
                            child: avatarUrl.isNotEmpty
                                ? GymaiNetworkImage(imageUrl: avatarUrl)
                                : Container(
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    child: Icon(
                                      LucideIcons.user,
                                      size: 32.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_profile?['is_verified'] == true)
                                Icon(
                                  LucideIcons.badgeCheck,
                                  color: Colors.blue,
                                  size: 18.sp,
                                ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: context.separatorColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(999.r),
                                  border: Border.all(
                                    color: context.separatorColor.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.trophy,
                                      size: 12.sp,
                                      color: leagueAccentColor,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      leagueLabel,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: context.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Flexible(
                                child: Text(
                                  username.isNotEmpty
                                      ? '@$username'
                                      : 'بدون نام کاربری',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 12.sp,
                                    color: context.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (bio.isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Text(
                              bio,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.sp,
                                color: context.textSecondary,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkGreySeparator.withValues(alpha: 0.4)
                        : AppTheme.lightCardColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.trendingUp,
                                  size: 14.sp,
                                  color: AppTheme.goldColor,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'پیشرفت به لیگ بعدی',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.textColor,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    nextLeague?.nameFa ?? 'در بالاترین لیگ',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11.sp,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  size: 11.sp,
                                  color: AppTheme.onGoldColor,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${(((nextLeague == null) ? 1.0 : progressToNext) * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onGoldColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999.r),
                        child: LinearProgressIndicator(
                          value: (nextLeague == null)
                              ? 1.0
                              : progressToNext.clamp(0.0, 1.0),
                          minHeight: 8.h,
                          backgroundColor: context.separatorColor.withValues(
                            alpha: 0.25,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.goldColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'امتیاز فعلی: ${FormatUtils.formatNumber(totalScore)}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10.sp,
                              color: context.textSecondary,
                            ),
                          ),
                          Text(
                            nextLeague == null
                                ? 'در بالاترین لیگ'
                                : 'امتیاز مورد نیاز: ${FormatUtils.formatNumber(nextLeague.minScore)}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10.sp,
                              color: AppTheme.goldColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final currentAuthId = Supabase.instance.client.auth.currentUser?.id;
    final profileAuthId = (_profile?['auth_user_id'] ?? '').toString();
    final profileId = (_profile?['id'] ?? '').toString();
    final isSelf =
        currentAuthId != null &&
        (currentAuthId == profileAuthId || currentAuthId == profileId);

    if (isSelf) return const SizedBox.shrink();

    final firstName = (_profile?['first_name'] ?? '').toString();
    final lastName = (_profile?['last_name'] ?? '').toString();
    final username = (_profile?['username'] ?? '').toString();
    final displayName = [firstName, lastName].join(' ').trim().isNotEmpty
        ? [firstName, lastName].join(' ')
        : (username.isNotEmpty ? username : 'کاربر');

    final isPrimaryAction =
        _friendshipStatus == FriendshipStatus.none ||
        _friendshipStatus == FriendshipStatus.requestReceived;

    return Row(
      children: [
        // دکمه اصلی (درخواست دوستی)
        Expanded(
          child: _buildPrimaryActionButton(
            icon: _getFriendshipIcon(_friendshipStatus),
            label: FriendshipStatusHelper.getStatusText(_friendshipStatus),
            isLoading: _actionLoading,
            onTap: _handleFriendAction,
            isActive: isPrimaryAction,
          ),
        ),
        SizedBox(width: 12.w),
        // دکمه پیام
        Expanded(
          child: _buildSecondaryActionButton(
            icon: LucideIcons.messageCircle,
            label: 'پیام',
            onTap: () {
              final targetProfileId = (_profile?['id'] ?? widget.userId)
                  .toString();
              Navigator.pushNamed(
                context,
                '/chat',
                arguments: {
                  'otherUserId': targetProfileId,
                  'otherUserName': displayName,
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isActive = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.goldColor
                : context.separatorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isActive ? AppTheme.onGoldColor : context.textColor,
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  size: 16.sp,
                  color: isActive ? AppTheme.onGoldColor : context.textColor,
                ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                    color: isActive ? AppTheme.onGoldColor : context.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: context.separatorColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.sp, color: context.textColor),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                    color: context.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFriendshipIcon(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.friends:
        return LucideIcons.userCheck;
      case FriendshipStatus.requestSent:
        return LucideIcons.clock;
      case FriendshipStatus.requestReceived:
        return LucideIcons.userPlus;
      default:
        return LucideIcons.userPlus;
    }
  }

  Widget _buildGamificationStats() {
    final bd =
        _scoreBreakdown ??
        RankingScoreBreakdown(
          totalScore: _userRanking?.totalScore ?? 0,
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

    final bool hasAnyScore =
        bd.totalScore > 0 ||
        bd.dailyActivitiesScore > 0 ||
        bd.currentStreak > 0 ||
        bd.longestStreak > 0 ||
        bd.activeDays > 0 ||
        bd.totalWorkouts > 0 ||
        bd.totalMeals > 0 ||
        bd.articlesReadCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Row(
            children: [
              Icon(LucideIcons.trophy, size: 20.sp, color: AppTheme.goldColor),
              SizedBox(width: 8.w),
              Text(
                'عملکرد و امتیازات',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(20.w),
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.goldColor.withValues(alpha: 0.15),
                AppTheme.goldColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  LucideIcons.crown,
                  size: 24.sp,
                  color: AppTheme.goldColor,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'امتیاز کل',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      FormatUtils.formatNumber(
                        _userRanking?.totalScore ?? bd.totalScore,
                      ),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.trendingUp, size: 20.sp, color: Colors.green),
            ],
          ),
        ),
        StreakCalendarWidget(
          streakDates: _streakDates,
          currentStreak: bd.currentStreak,
          longestStreak: bd.longestStreak,
        ),
        SizedBox(height: 16.h),
        ProgressMetricsWidget(breakdown: bd),
        if (!hasAnyScore) ...[
          SizedBox(height: 16.h),
          Text(
            'هنوز امتیازی برای این کاربر ثبت نشده است. با فعالیت روزانه، ثبت تمرین و تغذیه، این بخش به‌تدریج پر می‌شود.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              color: context.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  List<DateTime> _calculateStreakDates(DateTime lastLoginDate, int streakDays) {
    final dates = <DateTime>[];
    if (streakDays <= 0) return dates;

    final baseDate = DateTime(
      lastLoginDate.year,
      lastLoginDate.month,
      lastLoginDate.day,
    );

    for (int i = streakDays - 1; i >= 0; i--) {
      final date = baseDate.subtract(Duration(days: i));
      dates.add(date);
    }

    return dates;
  }

  Widget _buildSocialStats() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSocialItem(
            'دوستان',
            (_userStats['friends'] ?? 0).toString(),
            LucideIcons.users,
            const Color(0xFF2196F3),
          ),
          Container(width: 1, height: 40.h, color: context.separatorColor),
          _buildSocialItem(
            'برنامه‌ها',
            (_userStats['active_programs'] ?? 0).toString(),
            LucideIcons.clipboardList,
            const Color(0xFF4CAF50),
          ),
          Container(width: 1, height: 40.h, color: context.separatorColor),
          _buildSocialItem(
            'مربیان',
            (_userStats['active_trainers'] ?? 0).toString(),
            LucideIcons.userCheck,
            AppTheme.goldColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 20.sp, color: color),
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
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatar(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: GymaiNetworkImage(imageUrl: url),
        ),
      ),
    );
  }
}
