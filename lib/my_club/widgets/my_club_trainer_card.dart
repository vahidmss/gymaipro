import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/services/ai_trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_trainer_avatar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// کارت مربی در تب «مربی» باشگاه من — فشرده و کاربردی.
class MyClubTrainerCard extends StatelessWidget {
  const MyClubTrainerCard({
    required this.trainer,
    required this.onChat,
    required this.onViewProfile,
    required this.onEndRelationship,
    super.key,
  });

  final Map<String, dynamic> trainer;
  final VoidCallback? onChat;
  final VoidCallback onViewProfile;
  final VoidCallback onEndRelationship;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = trainer['trainer'] as Map<String, dynamic>?;
    final status = trainer['status'] as String? ?? 'pending';
    final isActive = status == 'active';
    final trainerId = profile?['id'] as String? ?? trainer['trainer_id'] as String?;
    final isAi = AITrainerService.isGymaiTrainer(
      userId: trainerId,
      username: profile?['username'] as String?,
    );
    final displayName = _displayName(profile);
    final username = (profile?['username'] as String?)?.trim() ?? '';
    final rating = _formatRating(profile?['rating']);
    final experience = profile?['experience_years'];
    final specialization = _formatSpecializations(profile?['specializations']);

    final borderColor = isActive
        ? AppTheme.goldColor.withValues(alpha: isDark ? 0.35 : 0.45)
        : (isDark ? Colors.white12 : AppTheme.lightDividerColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewProfile,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10.r,
                  offset: Offset(0, 3.h),
                ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 10.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GymaiTrainerAvatar(
                      avatarUrl: profile?['avatar_url'] as String?,
                      userId: trainerId,
                      username: username,
                      size: 52,
                      fallback: Icon(
                        LucideIcons.user,
                        size: 24.sp,
                        color: AppTheme.goldColor,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: context.textColor,
                                  ),
                                ),
                              ),
                              _StatusChip(status: status),
                            ],
                          ),
                          if (username.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              '@$username',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.sp,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                          SizedBox(height: 6.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            children: [
                              if (isAi)
                                const _MetaChip(
                                  icon: LucideIcons.bot,
                                  label: 'مربی هوشمند',
                                  color: AppTheme.goldColor,
                                ),
                              if (rating != null)
                                _MetaChip(
                                  icon: LucideIcons.star,
                                  label: rating,
                                  color: AppTheme.goldColor,
                                ),
                              if (experience != null &&
                                  experience.toString().isNotEmpty)
                                _MetaChip(
                                  icon: LucideIcons.badgeCheck,
                                  label: '$experience سال',
                                  color: context.textSecondary,
                                ),
                            ],
                          ),
                          if (specialization != null) ...[
                            SizedBox(height: 6.h),
                            Text(
                              specialization,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11.5.sp,
                                height: 1.35,
                                color: context.textSecondary.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _ActionButton(
                        icon: LucideIcons.messageCircle,
                        label: 'پیام',
                        filled: true,
                        enabled: isActive && onChat != null,
                        onPressed: isActive ? onChat : null,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _ActionButton(
                        icon: LucideIcons.user,
                        label: 'پروفایل',
                        filled: false,
                        enabled: true,
                        onPressed: onViewProfile,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    _MoreMenu(onEndRelationship: onEndRelationship),
                  ],
                ),
                if (!isActive) ...[
                  SizedBox(height: 8.h),
                  Text(
                    status == 'pending'
                        ? 'پس از تأیید مربی می‌توانید پیام بفرستید.'
                        : 'رابطه غیرفعال — برای هماهنگی پروفایل را ببینید.',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      color: context.textSecondary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// نام نمایشی مربی از ردیف `trainer_clients`.
  static String displayNameFor(Map<String, dynamic> trainerRow) {
    return _displayName(trainerRow['trainer'] as Map<String, dynamic>?);
  }

  static String _displayName(Map<String, dynamic>? profile) {
    if (profile == null) return 'مربی';
    final first = (profile['first_name'] as String?)?.trim() ?? '';
    final last = (profile['last_name'] as String?)?.trim() ?? '';
    final username = (profile['username'] as String?)?.trim() ?? '';
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    if (username == AITrainerService.systemUsername) {
      return AppConfig.gymAiDisplayName;
    }
    if (username.isNotEmpty) return username;
    return 'مربی';
  }

  static String? _formatRating(dynamic raw) {
    if (raw == null) return null;
    final n = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    if (n == null || n <= 0) return null;
    return n.toStringAsFixed(1);
  }

  static String? _formatSpecializations(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      final parts = raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isEmpty) return null;
      return parts.take(3).join(' · ');
    }
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('فعال', AppTheme.successColor),
      'pending' => ('در انتظار', Colors.orange.shade700),
      'ended' => ('پایان‌یافته', context.textSecondary),
      'rejected' => ('رد شده', AppTheme.errorColor),
      _ => ('غیرفعال', context.textSecondary),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = enabled
        ? (filled ? AppTheme.onGoldColor : AppTheme.goldColor)
        : context.textSecondary.withValues(alpha: 0.5);
    final bg = enabled && filled
        ? AppTheme.goldColor
        : (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.goldColor.withValues(alpha: 0.08));
    final border = enabled
        ? AppTheme.goldColor.withValues(alpha: filled ? 0 : 0.35)
        : context.textSecondary.withValues(alpha: 0.2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.sp, color: fg),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onEndRelationship});

  final VoidCallback onEndRelationship;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        LucideIcons.moreVertical,
        color: context.textSecondary,
        size: 20.sp,
      ),
      color: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      onSelected: (value) {
        if (value == 'end') onEndRelationship();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'end',
          child: Row(
            children: [
              Icon(
                LucideIcons.userMinus,
                size: 18.sp,
                color: AppTheme.errorColor,
              ),
              SizedBox(width: 10.w),
              Text(
                'پایان رابطه',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
