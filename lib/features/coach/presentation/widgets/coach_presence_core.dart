import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/theme/app_theme.dart';

// Presence mark intentionally has no human face — brand + motion only.

/// Gender-neutral GymAI coach presence — living gold core, no face.
///
/// Large size: breathing glow, dual rotating rings, monogram.
/// Compact size: quiet pulse + spark mark for chat / speech chips.
class CoachPresenceCore extends StatefulWidget {
  const CoachPresenceCore({
    this.size = 140,
    this.compact = false,
    super.key,
  });

  final double size;
  final bool compact;

  @override
  State<CoachPresenceCore> createState() => _CoachPresenceCoreState();
}

class _CoachPresenceCoreState extends State<CoachPresenceCore>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  AnimationController? _spin;
  AnimationController? _counter;
  AnimationController? _sweep;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.compact ? 3200 : 2600),
    );
    unawaited(_pulse.repeat(reverse: true));

    if (!widget.compact) {
      _spin = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 22),
      );
      _counter = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 14),
      );
      _sweep = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 4800),
      );
      unawaited(_spin!.repeat());
      unawaited(_counter!.repeat());
      unawaited(_sweep!.repeat());
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spin?.dispose();
    _counter?.dispose();
    _sweep?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.goldColor;
    final size = widget.size;
    final listenables = <Listenable>[_pulse];
    if (_spin != null) listenables.add(_spin!);
    if (_counter != null) listenables.add(_counter!);
    if (_sweep != null) listenables.add(_sweep!);

    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) {
        final breath = Curves.easeInOut.transform(_pulse.value);
        final glow = widget.compact
            ? 0.16 + breath * 0.12
            : 0.22 + breath * (isDark ? 0.28 : 0.18);
        final scale = 1 + breath * (widget.compact ? 0.02 : 0.028);

        return SizedBox(
          width: size,
          height: size,
          child: Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: gold.withValues(alpha: glow),
                        blurRadius: size * 0.28,
                        spreadRadius: size * 0.02,
                      ),
                      if (!widget.compact)
                        BoxShadow(
                          color: gold.withValues(alpha: glow * 0.45),
                          blurRadius: size * 0.42,
                          spreadRadius: size * 0.06,
                        ),
                    ],
                  ),
                ),
                CustomPaint(
                  size: Size.square(size),
                  painter: _PresencePainter(
                    gold: gold,
                    isDark: isDark,
                    spin: (_spin?.value ?? 0) * math.pi * 2,
                    counter: -(_counter?.value ?? 0) * math.pi * 2,
                    sweep: _sweep?.value ?? 0,
                    breath: breath,
                    compact: widget.compact,
                  ),
                ),
                if (!widget.compact) _Monogram(size: size, gold: gold),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.size, required this.gold});

  final double size;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'GymAI',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: size * 0.16,
            fontWeight: FontWeight.w800,
            letterSpacing: size * 0.012,
            height: 1,
            color: context.gymPrimary,
            shadows: <Shadow>[
              Shadow(
                color: gold.withValues(alpha: 0.55),
                blurRadius: size * 0.08,
              ),
            ],
          ),
        ),
        SizedBox(height: size * 0.035),
        Text(
          'مربی هوشمند',
          style: context.gymTextStyle(
            fontSize: size * 0.075,
            fontWeight: FontWeight.w600,
            color: context.gymTextSecondary.withValues(alpha: 0.85),
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _PresencePainter extends CustomPainter {
  _PresencePainter({
    required this.gold,
    required this.isDark,
    required this.spin,
    required this.counter,
    required this.sweep,
    required this.breath,
    required this.compact,
  });

  final Color gold;
  final bool isDark;
  final double spin;
  final double counter;
  final double sweep;
  final double breath;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Core disc
    final coreR = r * (compact ? 0.92 : 0.78);
    final disc = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          isDark ? const Color(0xFF1A1710) : const Color(0xFFFFF8E7),
          isDark ? const Color(0xFF0B0B0E) : const Color(0xFFF5E6C8),
          isDark ? const Color(0xFF050506) : const Color(0xFFE8D4A8),
        ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreR));
    canvas.drawCircle(center, coreR, disc);

    // Inner vignette rim
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.035
      ..shader = SweepGradient(
        colors: <Color>[
          gold.withValues(alpha: 0.15),
          gold.withValues(alpha: 0.75),
          gold.withValues(alpha: 0.2),
          gold.withValues(alpha: 0.85),
          gold.withValues(alpha: 0.15),
        ],
        transform: GradientRotation(spin * 0.35),
      ).createShader(Rect.fromCircle(center: center, radius: coreR));
    canvas.drawCircle(center, coreR - r * 0.01, rim);

    if (compact) {
      _paintSpark(canvas, center, r * 0.38, gold.withValues(alpha: 0.22));
      _paintSpark(canvas, center, r * 0.28, gold.withValues(alpha: 0.92));
      return;
    }

    // Outer dashed ring
    _paintDashedRing(
      canvas,
      center,
      r * 0.96,
      gold.withValues(alpha: 0.55 + breath * 0.2),
      spin,
      dash: 0.11,
      gap: 0.07,
      stroke: r * 0.018,
    );

    // Counter arc (living tip)
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.028
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: <Color>[
          Colors.transparent,
          gold.withValues(alpha: 0.05),
          gold.withValues(alpha: 0.95),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.55, 0.82, 1.0],
        transform: GradientRotation(counter),
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.88));
    canvas.drawCircle(center, r * 0.88, arcPaint);

    // Soft aurora sweep across core
    final sweepAngle = sweep * math.pi * 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle);
    final aurora = Paint()
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Colors.transparent,
          gold.withValues(alpha: isDark ? 0.14 : 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(-coreR, -coreR, coreR * 2, coreR * 2));
    canvas.drawCircle(Offset.zero, coreR * 0.92, aurora);
    canvas.restore();

    // Micro nodes on ring
    for (var i = 0; i < 4; i++) {
      final a = spin + i * (math.pi / 2);
      final p = Offset(
        center.dx + math.cos(a) * r * 0.96,
        center.dy + math.sin(a) * r * 0.96,
      );
      canvas.drawCircle(
        p,
        r * 0.028,
        Paint()..color = gold.withValues(alpha: 0.85),
      );
      canvas.drawCircle(
        p,
        r * 0.055,
        Paint()..color = gold.withValues(alpha: 0.18),
      );
    }

    _paintSpark(canvas, center, r * 0.22, gold.withValues(alpha: 0.12));
  }

  void _paintDashedRing(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double rotation, {
    required double dash,
    required double gap,
    required double stroke,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final step = dash + gap;
    final count = (math.pi * 2 / step).floor();
    for (var i = 0; i < count; i++) {
      final start = rotation + i * step;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dash,
        false,
        paint,
      );
    }
  }

  void _paintSpark(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 - math.pi / 2;
      final rr = i.isEven ? radius : radius * 0.38;
      final p = Offset(
        center.dx + math.cos(a) * rr,
        center.dy + math.sin(a) * rr,
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PresencePainter oldDelegate) {
    return oldDelegate.spin != spin ||
        oldDelegate.counter != counter ||
        oldDelegate.sweep != sweep ||
        oldDelegate.breath != breath ||
        oldDelegate.gold != gold ||
        oldDelegate.isDark != isDark ||
        oldDelegate.compact != compact;
  }
}
