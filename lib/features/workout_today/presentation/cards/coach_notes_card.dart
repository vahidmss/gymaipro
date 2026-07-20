import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_speech_card.dart';

class CoachNotesCard extends StatelessWidget {
  const CoachNotesCard({required this.notes, super.key});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    final visible = notes
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .take(3)
        .toList(growable: false);

    return CoachSpeechCard(
      title: ProductCopy.coachNotes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < visible.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == visible.length - 1 ? 0 : GymSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '•  ',
                    style: context.gymTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: context.gymTextPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      visible[i],
                      style: context.gymTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        color: context.gymTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class WorkoutExplainabilityCard extends StatelessWidget {
  const WorkoutExplainabilityCard({required this.reasons, super.key});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final visible = reasons
        .map(ProductCopy.humanizeReason)
        .where((reason) => reason.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    return CoachSpeechCard(
      title: ProductCopy.whyThisSuggestion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < visible.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == visible.length - 1 ? 0 : GymSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '•  ',
                    style: context.gymTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: context.gymTextPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      visible[i],
                      style: context.gymTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        color: context.gymTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
