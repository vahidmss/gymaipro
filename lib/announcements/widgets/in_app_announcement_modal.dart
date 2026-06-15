import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/announcements/models/in_app_announcement.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppAnnouncementModal extends StatelessWidget {
  const InAppAnnouncementModal({
    required this.announcement,
    required this.onDismiss,
    required this.onCtaTap,
    super.key,
  });

  final InAppAnnouncement announcement;
  final VoidCallback onDismiss;
  final VoidCallback onCtaTap;

  Future<bool> _openCta(BuildContext context) async {
    final value = announcement.ctaValue?.trim();
    if (value == null || value.isEmpty) return false;

    try {
      switch (announcement.ctaType) {
        case AnnouncementCtaType.deepLink:
          await Navigator.of(context).pushNamed(value);
          return true;
        case AnnouncementCtaType.externalUrl:
          final uri = Uri.tryParse(value);
          if (uri == null || uri.scheme.isEmpty) return false;
          final opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          return opened;
        case AnnouncementCtaType.none:
          return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لینک اقدام قابل باز شدن نیست'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const Icon(LucideIcons.megaphone, color: AppTheme.goldColor),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'اطلاعیه جدید',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextColor.withValues(alpha: 0.8)
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
                IconButton(onPressed: onDismiss, icon: const Icon(Icons.close)),
              ],
            ),
            SizedBox(height: 10.h),
            _buildMedia(isDark),
            SizedBox(height: 12.h),
            Text(
              announcement.title,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.darkTextColor
                    : AppTheme.lightTextColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              announcement.description,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark
                    ? AppTheme.darkTextColor.withValues(alpha: 0.85)
                    : AppTheme.lightTextSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    child: const Text('بعدا'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: announcement.hasCta
                        ? () async {
                            final opened = await _openCta(context);
                            if (opened) {
                              onCtaTap();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: AppTheme.onGoldColor,
                    ),
                    child: Text(
                      (announcement.ctaText?.trim().isNotEmpty ?? false)
                          ? announcement.ctaText!.trim()
                          : 'بزن بریم',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(bool isDark) {
    final mediaUrl = announcement.mediaUrl?.trim();
    if (mediaUrl == null || mediaUrl.isEmpty) return const SizedBox.shrink();

    if (announcement.mediaType == AnnouncementMediaType.video) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.black12,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.playCircle,
              color: AppTheme.goldColor,
              size: 28.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'ویدیو این اطلاعیه آماده مشاهده است',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark
                      ? AppTheme.darkTextColor
                      : AppTheme.lightTextColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Image.network(
        mediaUrl,
        width: double.infinity,
        height: 180.h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: 120.h,
            color: isDark ? Colors.black26 : Colors.black12,
            alignment: Alignment.center,
            child: const Text('خطا در بارگذاری تصویر'),
          );
        },
      ),
    );
  }
}
