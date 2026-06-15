import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/comprehensive_cache_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComprehensiveCacheInfoWidget extends StatefulWidget {
  const ComprehensiveCacheInfoWidget({super.key});

  @override
  State<ComprehensiveCacheInfoWidget> createState() =>
      _ComprehensiveCacheInfoWidgetState();
}

class _ComprehensiveCacheInfoWidgetState
    extends State<ComprehensiveCacheInfoWidget> {
  final ComprehensiveCacheService _cacheService = ComprehensiveCacheService();
  List<CacheInfo> _cacheInfos = [];
  int _totalSize = 0;
  int _totalFileCount = 0;
  bool _isLoading = true;
  bool _isClearing = false;
  String? _clearingType;
  final Map<String, bool> _expandedSections = {};
  final Map<String, List<CachedFile>> _cachedFiles = {};
  final Map<String, bool> _loadingFiles = {};

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cacheInfos = await _cacheService.getAllCacheInfo();
      final totalSize = await _cacheService.getTotalCacheSize();
      final totalCount = await _cacheService.getTotalFileCount();

      if (mounted) {
        setState(() {
          _cacheInfos = cacheInfos;
          _totalSize = totalSize;
          _totalFileCount = totalCount;
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

  Future<void> _clearCacheByType(String type) async {
    setState(() {
      _isClearing = true;
      _clearingType = type;
    });

    try {
      final success = await _cacheService.clearCacheByType(type);
      if (success) {
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
                  const Text('کش با موفقیت پاک شد'),
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
          _clearingType = null;
        });
      }
    }
  }

  Future<void> _clearAllCache() async {
    // تایید از کاربر
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          title: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: AppTheme.errorColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'پاک کردن همه کش‌ها',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
          content: Text(
            'آیا مطمئن هستید که می‌خواهید همه کش‌ها را پاک کنید؟ این عمل قابل بازگشت نیست.',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 14.sp,
              fontFamily: AppTheme.fontFamily,
            ),
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'انصراف',
                style: TextStyle(
                  color: context.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text(
                'پاک کردن',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
      _clearingType = 'all';
    });

    try {
      await _cacheService.clearAllCache();
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
                const Text('همه کش‌ها با موفقیت پاک شدند'),
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
          _clearingType = null;
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
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        // هدر با دکمه پاک کردن همه
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
                      'مدیریت کش',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'همه فایل‌های دانلود شده و کش شده',
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
            if (!_isLoading && _totalSize > 0)
              InkWell(
                onTap: _isClearing ? null : _clearAllCache,
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: _isClearing && _clearingType == 'all'
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

        // اطلاعات کلی
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
        else if (_totalSize == 0)
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
                    'کش خالی است',
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
              // خلاصه کلی
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          'کل فضای استفاده شده',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatFileSize(_totalSize),
                          style: TextStyle(
                            color: AppTheme.goldColor,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          'تعداد فایل‌ها',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '$_totalFileCount',
                          style: TextStyle(
                            color: AppTheme.goldColor,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // لیست انواع کش
              ..._cacheInfos.map((info) => _buildExpandableCacheItem(
                    context: context,
                    isDark: isDark,
                    info: info,
                  )),
            ],
          ),
      ],
    );
  }

  Widget _buildExpandableCacheItem({
    required BuildContext context,
    required bool isDark,
    required CacheInfo info,
  }) {
    final isExpanded = _expandedSections[info.type] ?? false;
    final isClearing = _isClearing && _clearingType == info.type;
    final files = _cachedFiles[info.type] ?? [];
    final isLoadingFiles = _loadingFiles[info.type] ?? false;

    // فقط برای ویدیو و موزیک expandable است
    final canExpand = info.type == 'video' ||
        info.type == 'music_cache' ||
        info.type == 'music_downloads';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? context.veryDarkBackground
            : AppTheme.lightButtonBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.separatorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // هدر (قابل کلیک برای expand)
          InkWell(
            onTap: canExpand && info.size > 0
                ? () => _toggleExpand(info.type)
                : null,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(12.r),
              bottom: isExpanded
                  ? Radius.zero
                  : Radius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  // آیکون
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      info.icon,
                      color: AppTheme.goldColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // اطلاعات
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          info.displayName,
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Text(
                              _formatFileSize(info.size),
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13.sp,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '•',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '${info.fileCount} فایل',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13.sp,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // آیکون expand/collapse
                  if (canExpand && info.size > 0)
                    Icon(
                      isExpanded
                          ? LucideIcons.chevronDown
                          : LucideIcons.chevronLeft,
                      color: context.textSecondary,
                      size: 20.sp,
                    ),

                  SizedBox(width: 8.w),

                  // دکمه پاک کردن همه
                  if (info.size > 0)
                    InkWell(
                      onTap: isClearing ? null : () => _clearCacheByType(info.type),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: isClearing
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
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
                                size: 16.sp,
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // لیست فایل‌ها (expandable)
          if (isExpanded && canExpand)
            DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? context.backgroundColor
                    : context.cardColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12.r),
                ),
              ),
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    color: context.separatorColor.withValues(alpha: 0.3),
                  ),
                  if (isLoadingFiles)
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.goldColor,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (files.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        'فایلی یافت نشد',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    )
                  else
                    ...files.map((file) => _buildFileItem(
                          context: context,
                          isDark: isDark,
                          file: file,
                        )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleExpand(String type) async {
    setState(() {
      _expandedSections[type] = !(_expandedSections[type] ?? false);
    });

    // اگر باز شد و فایل‌ها هنوز لود نشده‌اند، لود کن
    if ((_expandedSections[type] ?? false) && _cachedFiles[type] == null) {
      await _loadFiles(type);
    }
  }

  Future<void> _loadFiles(String type) async {
    setState(() {
      _loadingFiles[type] = true;
    });

    try {
      List<CachedFile> files = [];
      switch (type) {
        case 'video':
          files = await _cacheService.getVideoFiles();
        case 'music_cache':
          files = await _cacheService.getMusicCacheFiles();
        case 'music_downloads':
          files = await _cacheService.getMusicDownloadFiles();
      }

      if (mounted) {
        setState(() {
          _cachedFiles[type] = files;
          _loadingFiles[type] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingFiles[type] = false;
        });
      }
    }
  }

  Widget _buildFileItem({
    required BuildContext context,
    required bool isDark,
    required CachedFile file,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.separatorColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // آیکون فایل
          Icon(
            file.type == 'video'
                ? LucideIcons.video
                : LucideIcons.music,
            color: AppTheme.goldColor.withValues(alpha: 0.8),
            size: 18.sp,
          ),
          SizedBox(width: 12.w),

          // اطلاعات فایل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  _getFileDisplayName(file.fileName),
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppTheme.fontFamily,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      _formatFileSize(file.size),
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12.sp,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '•',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _formatDate(file.modifiedDate),
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
          ),

          // دکمه حذف
          InkWell(
            onTap: () => _deleteFile(file),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                LucideIcons.trash2,
                color: AppTheme.errorColor,
                size: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFileDisplayName(String fileName) {
    // اگر نام فایل hash است، یک نام عمومی نمایش بده
    if (fileName.length > 20 && !fileName.contains('.')) {
      return 'فایل ${fileName.substring(0, 8)}...';
    }
    // سعی کن نام واقعی را استخراج کن
    if (fileName.contains('.')) {
      return fileName.split('.').first;
    }
    return fileName;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'امروز';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks هفته پیش';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ماه پیش';
    }
  }

  Future<void> _deleteFile(CachedFile file) async {
    // تایید از کاربر
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          title: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: AppTheme.errorColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'حذف فایل',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
          content: Text(
            'آیا مطمئن هستید که می‌خواهید این فایل را حذف کنید؟',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 14.sp,
              fontFamily: AppTheme.fontFamily,
            ),
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'انصراف',
                style: TextStyle(
                  color: context.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text(
                'حذف',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final success = await _cacheService.deleteFile(file);
      if (success) {
        // به‌روزرسانی لیست فایل‌ها
        await _loadFiles(file.type);
        // به‌روزرسانی اطلاعات کلی
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
                  const Text('فایل با موفقیت حذف شد'),
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
                const Text('خطا در حذف فایل'),
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
    }
  }
}

