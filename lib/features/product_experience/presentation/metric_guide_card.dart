import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';

class MetricGuideCard extends StatelessWidget {
  const MetricGuideCard({
    required this.title,
    required this.value,
    required this.explanation,
    this.hint,
    super.key,
  });

  final String title;
  final String value;
  final String explanation;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: GymCardVariant.insight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(title, style: context.gymTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.gymTextSecondary,
                )),
              ),
              IconButton(
                tooltip: 'راهنما',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showGuide(context),
                icon: Icon(Icons.info_outline_rounded, color: context.gymPrimary),
              ),
            ],
          ),
          Text(
            value,
            style: context.gymTextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: context.gymTextPrimary,
            ),
          ),
          if (hint != null && hint!.trim().isNotEmpty) ...<Widget>[
            GymSpacing.gapSm,
            Text(
              hint!,
              style: context.gymTextStyle(
                fontSize: 13,
                color: context.gymTextSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.gymCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(GymSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: context.gymTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.gymTextPrimary,
                  ),
                ),
                GymSpacing.gapMd,
                Text(
                  explanation,
                  style: context.gymTextStyle(
                    fontSize: 14,
                    color: context.gymTextSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void showMetricGuideDialog(
  BuildContext context, {
  required String title,
  required String explanation,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.gymCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GymSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: context.gymTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.gymTextPrimary,
              ),
            ),
            GymSpacing.gapMd,
            Text(
              explanation,
              style: context.gymTextStyle(
                fontSize: 14,
                color: context.gymTextSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
