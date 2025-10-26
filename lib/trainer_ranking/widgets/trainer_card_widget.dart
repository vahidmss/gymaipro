import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.15),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8.r,
                      offset: Offset(0.w, 4.h),
                    ),
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.05),
                      blurRadius: 12.r,
                      offset: Offset(0.w, 2.h),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        // تصویر مربی + Hero
                        Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (widget.enableHero)
                                  Hero(
                                    tag: _heroTag,
                                    child: Container(
                                      width: 60.w,
                                      height: 60.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.goldColor,
                                            AppTheme.goldColor.withValues(
                                              alpha: 0.7,
                                            ),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.goldColor
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8.r,
                                            offset: Offset(0.w, 2.h),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(2.w),
                                        child: ClipOval(
                                          child: trainer.avatarUrl != null
                                              ? Image.network(
                                                  trainer.avatarUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return _buildDefaultAvatar();
                                                      },
                                                )
                                              : _buildDefaultAvatar(),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 60.w,
                                    height: 60.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.goldColor,
                                          AppTheme.goldColor.withValues(
                                            alpha: 0.7,
                                          ),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.goldColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8.r,
                                          offset: Offset(0.w, 2.h),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(2.w),
                                      child: ClipOval(
                                        child: trainer.avatarUrl != null
                                            ? Image.network(
                                                trainer.avatarUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return _buildDefaultAvatar();
                                                    },
                                              )
                                            : _buildDefaultAvatar(),
                                      ),
                                    ),
                                  ),
                                if (trainer.isOnline ?? false)
                                  Positioned(
                                    bottom: 2.h,
                                    right: 2.w,
                                    child: Container(
                                      padding: EdgeInsets.all(3.w),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF2A2A2A),
                                          width: 1.5.w,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 4.r,
                                            offset: Offset(0.w, 1.h),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        LucideIcons.wifi,
                                        color: Colors.white,
                                        size: 8.sp,
                                      ),
                                    ),
                                  ),
                                // Badge placeholder reserved for future use
                              ],
                            ),
                            SizedBox(height: 6.h),
                            // نمایش رتبه زیر عکس
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.goldColor,
                                    AppTheme.goldColor.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.goldColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 4.r,
                                    offset: Offset(0.w, 1.h),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.trophy,
                                    color: Colors.white,
                                    size: 8.sp,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    '${trainer.ranking ?? 999}',
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.white,
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 12.w),

                        // اطلاعات مربی
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // نام مربی
                              Text(
                                trainer.fullName.isNotEmpty
                                    ? trainer.fullName
                                    : trainer.username,
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.white,
                                  fontSize: widget.compact ? 10.sp : 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 6.h),

                              // Badge مالک باشگاه
                              if (trainer.isGymOwner ?? false)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple,
                                        Colors.purple.withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 4.r,
                                        offset: Offset(0.w, 1.h),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.building,
                                        color: Colors.white,
                                        size: 8.sp,
                                      ),
                                      SizedBox(width: 3.w),
                                      Text(
                                        'مالک باشگاه',
                                        style: GoogleFonts.vazirmatn(
                                          color: Colors.white,
                                          fontSize: widget.compact
                                              ? 7.sp
                                              : 8.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              SizedBox(height: widget.compact ? 4 : 6),

                              // امتیاز و تعداد نظرات
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.star,
                                    color: Colors.amber,
                                    size: 12.sp,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    (trainer.rating ?? 0.0).toStringAsFixed(1),
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.amber,
                                      fontSize: widget.compact ? 10.sp : 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Flexible(
                                    child: Text(
                                      '(${trainer.reviewCount ?? 0} نظر)',
                                      style: GoogleFonts.vazirmatn(
                                        color: Colors.grey[400],
                                        fontSize: widget.compact ? 8.sp : 9.sp,
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
                                  spacing: 3,
                                  runSpacing: 3,
                                  children: trainer.specializations!.map((
                                    String spec,
                                  ) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.goldColor.withValues(
                                              alpha: 0.2,
                                            ),
                                            AppTheme.goldColor.withValues(
                                              alpha: 0.1,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                        border: Border.all(
                                          color: AppTheme.goldColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 0.5.w,
                                        ),
                                      ),
                                      child: Text(
                                        spec,
                                        style: GoogleFonts.vazirmatn(
                                          color: AppTheme.goldColor,
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                              if (!widget.compact) SizedBox(height: 6.h),

                              // اطلاعات اضافی
                              if (!widget.compact)
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.users,
                                      color: Colors.blue,
                                      size: 10.sp,
                                    ),
                                    SizedBox(width: 3.w),
                                    Flexible(
                                      child: Text(
                                        '${trainer.studentCount ?? 0} شاگرد',
                                        style: GoogleFonts.vazirmatn(
                                          color: Colors.grey[400],
                                          fontSize: 9.sp,
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
                                      size: 10.sp,
                                    ),
                                    SizedBox(width: 3.w),
                                    Flexible(
                                      child: Text(
                                        '${trainer.experienceYears ?? 0} سال تجربه',
                                        style: GoogleFonts.vazirmatn(
                                          color: Colors.grey[400],
                                          fontSize: 9.sp,
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

                        // دکمه
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.goldColor.withValues(alpha: 0.2),
                                AppTheme.goldColor.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: AppTheme.goldColor.withValues(alpha: 0.3),
                              width: 0.5.w,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.chevronLeft,
                            color: AppTheme.goldColor,
                            size: 14.sp,
                          ),
                        ),
                      ],
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

  Widget _buildDefaultAvatar() {
    return const ColoredBox(
      color: Color(0xFF3A3A3A),
      child: Icon(LucideIcons.user, color: Colors.white, size: 30),
    );
  }
}
