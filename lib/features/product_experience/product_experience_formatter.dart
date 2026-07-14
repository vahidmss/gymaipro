import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/state/conversation_phase.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_recommendation.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_reason.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_result.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/coach_resolved_program.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';

/// Shared formatter for Coach product surfaces (EPIC 33).
abstract final class ProductExperienceFormatter {
  static CoachRecoverySnapshot recoverySnapshot({
    required CoachContext context,
    CoachIntegrationResult? result,
  }) {
    final profileRecovery = _readInt(context.profile['recovery']);
    final profileFatigue = _readInt(context.profile['fatigue']);
    final profileSleep = _readInt(context.profile['sleep']);
    final profileReadiness = _readInt(context.profile['readiness']);

    var recovery = profileRecovery;
    if (recovery == 0) {
      recovery = _readInt(context.preferences['recovery_score']);
    }
    if (recovery == 0) {
      recovery = _readInt(context.preferences['recovery']);
    }

    var sleep = profileSleep;
    if (sleep == 0) {
      final sleepHours = _readDouble(context.preferences['bb_sleep_hours']);
      if (sleepHours != null) {
        sleep = (sleepHours / 8 * 100).round().clamp(0, 100);
      }
    }

    var fatigue = profileFatigue;
    if (fatigue == 0) {
      final heatmap = context.weeklyHeatmap?.targets;
      if (heatmap != null && heatmap.isNotEmpty) {
        final average =
            heatmap.values.reduce((a, b) => a + b) / heatmap.length;
        fatigue = average.round().clamp(18, 88);
      } else {
        final days = _daysSinceLastWorkout(context);
        if (days != null && days <= 1) {
          fatigue = 58;
        } else if (days != null && days >= 4) {
          fatigue = 24;
        } else {
          fatigue = 36;
        }
      }
    }

    var readiness = profileReadiness;
    if (readiness == 0) {
      readiness =
          ((recovery * 0.55) +
                  ((100 - fatigue) * 0.25) +
                  (sleep * 0.20))
              .round()
              .clamp(0, 100);
    }

    final skillRecovery = result?.skillExecutionResult?.response.structuredData;
    if (skillRecovery != null) {
      final readinessHint = _readInt(skillRecovery['readinessPercent']);
      if (readiness == 0 && readinessHint > 0) readiness = readinessHint;
    }

    return CoachRecoverySnapshot(
      recovery: recovery.clamp(0, 100),
      fatigue: fatigue.clamp(0, 100),
      sleep: sleep.clamp(0, 100),
      readiness: readiness.clamp(0, 100),
    );
  }

  static String coachBrief({
    required CoachContext context,
    required CoachIntegrationResult result,
    required CoachRecoverySnapshot recovery,
    CoachResolvedTodayWorkout? workout,
    List<String> memories = const <String>[],
    List<String> insights = const <String>[],
  }) {
    final lines = <String>[];

    if (recovery.readiness >= 70) {
      lines.add('امروز ریکاوری خوبی داری.');
    } else if (recovery.readiness >= 45) {
      lines.add('امروز می‌توانی با شدت متوسط تمرین کنی.');
    } else if (recovery.readiness > 0) {
      lines.add('امروز بهتر است تمرین سبک‌تری انجام بدهی.');
    }

    if (workout != null && workout.focus.trim().isNotEmpty) {
      lines.add('بهترین زمان برای تمرین ${workout.focus} است.');
      if (workout.durationMinutes > 0) {
        lines.add(
          'جلسه حدود ${workout.durationMinutes} ${ProductCopy.minutes} طول می‌کشد و شدت آن ${workout.intensity} است.',
        );
      }
    } else if (insights.isNotEmpty) {
      final insight = humanizeReason(insights.first);
      if (insight.isNotEmpty) lines.add(insight);
    }

    final goal = context.goals.firstOrNull;
    if (goal != null && goal.trim().isNotEmpty) {
      lines.add('هدف فعلی تو: $goal');
    }

    for (final memory in memories) {
      if (memory.trim().isNotEmpty) lines.add(memory);
    }

    final knowledge = result.decision.knowledgeReasons;
    for (final item in knowledge.take(2)) {
      final text = humanizeReason(item);
      if (text.isNotEmpty) lines.add(text);
    }

    for (var i = 1; i < insights.length; i++) {
      final insight = humanizeReason(insights[i]);
      if (insight.isNotEmpty) lines.add(insight);
    }

    final skillMessage = result.skillExecutionResult?.response.message;
    if (skillMessage != null && skillMessage.trim().isNotEmpty) {
      final localized = humanizeReason(skillMessage);
      if (localized.isNotEmpty && !lines.contains(localized)) {
        lines.add(localized);
      }
    }

    if (lines.isEmpty) {
      return 'هنوز اطلاعات کافی برای جمع‌بندی ندارم؛ یک پیام به مربی بفرست.';
    }

    return lines.join('\n\n');
  }

