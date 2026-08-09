import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_rank_chip.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// هویت یکپارچه: آواتار + سلام + نام + متای ساکت.
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({
    required this.username,
    required this.welcomeMessage,
    super.key,
    this.profileData,
    this.streak,
  });

  final String username;
  final String welcomeMessage;
  final Map<String, dynamic>? profileData;
  final int? streak;

  String _getDisplayName() {
    if (profileData != null) {
      final firstName = profileData!['first_name']?.toString() ?? '';
      final lastName = profileData!['last_name']?.toString() ?? '';
      final userUsername = profileData!['username']?.toString() ?? '';

      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
      if (userUsername.isNotEmpty) {
        return userUsername;
      }
    }
    return username.isNotEmpty ? username : 'کاربر عزیز';
  }

  String? get _avatarUrl {
    final url = profileData?['avatar_url']?.toString();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final name = _getDisplayName();
    final streakDays = (streak != null && streak! > 0) ? streak! : 0;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (userId.isNotEmpty) {
                Navigator.pushNamed(context, '/profile');
              }
            },
            child: _WelcomeAvatar(avatarUrl: _avatarUrl, name: name),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  welcomeMessage,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppTheme.fontFamily,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 4.h),
                Text(
                  name,
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: AppTheme.fontFamily,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 6.h),
                _WelcomeMetaRow(streakDays: streakDays),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeAvatar extends StatelessWidget {
  const _WelcomeAvatar({required this.avatarUrl, required this.name});

  final String? avatarUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final size = 52.w;
    final initial = name.isNotEmpty ? name.substring(0, 1) : 'U';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.separatorColor, width: 1.w),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? GymaiNetworkImage(
                imageUrl: avatarUrl!,
                placeholder: _fallback(context, initial),
                errorWidget: _fallback(context, initial),
              )
            : _fallback(context, initial),
      ),
    );
  }

  Widget _fallback(BuildContext context, String initial) {
    return ColoredBox(
      color: context.cardColor,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
            color: context.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _WelcomeMetaRow extends StatelessWidget {
  const _WelcomeMetaRow({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final hasStreak = streakDays > 0;

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        if (hasStreak) ...[
          Icon(
            LucideIcons.flame,
            size: 13.sp,
            color: context.textSecondary,
          ),
          SizedBox(width: 4.w),
          Text(
            streakDays == 1 ? 'روز اول' : '$streakDays روز',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
              color: context.textSecondary,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              '·',
              style: TextStyle(
                color: context.textSecondary.withValues(alpha: 0.45),
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
        const Expanded(child: DashboardRankChip()),
      ],
    );
  }
}
