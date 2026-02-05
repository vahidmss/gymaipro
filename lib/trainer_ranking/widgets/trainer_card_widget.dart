import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TrainerCardWidget extends StatefulWidget {
  const TrainerCardWidget({
    required this.trainer,
    required this.onTap,
    super.key,
    this.compact = false,
    this.enableHero = false,
  });
  final UserProfile trainer;
  final VoidCallback onTap;
  final bool compact;
  final bool enableHero;

  @override
  State<TrainerCardWidget> createState() => _TrainerCardWidgetState();
}

class _TrainerCardWidgetState extends State<TrainerCardWidget> {
  double _tiltX = 0;
  double _tiltY = 0;
  bool _pressed = false;

  void _onPointerMove(PointerEvent e, Size size) {
    final local = e.localPosition;
    final dx = (local.dx - size.width / 2) / (size.width / 2);
    final dy = (local.dy - size.height / 2) / (size.height / 2);
    setState(() {
      _tiltX = (dy.clamp(-1.0, 1.0)) * -6;
      _tiltY = (dx.clamp(-1.0, 1.0)) * 6;
    });
  }

  void _resetTilt() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
      _pressed = false;
    });
  }

  String get _heroTag =>
      'trainer_${widget.trainer.id}_${widget.trainer.username}';

  @override
  Widget build(BuildContext context) {
    final trainer = widget.trainer;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      onPointerUp: (_) => _resetTilt(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, 100);
          return MouseRegion(
            onExit: (_) => _resetTilt(),
            onHover: (e) => _onPointerMove(e, size),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: _resetTilt,
              onTap: () {
                _resetTilt();
                widget.onTap();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_tiltX * 3.1415 / 180)
                  ..rotateY(_tiltY * 3.1415 / 180)
                  ..scale(_pressed ? 0.98 : 1.0),
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.05),
                      blurRadius: 16.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.all(14.w),
                      child: Row(
                        children: [
                          // تصویر مربی + Hero
                          _buildAvatarSection(trainer, isDark),
                          SizedBox(width: 14.w),

                          // اطلاعات مربی
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // نام مربی
                                Text(
                                  trainer.fullName.isNotEmpty
                                      ? trainer.fullName
                                      : trainer.username,
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: widget.compact ? 13.sp : 15.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppTheme.fontFamily,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                SizedBox(height: 6.h),

                                // Badge مالک باشگاه
                                if (trainer.isGymOwner ?? false)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 6.h),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.purple,
                                            Colors.purple.withValues(
                                              alpha: 0.8,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.purple.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 4.r,
                                            offset: Offset(0, 1.h),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.building,
                                            color: Colors.white,
                                            size: 10.sp,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            'مالک باشگاه',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: widget.compact
                                                  ? 8.sp
                                                  : 9.sp,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: AppTheme.fontFamily,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // امتیاز و تعداد نظرات
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.star,
                                      color: Colors.amber,
                                      size: 14.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      (trainer.rating ?? 0.0).toStringAsFixed(
                                        1,
                                      ),
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: widget.compact
                                            ? 12.sp
                                            : 13.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: AppTheme.fontFamily,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(width: 8.w),
                                    Flexible(
                                      child: Text(
                                        '(${trainer.reviewCount ?? 0} نظر)',
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: widget.compact
                                              ? 10.sp
                                              : 11.sp,
                                          fontFamily: AppTheme.fontFamily,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                  ],
                                ),

                                if (!widget.compact) SizedBox(height: 6.h),

                                // تخصص‌ها
                                if (!widget.compact &&
                                    trainer.specializations != null &&
                                    trainer.specializations!.isNotEmpty)
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: trainer.specializations!
                                        .take(2)
                                        .map((String spec) {
                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppTheme.goldColor.withValues(
                                                    alpha: 0.15,
                                                  ),
                                                  AppTheme.goldColor.withValues(
                                                    alpha: 0.08,
                                                  ),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              border: Border.all(
                                                color: AppTheme.goldColor
                                                    .withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              spec,
                                              style: TextStyle(
                                                color: AppTheme.goldColor,
                                                fontSize: 9.sp,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: AppTheme.fontFamily,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),

                                if (!widget.compact) SizedBox(height: 6.h),

                                // اطلاعات اضافی
                                if (!widget.compact)
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.users,
                                        color: Colors.blue,
                                        size: 12.sp,
                                      ),
                                      SizedBox(width: 4.w),
                                      Flexible(
                                        child: Text(
                                          '${trainer.studentCount ?? 0} شاگرد',
                                          style: TextStyle(
                                            color: context.textSecondary,
                                            fontSize: 10.sp,
                                            fontFamily: AppTheme.fontFamily,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Icon(
                                        LucideIcons.clock,
                                        color: Colors.green,
                                        size: 12.sp,
                                      ),
                                      SizedBox(width: 4.w),
                                      Flexible(
                                        child: Text(
                                          '${trainer.experienceYears ?? 0} سال تجربه',
                                          style: TextStyle(
                                            color: context.textSecondary,
                                            fontSize: 10.sp,
                                            fontFamily: AppTheme.fontFamily,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          // دکمه فلش
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.goldColor.withValues(alpha: 0.15),
                                  AppTheme.goldColor.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.chevronLeft,
                              color: AppTheme.goldColor,
                              size: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(UserProfile trainer, bool isDark) {
    final avatarWidget = Container(
      width: 64.w,
      height: 64.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.goldColor,
            AppTheme.goldColor.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(2.5.w),
        child: ClipOval(
          child: trainer.avatarUrl != null
              ? Image.network(
                  trainer.avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar();
                  },
                )
              : _buildDefaultAvatar(),
        ),
      ),
    );

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            if (widget.enableHero)
              Hero(tag: _heroTag, child: avatarWidget)
            else
              avatarWidget,

            // نشان آنلاین
            if (trainer.isOnline ?? false)
              Positioned(
                bottom: 2.h,
                right: 2.w,
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.cardColor, width: 2.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.5),
                        blurRadius: 4.r,
                        offset: Offset(0, 1.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.wifi,
                    color: Colors.white,
                    size: 9.sp,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        // نمایش رتبه زیر عکس
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.goldColor,
                AppTheme.goldColor.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
                blurRadius: 6.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.trophy, color: Colors.white, size: 10.sp),
              SizedBox(width: 4.w),
              Text(
                '${trainer.ranking ?? 999}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: context.separatorColor,
      child: Icon(LucideIcons.user, color: context.textSecondary, size: 32.sp),
    );
  }
}