  static List<String> explainabilityReasons({
    required CoachIntegrationResult result,
    required CoachContext context,
    WorkoutReviewResult? reviewResult,
    List<WorkoutGeneratorReason> generatorReasons = const [],
  }) {
    final reasons = <String>[
      ...generatorReasons.map(
        (reason) => humanizeReason(
          reason.because.isNotEmpty ? reason.because.first : reason.subject,
        ),
      ),
      ...?result.skillExecutionResult?.response.explanation?.bullets.map(
        humanizeReason,
      ),
      ...result.skillExecutionResult?.response.reasons.map(
            (reason) => humanizeReason(reason.message),
          ) ??
          const <String>[],
      ...result.skillExecutionResult?.response.recommendations.map(
            (SkillRecommendation item) => humanizeReason(item.detail),
          ) ??
          const <String>[],
      ...result.decision.notes.map(humanizeReason),
      ...result.decision.knowledgeReasons.map(humanizeReason),
      ...result.responsePlan.notes.map(humanizeReason),
      if (context.weeklyHeatmap?.activityLine != null)
        humanizeReason(context.weeklyHeatmap!.activityLine!),
      if (context.weeklyHeatmap?.programGapLine != null)
        humanizeReason(context.weeklyHeatmap!.programGapLine!),
      if (reviewResult != null) ...reviewSummaryLines(reviewResult),
    ];

    return reasons
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(6)
        .toList(growable: false);
  }

  static List<String> coachNotes(CoachIntegrationResult result) {
    return <String>[
      ...result.skillExecutionResult?.response.warnings ?? const <String>[],
      ...result.skillExecutionResult?.response.nextActions ?? const <String>[],
      ...result.responsePlan.notes,
      ...result.decision.notes,
      ...result.skillExecutionResult?.response.recommendations.map(
            (item) => '${item.title}: ${item.detail}',
          ) ??
          const <String>[],
    ].map(humanizeReason).where((item) => item.isNotEmpty).take(5).toList();
  }

  static List<String> insights(CoachContext context, CoachIntegrationResult result) {
    return <String>[
      if (context.weeklyHeatmap?.programGapLine != null)
        context.weeklyHeatmap!.programGapLine!,
      if (context.weeklyHeatmap?.balanceLine != null)
        context.weeklyHeatmap!.balanceLine!,
      if (context.weeklyHeatmap?.weekTrendLine != null)
        context.weeklyHeatmap!.weekTrendLine!,
      ...result.responsePlan.notes,
      ...result.skillExecutionResult?.response.recommendations.map(
            (item) => item.detail,
          ) ??
          const <String>[],
    ].map(humanizeReason).where((item) => item.isNotEmpty).take(4).toList(growable: false);
  }

  static bool _isTechnicalNoise(String text) {
    final lower = text.toLowerCase();
    return lower.contains('knowledge_node:') ||
        lower.contains('intent matched') ||
        lower.contains('entity overlap') ||
        lower.contains('goal overlap') ||
        lower.contains('restriction overlap') ||
        lower.contains('equipment overlap') ||
        lower.contains('active program available') ||
        lower.contains('conversation state available') ||
        lower.contains('memory relevance') ||
        lower.contains('knowledge priority boost') ||
        lower.contains('with score') ||
        lower.contains('selected workout') ||
        lower.contains('no knowledge node') ||
        lower.contains('minimum ranking threshold') ||
        lower.contains('pipeline started') ||
        lower.contains('generating response') ||
        lower.contains('local coach route') ||
        lower.contains('local skill runtime') ||
        lower.contains('preview used') ||
        lower.contains('explainability') ||
        RegExp(r'score\s*[\d.]+').hasMatch(lower);
  }

