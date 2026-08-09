import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/services/water_log_service.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نوار فشرده ثبت آب — آبی ملایم، بدون طلا.
class WaterIntakeStrip extends StatefulWidget {
  const WaterIntakeStrip({
    required this.date,
    required this.targetMl,
    this.userId,
    super.key,
  });

  final DateTime date;
  final int targetMl;
  final String? userId;

  @override
  State<WaterIntakeStrip> createState() => _WaterIntakeStripState();
}

class _WaterIntakeStripState extends State<WaterIntakeStrip> {
  final _service = WaterLogService();
  int _ml = 0;
  bool _ready = false;

  static const _water = Color(0xFF2B9EB3);
  static const _waterDeep = Color(0xFF1A7A8C);
  static const _waterSoft = Color(0xFFE8F6F8);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant WaterIntakeStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date.year != widget.date.year ||
        oldWidget.date.month != widget.date.month ||
        oldWidget.date.day != widget.date.day ||
        oldWidget.userId != widget.userId) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final ml = await _service.getMl(
      date: widget.date,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _ml = ml;
      _ready = true;
    });
  }

  Future<void> _add() async {
    unawaited(HapticFeedback.selectionClick());
    final next = await _service.addGlass(
      date: widget.date,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _ml = next);
  }

  Future<void> _remove() async {
    if (_ml <= 0) return;
    unawaited(HapticFeedback.lightImpact());
    final next = await _service.removeGlass(
      date: widget.date,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _ml = next);
  }

  Future<void> _setGlasses(int glasses) async {
    unawaited(HapticFeedback.selectionClick());
    final next = glasses * WaterLogService.glassMl;
    await _service.setMl(
      date: widget.date,
      ml: next,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _ml = next);
  }

  static String _formatLiters(double liters) {
    if (liters <= 0) return '0';
    if (liters >= 10) return liters.round().toString();
    final s = liters.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MealLogColors.isDark(context);
    final target = widget.targetMl;
    final glassSlots = WaterLogService.glassCountForTarget(target);
    final filled = (_ml / WaterLogService.glassMl).floor();
    final liters = _ml / 1000;
    final targetLiters = target / 1000;
    final currentFa = MealLogUtils.convertToPersianNumbers(
      _formatLiters(liters),
    );
    final targetFa = MealLogUtils.convertToPersianNumbers(
      _formatLiters(targetLiters),
    );
    final accent = isDark ? const Color(0xFF7DD3E0) : _waterDeep;

    return AnimatedOpacity(
      opacity: _ready ? 1 : 0.55,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: EdgeInsets.only(top: 6.h, bottom: 2.h),
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 10.w, 10.h),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF102428)
              : _waterSoft.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark
                ? _water.withValues(alpha: 0.35)
                : _water.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: _water.withValues(alpha: isDark ? 0.22 : 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.droplets,
                    size: 16.sp,
                    color: accent,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'آب امروز',
                        style: MealLogTypography.statLabel(context).copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: MealLogColors.mutedText(context),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text.rich(
                        textDirection: TextDirection.rtl,
                        TextSpan(
                          children: [
                            TextSpan(
                              text: currentFa,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: accent,
                                height: 1.05,
                              ),
                            ),
                            TextSpan(
                              text: ' لیتر',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: MealLogColors.mutedText(context),
                              ),
                            ),
                            TextSpan(
                              text: '  از  ',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: MealLogColors.hintText(context),
                              ),
                            ),
                            TextSpan(
                              text: targetFa,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: MealLogColors.secondaryText(context),
                              ),
                            ),
                            TextSpan(
                              text: ' لیتر',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: MealLogColors.hintText(context),
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                _RoundIconButton(
                  icon: LucideIcons.minus,
                  enabled: _ml > 0,
                  onTap: _remove,
                  color: _waterDeep,
                ),
                SizedBox(width: 4.w),
                _RoundIconButton(
                  icon: LucideIcons.plus,
                  enabled: true,
                  onTap: _add,
                  color: _waterDeep,
                  filled: true,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              textDirection: TextDirection.rtl,
              children: List.generate(glassSlots, (i) {
                final isFilled = i < filled;
                final isPartial =
                    i == filled && (_ml % WaterLogService.glassMl) > 0;
                final fill = isFilled
                    ? 1.0
                    : (isPartial
                          ? (_ml % WaterLogService.glassMl) /
                                WaterLogService.glassMl
                          : 0.0);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: GestureDetector(
                      onTap: () => _setGlasses(i + 1),
                      onLongPress: () => _setGlasses(i),
                      child: _WaterGlass(
                        fill: fill,
                        color: _water,
                        deep: _waterDeep,
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_ml == 0) ...[
              SizedBox(height: 6.h),
              Text(
                MealLogUtils.convertToPersianNumbers(
                  'هر لیوان ${WaterLogService.glassMl} میلی‌لیتر',
                ),
                style: MealLogTypography.caption(
                  context,
                  color: MealLogColors.hintText(context),
                  fontWeight: FontWeight.w500,
                ).copyWith(fontSize: 9.5.sp),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.enabled = true,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool enabled;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999.r),
        child: Ink(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? color.withValues(alpha: enabled ? 0.9 : 0.35)
                : color.withValues(alpha: enabled ? 0.12 : 0.05),
            border: filled
                ? null
                : Border.all(
                    color: color.withValues(alpha: enabled ? 0.45 : 0.2),
                  ),
          ),
          child: Icon(
            icon,
            size: 14.sp,
            color: filled
                ? Colors.white
                : color.withValues(alpha: enabled ? 1 : 0.4),
          ),
        ),
      ),
    );
  }
}

class _WaterGlass extends StatelessWidget {
  const _WaterGlass({
    required this.fill,
    required this.color,
    required this.deep,
  });

  final double fill;
  final Color color;
  final Color deep;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fill.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return AspectRatio(
          aspectRatio: 0.62,
          child: CustomPaint(
            painter: _GlassPainter(
              fill: value,
              color: color,
              deep: deep,
              track: MealLogColors.isDark(context)
                  ? Colors.white.withValues(alpha: 0.12)
                  : color.withValues(alpha: 0.2),
            ),
          ),
        );
      },
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({
    required this.fill,
    required this.color,
    required this.deep,
    required this.track,
  });

  final double fill;
  final Color color;
  final Color deep;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final glass = Path()
      ..moveTo(w * 0.18, h * 0.08)
      ..lineTo(w * 0.82, h * 0.08)
      ..lineTo(w * 0.72, h * 0.92)
      ..quadraticBezierTo(w * 0.5, h * 1.02, w * 0.28, h * 0.92)
      ..close();

    final rim = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(glass, rim);

    if (fill <= 0.01) return;

    canvas.save();
    canvas.clipPath(glass);
    final waterTop = h * (0.92 - 0.78 * fill);
    final waterRect = Rect.fromLTRB(0, waterTop, w, h);
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.75),
          deep.withValues(alpha: 0.95),
        ],
      ).createShader(waterRect);
    canvas.drawRect(waterRect, waterPaint);

    final wave = Path()..moveTo(0, waterTop);
    for (var x = 0.0; x <= w; x += 2) {
      final y = waterTop + math.sin(x / w * math.pi * 2) * 1.2;
      wave.lineTo(x, y);
    }
    wave
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      wave,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.restore();
    canvas.drawPath(glass, rim);
  }

  @override
  bool shouldRepaint(covariant _GlassPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.color != color ||
      oldDelegate.deep != deep ||
      oldDelegate.track != track;
}
