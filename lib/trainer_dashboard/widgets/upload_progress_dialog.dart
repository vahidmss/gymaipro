import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// دیالوگ جذاب برای نمایش پیشرفت آپلود
class UploadProgressDialog extends StatefulWidget {
  final String title;
  final String? fileName;
  final double progress;
  final String? statusText;
  final bool isIndeterminate;

  const UploadProgressDialog({
    super.key,
    required this.title,
    this.fileName,
    required this.progress,
    this.statusText,
    this.isIndeterminate = false,
  });

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressPercent = (widget.progress * 100).clamp(0.0, 100.0).toInt();

    return WillPopScope(
      onWillPop: () async => false, // جلوگیری از بستن با back button
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // آیکون انیمیشن دار
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.goldColor,
                            AppTheme.goldColor.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.upload,
                        color: Colors.black,
                        size: 40.sp,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24.h),

              // عنوان
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),

              // نام فایل
              if (widget.fileName != null) ...[
                Text(
                  widget.fileName!,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 24.h),
              ] else
                SizedBox(height: 16.h),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: LinearProgressIndicator(
                  value: widget.isIndeterminate ? null : widget.progress,
                  minHeight: 8.h,
                  backgroundColor: isDark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.goldColor,
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // درصد و وضعیت
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isIndeterminate
                        ? 'در حال آماده‌سازی...'
                        : '$progressPercent%',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.goldColor,
                    ),
                  ),
                  if (widget.statusText != null)
                    Expanded(
                      child: Text(
                        widget.statusText!,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.sp,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper برای نمایش دیالوگ آپلود
class UploadProgressHelper {
  static OverlayEntry? _overlayEntry;
  static BuildContext? _context;
  static String _title = '';
  static String? _fileName;
  static double _progress = 0.0;
  static String? _statusText;
  static bool _isIndeterminate = false;

  /// نمایش دیالوگ آپلود
  static void show({
    required BuildContext context,
    required String title,
    String? fileName,
    double progress = 0.0,
    String? statusText,
    bool isIndeterminate = false,
  }) {
    _context = context;
    _title = title;
    _fileName = fileName;
    _progress = progress;
    _statusText = statusText;
    _isIndeterminate = isIndeterminate;

    final overlay = Overlay.of(context);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: UploadProgressDialog(
            title: _title,
            fileName: _fileName,
            progress: _progress,
            statusText: _statusText,
            isIndeterminate: _isIndeterminate,
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  /// به‌روزرسانی progress
  static void update({
    double? progress,
    String? statusText,
    String? fileName,
    bool? isIndeterminate,
  }) {
    if (_overlayEntry == null || _context == null) return;

    if (progress != null) _progress = progress;
    if (statusText != null) _statusText = statusText;
    if (fileName != null) _fileName = fileName;
    if (isIndeterminate != null) _isIndeterminate = isIndeterminate;

    _overlayEntry!.markNeedsBuild();
  }

  /// بستن دیالوگ
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _context = null;
    _progress = 0.0;
    _statusText = null;
  }
}

