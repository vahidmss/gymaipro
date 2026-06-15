import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/video_cache_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class VideoCacheInfoWidget extends StatefulWidget {
  const VideoCacheInfoWidget({super.key});

  @override
  State<VideoCacheInfoWidget> createState() => _VideoCacheInfoWidgetState();
}

class _VideoCacheInfoWidgetState extends State<VideoCacheInfoWidget> {
  final VideoCacheService _videoCacheService = VideoCacheService();
  int _cacheSize = 0;
  int _cachedFilesCount = 0;
  bool _isLoading = true;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    try {
      final size = await _videoCacheService.getCacheSize();
      final count = await _videoCacheService.getCachedFilesCount();

      if (mounted) {
        setState(() {
          _cacheSize = size;
          _cachedFilesCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearCache() async {
    if (_cacheSize == 0) return;

    setState(() {
      _isClearing = true;
    });

    try {
      await _videoCacheService.clearCache();
      await _loadCacheInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                const Text('کش ویدیو با موفقیت پاک شد'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                const Text('خطا در پاک‌سازی کش'),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        // هدر با دکمه پاک‌سازی
        Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    LucideIcons.hardDrive,
                    color: AppTheme.goldColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      'کش ویدیو',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'ذخیره‌سازی محلی ویدیوها',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12.sp,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!_isLoading && _cacheSize > 0)
              InkWell(
                onTap: _isClearing ? null : _clearCache,
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: _isClearing
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.errorColor,
                            ),
                          ),
                        )
                      : Icon(
                          LucideIcons.trash2,
                          color: AppTheme.errorColor,
                          size: 18.sp,
                        ),
                ),
              ),
          ],
        ),

        SizedBox(height: 16.h),

        // اطلاعات کش
        if (_isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const CircularProgressIndicator(
                color: AppTheme.goldColor,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_cacheSize == 0)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark
                  ? context.veryDarkBackground
                  : AppTheme.lightButtonBackground,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.separatorColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  LucideIcons.info,
                  color: context.textSecondary,
                  size: 18.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'کش ویدیو خالی است',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13.sp,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              // اندازه کش
              _buildInfoRow(
                context: context,
                icon: LucideIcons.hardDrive,
                label: 'اندازه',
                value: _formatFileSize(_cacheSize),
              ),
              SizedBox(height: 12.h),

              // تعداد فایل‌ها
              _buildInfoRow(
                context: context,
                icon: LucideIcons.video,
                label: 'تعداد فایل‌ها',
                value: '$_cachedFilesCount',
              ),
              SizedBox(height: 12.h),

              // توضیحات
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? context.veryDarkBackground
                      : AppTheme.lightButtonBackground,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.info,
                      color: AppTheme.goldColor.withValues(alpha: 0.8),
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'ویدیوها پس از مشاهده در کش ذخیره می‌شوند تا دفعات بعد نیازی به دانلود مجدد نباشد.',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12.sp,
                          height: 1.5,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              icon,
              color: AppTheme.goldColor.withValues(alpha: 0.8),
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13.sp,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: context.textColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }
}