  static String humanizeReason(String raw) {
    var text = raw.trim();
    if (text.isEmpty || _isTechnicalNoise(text)) {
      return '';
    }

    text = text
        .replaceAll(RegExp(r'knowledge_node:\w+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bRecovery\b', caseSensitive: false), 'ریکاوری')
        .replaceAll(RegExp(r'\bFatigue\b', caseSensitive: false), 'خستگی')
        .replaceAll(RegExp(r'\bReadiness\b', caseSensitive: false), 'آمادگی')
        .replaceAll(RegExp(r'\bSleep\b', caseSensitive: false), 'خواب')
        .replaceAll(RegExp(r'\bworkoutToday\b'), 'تمرین امروز')
        .replaceAll(RegExp(r'\bworkout_today\b', caseSensitive: false), 'تمرین امروز')
        .replaceAll(
          RegExp(r'\bselected_workout\b', caseSensitive: false),
          'تمرین انتخاب‌شده',
        )
        .replaceAll(RegExp(r'intent matched\s+\w+', caseSensitive: false), '')
        .replaceAll(
          RegExp(
            r'selected\s+\w+\s+with\s+score\s+[\d.]+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\bKeep your form tight\.?', caseSensitive: false),
          'فرم حرکت را حفظ کن.',
        )
        .replaceAll(
          RegExp(r'\bPreview selected today workout\.?', caseSensitive: false),
          'تمرین امروز انتخاب شد.',
        )
        .replaceAll(
          RegExp(r'\bRecovery is ready\.?', caseSensitive: false),
          'ریکاوری مناسب است.',
        )
        .replaceAll(
          RegExp(r'\bOpen Workout Today\b', caseSensitive: false),
          'تمرین امروز را باز کن.',
        )
        .replaceAll(RegExp(r'\bpreview\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    if (text.isEmpty || _isTechnicalNoise(text)) {
      return '';
    }

    if (text.contains('پایین') || text.toLowerCase().contains('low')) {
      return 'چون ریکاوری کامل نبود، تمرین سبک‌تر پیشنهاد شد.';
    }

    return text;
  }

  static String workoutHeadline({
    required CoachResolvedTodayWorkout? workout,
    required CoachIntegrationResult result,
    List<String> muscleGroups = const <String>[],
  }) {
    final skillData =
        result.skillExecutionResult?.response.structuredData ??
        const <String, Object?>{};
    final todaysFocus = skillData['todaysFocus']?.toString();
    if (todaysFocus != null && todaysFocus.trim().isNotEmpty) {
      return 'امروز تمرکز روی $todaysFocus است.';
    }
    if (workout != null && workout.sessionLabel.trim().isNotEmpty) {
      return 'امروز ${workout.sessionLabel} در برنامه است.';
    }
    if (muscleGroups.isNotEmpty) {
      return 'امروز روز تمرین ${muscleGroups.take(2).join(' + ')} است.';
    }
    return 'امروز برنامه تمرینی آماده است.';
  }

  static WorkoutTodayExercise timelineExercise(CoachResolvedExercise exercise) {
    return WorkoutTodayExercise(
      name: exercise.name,
      sets: exercise.sets,
      reps: exercise.reps,
      primaryMuscle: exercise.primaryMuscle,
      restSeconds: exercise.restSeconds,
      tempo: exercise.tempo,
      notes: exercise.notes,
      weightKg: exercise.weightKg,
    );
  }

  static String timelineSubtitle(WorkoutTodayExercise exercise) {
    final parts = <String>[
      if (exercise.primaryMuscle.isNotEmpty) exercise.primaryMuscle,
      '${exercise.sets} × ${exercise.reps}',
      if (exercise.restSeconds != null)
        'استراحت ${exercise.restSeconds} ثانیه',
      if (exercise.tempo != null && exercise.tempo!.isNotEmpty)
        'تمپو ${exercise.tempo}',
    ];
    return parts.join(' • ');
  }

  static List<String> reviewSummaryLines(WorkoutReviewResult review) {
    if (!review.enabled) return const <String>[];
    final lines = <String>[
      humanizeReason(review.summary),
      ...review.recommendations
          .map((item) => humanizeReason(item.action))
          .take(3),
    ];
    return lines.where((item) => item.isNotEmpty).toList(growable: false);
  }

  static List<String> thinkingSteps(CoachIntegrationResult? result) {
    return CoachChatThinkingDefaults.steps;
  }

  static AIIntent intentForQuickAction(String id) {
    return switch (id) {
      'build_program' || 'today_program' || 'today_workout' =>
        AIIntent.workoutToday,
      'modify_program' || 'modify_workout' || 'modify' =>
        AIIntent.workoutModification,
      'review_program' || 'review' => AIIntent.progressAnalysis,
      'replace' || 'replace_exercise' => AIIntent.workoutModification,
      'recovery' => AIIntent.recovery,
      'nutrition' => AIIntent.nutrition,
      'supplements' => AIIntent.supplement,
      'progress' => AIIntent.progressAnalysis,
      'low_motivation' => AIIntent.motivation,
      'ask_coach' || 'ask' => AIIntent.generalChat,
      _ => AIIntent.generalChat,
    };
  }

  static String promptForQuickAction(String id) {
    return switch (id) {
      'build_program' => 'برای من یک برنامه تمرینی بساز',
      'today_program' || 'today_workout' => 'تمرین امروز من چیه؟',
      'modify_program' || 'modify_workout' || 'modify' =>
        'تمرین امروز من را اصلاح کن',
      'review_program' || 'review' => 'برنامه تمرینی من را تحلیل کن',
      'replace' || 'replace_exercise' => 'یک حرکت جایگزین برای تمرین امروز پیشنهاد بده',
      'recovery' => 'ریکاوری من برای تمرین امروز چطوره؟',
      'nutrition' => 'برای تمرین امروز چی بخورم؟',
      'supplements' => 'مکمل‌های امروز من چی باشه؟',
      'progress' => 'پیشرفت تمرینی من را بررسی کن',
      'low_motivation' => 'امروز حوصله تمرین ندارم، چه کار کنم؟',
      'ask_coach' || 'ask' => 'یک سوال از مربی دارم',
      _ => 'به من کمک کن',
    };
  }

  static String localizeFlowType(ConversationFlowType flow) {
    return switch (flow) {
      ConversationFlowType.workoutGeneration => 'ساخت برنامه تمرین',
      ConversationFlowType.progressAnalysis => 'تحلیل پیشرفت',
      ConversationFlowType.onboarding => 'آشنایی اولیه',
      ConversationFlowType.general => 'گفتگوی عمومی',
    };
  }

  static String localizePhase(ConversationPhase phase) {
    return switch (phase) {
      ConversationPhase.notStarted => 'شروع نشده',
      ConversationPhase.greeting => 'خوش‌آمدگویی',
      ConversationPhase.collectingProfile => 'جمع‌آوری پروفایل',
      ConversationPhase.collectingGoals => 'جمع‌آوری اهداف',
      ConversationPhase.collectingRestrictions => 'محدودیت‌ها',
      ConversationPhase.collectingEquipment => 'تجهیزات',
      ConversationPhase.collectingProgressData => 'داده پیشرفت',
      ConversationPhase.reviewingCollectedData => 'بازبینی اطلاعات',
      ConversationPhase.awaitingConfirmation => 'در انتظار تأیید',
      ConversationPhase.readyToExecute => 'آماده اجرا',
      ConversationPhase.completed => 'تکمیل‌شده',
      ConversationPhase.cancelled => 'لغو شده',
      ConversationPhase.expired => 'منقضی شده',
    };
  }

  static String localizeCardTitle(String title) {
    return switch (title) {
      'Reasons' => 'دلایل',
      'Warnings' => 'هشدارها',
      'Recommendations' => 'پیشنهادها',
      'Next Actions' => 'گام بعدی',
      'Coach Notes' => 'یادداشت مربی',
      'Knowledge Insight' => 'بینش تمرینی',
      'Follow-up Question' => 'سؤال بعدی',
      'Trace' => 'جزئیات فنی',
      'Explanation' => 'توضیح',
      _ => title,
    };
  }

  static String quickActionEmoji(String id) {
    return switch (id) {
      'build_program' => '📝',
      'today_workout' || 'today_program' => '🔥',
      'modify_workout' || 'modify_program' || 'modify' => '💪',
      'review_program' || 'review' => '📈',
      'nutrition' => '🍽',
      'recovery' => '😴',
      'replace_exercise' || 'replace' => '💪',
      'low_motivation' => '😌',
      _ => '✨',
    };
  }

  static String quickActionLabel(String id, String fallback) {
    return switch (id) {
      'build_program' => 'ساخت برنامه',
      'today_workout' || 'today_program' => 'تمرین امروز',
      'modify_workout' || 'modify_program' || 'modify' => 'اصلاح برنامه',
      'review_program' || 'review' => 'تحلیل برنامه',
      'nutrition' => 'تغذیه',
      'recovery' => 'ریکاوری',
      'replace_exercise' || 'replace' => 'جایگزین حرکت',
      'low_motivation' => 'امروز حوصله ندارم',
      'ask_coach' || 'ask' => 'پرسش از مربی',
      _ => fallback,
    };
  }

  static String localizePrimaryAction(String label) {
    return switch (label) {
      'Complete Set' => ProductCopy.completeSet,
      ProductCopy.completeSet => ProductCopy.completeSet,
      'Next Exercise' => ProductCopy.nextExercise,
      ProductCopy.nextExercise => ProductCopy.nextExercise,
      'Finish Workout' => ProductCopy.finishWorkout,
      ProductCopy.finishWorkout => ProductCopy.finishWorkout,
      'Skip Rest' => ProductCopy.skipRest,
      ProductCopy.skipRest => ProductCopy.skipRest,
      _ => label,
    };
  }

  static int? _daysSinceLastWorkout(CoachContext context) {
    if (context.workoutHistory.isEmpty) return null;
    final latest = context.workoutHistory
        .map((log) => log.logDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return context.metadata.buildTime.difference(latest).inDays;
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String postWorkoutCoachMessage({
    required String sessionTitle,
    required int completedSets,
    required int previousSessionSets,
    required double totalVolumeKg,
    List<String> coachTips = const <String>[],
  }) {
    if (previousSessionSets > 0 && completedSets > previousSessionSets) {
      return 'امروز عملکردت از جلسه قبل بهتر بود؛ $completedSets ست ثبت کردی.';
    }
    if (totalVolumeKg > 0) {
      return 'جلسه $sessionTitle تمام شد. حجم ${totalVolumeKg.toStringAsFixed(0)} کیلو ثبت شد.';
    }
    if (coachTips.isNotEmpty) {
      return humanizeReason(coachTips.first);
    }
    return 'جلسه $sessionTitle تمام شد. کار خوبی کردی.';
  }

  static List<String> workoutCompletionHighlights({
    required int completedExercises,
    required int totalExercises,
    required int completedSets,
    required int totalSets,
    required double totalVolumeKg,
    List<String> explainability = const <String>[],
  }) {
    final highlights = <String>[
      '$completedExercises از $totalExercises حرکت',
      '$completedSets از $totalSets ست',
      if (totalVolumeKg > 0)
        'حجم کل ${totalVolumeKg.toStringAsFixed(0)} کیلو',
    ];
    highlights.addAll(
      explainability.take(2).map(humanizeReason).where((item) => item.isNotEmpty),
    );
    return highlights;
  }
}

/// Default thinking copy when pipeline trace is unavailable.
abstract final class CoachChatThinkingDefaults {
  static const List<String> steps = <String>[
    'بررسی ریکاوری...',
    'مرور حافظه تمرینی...',
    'بررسی تمرین‌های اخیر...',
    'ساخت پاسخ...',
  ];
}
