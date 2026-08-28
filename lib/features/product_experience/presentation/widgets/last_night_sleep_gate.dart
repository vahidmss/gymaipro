import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/product_experience/recovery/last_night_sleep.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Collects last night's useful sleep hours before recovery metrics.
class LastNightSleepGate extends StatefulWidget {
  const LastNightSleepGate({
    required this.initialHours,
    required this.onSubmit,
    this.isEditing = false,
    this.submitting = false,
    super.key,
  });

  final double initialHours;
  final ValueChanged<double> onSubmit;
  final bool isEditing;
  final bool submitting;

  @override
  State<LastNightSleepGate> createState() => _LastNightSleepGateState();
}

class _LastNightSleepGateState extends State<LastNightSleepGate> {
  late double _hours;

  @override
  void initState() {
    super.initState();
    _hours = LastNightSleep.snap(widget.initialHours);
  }

  @override
  void didUpdateWidget(LastNightSleepGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHours != widget.initialHours) {
      _hours = LastNightSleep.snap(widget.initialHours);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(GymSpacing.xl),
          decoration: BoxDecoration(
            color: context.gymCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.gymBorderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(LucideIcons.moon, size: 18, color: context.gymPrimary),
                  GymSpacing.gapSm,
                  Text(
                    ProductCopy.lastNightSleepTitle,
                    style: context.gymTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              GymSpacing.gapMd,
              Text(
                ProductCopy.lastNightSleepGateBody,
                style: context.gymTextStyle(
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                  color: context.gymTextSecondary,
                ),
              ),
              GymSpacing.gapXxl,
              Center(
                child: Text(
                  LastNightSleep.formatHoursLabel(_hours),
                  style: context.gymTextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: context.gymGold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  ProductCopy.lastNightSleepRangeHint,
                  style: context.gymTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.gymTextTertiary,
                  ),
                ),
              ),
              GymSpacing.gapLg,
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: context.gymGold,
                  inactiveTrackColor: context.gymGold.withValues(alpha: 0.22),
                  thumbColor: context.gymGold,
                  overlayColor: context.gymGold.withValues(alpha: 0.12),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(),
                ),
                child: Slider(
                  value: _hours,
                  min: LastNightSleep.minHours,
                  max: LastNightSleep.maxHours,
                  divisions: LastNightSleep.sliderDivisions,
                  onChanged: widget.submitting
                      ? null
                      : (value) {
                          setState(() {
                            _hours = LastNightSleep.snap(value);
                          });
                        },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    LastNightSleep.formatHoursLabel(LastNightSleep.minHours),
                    style: context.gymTextStyle(
                      fontSize: 12,
                      color: context.gymTextTertiary,
                    ),
                  ),
                  Text(
                    LastNightSleep.formatHoursLabel(LastNightSleep.maxHours),
                    style: context.gymTextStyle(
                      fontSize: 12,
                      color: context.gymTextTertiary,
                    ),
                  ),
                ],
              ),
              GymSpacing.gapLg,
              Text(
                ProductCopy.lastNightSleepHint,
                style: context.gymTextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: context.gymTextSecondary,
                ),
              ),
            ],
          ),
        ),
        GymSpacing.gapXl,
        GymButton(
          label: widget.isEditing
              ? ProductCopy.lastNightSleepUpdate
              : ProductCopy.lastNightSleepSubmit,
          onPressed: widget.submitting
              ? null
              : () => widget.onSubmit(_hours),
          loading: widget.submitting,
          fullWidth: true,
        ),
      ],
    );
  }
}
