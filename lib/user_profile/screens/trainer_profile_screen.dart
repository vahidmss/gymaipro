import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/friendship_models.dart';
import 'package:gymaipro/my_club/services/friendship_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/profile/widgets/profile_new_widgets.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_kpi_service.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// اسکرین پروفایل مربی (عمومی)
class TrainerProfileScreen extends StatefulWidget {
  const TrainerProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  TrainerKpis? _trainerKpis;
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _profile = await UserProfileService.fetchProfile(widget.userId);
      final targetId = _getTargetId();

      if (targetId.isNotEmpty) {
        await Future.wait([
          _loadTrainerKpis(targetId),
          _loadFriendshipStatus(),
        ]);
      }
    } catch (_) {
      // Error handling - profile will be null and error message will be shown
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFriendshipStatus() async {
    try {
      final viewerProfile = await SimpleProfileService.getCurrentProfile();
      final viewerProfileId = (viewerProfile?['id'] ?? '').toString();

      if (viewerProfileId.isNotEmpty) {
        final targetAuthId =
            _profile?['auth_user_id']?.toString() ??
            _profile?['id']?.toString() ??
            widget.userId;

        if (targetAuthId.isNotEmpty) {
          _friendshipStatus = await FriendshipService.getFriendshipStatus(
            targetAuthId,
          );
        }
      }
    } catch (_) {
      // Ignore errors
    }
  }

  String _getTargetId() {
    final profileId = (_profile?['id'] ?? '').toString();
    return profileId.isNotEmpty ? profileId : widget.userId;
  }

  Future<void> _loadTrainerKpis(String targetId) async {
    try {
      _trainerKpis = await TrainerKpiService().getTrainerKpis(targetId);
    } catch (_) {
      _trainerKpis = null;
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
        children: [
          _buildModernHeader(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                // فاصله کمتر تا هدر تا کل بلوک بالاتر بیاید
                SizedBox(height: 40.h),
                _buildQuickActions(),
                SizedBox(height: 40.h),
                ModernTrainerKpiDashboard(
                  profileData: _profile!,
                  kpis: _trainerKpis,
                  onOpenTrainerRanking: () =>
                      Navigator.pushNamed(context, '/trainer-ranking'),
                  isSelfView: false,
                ),
                SizedBox(height: 12.h),
                _buildViewFullProfileButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewFullProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(
          context,
          '/trainer-detail',
          arguments: {
            'trainerId': (_profile?['id'] ?? widget.userId).toString(),
          },
        ),
        icon: Icon(LucideIcons.externalLink, size: 18.sp),
        label: const Text(
          'مشاهده صفحه کامل مربی',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.goldColor,
          side: BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.7)),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
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

    const accentColor = AppTheme.goldColor;
    const roleLabel = 'مربی';

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180.h,
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
          bottom: 0.h,
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
                _buildHeaderContent(
                  context,
                  avatarUrl: avatarUrl,
                  displayName: displayName,
                  username: username,
                  bio: bio,
                  accentColor: accentColor,
                  roleLabel: roleLabel,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderContent(
    BuildContext context, {
    required String avatarUrl,
    required String displayName,
    required String username,
    required String bio,
    required Color accentColor,
    required String roleLabel,
    required bool isDark,
  }) {
    final rankingValue = (_profile?['ranking'] as num?)?.toInt();

    return Row(
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
              border: Border.all(color: accentColor, width: 3.w),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
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
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
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
                        fontSize: 16.sp,
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
                  if (rankingValue != null && rankingValue > 0) ...[
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.trophy,
                            size: 12.sp,
                            color: AppTheme.goldColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '#$rankingValue',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.goldColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      color: context.separatorColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(
                        color: context.separatorColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.badgeCheck,
                          size: 12.sp,
                          color: accentColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          roleLabel,
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
                      username.isNotEmpty ? '@$username' : 'بدون نام کاربری',
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
}
