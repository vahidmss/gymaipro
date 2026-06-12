import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ChatHubLoadingMode { conversations, room }

/// نوار جستجو (هم‌سبک کارت‌های اپ).
class ChatHubSearchBar extends StatelessWidget {
  /// [controller] متن جستجو؛ [onChanged] پس از هر تغییر (اختیاری).
  const ChatHubSearchBar({
    required this.controller,
    super.key,
    this.hint = 'جستجو در گفتگوها',
    this.onChanged,
  });

  /// کنترلر فیلد جستجو.
  final TextEditingController controller;

  /// متن راهنما.
  final String hint;

  /// پس از تغییر متن جستجو.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isDark
                    ? context.separatorColor.withValues(alpha: 0.5)
                    : AppTheme.goldColor.withValues(alpha: 0.12),
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15.sp,
                  color: context.textColor,
                ),
                cursorColor: AppTheme.goldColor,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    color: context.textSecondary,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 20.sp,
                    color: context.textSecondary,
                  ),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'پاک کردن',
                          onPressed: () {
                            controller.clear();
                            onChanged?.call('');
                          },
                          icon: Icon(
                            LucideIcons.x,
                            size: 20.sp,
                            color: context.textSecondary,
                          ),
                        ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// وضعیت بارگذاری حرفه‌ای و سبک (هم‌سبک پیام‌رسان‌های مدرن).
class ChatHubLoadingView extends StatefulWidget {
  /// [title] عنوان اصلی؛ [subtitle] توضیح کوتاه (اختیاری).
  const ChatHubLoadingView({
    super.key,
    this.title = 'در حال همگام‌سازی…',
    this.subtitle,
    this.mode = ChatHubLoadingMode.conversations,
  });

  /// عنوان.
  final String title;

  /// زیرنویس.
  final String? subtitle;
  final ChatHubLoadingMode mode;

  @override
  State<ChatHubLoadingView> createState() => _ChatHubLoadingViewState();
}

class _ChatHubLoadingViewState extends State<ChatHubLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = 0.52 + (_controller.value * 0.36);
        if (widget.mode == ChatHubLoadingMode.room) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62.w,
                    height: 62.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.cardColor,
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.hash,
                      color: AppTheme.goldColor.withValues(alpha: pulse),
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                      color: context.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.subtitle != null) ...[
                    SizedBox(height: 6.h),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5.sp,
                        color: context.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
          children: [
            _buildSyncHeader(context, pulse),
            SizedBox(height: 16.h),
            ...List<Widget>.generate(
              6,
              (index) => _buildSkeletonTile(
                context: context,
                pulse: pulse,
                isDark: isDark,
                longPreview: index.isEven,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncHeader(BuildContext context, double pulse) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: 18.w,
            height: 18.w,
            child: CircularProgressIndicator(
              color: AppTheme.goldColor.withValues(alpha: pulse.clamp(0.55, 1)),
              strokeWidth: 2.2,
              strokeCap: StrokeCap.round,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5.sp,
                    color: context.textColor,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    widget.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonTile({
    required BuildContext context,
    required double pulse,
    required bool isDark,
    required bool longPreview,
  }) {
    final base = isDark
        ? AppTheme.darkTextColor.withValues(alpha: 0.07)
        : AppTheme.veryDarkBackground.withValues(alpha: 0.045);
    final shine = isDark
        ? AppTheme.darkTextColor.withValues(alpha: 0.12 * pulse)
        : AppTheme.veryDarkBackground.withValues(alpha: 0.065 * pulse);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: context.separatorColor.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: base.withValues(alpha: 1),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 96.w,
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: shine.withValues(alpha: 1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: longPreview ? double.infinity : 180.w,
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: base.withValues(alpha: 1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            width: 30.w,
            height: 18.h,
            decoration: BoxDecoration(
              color: base.withValues(alpha: 1),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ],
      ),
    );
  }
}

/// حالت خالی با آیکن در هالهٔ گرادیان.
class ChatHubEmptyView extends StatelessWidget {
  /// [icon]، [title] و [subtitle] پیام راهنما به کاربر.
  const ChatHubEmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  /// آیکن مرکزی.
  final IconData icon;

  /// عنوان.
  final String title;

  /// توضیح.
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.cardColor,
                border: Border.all(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.22 : 0.18,
                  ),
                ),
              ),
              child: Icon(
                icon,
                size: 48.sp,
                color: isDark ? AppTheme.goldColor : AppTheme.darkGold,
              ),
            ),
            SizedBox(height: 28.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 19.sp,
                height: 1.25,
                letterSpacing: -0.2,
                color: context.textColor,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                height: 1.55,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
