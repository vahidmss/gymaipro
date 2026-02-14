import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/my_club/services/confidential_user_info_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/user_profile/screens/athlete_profile_screen.dart';
import 'package:gymaipro/user_profile/screens/trainer_profile_screen.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Wrapper برای پروفایل کاربر - بر اساس role اسکرین مناسب رو نمایش می‌دهد
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({required this.userId, super.key});
  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _hasTrainerAccess = false;
  bool _confHasConsented = false;
  Map<String, dynamic>? _confidentialData;

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
        await _checkTrainerAccess(targetId);
      }
    } catch (_) {
      // Error handling - profile will be null and error message will be shown
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getTargetId() {
    final profileId = (_profile?['id'] ?? '').toString();
    return profileId.isNotEmpty ? profileId : widget.userId;
  }

  Future<void> _checkTrainerAccess(String targetId) async {
    try {
      final viewerProfile = await SimpleProfileService.getCurrentProfile();
      final viewerProfileId = (viewerProfile?['id'] ?? '').toString();

      if (viewerProfileId.isEmpty) return;

      final trainerService = TrainerService();
      final isTrainer = await trainerService.isClientOfTrainer(
        targetId,
        viewerProfileId,
      );

      if (!isTrainer) return;

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
    } catch (_) {
      // Silent fail - trainer access will remain false
    }
  }

  String get _userRole => (_profile?['role'] ?? 'athlete').toString();
  bool get _isTrainerProfile => _userRole == 'trainer';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: _buildAppBar(context),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
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
        _isTrainerProfile ? 'پروفایل مربی' : 'پروفایل کاربر',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          color: context.textColor,
        ),
      ),
      bottom: _hasTrainerAccess ? _buildTabBar() : null,
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
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
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    if (_profile == null) {
      return Center(
        child: Text(
          'پروفایل یافت نشد',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
      );
    }

    if (_hasTrainerAccess) {
      return DefaultTabController(
        length: 2,
        child: TabBarView(
          children: [
            _buildRoleBasedScreen(),
            _buildTrainerTab(),
          ],
        ),
      );
    }

    return _buildRoleBasedScreen();
  }

  Widget _buildRoleBasedScreen() {
    if (_isTrainerProfile) {
      return TrainerProfileScreen(userId: widget.userId);
    }
    return AthleteProfileScreen(userId: widget.userId);
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
            margin: EdgeInsets.only(top: 80.h),
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
}
