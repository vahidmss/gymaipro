import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

class CoachNotesCard extends StatelessWidget {
  const CoachNotesCard({required this.notes, super.key});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: double.infinity,
        padding: GymSpacing.card,
        decoration: BoxDecoration(
          color: GymColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(GymSpacing.xl),
            topRight: Radius.circular(GymSpacing.xl),
            bottomLeft: Radius.circular(GymSpacing.xl),
            bottomRight: Radius.circular(GymSpacing.sm),
          ),
          border: Border.all(color: GymColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              ProductCopy.coachNotes,
              style: GymTypography.overline.copyWith(
                color: GymColors.textTertiary,
              ),
            ),
            GymSpacing.gapMd,
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: GymSpacing.sm),
                child: Text(
                  note,
                  style: GymTypography.body.copyWith(
                    fontSize: 15,
                    height: 1.65,
                    color: GymColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WorkoutExplainabilityCard extends StatelessWidget {
  const WorkoutExplainabilityCard({required this.reasons, super.key});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) return const SizedBox.shrink();

    return GymExpandableCard(
      title: ProductCopy.whyThisSuggestion,
      variant: GymCardVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final reason in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: GymSpacing.md),
              child: Text(
                ProductCopy.humanizeReason(reason),
                style: GymTypography.body.copyWith(
                  fontSize: 15,
                  height: 1.6,
                  color: GymColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
