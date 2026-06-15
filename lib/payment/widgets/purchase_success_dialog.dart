import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PurchaseSuccessDialog extends StatefulWidget {
  const PurchaseSuccessDialog({
    required this.serviceName,
    required this.trainerName,
    required this.onViewPrograms,
    super.key,
  });

  final String serviceName;
  final String trainerName;
  final VoidCallback onViewPrograms;

  static Future<void> show(
    BuildContext context, {
    required String serviceName,
    required String trainerName,
    required VoidCallback onViewPrograms,
  }) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return PurchaseSuccessDialog(
          serviceName: serviceName,
          trainerName: trainerName,
          onViewPrograms: onViewPrograms,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  State<PurchaseSuccessDialog> createState() => _PurchaseSuccessDialogState();
}

class _PurchaseSuccessDialogState extends State<PurchaseSuccessDialog>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _particleController;
  late final AnimationController _pulseController;
  late final Animation<double> _checkScale;
  late final Animation<double> _pulseAnimation;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble() * 2 - 1,
        y: _random.nextDouble() * -2,
        speed: 0.5 + _random.nextDouble() * 1.5,
        size: 3 + _random.nextDouble() * 5,
        color: [
          AppTheme.goldColor,
          const Color(0xFFFFD700),
          const Color(0xFFFFA500),
          const Color(0xFF4CAF50),
          Colors.white,
        ][_random.nextInt(5)],
      ));
    }

    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _particleController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimatedCheck(isDark),
                      SizedBox(height: 20.h),
                      _buildTitle(isDark),
                      SizedBox(height: 8.h),
                      _buildSubtitle(isDark),
                      SizedBox(height: 24.h),
                      _buildStatusTimeline(isDark),
                      SizedBox(height: 24.h),
                      _buildInfoCard(isDark),
                      SizedBox(height: 24.h),
                      _buildViewProgramsButton(isDark),
                      SizedBox(height: 12.h),
                      _buildCloseButton(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCheck(bool isDark) {
    return SizedBox(
      width: 100.w,
      height: 100.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(100.w, 100.w),
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              );
            },
          ),
          ScaleTransition(
            scale: _checkScale,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4CAF50),
                          Color(0xFF2E7D32),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.check,
                      color: Colors.white,
                      size: 42.sp,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Text(
      'درخواست شما ثبت شد!',
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 22.sp,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppTheme.lightTextColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(bool isDark) {
    return Text(
      'درخواست ${widget.serviceName} شما با موفقیت ثبت شد.\nمربی ${widget.trainerName} به زودی برنامه شما را آماده می‌کند.',
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 13.sp,
        color: isDark ? Colors.grey[400] : AppTheme.lightTextSecondary,
        height: 1.8,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatusTimeline(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.lightButtonBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          _buildTimelineStep(
            icon: LucideIcons.checkCircle2,
            title: 'پرداخت موفق',
            subtitle: 'پرداخت شما با موفقیت انجام شد',
            isCompleted: true,
            isLast: false,
            isDark: isDark,
          ),
          _buildTimelineStep(
            icon: LucideIcons.clock,
            title: 'در انتظار آماده‌سازی برنامه',
            subtitle: 'مربی در حال آماده‌سازی برنامه شماست',
            isCompleted: false,
            isActive: true,
            isLast: false,
            isDark: isDark,
          ),
          _buildTimelineStep(
            icon: LucideIcons.dumbbell,
            title: 'دریافت و شروع برنامه',
            subtitle: 'برنامه شما آماده استفاده خواهد بود',
            isCompleted: false,
            isLast: true,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isLast,
    required bool isDark,
    bool isActive = false,
  }) {
    final Color activeColor = isCompleted
        ? const Color(0xFF4CAF50)
        : isActive
            ? AppTheme.goldColor
            : isDark
                ? Colors.grey[600]!
                : Colors.grey[400]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(alpha: isCompleted || isActive ? 0.2 : 0.1),
                border: Border.all(color: activeColor, width: 2),
              ),
              child: Icon(icon, color: activeColor, size: 14.sp),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30.h,
                color: isCompleted
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
              ),
          ],
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isCompleted || isActive
                        ? (isDark ? Colors.white : AppTheme.lightTextColor)
                        : (isDark ? Colors.grey[500] : Colors.grey[500]),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, color: AppTheme.goldColor, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'می‌توانید وضعیت درخواست خود را از بخش «برنامه‌های من» پیگیری کنید.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.5.sp,
                color: AppTheme.goldColor,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewProgramsButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          widget.onViewPrograms();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.goldColor,
          foregroundColor: isDark ? AppTheme.onGoldColor : Colors.white,
          elevation: 6,
          shadowColor: AppTheme.goldColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.layoutList, size: 20.sp),
            SizedBox(width: 10.w),
            Text(
              'مشاهده برنامه‌های من',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(bool isDark) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(
        'بعداً',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 14.sp,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
  });
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.progress});
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final angle = math.atan2(particle.y, particle.x);
      final distance = math.sqrt(particle.x * particle.x + particle.y * particle.y);
      final currentDistance = distance * particle.speed * progress * size.width * 0.6;

      final dx = center.dx + math.cos(angle) * currentDistance;
      final dy = center.dy + math.sin(angle) * currentDistance;

      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), particle.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
