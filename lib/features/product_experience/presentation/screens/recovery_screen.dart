import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach/presentation/widgets/coach_hub_sections.dart';
import 'package:gymaipro/features/coach_chat/navigation/coach_chat_navigation.dart';
import 'package:gymaipro/features/live_workout/navigation/live_workout_route.dart';
import 'package:gymaipro/features/product_experience/application/recovery_facade.dart';
import 'package:gymaipro/features/product_experience/domain/program_modify_options.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_navigation.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';
import 'package:gymaipro/features/product_experience/training_metric_guides.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_speech_card.dart';

/// Dedicated readiness / recovery surface — metrics + local coach guidance.
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({this.facade, super.key});

  final RecoveryFacade? facade;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  late final RecoveryFacade _facade;
  bool _loading = true;
  String? _error;
  RecoveryGuidance? _guidance;

  @override
  void initState() {
    super.initState();
    _facade = widget.facade ?? RecoveryFacade();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _facade.load();
      if (!mounted) return;
      setState(() {
        _guidance = result.guidance;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openLighterSession() async {
    await HapticFeedback.selectionClick();
    if (!mounted) return;
    await ProgramModifyNavigation.open(
      context,
      quickActionId: 'modify',
      initialRequest: ProgramModifyGoal.tiredAdapt.buildRequestText(),
    );
  }

  Future<void> _askCoach() async {
    await HapticFeedback.selectionClick();
    if (!mounted) return;
    final guidance = _guidance;
    final prompt = switch (guidance?.scenario) {
      RecoveryScenario.postSessionToday =>
        'جلسه امروزم را کامل کردم. برای ریکاوری امشب و آمادگی جلسه بعد چه کارهایی پیشنهاد می‌کنی؟',
      RecoveryScenario.needsRestOrLighter =>
        'آمادگی‌ام پایین است و هنوز تمرین امروز را شروع نکرده‌ام؛ سبک‌تر تمرین کنم یا استراحت؟',
      RecoveryScenario.returningAfterBreak =>
        'چند روز تمرین نکرده‌ام؛ برای برگشت چطور شروع کنم؟',
      _ => guidance == null
          ? 'ریکاوری من برای تمرین امروز چطوره و چه شدت و رویکردی مناسب‌تر است؟'
          : 'با توجه به آمادگی ${guidance.snapshot.readiness}٪ و '
              'خستگی ${guidance.snapshot.fatigue}، '
              'برای تمرین امروز چه پیشنهادی داری؟',
    };
    await CoachChatNavigation.open(
      context,
      initialPrompt: prompt,
      quickActionId: 'ask_coach',
    );
  }

  Future<void> _startWorkout() async {
    await HapticFeedback.selectionClick();
    if (!mounted) return;
    await Navigator.of(context).pushNamed(LiveWorkoutRoute.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return GymPageScaffold(
      title: ProductCopy.recovery,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const GymPagePadding(
        child: Column(
          children: <Widget>[
            GymSkeleton(height: 120),
            SizedBox(height: GymSpacing.lg),
            GymSkeleton(height: 160),
          ],
        ),
      );
    }

    if (_error != null) {
      return GymPagePadding(
        child: GymErrorState(
          title: 'خطا در بارگذاری ریکاوری',
          message: _error!,
          onRetry: () => unawaited(_load()),
        ),
      );
    }

    final guidance = _guidance;
    if (guidance == null) {
      return const GymPagePadding(
        child: GymEmptyState(
          title: 'داده ریکاوری نیست',
          message: 'بعد از ثبت جلسه تمرین، آمادگی اینجا دیده می‌شود.',
        ),
      );
    }

    final readiness = guidance.snapshot.readiness;
    return GymPagePadding(
      child: ListView(
        children: <Widget>[
          Text(
            TrainingMetricGuides.readinessTitle,
            style: context.gymTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.gymTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            guidance.headline,
            style: context.gymTextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          if (readiness > 0) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              guidance.scenario == RecoveryScenario.postSessionToday
                  ? 'آمادگی فعلی $readiness٪ — بعد از جلسه طبیعی است پایین‌تر باشد.'
                  : 'آمادگی فعلی $readiness٪',
              style: context.gymTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.gymTextSecondary,
              ),
            ),
          ],
          GymSpacing.gapLg,
          CoachStatusMonitor(recovery: guidance.snapshot),
          GymSpacing.gapLg,
          CoachSpeechCard(
            title: 'توصیه مربی',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  guidance.body,
                  style: context.gymTextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (guidance.tips.isNotEmpty) ...<Widget>[
                  GymSpacing.gapMd,
                  ...guidance.tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $tip',
                        style: context.gymTextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: context.gymTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          GymSpacing.gapXl,
          if (guidance.suggestLighterSession) ...<Widget>[
            GymButton(
              label: 'جلسه را سبک‌تر کن',
              onPressed: () => unawaited(_openLighterSession()),
              fullWidth: true,
            ),
            GymSpacing.gapMd,
          ],
          if (guidance.suggestStartWorkout) ...<Widget>[
            GymButton(
              label: guidance.scenario == RecoveryScenario.returningAfterBreak
                  ? 'شروع جلسه برگشت'
                  : 'شروع تمرین',
              onPressed: () => unawaited(_startWorkout()),
              fullWidth: true,
            ),
            GymSpacing.gapMd,
          ],
          GymButton(
            label: guidance.scenario == RecoveryScenario.postSessionToday
                ? 'سوال درباره ریکاوری امشب'
                : 'از مربی بیشتر بپرس',
            onPressed: () => unawaited(_askCoach()),
            variant: GymButtonVariant.secondary,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
