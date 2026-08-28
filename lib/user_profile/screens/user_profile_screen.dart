import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/my_club/services/confidential_user_info_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/user_profile/screens/athlete_profile_screen.dart';
import 'package:gymaipro/user_profile/screens/trainer_profile_screen.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  String get _appBarTitle {
    if (_isTrainerProfile) return 'پروفایل مربی';
    if (_hasTrainerAccess) return 'پروفایل شاگرد';
    return 'پروفایل کاربر';
  }

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
        _appBarTitle,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          color: context.textColor,
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
      return const Center(
        child: Text(
          'پروفایل یافت نشد',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
      );
    }

    if (_isTrainerProfile) {
      return TrainerProfileScreen(userId: widget.userId);
    }

    return AthleteProfileScreen(
      userId: widget.userId,
      isTrainerViewer: _hasTrainerAccess,
      confHasConsented: _confHasConsented,
      confidentialData: _confidentialData,
    );
  }
}
