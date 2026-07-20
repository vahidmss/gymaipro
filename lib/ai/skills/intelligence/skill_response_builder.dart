import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_data_validator.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_explanation.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_reason.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_reason_type.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_recommendation.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';

/// Builds intelligent local skill responses from existing [CoachContext] data.
///
/// Uses read-only context snapshots only. No prompts, OpenAI, APIs, or new
/// queries are introduced here.
class SkillResponseBuilder {
  const SkillResponseBuilder({
    SkillDataValidator validator = const SkillDataValidator(),
  }) : _validator = validator;

  final SkillDataValidator _validator;

  /// Builds an intelligent workout-today response.
  CoachSkillResponse buildWorkoutToday(CoachContext context) {
    final coverage = _validator.workoutToday(context);
    if (coverage.requiresAI) {
      return CoachSkillResponse(
        confidence: coverage.confidence,
        requiresAI: true,
        reasons: _coverageReasons(coverage),
      );
    }

    final reasons = <SkillReason>[];
    final warnings = <String>[];
    final recommendations = <SkillRecommendation>[];
    final heatmap = context.weeklyHeatmap;
    final goal = _primaryGoal(context);

    if (goal != null) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.goalAlignment,
          message: 'هدف تمرینی: $goal',
          weight: 0.15,
        ),
      );
    }

    if (context.equipment.isNotEmpty) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.equipmentAvailable,
          message: 'تجهیزات در دسترس: ${context.equipment.take(3).join('، ')}',
        ),
      );
    }

    if (_hasRecoverySignal(context)) {
      reasons.add(
        const SkillReason(
          type: SkillReasonType.recoveryStatus,
          message: 'سیگنال ریکاوری در پروفایل موجود است و وضعیت مناسب فرض شد.',
        ),
      );
    }

    final daysSinceWorkout = _daysSinceLastWorkout(context);
    if (daysSinceWorkout != null) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.trainingGap,
          message: 'آخرین جلسه ثبت‌شده $daysSinceWorkout روز پیش بوده است.',
          weight: 0.15,
        ),
      );
    }

    if (heatmap != null && heatmap.hasHeatmapData) {
      // TODO(epic11): Derive per-muscle day gaps via read-only exercise catalog on
      // CoachContext instead of weekly aggregate proxies.
      if (heatmap.balanceLine != null) {
        reasons.add(
          SkillReason(
            type: SkillReasonType.heatmapSignal,
            message: heatmap.balanceLine!,
            weight: 0.15,
          ),
        );
      }
      if (heatmap.weekTrendLine != null) {
        reasons.add(
          SkillReason(
            type: SkillReasonType.progressTrend,
            message: heatmap.weekTrendLine!,
          ),
        );
      }
      if (heatmap.programGapLine != null) {
        reasons.add(
          SkillReason(
            type: SkillReasonType.programContext,
            message: heatmap.programGapLine!,
            weight: 0.15,
          ),
        );
      }
      recommendations.addAll(_undertrainedMuscleRecommendations(heatmap.targets));
    }

    for (final restriction in context.restrictions.take(2)) {
      warnings.add('محدودیت فعال: $restriction');
      reasons.add(
        SkillReason(
          type: SkillReasonType.restrictionAware,
          message: 'محدودیت $restriction در توصیه لحاظ شد.',
          weight: 0.05,
        ),
      );
    }

    final focus = _resolveTodayFocus(
      recommendations: recommendations,
      heatmap: heatmap,
      goal: goal,
    );
    final priority = recommendations.isEmpty ? 'متوسط' : 'بالا';
    final programLabel = _programLabel(context);

    final message = StringBuffer('تمرکز امروز: $focus');
    if (programLabel != null) {
      message.write('\nبرنامه فعال: $programLabel');
    }
    if (recommendations.isNotEmpty) {
      message.write(
        '\nاولویت: ${recommendations.first.title} — ${recommendations.first.detail}',
      );
    }
    if (warnings.isNotEmpty) {
      message.write('\nهشدار: ${warnings.first}');
    }

    final explanation = SkillExplanation(
        summary: 'این تمرکز بر اساس نقشه عضلانی، تاریخچه و هدف فعلی پیشنهاد شد.',
      bullets: reasons.map((reason) => reason.message).take(5).toList(),
    );

    return CoachSkillResponse(
      message: message.toString(),
      confidence: coverage.confidence,
      requiresAI: false,
      structuredData: <String, Object?>{
        'todaysFocus': focus,
        'priority': priority,
        'recommendedMuscles': recommendations
            .map((item) => item.muscleKey)
            .whereType<String>()
            .toList(growable: false),
        'program': context.activeProgram,
      },
      actions: const <CoachAction>[CoachAction.showProgram],
      reasons: reasons,
      explanation: explanation,
      recommendations: recommendations,
      warnings: warnings,
      nextActions: <String>[
        'برنامه امروز را باز کن',
        if (heatmap?.hasHeatmapData ?? false) 'نقشه عضلانی هفته را ببین',
      ],
    );
  }

  /// Builds an intelligent heatmap analysis response.
  CoachSkillResponse buildHeatmap(CoachContext context) {
    final coverage = _validator.heatmap(context);
    final heatmap = context.weeklyHeatmap;
    if (coverage.requiresAI || heatmap == null || !heatmap.hasHeatmapData) {
      return CoachSkillResponse(
        confidence: coverage.confidence,
        requiresAI: true,
        reasons: _coverageReasons(coverage),
      );
    }

    final reasons = <SkillReason>[
      SkillReason(
        type: SkillReasonType.heatmapSignal,
        message: heatmap.activityLine,
        weight: 0.2,
      ),
    ];
    final recommendations = <SkillRecommendation>[];
    final warnings = <String>[];

    final mostTrained = heatmap.topMuscleLabel;
    final leastTrained = heatmap.lightMuscleLabel;
    if (mostTrained != null) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.heatmapSignal,
          message: 'بیشترین بار هفتگی: $mostTrained',
          weight: 0.15,
        ),
      );
    }
    if (leastTrained != null) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.trainingGap,
          message: 'کمترین بار هفتگی: $leastTrained',
          weight: 0.15,
        ),
      );
      recommendations.add(
        SkillRecommendation(
          title: 'تمرکز بعدی',
          detail: 'در جلسه بعدی $leastTrained را تقویت کن.',
          muscleKey: _muscleKeyForLabel(heatmap.targets, leastTrained),
          priority: 1,
        ),
      );
    }

    if (heatmap.balanceLine != null) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.heatmapSignal,
          message: 'نابرابری عضلانی: ${heatmap.balanceLine}',
          weight: 0.15,
        ),
      );
      warnings.add('تعادل عضلانی این هفته به‌هم خورده است.');
    }

    if (heatmap.weekTrendLine != null) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.progressTrend,
          message: heatmap.weekTrendLine!,
        ),
      );
    }

    if (heatmap.programGapLine != null) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.programContext,
          message: heatmap.programGapLine!,
        ),
      );
    }

    final message = StringBuffer('تحلیل نقشه عضلانی هفته')
      ..write('\n${heatmap.activityLine}');
    if (mostTrained != null) {
      message.write('\nبیشترین تمرین: $mostTrained');
    }
    if (leastTrained != null) {
      message.write('\nکمترین تمرین: $leastTrained');
    }
    if (heatmap.balanceLine != null) {
      message.write('\nنابرابری عضلانی: ${heatmap.balanceLine}');
    }
    if (recommendations.isNotEmpty) {
      message.write('\nپیشنهاد: ${recommendations.first.detail}');
    }

    return CoachSkillResponse(
      message: message.toString(),
      confidence: coverage.confidence,
      requiresAI: false,
      structuredData: <String, Object?>{
        'mostTrained': mostTrained,
        'leastTrained': leastTrained,
        'sessionCount': heatmap.sessionCount,
        'workoutDays': heatmap.workoutDays,
        'imbalanceDetected': heatmap.balanceLine != null,
      },
      actions: const <CoachAction>[CoachAction.showHeatmap],
      reasons: reasons,
      explanation: SkillExplanation(
        summary: 'این تحلیل از نقشه عضلانی هفته ساخته شد.',
        bullets: reasons.map((reason) => reason.message).toList(),
      ),
      recommendations: recommendations,
      warnings: warnings,
      nextActions: const <String>[
        'نقشه هفتگی را در بخش پیشرفت باز کن',
        'تمرکز بعدی را در برنامه امروز اعمال کن',
      ],
    );
  }

  /// Builds recovery / readiness guidance from local training signals.
  CoachSkillResponse buildRecovery(CoachContext context) {
    final coverage = _validator.recovery(context);
    final guidance = RecoveryGuidance.fromContext(context);

    final reasons = <SkillReason>[
      SkillReason(
        type: SkillReasonType.recoveryStatus,
        message: guidance.headline,
        weight: 0.35,
      ),
      if (guidance.snapshot.readiness > 0)
        SkillReason(
          type: SkillReasonType.recoveryStatus,
          message: 'آمادگی ${guidance.snapshot.readiness}٪',
          weight: 0.25,
        ),
      if (guidance.daysSinceLastWorkout != null)
        SkillReason(
          type: SkillReasonType.trainingGap,
          message:
              'فاصله از آخرین تمرین: ${guidance.daysSinceLastWorkout} روز',
          weight: 0.15,
        ),
      ..._coverageReasons(coverage),
    ];

    return CoachSkillResponse(
      message: guidance.chatMessage,
      confidence: coverage.confidence.clamp(0.55, 0.95),
      requiresAI: false,
      structuredData: <String, Object?>{
        'readinessPercent': guidance.snapshot.readiness,
        'recovery': guidance.snapshot.recovery,
        'fatigue': guidance.snapshot.fatigue,
        'sleep': guidance.snapshot.sleep,
        'band': guidance.band.name,
        'suggestLighterSession': guidance.suggestLighterSession,
      },
      reasons: reasons,
      explanation: SkillExplanation(
        summary: guidance.headline,
        bullets: guidance.tips,
      ),
      nextActions: <String>[
        if (guidance.suggestLighterSession) 'جلسه را سبک‌تر کن',
        if (guidance.suggestStartWorkout) 'شروع تمرین امروز',
        if (guidance.scenario == RecoveryScenario.postSessionToday)
          'روی خواب و تغذیه امشب تمرکز کن'
        else
          'از مربی بیشتر بپرس',
      ],
    );
  }

  /// Builds a personalized motivation response.
  CoachSkillResponse buildMotivation(CoachContext context) {
    final coverage = _validator.motivation(context);
    if (coverage.requiresAI) {
      return CoachSkillResponse(
        confidence: coverage.confidence,
        requiresAI: true,
        reasons: _coverageReasons(coverage),
      );
    }

    final reasons = <SkillReason>[];
    final question = context.currentQuestion!.trim();
    final goal = _primaryGoal(context);
    final heatmap = context.weeklyHeatmap;
    final tone = _detectMotivationTone(question);

    reasons.add(
      SkillReason(
        type: SkillReasonType.conversationContext,
        message: 'پیام کاربر: $question',
        weight: 0.2,
      ),
    );

    if (goal != null) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.goalAlignment,
          message: 'هدف فعلی: $goal',
          weight: 0.2,
        ),
      );
    }

    if (heatmap != null && heatmap.hasHeatmapData) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.progressTrend,
          message: heatmap.weekTrendLine ?? heatmap.activityLine,
          weight: 0.15,
        ),
      );
    }

    final daysSinceWorkout = _daysSinceLastWorkout(context);
    if (daysSinceWorkout != null) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.trainingGap,
          message: 'آخرین جلسه $daysSinceWorkout روز پیش ثبت شده است.',
        ),
      );
    }

    final message = _personalizedMotivationMessage(
      tone: tone,
      goal: goal,
      heatmap: heatmap,
      daysSinceWorkout: daysSinceWorkout,
    );

    return CoachSkillResponse(
      message: message,
      confidence: coverage.confidence,
      requiresAI: false,
      structuredData: <String, Object?>{
        'tone': tone,
        'goal': goal,
        'daysSinceWorkout': daysSinceWorkout,
      },
      reasons: reasons,
      explanation: SkillExplanation(
        summary: 'پیام انگیزشی بر اساس هدف، روند تمرین و متن کاربر شخصی‌سازی شد.',
        bullets: reasons.map((reason) => reason.message).toList(),
      ),
      nextActions: <String>[
        if (goal != null) 'یک قدم کوچک برای $goal بردار',
        'برنامه امروز را شروع کن',
      ],
    );
  }

  /// Builds contextual app-help guidance.
  CoachSkillResponse buildAppHelp({
    required CoachContext context,
    required AIIntent intent,
  }) {
    final coverage = _validator.appHelp(context: context, intent: intent);
    if (coverage.requiresAI) {
      return CoachSkillResponse(
        confidence: coverage.confidence,
        requiresAI: true,
        reasons: _coverageReasons(coverage),
      );
    }

    final reasons = <SkillReason>[];
    final warnings = <String>[];
    final question = context.currentQuestion!.trim();
    final normalized = question.toLowerCase();

    reasons.add(
      SkillReason(
        type: SkillReasonType.conversationContext,
        message: 'سوال راهنما: $question',
        weight: 0.2,
      ),
    );

    final chatUsage = _chatUsage(context);
    if (chatUsage != null) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.usageLimit,
          message:
              'سهمیه چت: ${chatUsage['daily_used']}/${chatUsage['daily_limit']}',
          weight: 0.15,
        ),
      );
      final remaining = chatUsage['daily_remaining'];
      if (remaining is int && remaining <= 1) {
        warnings.add('سهمیه روزانه چت رو به اتمام است.');
      }
    }

    final progressUsage = _progressUsage(context);
    if (progressUsage != null) {
      reasons.add(
        SkillReason(
          type: SkillReasonType.usageLimit,
          message:
              'تحلیل پیشرفت رایگان: ${progressUsage['free_used']}/${progressUsage['free_limit']}',
        ),
      );
    }

    if (_hasActiveProgram(context)) {
      reasons.add(
        const SkillReason(
          type: SkillReasonType.programContext,
          message: 'برنامه فعال در حساب کاربر موجود است.',
          weight: 0.15,
        ),
      );
    } else {
      reasons.add(
        const SkillReason(
          type: SkillReasonType.programContext,
          message: 'برنامه فعالی ثبت نشده است.',
        ),
      );
    }

    final message = _appHelpMessage(
      normalizedQuestion: normalized,
      hasProgram: _hasActiveProgram(context),
      hasHistory: context.workoutHistory.isNotEmpty,
      chatUsage: chatUsage,
      progressUsage: progressUsage,
    );

    return CoachSkillResponse(
      message: message,
      confidence: coverage.confidence,
      requiresAI: false,
      structuredData: <String, Object?>{
        'question': question,
        'hasActiveProgram': _hasActiveProgram(context),
        'apiUsage': context.apiUsage,
      },
      actions: const <CoachAction>[CoachAction.showChat],
      reasons: reasons,
      explanation: SkillExplanation(
        summary: 'راهنما از وضعیت فعلی کاربر و سهمیه‌های موجود در اپ ساخته شد.',
        bullets: reasons.map((reason) => reason.message).toList(),
      ),
      recommendations: _appHelpRecommendations(normalized),
      warnings: warnings,
      nextActions: _appHelpNextActions(normalized),
    );
  }

  List<SkillReason> _coverageReasons(SkillDataCoverage coverage) {
    return <SkillReason>[
      SkillReason(
        type: SkillReasonType.dataCoverage,
        message:
            'داده کافی برای پاسخ محلی موجود نیست. موجود: ${coverage.presentSignals.join(', ')}',
        weight: coverage.confidence,
      ),
    ];
  }

  String? _primaryGoal(CoachContext context) {
    if (context.goals.isNotEmpty) return context.goals.first;
    final profileGoal = context.profile['goal'] ?? context.profile['fitness_goals'];
    if (profileGoal is String && profileGoal.trim().isNotEmpty) {
      return profileGoal.trim();
    }
    if (profileGoal is Iterable<Object?>) {
      for (final item in profileGoal) {
        final text = item?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }
    return null;
  }

  bool _hasActiveProgram(CoachContext context) {
    final program = context.activeProgram;
    return program != null && program.isNotEmpty;
  }

  bool _hasRecoverySignal(CoachContext context) {
    return context.preferences.containsKey('recovery') ||
        context.preferences.containsKey('recovery_score') ||
        context.preferences.containsKey('bb_sleep_hours');
  }

  String? _programLabel(CoachContext context) {
    final program = context.activeProgram;
    if (program == null) return null;
    return _stringValue(program['name']) ??
        _stringValue(program['title']) ??
        _stringValue(program['program_name']) ??
        _stringValue(program['active_program_id']);
  }

  int? _daysSinceLastWorkout(CoachContext context) {
    if (context.workoutHistory.isEmpty) return null;
    final latest = context.workoutHistory
        .map((log) => log.logDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return context.metadata.buildTime.difference(latest).inDays;
  }

  List<SkillRecommendation> _undertrainedMuscleRecommendations(
    Map<String, int> targets,
  ) {
    const threshold = 18;
    final entries = MuscleTargets.sortedEntries(targets);
    final recommendations = <SkillRecommendation>[];
    for (final entry in entries.reversed) {
      if (entry.value >= threshold) continue;
      recommendations.add(
        SkillRecommendation(
          title: MuscleTargets.label(entry.key),
          detail:
              '${MuscleTargets.label(entry.key)} این هفته بار پایینی دارد و برای تمرکز امروز مناسب است.',
          muscleKey: entry.key,
          priority: recommendations.length + 1,
        ),
      );
      if (recommendations.length >= 3) break;
    }
    return recommendations;
  }

  String _resolveTodayFocus({
    required List<SkillRecommendation> recommendations,
    required WeeklyMuscleHeatmapResult? heatmap,
    required String? goal,
  }) {
    if (recommendations.isNotEmpty) {
      return recommendations.first.title;
    }
    if (heatmap?.lightMuscleLabel != null) {
      return heatmap!.lightMuscleLabel!;
    }
    if (goal != null) {
      return 'تمرین متناسب با $goal';
    }
    return 'تمرین متعادل کل بدن';
  }

  String? _muscleKeyForLabel(Map<String, int> targets, String label) {
    for (final key in targets.keys) {
      if (MuscleTargets.label(key) == label) return key;
    }
    return null;
  }

  String _detectMotivationTone(String question) {
    final normalized = question.toLowerCase();
    if (normalized.contains('ندارم') ||
        normalized.contains('خسته') ||
        normalized.contains('سخت')) {
      return 'supportive';
    }
    if (normalized.contains('انگیزه') || normalized.contains('شروع')) {
      return 'energizing';
    }
    return 'encouraging';
  }

  String _personalizedMotivationMessage({
    required String tone,
    required String? goal,
    required WeeklyMuscleHeatmapResult? heatmap,
    required int? daysSinceWorkout,
  }) {
    final goalPart = goal != null ? ' برای رسیدن به «$goal»' : '';
    final trendPart = heatmap?.weekTrendLine;
    final activityPart = heatmap?.activityLine;

    switch (tone) {
      case 'supportive':
        return trendPart != null
            ? 'هفته‌ات $trendPart است$goalPart. یک جلسه سبک امروز می‌تواند مسیر را دوباره باز کند.'
            : 'فشار ذهنی طبیعی است$goalPart. با یک جلسه کوتاه و هدفمند دوباره ریتم بگیر.';
      case 'energizing':
        return activityPart != null
            ? 'تا اینجای هفته $activityPart داشتی$goalPart. امروز همان انرژی را ادامه بده.'
            : 'بهترین زمان شروع، همین الان است$goalPart. یک قدم کوچک امروز فردا را قوی‌تر می‌کند.';
      default:
        if (daysSinceWorkout != null && daysSinceWorkout >= 4) {
          return 'آخرین جلسه $daysSinceWorkout روز پیش بوده$goalPart. بازگشت با یک تمرین کوتاه از امروز شروع می‌شود.';
        }
        return trendPart != null
            ? 'روند هفته‌ات $trendPart است$goalPart. همین مسیر را با ثبات ادامه بده.'
            : 'مسیر درست را ادامه بده$goalPart — پیشرفت از ثبات ساخته می‌شود.';
    }
  }

  Map<String, Object?>? _chatUsage(CoachContext context) {
    final usage = context.apiUsage['ai_chat'];
    if (usage is Map<String, Object?>) return usage;
    return null;
  }

  Map<String, Object?>? _progressUsage(CoachContext context) {
    final usage = context.apiUsage['progress_analysis'];
    if (usage is Map<String, Object?>) return usage;
    return null;
  }

  String _appHelpMessage({
    required String normalizedQuestion,
    required bool hasProgram,
    required bool hasHistory,
    required Map<String, Object?>? chatUsage,
    required Map<String, Object?>? progressUsage,
  }) {
    final buffer = StringBuffer();

    if (normalizedQuestion.contains('اشتراک') ||
        normalizedQuestion.contains('سهمیه') ||
        normalizedQuestion.contains('limit')) {
      if (chatUsage != null) {
        buffer.write(
          'سهمیه چت امروز: ${chatUsage['daily_used']}/${chatUsage['daily_limit']}. ',
        );
      }
      if (progressUsage != null) {
        buffer.write(
          'تحلیل پیشرفت رایگان: ${progressUsage['free_used']}/${progressUsage['free_limit']}.',
        );
      }
      if (buffer.isEmpty) {
        buffer.write('اطلاعات سهمیه در حساب فعلی در دسترس نیست.');
      }
      return buffer.toString().trim();
    }

    if (normalizedQuestion.contains('برنامه') ||
        normalizedQuestion.contains('program')) {
      return hasProgram
          ? 'برنامه فعال داری. از بخش برنامه تمرینی می‌توانی جلسه امروز را ببینی.'
          : 'هنوز برنامه فعالی ثبت نشده. از بخش برنامه تمرینی یک برنامه فعال انتخاب کن.';
    }

    if (normalizedQuestion.contains('هیت') ||
        normalizedQuestion.contains('heatmap') ||
        normalizedQuestion.contains('نقشه') ||
        normalizedQuestion.contains('پیشرفت')) {
      return hasHistory
          ? 'نقشه عضلانی و پیشرفت هفتگی را در بخش پیشرفت می‌بینی.'
          : 'برای دیدن نقشه عضلانی، ابتدا چند جلسه تمرین ثبت کن.';
    }

    if (normalizedQuestion.contains('چت') ||
        normalizedQuestion.contains('coach') ||
        normalizedQuestion.contains('مربی')) {
      final remaining = chatUsage?['daily_remaining'];
      final suffix = remaining is int ? ' ($remaining پیام باقی‌مانده)' : '';
      return 'می‌توانی همین‌جا با مربی گفتگو کنی$suffix.';
    }

    return hasProgram
        ? 'از منوی اصلی به برنامه، پیشرفت و تنظیمات دسترسی داری. الان هم برنامه فعال داری.'
        : 'از منوی اصلی به برنامه، پیشرفت و تنظیمات دسترسی داری.';
  }

  List<SkillRecommendation> _appHelpRecommendations(String normalizedQuestion) {
    if (normalizedQuestion.contains('برنامه')) {
      return const <SkillRecommendation>[
        SkillRecommendation(
          title: 'برنامه تمرینی',
          detail: 'از بخش برنامه، جلسه امروز را بررسی کن.',
          priority: 1,
        ),
      ];
    }
    if (normalizedQuestion.contains('پیشرفت') ||
        normalizedQuestion.contains('هیت') ||
        normalizedQuestion.contains('نقشه')) {
      return const <SkillRecommendation>[
        SkillRecommendation(
          title: 'پیشرفت هفتگی',
          detail: 'نقشه عضلانی هفته را در بخش پیشرفت ببین.',
          priority: 1,
        ),
      ];
    }
    return const <SkillRecommendation>[];
  }

  List<String> _appHelpNextActions(String normalizedQuestion) {
    if (normalizedQuestion.contains('برنامه')) {
      return const <String>['بخش برنامه تمرینی را باز کن'];
    }
    if (normalizedQuestion.contains('پیشرفت') ||
        normalizedQuestion.contains('هیت')) {
      return const <String>['بخش پیشرفت را باز کن'];
    }
    return const <String>['منوی اصلی را باز کن'];
  }

  String? _stringValue(Object? value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString();
  }
}
