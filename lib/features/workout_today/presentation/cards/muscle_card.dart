import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_chip.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/workout_today_base_card.dart';

class MuscleCard extends StatelessWidget {
  const MuscleCard({required this.muscles, super.key});

  final List<String> muscles;

  @override
  Widget build(BuildContext context) {
    return WorkoutTodayBaseCard(
      variant: GymCardVariant.insight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'نقشه عضلات',
            style: GymTypography.caption.copyWith(color: GymColors.textTertiary),
          ),
          GymSpacing.gapLg,
          Center(
            child: SizedBox(
              width: 150,
              height: 220,
              child: CustomPaint(
                painter: _MuscleHighlightPainter(muscles: muscles),
              ),
            ),
          ),
          GymSpacing.gapLg,
          Wrap(
            spacing: GymSpacing.sm,
            runSpacing: GymSpacing.sm,
            children: muscles
                .map(
                  (muscle) => GymChip(
                    label: muscle,
                    variant: GymChipVariant.filled,
                    selected: true,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MuscleHighlightPainter extends CustomPainter {
  const _MuscleHighlightPainter({required this.muscles});

  final List<String> muscles;

  bool _targets(String keyword) {
    return muscles.any((muscle) => muscle.contains(keyword));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = GymColors.textPrimary.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final highlight = Paint()
      ..color = GymColors.textPrimary.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, 24);
    canvas
      ..drawCircle(center, 18, outline)
      ..drawLine(
        Offset(size.width / 2, 45),
        Offset(size.width / 2, 125),
        outline,
      )
      ..drawLine(Offset(size.width / 2, 62), const Offset(28, 92), outline)
      ..drawLine(
        Offset(size.width / 2, 62),
        Offset(size.width - 28, 92),
        outline,
      )
      ..drawLine(Offset(size.width / 2, 125), const Offset(44, 198), outline)
      ..drawLine(
        Offset(size.width / 2, 125),
        Offset(size.width - 44, 198),
        outline,
      );

    if (_targets('سینه') || _targets('بالاسینه')) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width / 2, 76),
          width: 72,
          height: 42,
        ),
        0.1,
        3,
        false,
        highlight,
      );
    }
    if (_targets('بازو') || _targets('پشت بازو') || _targets('جلو بازو')) {
      canvas
        ..drawLine(const Offset(30, 92), const Offset(12, 132), highlight)
        ..drawLine(
          Offset(size.width - 30, 92),
          Offset(size.width - 12, 132),
          highlight,
        );
    }
    if (_targets('پا') || _targets('ران') || _targets('ساق')) {
      canvas
        ..drawLine(Offset(size.width / 2, 125), const Offset(44, 198), highlight)
        ..drawLine(
          Offset(size.width / 2, 125),
          Offset(size.width - 44, 198),
          highlight,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _MuscleHighlightPainter oldDelegate) {
    return oldDelegate.muscles != muscles;
  }
}
