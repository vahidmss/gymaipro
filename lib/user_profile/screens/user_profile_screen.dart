import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/friendship_models.dart';
import 'package:gymaipro/my_club/services/confidential_user_info_service.dart';
import 'package:gymaipro/my_club/services/friendship_service.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/ranking/models/ranking_score_breakdown.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/services/ranking_score_service.dart';
import 'package:gymaipro/ranking/services/ranking_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({required this.userId, super.key});
  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, int> _userStats = {};
  bool _loading = true;
  bool _hasTrainerAccess = false;
  bool _confHasConsented = false;
  Map<String, dynamic>? _confidentialData;
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

        // Load Ranking (if athlete)
        final role = (_profile?['role'] ?? 'athlete').toString();
        if (role == 'athlete') {
          try {
            final rankingService = RankingService();
            final scoreService = RankingScoreService();
            final ranking = await rankingService.getUserRanking(targetId);
            final breakdown = await scoreService.getScoreBreakdown(targetId);
            _userRanking = ranking;
            _scoreBreakdown = breakdown;

            // Calculate streak dates
            final currentStreak = breakdown?.currentStreak ?? 0;
            final lastLoginDateStr = _profile?['last_login_date'] as String?;
            if (lastLoginDateStr != null &&
                lastLoginDateStr.isNotEmpty &&
                currentStreak > 0) {
              try {
                final lastLoginDate = DateTime.parse(lastLoginDateStr);
                _streakDates = _calculateStreakDates(
                  lastLoginDate,
                  currentStreak,
                );
              } catch (_) {}
            }
          } catch (_) {}
        }

        // Check Trainer Access
        final viewerProfile = await SimpleProfileService.getCurrentProfile();
        final viewerProfileId = (viewerProfile?['id'] ?? '').toString();

        if (viewerProfileId.isNotEmpty) {
          // Check Friendship Status
          final targetAuthId =
              _profile?['auth_user_id']?.toString() ??
              (_profile?['id']?.toString()) ??
              widget.userId;

          if (targetAuthId.isNotEmpty) {
            try {
              _friendshipStatus = await FriendshipService.getFriendshipStatus(
                targetAuthId,
              );
            } catch (_) {}
          }

          try {
            final trainerService = TrainerService();
            final isTrainer = await trainerService.isClientOfTrainer(
              targetId,
              viewerProfileId,
            );
            if (isTrainer) {
              _hasTrainerAccess = true;
              _confHasConsented =
                  await ConfidentialUserInfoService.getConsentStatusForProfile(
                    targetId,
                  );
              if (_confHasConsented) {
                _confidentialData =
                    await ConfidentialUserInfoService.loadUserDataForProfile(
                      targetId,
                    );
              }
            }
          } catch (_) {}
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
          (_profile?['id']?.toString()) ??
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
          break;
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
          break;
        case FriendshipStatus.friends:
          // Optional: Show unfriend dialog
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int tabCount = _hasTrainerAccess ? 2 : 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: tabCount,
        child: Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: AppBar(
            backgroundColor: context.backgroundColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                LucideIcons.arrowRight,
                color: context.textColor,
                size: 24.sp,
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: 'بازگشت',
            ),
            title: Text(
              'پروفایل کاربر',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: context.textColor,
              ),
            ),
            bottom: _hasTrainerAccess
                ? PreferredSize(
                    preferredSize: Size.fromHeight(50.h),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          color: AppTheme.goldColor,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.black,
                        unselectedLabelColor: context.textSecondary,
                        labelStyle: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                        tabs: const [
                          Tab(text: 'نمای کلی'),
                          Tab(text: 'اطلاعات مربی'),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor),
                )
              : _profile == null
              ? Center(
                  child: Text(
                    'پروفایل یافت نشد',
                    style: TextStyle(fontFamily: AppTheme.fontFamily),
                  ),
                )
              : _hasTrainerAccess
              ? TabBarView(children: [_buildMainTab(), _buildTrainerTab()])
              : _buildMainTab(),
        ),
      ),
    );
  }

  Widget _buildMainTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 32.h),
      child: Column(
        children: [
          _buildModernHeader(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                // Quick Actions
                _buildQuickActions(),
                SizedBox(height: 20.h),
                // Social Stats - Compact
                _buildSocialStats(),
                SizedBox(height: 20.h),
                // Ranking & Gamification — برای همه کاربران (چه در لیگ باشند چه نه)
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

    final isAthlete = (_profile?['role'] ?? 'athlete').toString() == 'athlete';
    // نکته: «بدون لیگ» یعنی هنوز رکورد ranking ندارد (نه اینکه امتیازش ۰ باشد)
    final isInLeague = isAthlete && _userRanking != null;

    // League info
    final totalScore =
        _userRanking?.totalScore ?? _scoreBreakdown?.totalScore ?? 0;
    final league = League.getLeagueByScore(totalScore);
    final progressToNext = league.getProgressToNextLeague(totalScore);
    final nextLeague = league.nextLeague;
    final leagueAccentColor = isInLeague
        ? Color(league.color)
        : context.textSecondary;
    final leagueLabel = isInLeague ? league.nameFa : 'بدون لیگ';

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Compact Background
        Container(
          height: 240.h,
          width: double.infinity,
          decoration: BoxDecoration(
            // از همان گرادیانت هدر پروفایل اصلی استفاده می‌کنیم
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

        // Content - Compact Card Style
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
                // Avatar Row
                Row(
                  children: [
                    // Avatar
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
                                ? Image.network(avatarUrl, fit: BoxFit.cover)
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
                    // Name & Info Column
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
                              // League pill – با کنتراست نرم‌تر و خوانایی بهتر
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: context.separatorColor.withValues(
                                    alpha: isInLeague ? 0.12 : 0.08,
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

                // League Status / Progress (always rendered to keep UI uniform)
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
                                    isAthlete
                                        ? (isInLeague
                                              ? 'پیشرفت به لیگ بعدی'
                                              : 'وضعیت لیگ')
                                        : 'سیستم لیگ',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.textColor,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    isAthlete
                                        ? (isInLeague
                                              ? (nextLeague?.nameFa ??
                                                    'در بالاترین لیگ')
                                              : 'بدون لیگ')
                                        : 'ویژه ورزشکاران',
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
                                  isAthlete
                                      ? (isInLeague
                                            ? '${(((nextLeague == null) ? 1.0 : progressToNext) * 100).toStringAsFixed(0)}%'
                                            : '0%')
                                      : '—',
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
                          value: isAthlete
                              ? (isInLeague
                                    ? ((nextLeague == null)
                                          ? 1.0
                                          : progressToNext.clamp(0.0, 1.0))
                                    : 0.0)
                              : 0.0,
                          minHeight: 8.h,
                          backgroundColor: context.separatorColor.withValues(
                            alpha: 0.25,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.goldColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'امتیاز فعلی: ${_formatNumber(totalScore)}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10.sp,
                              color: context.textSecondary,
                            ),
                          ),
                          Text(
                            isAthlete
                                ? (isInLeague
                                      ? (nextLeague == null
                                            ? 'در بالاترین لیگ'
                                            : 'امتیاز مورد نیاز: ${_formatNumber(nextLeague.minScore)}')
                                      : 'برای ورود به لیگ: 1 امتیاز')
                                : '—',
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

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Friend Request Button
          Expanded(
            child: _buildQuickActionButton(
              icon: _getFriendshipIcon(_friendshipStatus),
              label: FriendshipStatusHelper.getStatusText(_friendshipStatus),
              isPrimary:
                  _friendshipStatus == FriendshipStatus.none ||
                  _friendshipStatus == FriendshipStatus.requestReceived,
              isLoading: _actionLoading,
              onTap: _handleFriendAction,
            ),
          ),
          SizedBox(width: 12.w),
          // Message Button
          Expanded(
            child: _buildQuickActionButton(
              icon: LucideIcons.messageCircle,
              label: 'پیام شخصی',
              isPrimary: false,
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
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppTheme.goldColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16.r),
          border: isPrimary
              ? null
              : Border.all(
                  color: context.separatorColor.withValues(alpha: 0.5),
                ),
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
                  color: isPrimary ? Colors.black : context.textColor,
                ),
              )
            else
              Icon(
                icon,
                size: 16.sp,
                color: isPrimary ? Colors.black : context.textColor,
              ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                  color: isPrimary ? Colors.black : context.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
    // اگر کاربر هنوز وارد سیستم لیگ نشده و breakdown ندارد،
    // یک breakdown خالی با مقادیر صفر می‌سازیم تا بخش امتیازات
    // همچنان به‌صورت کامل و منظم نمایش داده شود و برای همه
    // کاربران (چه در لیگ باشند چه نه) یک UI یکسان داشته باشیم.
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
        bd.totalMeals > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
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

        // Total Score Card
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
                      _formatNumber(bd.totalScore),
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

        // Streak Chain Visualization (نمایش برای همه کاربران)
        _buildStreakChain(bd),

        SizedBox(height: 16.h),

        // Progress Bars for All Metrics (نمایش برای همه کاربران)
        _buildProgressMetrics(bd),

        // پیام راهنما برای کاربرانی که هنوز امتیازی نگرفته‌اند
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

  Widget _buildStreakChain(RankingScoreBreakdown bd) {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.flame,
                size: 18.sp,
                color: const Color(0xFFFF5722),
              ),
              SizedBox(width: 8.w),
              Text(
                'زنجیره فعالیت',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildChainVisualization(bd.currentStreak),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.trophy,
                size: 14.sp,
                color: const Color(0xFFE91E63),
              ),
              SizedBox(width: 6.w),
              Text(
                'رکورد زنجیره: ',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  color: context.textSecondary,
                ),
              ),
              Text(
                '${bd.longestStreak} روز متوالی',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE91E63),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getJalaliDaysInMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return Jalali(year).isLeapYear() ? 30 : 29;
  }

  List<DateTime> _calculateStreakDates(DateTime lastLoginDate, int streakDays) {
    final dates = <DateTime>[];
    if (streakDays <= 0) return dates;

    // زنجیره باید بر اساس آخرین روز فعال کاربر محاسبه شود، نه امروز
    final baseDate = DateTime(
      lastLoginDate.year,
      lastLoginDate.month,
      lastLoginDate.day,
    );

    // قدیمی‌ترین روز تا جدیدترین روز زنجیره
    for (int i = streakDays - 1; i >= 0; i--) {
      final date = baseDate.subtract(Duration(days: i));
      dates.add(date);
    }

    return dates; // Oldest first
  }

  static const List<String> _persianMonthNames = [
    '',
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  Widget _buildChainVisualization(int currentStreak) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final jalaliNow = Jalali.fromDateTime(now);
    final year = jalaliNow.year;
    final month = jalaliNow.month;
    final daysInMonth = _getJalaliDaysInMonth(year, month);

    final streakSet = <int>{};
    for (final d in _streakDates) {
      streakSet.add(DateTime(d.year, d.month, d.day).millisecondsSinceEpoch);
    }

    final firstDay = Jalali(year, month, 1);
    final firstWeekday = firstDay.weekDay;
    final emptyBoxes = firstWeekday - 1;
    final totalCells = emptyBoxes + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.06),
                  AppTheme.goldColor.withValues(alpha: 0.02),
                ],
              ),
        color: isDark
            ? AppTheme.darkGreySeparator.withValues(alpha: 0.25)
            : null,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _persianMonthNames[month],
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark ? AppTheme.goldColor : context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$year',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor.withValues(alpha: 0.6),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 12.h),
          _buildStreakWeekdayHeaders(isDark),
          SizedBox(height: 6.h),
          ...List.generate(
            weeks,
            (weekIndex) => _buildStreakWeekRow(
              weekIndex,
              emptyBoxes,
              daysInMonth,
              year,
              month,
              streakSet,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakWeekdayHeaders(bool isDark) {
    const weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    return Row(
      children: weekdays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isDark
                        ? AppTheme.goldColor.withValues(alpha: 0.7)
                        : context.textColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStreakWeekRow(
    int weekIndex,
    int emptyBoxes,
    int daysInMonth,
    int year,
    int month,
    Set<int> streakSet,
    bool isDark,
  ) {
    final startCell = weekIndex * 7;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: List.generate(7, (dayIndex) {
          final cellIndex = startCell + dayIndex;
          final dayNumber = cellIndex - emptyBoxes + 1;
          if (dayNumber < 1 || dayNumber > daysInMonth) {
            return Expanded(child: SizedBox(height: 40.h));
          }
          final persianDate = Jalali(year, month, dayNumber);
          final gregorianDate = persianDate.toGregorian().toDateTime();
          final dateKey = DateTime(
            gregorianDate.year,
            gregorianDate.month,
            gregorianDate.day,
          );
          final isStreak = streakSet.contains(dateKey.millisecondsSinceEpoch);
          final now = DateTime.now();
          final isTodayAndStreak =
              isStreak &&
              now.year == gregorianDate.year &&
              now.month == gregorianDate.month &&
              now.day == gregorianDate.day;
          // برای وصل شدن ظاهری روزهای پشت‌سرهم، چک می‌کنیم آیا روز قبل/بعد هم جزو زنجیره است
          bool connectLeft = false;
          bool connectRight = false;
          if (isStreak) {
            // چک روز قبل در همان ردیف
            if (dayIndex > 0 && dayNumber > 1) {
              final leftPersian = Jalali(year, month, dayNumber - 1);
              final leftGreg = leftPersian.toGregorian().toDateTime();
              final leftKey = DateTime(
                leftGreg.year,
                leftGreg.month,
                leftGreg.day,
              );
              connectLeft = streakSet.contains(leftKey.millisecondsSinceEpoch);
            }
            // چک روز بعد در همان ردیف
            if (dayIndex < 6 && dayNumber < daysInMonth) {
              final rightPersian = Jalali(year, month, dayNumber + 1);
              final rightGreg = rightPersian.toGregorian().toDateTime();
              final rightKey = DateTime(
                rightGreg.year,
                rightGreg.month,
                rightGreg.day,
              );
              connectRight = streakSet.contains(
                rightKey.millisecondsSinceEpoch,
              );
            }
          }

          return Expanded(
            child: _buildStreakDayCell(
              dayNumber: dayNumber,
              isStreak: isStreak,
              isTodayAndStreak: isTodayAndStreak,
              connectLeft: connectLeft,
              connectRight: connectRight,
              isDark: isDark,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStreakDayCell({
    required int dayNumber,
    required bool isStreak,
    required bool isTodayAndStreak,
    required bool connectLeft,
    required bool connectRight,
    required bool isDark,
  }) {
    final radius = 10.r;
    final borderRadius = BorderRadius.horizontal(
      left: Radius.circular(isStreak && !connectLeft ? radius : 4.r),
      right: Radius.circular(isStreak && !connectRight ? radius : 4.r),
    );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isStreak ? 0.5.w : 1.5.w,
        vertical: 1.5.h,
      ),
      height: 40.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isStreak
            ? null
            : (isDark
                  ? AppTheme.darkGreySeparator.withValues(alpha: 0.2)
                  : Colors.transparent),
        gradient: isStreak
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF5722).withValues(alpha: 0.9),
                  const Color(0xFFFF5722).withValues(alpha: 0.75),
                ],
              )
            : null,
        borderRadius: borderRadius,
        border: Border.all(
          color: isTodayAndStreak
              ? AppTheme.goldColor.withValues(alpha: 0.7)
              : Colors.transparent,
          width: isTodayAndStreak ? 1.5 : 0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isStreak) ...[
            Icon(
              LucideIcons.flame,
              size: 12.sp,
              color: Colors.white.withValues(alpha: 0.95),
            ),
            SizedBox(height: 2.h),
          ] else
            SizedBox(height: 4.h),
          Text(
            '$dayNumber',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              fontWeight: isStreak ? FontWeight.bold : FontWeight.w500,
              color: isStreak ? Colors.white : context.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetrics(RankingScoreBreakdown bd) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.barChart3,
                size: 18.sp,
                color: AppTheme.goldColor,
              ),
              SizedBox(width: 8.w),
              Text(
                'جزئیات امتیازات',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // All metrics with progress bars
          _buildProgressMetric(
            'فعالیت روزانه',
            bd.dailyActivitiesScore,
            RankingScoreBreakdown.maxDailyActivitiesScore,
            LucideIcons.activity,
            const Color(0xFF00BCD4),
            'امتیاز ۳۰ روز گذشته',
          ),
          SizedBox(height: 16.h),
          _buildProgressMetric(
            'روزهای فعال',
            bd.activeDaysScore,
            RankingScoreBreakdown.maxActiveDaysScore,
            LucideIcons.calendarCheck,
            const Color(0xFF9C27B0),
            '${bd.activeDays} روز فعال',
          ),
          SizedBox(height: 16.h),
          _buildProgressMetric(
            'تمرینات',
            bd.totalWorkoutsScore,
            RankingScoreBreakdown.maxTotalWorkoutsScore,
            LucideIcons.dumbbell,
            const Color(0xFF4CAF50),
            '${bd.totalWorkouts} جلسه',
          ),
          SizedBox(height: 16.h),
          _buildProgressMetric(
            'وعده‌های غذایی',
            bd.totalMealsScore,
            RankingScoreBreakdown.maxTotalMealsScore,
            LucideIcons.utensils,
            const Color(0xFF2196F3),
            '${bd.totalMeals} وعده',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric(
    String label,
    int score,
    int maxScore,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    final progress = maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
    return Column(
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
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, size: 14.sp, color: color),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '$score / $maxScore',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8.h,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
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

  Widget _buildTrainerTab() {
    if (!_hasTrainerAccess) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            margin: EdgeInsets.only(top: 80.h), // Offset for header overlap
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lock, color: AppTheme.goldColor, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'این بخش فقط برای شما (مربی) قابل مشاهده است.',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: AppTheme.goldColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          if (!_confHasConsented)
            Center(
              child: Text(
                'شاگرد هنوز دسترسی به اطلاعات محرمانه را تایید نکرده است.',
                style: TextStyle(
                  color: context.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            )
          else
            _buildConfidentialContent(),
        ],
      ),
    );
  }

  Widget _buildConfidentialContent() {
    final prefs =
        (_confidentialData?['lifestyle_preferences']
            as Map<String, dynamic>?) ??
        {};

    return Column(
      children: [
        _trainerCard(
          icon: LucideIcons.heart,
          title: 'سلامت و شرایط خاص',
          lines: [
            _kv('شرایط پزشکی', prefs['medical_conditions']),
            _kv('داروها', prefs['medications']),
            _kv('آلرژی‌ها', prefs['allergies']),
          ],
        ),
        SizedBox(height: 12.h),
        _trainerCard(
          icon: LucideIcons.target,
          title: 'هدف‌ها',
          lines: [
            _kv('اهداف اصلی', prefs['primary_goals']),
            _kv('وزن هدف', prefs['target_weight']),
          ],
        ),
        // More fields can be added here
      ],
    );
  }

  Widget _trainerCard({
    required IconData icon,
    required String title,
    required List<Widget> lines,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.goldColor, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          Divider(height: 24.h),
          ...lines,
        ],
      ),
    );
  }

  Widget _kv(String label, dynamic value) {
    final String v = (value ?? '').toString();
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 13.sp,
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
                fontSize: 13.sp,
              ),
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
          child: Image.network(url, fit: BoxFit.cover),
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
