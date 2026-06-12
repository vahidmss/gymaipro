import 'package:flutter/material.dart';
import 'package:gymaipro/guide/models/guide_sequence.dart';
import 'package:gymaipro/guide/services/guide_service.dart';
import 'package:gymaipro/guide/widgets/feature_showcase_overlay.dart';
import 'package:provider/provider.dart';

/// ویجت اصلی برای نمایش feature tour
class FeatureTourWidget extends StatelessWidget { // اگر مشخص شده، فقط این راهنما رو نمایش بده

  const FeatureTourWidget({
    required this.child, super.key,
    this.guideId,
  });
  final Widget child;
  final String? guideId;

  @override
  Widget build(BuildContext context) {
    return Consumer<GuideService>(
      builder: (context, guideService, _) {
        if (!guideService.hasActiveGuide) {
          return child;
        }

        final activeGuide = guideService.activeGuide!;
        
        // اگر guideId مشخص شده، فقط اون راهنما رو نمایش بده
        if (guideId != null && activeGuide.id != guideId) {
          return child;
        }

        final currentStep = activeGuide.steps[guideService.currentStepIndex];

        return Stack(
          children: [
            child,
            FeatureShowcaseOverlay(
              step: currentStep,
              currentIndex: guideService.currentStepIndex,
              totalSteps: activeGuide.stepCount,
              isFirstStep: guideService.isFirstStep,
              isLastStep: guideService.isLastStep,
              onNext: () {
                if (guideService.isLastStep) {
                  guideService.completeGuide();
                } else {
                  guideService.nextStep();
                }
              },
              onPrevious: guideService.isFirstStep
                  ? null
                  : () {
                      guideService.previousStep();
                    },
              onSkip: ({bool dontShowAgain = false}) {
                guideService.skipGuide(dontShowAgain: dontShowAgain);
              },
            ),
          ],
        );
      },
    );
  }
}

/// تابع کمکی برای شروع راهنما
Future<void> startGuide(
  BuildContext context,
  String guideId,
) async {
  final guideService = Provider.of<GuideService>(context, listen: false);

  if (guideService.shouldShowGuide(guideId)) {
    // تاخیر کوتاه برای اطمینان از render شدن ویجت‌ها
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await guideService.startGuide(guideId);
  }
}

/// تابع کمکی برای ثبت راهنما
void registerGuide(
  BuildContext context,
  GuideSequence guide,
) {
  final guideService = Provider.of<GuideService>(context, listen: false);
  guideService.registerGuide(guide);
}

