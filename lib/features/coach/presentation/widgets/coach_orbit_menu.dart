import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach/presentation/widgets/coach_presence_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One action on the coach orbit ring.
class CoachOrbitAction {
  const CoachOrbitAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
    this.locked = false,
    this.lockedHint,
  });

  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool locked;
  final String? lockedHint;
}

/// Central coach presence with four orbit actions (program / today / meal / chat).
class CoachOrbitMenu extends StatefulWidget {
  const CoachOrbitMenu({
    required this.actions,
    this.coreSize = 140,
    this.orbitRadius = 110,
    super.key,
  });

  final List<CoachOrbitAction> actions;
  final double coreSize;
  final double orbitRadius;

  @override
  State<CoachOrbitMenu> createState() => _CoachOrbitMenuState();
}

class _CoachOrbitMenuState extends State<CoachOrbitMenu>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final AnimationController _ringSpin;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _ringSpin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 48),
    );
    unawaited(_ringSpin.repeat());
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    _ringSpin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extra room for 2-line labels under orbit chips.
    final size = (widget.orbitRadius + 64) * 2;
    final center = size / 2;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              AnimatedBuilder(
                animation: _ringSpin,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _OrbitRingPainter(
                      color: context.gymBorder.withValues(alpha: 0.5),
                      accent: context.gymPrimary.withValues(alpha: 0.35),
                      radius: widget.orbitRadius,
                      rotation: _ringSpin.value * math.pi * 2,
                    ),
                  );
                },
              ),
              ..._buildOrbitItems(center),
              Align(
                child: CoachPresenceCore(size: widget.coreSize),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOrbitItems(double center) {
    // Clock positions: top, right, bottom, left (screen coords, y down).
    const anglesDeg = <double>[-90, 0, 90, 180];
    final actions = widget.actions.take(4).toList();

    return List<Widget>.generate(actions.length, (index) {
      final action = actions[index];
      final rad = anglesDeg[index] * math.pi / 180;
      final dx = math.cos(rad) * widget.orbitRadius;
      final dy = math.sin(rad) * widget.orbitRadius;
      const itemWidth = 86.0;
      const itemHeight = 82.0;
      final delay = 0.12 + index * 0.07;

      return Positioned(
        left: center + dx - itemWidth / 2,
        top: center + dy - itemHeight / 2,
        width: itemWidth,
        height: itemHeight,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, (delay + 0.35).clamp(0.0, 1.0),
                curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  delay,
                  (delay + 0.4).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
            child: _OrbitItemChip(action: action),
          ),
        ),
      );
    });
  }
}

class _OrbitItemChip extends StatelessWidget {
  const _OrbitItemChip({required this.action});

  final CoachOrbitAction action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locked = action.locked;
    final accent = locked ? context.gymTextTertiary : context.gymPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          action.onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: locked ? 0.72 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF1A1A1F)
                          : context.gymCard,
                      border: Border.all(
                        color: accent.withValues(alpha: locked ? 0.35 : 0.55),
                        width: 1.4,
                      ),
                      boxShadow: locked
                          ? null
                          : <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.35 : 0.08,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Icon(action.icon, size: 20, color: accent),
                  ),
                  if (locked)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF1A1A1F)
                              : context.gymCard,
                          border: Border.all(
                            color: context.gymBorderSubtle,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          size: 10,
                          color: context.gymTextTertiary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: GymSpacing.xs),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.gymTextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: locked
                      ? context.gymTextTertiary
                      : context.gymTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({
    required this.color,
    required this.accent,
    required this.radius,
    required this.rotation,
  });

  final Color color;
  final Color accent;
  final double radius;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;

    const dash = 4.5;
    const gap = 5.5;
    final circumference = 2 * math.pi * radius;
    final count = (circumference / (dash + gap)).floor();
    final sweep = (2 * math.pi) / count;

    for (var i = 0; i < count; i++) {
      final start = rotation + i * sweep;
      final isAccent = i % 7 == 0;
      paint.color = isAccent ? accent : color;
      paint.strokeWidth = isAccent ? 1.6 : 1.15;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * (dash / (dash + gap)),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.accent != accent ||
        oldDelegate.radius != radius ||
        oldDelegate.rotation != rotation;
  }
}
