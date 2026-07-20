import 'package:gymaipro/ai/coach/coach_decision.dart';
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
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';
import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';

/// Shared formatter for Coach product surfaces (EPIC 33).
abstract final class ProductExperienceFormatter {
  static String? readinessHint(CoachRecoverySnapshot recovery) {
    if (recovery.readiness <= 0 && recovery.daysSinceLastWorkout == null) {
      return null;
    }

    final guidance = RecoveryGuidance.fromSnapshot(
      recovery,
      daysSinceLastWorkout: recovery.daysSinceLastWorkout,
    );

    return switch (guidance.scenario) {
      RecoveryScenario.postSessionToday =>
        'جلسه امروز ثبت شده؛ پایین آمدن آمادگی طبیعیه — امشب روی خواب و ریکاوری تمرکز کن.',
      RecoveryScenario.readyToTrain =>
        'آمادگی امروز خوبه؛ ست‌های اصلی را با تمرکز کامل اجرا کن.',
      RecoveryScenario.trainCautiously =>
        'آمادگی امروز متوسطه؛ با یکی دو ست اول بدن را خوب گرم کن و بعد فشار را بیشتر کن.',
      RecoveryScenario.needsRestOrLighter =>
        'آمادگی امروز پایین‌تره؛ اگر هنوز تمرین نکرده‌ای، فرم دقیق و فشار سبک‌تر بهتره.',
      RecoveryScenario.returningAfterBreak =>
        'چند روز فاصله داشته‌ای؛ با شدت متوسط برگرد، نه با حداکثر توان.',
      RecoveryScenario.unknown => null,
    };
  }

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
      final sleepHours = _readDouble(context.preferences['bb_sleep_hours']) ??
          _readDouble(context.preferences['sleep_hours']);
      if (sleepHours != null && sleepHours > 0) {
        sleep = (sleepHours / 8 * 100).round().clamp(0, 100);
      }
    }

    final daysFromPrefs = _readInt(context.preferences['days_since_last_workout']);
    final hasDaysPref =
        context.preferences.containsKey('days_since_last_workout');
    final days = _daysSinceLastWorkout(context) ??
        (hasDaysPref ? daysFromPrefs : null);

    // If we know rest days but have no stored score, estimate from rest.
    if (recovery == 0 && days != null) {
      recovery = (48 + days * 11).clamp(35, 96);
    }

    var fatigue = profileFatigue;
    if (fatigue == 0) {
      if (days != null) {
        if (days <= 0) {
          fatigue = 62;
        } else if (days == 1) {
          fatigue = 48;
        } else if (days >= 4) {
          fatigue = 22;
        } else {
          fatigue = 34;
        }
      } else {
        final heatmap = context.weeklyHeatmap?.targets;
        if (heatmap != null && heatmap.isNotEmpty) {
          final average =
              heatmap.values.reduce((a, b) => a + b) / heatmap.length;
          fatigue = average.round().clamp(18, 88);
        }
      }
    }

    // Inverse coupling when we have recovery but no fatigue signal.
    if (fatigue == 0 && recovery > 0) {
      fatigue = (100 - recovery).clamp(15, 85);
    }

    var readiness = profileReadiness;
    if (readiness == 0) {
      if (recovery > 0 || fatigue > 0 || sleep > 0) {
        final r = recovery > 0 ? recovery : 55;
        final f = fatigue > 0 ? fatigue : 40;
        final s = sleep > 0 ? sleep : 60;
        readiness =
            ((r * 0.55) + ((100 - f) * 0.25) + (s * 0.20)).round().clamp(0, 100);
      }
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
      daysSinceLastWorkout: days,
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
    CoachRecoverySnapshot? recovery,
  }) {
    final reasons = <String>[
      ..._recoveryExplainability(recovery, context),
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
      if (context.weeklyHeatmap != null) ..._heatmapExplainability(context),
      if (reviewResult != null) ...reviewSummaryLines(reviewResult),
    ];

    return reasons
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(6)
        .toList(growable: false);
  }

  static List<String> _recoveryExplainability(
    CoachRecoverySnapshot? recovery,
    CoachContext context,
  ) {
    if (recovery == null || recovery.readiness <= 0) return const <String>[];
    final lines = <String>[];
    final hint = readinessHint(recovery);
    if (hint != null && hint.isNotEmpty) lines.add(hint);

    final days = recovery.daysSinceLastWorkout ??
        _daysSinceLastWorkout(context) ??
        (context.preferences.containsKey('days_since_last_workout')
            ? _readInt(context.preferences['days_since_last_workout'])
            : null);
    final trainedToday = days != null && days <= 0;

    if (days != null) {
      if (trainedToday) {
        lines.add(
          'جلسه امروز ثبت شده؛ الان فاز ریکاوری است، نه زمان فشار دوباره.',
        );
      } else if (days == 1) {
        lines.add('از آخرین تمرین حدود یک روز گذشته؛ ریکاوری در جریان است.');
      } else {
        lines.add('از آخرین تمرین $days روز گذشته؛ آمادگی‌ات بهتر شده.');
      }
    }

    if (recovery.sleep > 0) {
      if (recovery.sleep >= 75) {
        lines.add(
          trainedToday
              ? 'خوابت خوب بوده؛ امشب هم همین کیفیت را حفظ کن تا ترمیم کامل‌تر شود.'
              : 'خوابت در وضعیت خوبی است و به آمادگی امروز کمک می‌کند.',
        );
      } else if (recovery.sleep < 45) {
        lines.add(
          trainedToday
              ? 'خوابت کمتر از حد ایده‌آل بوده؛ امشب زودتر بخواب تا ریکاوری جبران شود.'
              : 'خوابت کمتر از حد ایده‌آل بوده؛ اگر هنوز تمرین نکرده‌ای شدت را متعادل نگه دار.',
        );
      }
    }
    return lines;
  }

  static List<String> _heatmapExplainability(CoachContext context) {
    final heatmap = context.weeklyHeatmap;
    if (heatmap == null) return const <String>[];
    final lines = <String>[];
    final activity = heatmap.activityLine.trim();
    if (activity.isNotEmpty) {
      lines.add('این هفته $activity تمرین داشته‌ای.');
    }
    final gap = heatmap.programGapLine?.trim();
    if (gap != null && gap.isNotEmpty) {
      lines.add(humanizeReason(gap));
    }
    final trend = heatmap.weekTrendLine?.trim();
    if (trend != null && trend.isNotEmpty) {
      lines.add(humanizeReason(trend));
    }
    final balance = heatmap.balanceLine?.trim();
    if (balance != null && balance.isNotEmpty) {
      lines.add(humanizeReason(balance));
    }
    return lines;
  }

  static List<String> coachNotes(CoachIntegrationResult result) {
    final raw = <String>[
      ...result.skillExecutionResult?.response.warnings ?? const <String>[],
      ...result.skillExecutionResult?.response.nextActions ?? const <String>[],
      ...result.skillExecutionResult?.response.recommendations.map(
            (item) {
              final title = item.title.trim();
              final detail = item.detail.trim();
              if (title.isEmpty) return detail;
              if (detail.isEmpty) return title;
              if (detail.contains(title)) return detail;
              return detail;
            },
          ) ??
          const <String>[],
    ];

    final cleaned = <String>[];
    final seen = <String>{};
    for (final item in raw) {
      final note = _toCoachNote(item);
      if (note == null) continue;
      if (!seen.add(note)) continue;
      cleaned.add(note);
      if (cleaned.length >= 3) break;
    }
    return cleaned;
  }

  /// Turns engine/skill leftovers into one clear Persian coaching line.
  static String? _toCoachNote(String raw) {
    final humanized = humanizeReason(raw).trim();
    if (humanized.isEmpty) return null;
    if (_isTechnicalNoise(humanized)) return null;

    final latin = RegExp(r'[A-Za-z]').allMatches(humanized).length;
    final persian = RegExp(r'[\u0600-\u06FF]').allMatches(humanized).length;
    if (persian < 6 || latin > persian) return null;

    // Drop vague meta lines.
    final lower = humanized.toLowerCase();
    if (lower.contains('status') ||
        lower.contains('score') ||
        lower.contains('route') ||
        lower.contains('entitlement')) {
      return null;
    }

    var note = humanized;
    if (!note.endsWith('.') &&
        !note.endsWith('。') &&
        !note.endsWith('!') &&
        !note.endsWith('؟')) {
      note = '$note.';
    }
    return note;
  }

  static List<String> insights(CoachContext context, CoachIntegrationResult result) {
    return <String>[
      if (context.weeklyHeatmap?.programGapLine != null)
        context.weeklyHeatmap!.programGapLine!,
      if (context.weeklyHeatmap?.balanceLine != null)
        context.weeklyHeatmap!.balanceLine!,
      if (context.weeklyHeatmap?.weekTrendLine != null)
        context.weeklyHeatmap!.weekTrendLine!,
      ...result.skillExecutionResult?.response.recommendations.map(
            (item) => item.detail,
          ) ??
          const <String>[],
    ].map(humanizeReason).where((item) => item.isNotEmpty).take(4).toList(growable: false);
  }

  /// Persian copy for entitlement and pipeline messages surfaced to users.
  static String? localizeSystemMessage(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return null;

    if (lower.contains('upgrade to') && lower.contains('coach')) {
      return 'برای این قابلیت به اشتراک مربی پیشرفته نیاز داری.';
    }
    if (lower.contains('coach capability is not available') ||
        lower.contains('not available for the current entitlement')) {
      return 'این قابلیت در پلن فعلی تو فعال نیست.';
    }
    if (lower.contains('local coach route selected') ||
        lower == 'local coach route selected.') {
      return '';
    }
    if (lower.contains('heatmap snapshot is missing') ||
        lower.contains('local recovery summary is available')) {
      return '';
    }
    if (lower.contains('recovery') &&
        (lower.contains('low') || lower.contains('پایین'))) {
      return 'چون ریکاوری کامل نبود، تمرین سبک‌تر پیشنهاد شد.';
    }

    return null;
  }

  static String localizeEntitlementStatus(CoachDecisionStatus status) {
    return switch (status) {
      CoachDecisionStatus.upgradeRequired =>
        'برای این قابلیت به اشتراک مربی پیشرفته نیاز داری. از بخش اشتراک می‌توانی ارتقا بدهی.',
      CoachDecisionStatus.usageExceeded =>
        'سقف استفاده از این قابلیت امروز تمام شده. فردا دوباره امتحان کن.',
      CoachDecisionStatus.featureDisabled =>
        'این قابلیت در حال حاضر غیرفعال است.',
      CoachDecisionStatus.temporarilyLocked =>
        'این قابلیت موقتاً قفل است. کمی بعد دوباره امتحان کن.',
      CoachDecisionStatus.allowed => '',
    };
  }

  static bool _isTechnicalNoise(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return true;
    if (RegExp(r'^(male|female|other)$').hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'^(general_chat|workout_generation|coach_pro)$').hasMatch(lower)) {
      return true;
    }
    return lower.contains('knowledge_node:') ||
        lower.contains('knowledge node') ||
        lower.contains('selected route source') ||
        lower.contains('entitlement blocked') ||
        lower.contains('upgrade to') ||
        lower.contains('coach capability') ||
        lower.contains('coach_pro') ||
        lower.contains('status:') ||
        lower.contains('is missing required context') ||
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
        lower.contains('requiresai') ||
        lower.contains('openai') ||
        lower.contains('heatmap explanation') ||
        lower.contains('explain heatmap') ||
        RegExp(r'\bgeneral_chat\b').hasMatch(lower) ||
        RegExp(r'\bworkout_generation\b').hasMatch(lower) ||
        RegExp(r'score\s*[\d.]+').hasMatch(lower);
  }

  static String humanizeReason(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return '';

    final localized = localizeSystemMessage(text);
    if (localized != null) return localized;
    if (_isTechnicalNoise(text)) return '';

    text = text
        .replaceAll(RegExp(r'knowledge_node:\w+', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'Knowledge node [\u0600-\u06FFa-zA-Z0-9_]+', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'Entitlement blocked knowledge node [\w_]+\.?', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'selected route source\.?', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\bStatus:\s*\w+\.?', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bHeatmap\b', caseSensitive: false), 'نقشه عضلانی')
        .replaceAll(RegExp(r'هیت[‌\s\-]?مپ'), 'نقشه عضلانی')
        .replaceAll(RegExp(r'\bRPE\b', caseSensitive: false), 'شدت تلاش')
        .replaceAll(RegExp(r'\bOpenAI\b', caseSensitive: false), 'هوش مصنوعی')
        .replaceAll(RegExp(r'\bAI\b'), 'هوش مصنوعی')
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
        .replaceAll(RegExp(r'[ℹ️🔧⚙️✅❌▶️]+'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\s+([.،؟!])'), r'$1')
        .trim();

    if (text.isEmpty || _isTechnicalNoise(text)) {
      return '';
    }

    // Drop English-dominant engine leftovers that weren't mapped.
    final latinCount = RegExp(r'[A-Za-z]').allMatches(text).length;
    final persianCount = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
    if (latinCount >= 6 && latinCount > persianCount) {
      return '';
    }
    if (persianCount == 0 && latinCount >= 3) {
      return '';
    }

    return text;
  }

  static String workoutHeadline({
    required CoachResolvedTodayWorkout? workout,
    CoachIntegrationResult? result,
    List<String> muscleGroups = const <String>[],
  }) {
    final skillData =
        result?.skillExecutionResult?.response.structuredData ??
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

  static String displayMuscle(String? raw) {
    return ExerciseDisplayLabels.musclesCsv(raw);
  }

  static String displayExerciseName({
    required String name,
    String primaryMuscle = '',
    int? exerciseId,
    int? orderIndex,
  }) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && int.tryParse(trimmed) == null) return trimmed;

    final muscle = primaryMuscle.trim();
    if (muscle.isNotEmpty) return displayMuscle(muscle);

    if (exerciseId != null && exerciseId > 0) return 'حرکت $exerciseId';
    if (orderIndex != null) return 'حرکت ${orderIndex + 1}';
    if (trimmed.isNotEmpty) return 'حرکت $trimmed';
    return 'حرکت';
  }

  static WorkoutTodayExercise timelineExercise(CoachResolvedExercise exercise) {
    return WorkoutTodayExercise(
      name: displayExerciseName(
        name: exercise.name,
        primaryMuscle: exercise.primaryMuscle,
        exerciseId: exercise.exerciseId,
      ),
      sets: exercise.sets,
      reps: exercise.reps,
      primaryMuscle: displayMuscle(exercise.primaryMuscle),
      restSeconds: exercise.restSeconds,
      tempo: exercise.tempo,
      notes: exercise.notes,
      weightKg: exercise.weightKg,
    );
  }

  static String timelineSubtitle(WorkoutTodayExercise exercise) {
    final muscle = displayMuscle(exercise.primaryMuscle);
    final parts = <String>[
      if (muscle.isNotEmpty) muscle,
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
      'build_program' => AIIntent.workoutGeneration,
      'today_program' || 'today_workout' => AIIntent.workoutToday,
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
        'برنامه‌ام را اصلاح کن: اگر لازم است حرکت عوض شود، ست کم/زیاد شود، یا جلسه سبک‌تر/سنگین‌تر شود.',
      'review_program' || 'review' => 'برنامه تمرینی من را تحلیل کن',
      'replace' || 'replace_exercise' =>
        'یک حرکت این جلسه را نمی‌توانم بزنم؛ جایگزین مناسب بده و روی برنامه اعمال کن',
      'recovery' => 'ریکاوری من برای تمرین امروز چطوره؟',
      'form' || 'ask_form' || 'form_tip' => ProductCopy.askFormPrompt,
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
    final trimmed = title.trim();
    final mapped = switch (trimmed) {
      'Reasons' => 'دلایل',
      'Warnings' => 'هشدارها',
      'Recommendations' => 'پیشنهادها',
      'Next Actions' => 'گام بعدی',
      'Coach Notes' => 'یادداشت مربی',
      'Knowledge Insight' => 'بینش تمرینی',
      'Follow-up Question' => 'سؤال بعدی',
      'Trace' => 'جزئیات',
      'Explanation' => 'توضیح',
      'Heatmap' || 'Heatmap Explanation' || 'Explain Heatmap' => 'نقشه عضلانی',
      _ => null,
    };
    if (mapped != null) return mapped;

    final latin = RegExp(r'[A-Za-z]').allMatches(trimmed).length;
    final persian = RegExp(r'[\u0600-\u06FF]').allMatches(trimmed).length;
    if (persian == 0 && latin >= 3) return 'جزئیات';
    return trimmed;
  }

  static String quickActionEmoji(String id) {
    return switch (id) {
      'build_program' => '📝',
      'today_workout' || 'today_program' => '🔥',
      'modify_workout' || 'modify_program' || 'modify' => '💪',
      'review_program' || 'review' => '📈',
      'nutrition' => '🍽',
      'recovery' => '😴',
      'form' || 'ask_form' || 'form_tip' => '🎯',
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
      'form' || 'ask_form' || 'form_tip' => ProductCopy.askFormTip,
      'replace_exercise' || 'replace' => 'اصلاح برنامه',
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
    final completedAtRaw =
        context.preferences['last_workout_completed_at']?.toString();
    final completedAt = DateTime.tryParse(completedAtRaw ?? '');
    if (completedAt != null) {
      return context.metadata.buildTime.difference(completedAt).inDays;
    }
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
    String? focus,
    int? durationMinutes,
  }) {
    final parts = <String>[];
    final focusLabel = (focus ?? '').trim();
    if (focusLabel.isNotEmpty) {
      parts.add('جلسه «$focusLabel» ثبت شد.');
    } else {
      parts.add('جلسه $sessionTitle ثبت شد.');
    }
    if (completedSets > 0) {
      parts.add('$completedSets ست کامل کردی');
      if (totalVolumeKg > 0) {
        parts.add('با حجم ${totalVolumeKg.toStringAsFixed(0)} کیلو');
      }
      parts.add('.');
    }
    if (previousSessionSets > 0 && completedSets > previousSessionSets) {
      parts.add(
        ' نسبت به جلسه قبل (${previousSessionSets} ست) پیشرفت داشتی.',
      );
    } else if (previousSessionSets > 0 && completedSets == previousSessionSets) {
      parts.add(' حجم کار امروز هم‌سطح جلسه قبل بود — ثبات خوبه.');
    }
    if (durationMinutes != null && durationMinutes > 0) {
      parts.add(' حدود $durationMinutes دقیقه تمرین کردی.');
    }
    if (coachTips.isNotEmpty) {
      final tip = humanizeReason(coachTips.first).trim();
      if (tip.isNotEmpty) {
        parts.add(' $tip');
      }
    }
    return parts.join('').replaceAll(' .', '.').trim();
  }

  static List<String> workoutCompletionHighlights({
    required int completedExercises,
    required int totalExercises,
    required int completedSets,
    required int totalSets,
    required double totalVolumeKg,
    List<String> explainability = const <String>[],
    String? readinessHint,
  }) {
    final highlights = <String>[
      '$completedExercises از $totalExercises حرکت',
      '$completedSets از $totalSets ست',
      if (totalVolumeKg > 0)
        'حجم کل ${totalVolumeKg.toStringAsFixed(0)} کیلو',
    ];
    if (readinessHint != null && readinessHint.trim().isNotEmpty) {
      highlights.add(humanizeReason(readinessHint));
    }
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
