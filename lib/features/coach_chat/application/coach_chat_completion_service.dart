import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/context/coach_profile_metrics.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/prompt/prompt_package_renderer.dart';
import 'package:gymaipro/ai/services/openai_coach_turn.dart';
import 'package:gymaipro/ai/tools/coach_chat_tool_executor.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_program_policy.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/utils/auth_helper.dart';

/// Resolves the final coach chat text — local skill, local decision, or OpenAI.
class CoachChatCompletionService {
  CoachChatCompletionService({
    OpenAiCoachTurn? coachTurn,
    CoachChatToolExecutor? toolExecutor,
  }) : _coachTurn = coachTurn ?? OpenAiCoachTurn(),
       _toolExecutor = toolExecutor ?? CoachChatToolExecutor();

  final OpenAiCoachTurn _coachTurn;
  final CoachChatToolExecutor _toolExecutor;

  /// Recent chat turns forwarded to the model alongside the system prompt.
  static const int _historyWindow = 12;

  Future<String> resolveResponse({
    required CoachIntegrationResult result,
    required String userMessage,
    List<ChatMessage> history = const <ChatMessage>[],
    AIIntent? intent,
    void Function(String partial)? onPartial,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in resolveResponseStream(
      result: result,
      userMessage: userMessage,
      history: history,
      intent: intent,
    )) {
      buffer.write(chunk);
      onPartial?.call(buffer.toString());
    }
    return buffer.toString().trim();
  }

  /// Yields text as it arrives (local answers yield once; AI may stream).
  Stream<String> resolveResponseStream({
    required CoachIntegrationResult result,
    required String userMessage,
    List<ChatMessage> history = const <ChatMessage>[],
    AIIntent? intent,
  }) async* {
    if (CoachChatProgramPolicy.shouldBlockChatProgramDelivery(
      intent: intent ?? result.intent,
      knowledgeId: result.decision.selectedKnowledgeId,
      userMessage: userMessage,
    )) {
      yield CoachChatProgramPolicy.redirectMessage;
      return;
    }

    final resolvedIntent = intent ?? result.intent;

    // Nutrition-today must beat local skills AND the LLM — both invent
    // «نتونستم اطلاعات تغذیه رو بگیرم» when context is thin.
    final nutritionAnswer = await _directNutritionTodayAnswer(
      result: result,
      userMessage: userMessage,
      intent: resolvedIntent,
    );
    if (nutritionAnswer != null) {
      debugPrint(
        '[CoachChat] nutrition_short_circuit '
        'len=${nutritionAnswer.length}',
      );
      yield nutritionAnswer;
      return;
    }

    final skillMessage = result.skillExecutionResult?.response.message?.trim();
    if (result.isLocalResponse &&
        skillMessage != null &&
        skillMessage.isNotEmpty &&
        !_shouldSkipLocalSkillForEngineAnswer(
          userMessage: userMessage,
          intent: resolvedIntent,
          history: history,
        )) {
      final localized = ProductExperienceFormatter.humanizeReason(skillMessage);
      if (localized.isNotEmpty) {
        yield localized;
        return;
      }
    }

    final bodyMetricsAnswer = _directBodyMetricsAnswer(
      result: result,
      userMessage: userMessage,
      history: history,
    );
    if (bodyMetricsAnswer != null) {
      yield bodyMetricsAnswer;
      return;
    }

    final localText = _pickLocalText(result);
    final entitlementBlocked =
        result.decision.status != CoachDecisionStatus.allowed;
    if (entitlementBlocked) {
      final blocked = localText?.trim();
      yield (blocked != null && blocked.isNotEmpty)
          ? blocked
          : _genericFallback(result, userMessage);
      return;
    }

    final preferDirectAiAnswer = _preferDirectAiAnswer(resolvedIntent);
    final needsGuidedFollowUp =
        result.decision.requiresFollowUp ||
        result.decision.missingData.isNotEmpty ||
        (result.conversationState?.pendingQuestions.isNotEmpty ?? false);

    if (needsGuidedFollowUp &&
        !preferDirectAiAnswer &&
        localText != null &&
        localText.trim().isNotEmpty) {
      yield localText;
      return;
    }

    if (result.decision.shouldCallAI || preferDirectAiAnswer) {
      final promptPackage = result.promptPackage;
      if (promptPackage != null) {
        try {
          final systemPrompt = PromptPackageRenderer.render(promptPackage);
          final recentHistory = history
              .where(
                (message) =>
                    !message.isTyping && message.content.trim().isNotEmpty,
              )
              .toList(growable: false);
          var trimmedHistory = recentHistory.length <= _historyWindow
              ? recentHistory
              : recentHistory.sublist(recentHistory.length - _historyWindow);
          // Avoid duplicating the current user turn when the caller already
          // included it in [history].
          if (trimmedHistory.isNotEmpty) {
            final last = trimmedHistory.last;
            if (last.type == ChatMessageType.user &&
                last.content.trim() == userMessage.trim()) {
              trimmedHistory = trimmedHistory.sublist(
                0,
                trimmedHistory.length - 1,
              );
            }
          }

          final userId =
              AuthHelper.currentUserIdSync ??
              result.coachContext.profile['id']?.toString() ??
              '';

          var emitted = false;
          await for (final chunk in _coachTurn.run(
            userId: userId,
            messages: <ChatMessage>[
              ...trimmedHistory,
              ChatMessage.user(content: userMessage),
            ],
            systemPrompt: systemPrompt,
            enableTools: true,
          )) {
            if (chunk.isEmpty) continue;
            emitted = true;
            yield chunk;
          }
          if (emitted) return;
        } on Object {
          if (localText != null) {
            yield localText;
            return;
          }
          yield 'الان نتوانستم به سرور هوش مصنوعی وصل شوم. لطفاً دوباره امتحان کن.';
          return;
        }
      } else if (result.decision.shouldCallAI) {
        yield localText ?? _genericFallback(result, userMessage);
        return;
      }
    }

    if (needsGuidedFollowUp &&
        localText != null &&
        localText.trim().isNotEmpty) {
      yield localText;
      return;
    }

    final resolved = localText ?? _genericFallback(result, userMessage);
    yield resolved.trim().isEmpty
        ? _genericFallback(result, userMessage)
        : resolved;
  }

  bool _preferDirectAiAnswer(AIIntent intent) {
    return switch (intent) {
      AIIntent.generalFitness ||
      AIIntent.generalChat ||
      AIIntent.nutrition ||
      AIIntent.supplement ||
      AIIntent.exerciseQuestion ||
      AIIntent.workoutQuestion => true,
      _ => false,
    };
  }

  /// Local workout/skill cards must not hijack readiness / weight-trend /
  /// nutrition questions that need engine facts or tools.
  bool _shouldSkipLocalSkillForEngineAnswer({
    required String userMessage,
    required AIIntent intent,
    List<ChatMessage> history = const <ChatMessage>[],
  }) {
    if (_looksLikeWeightTrend(userMessage)) return true;
    if (_looksLikeReadiness(userMessage) && intent != AIIntent.recovery) {
      return true;
    }
    // Always prefer the deterministic nutrition short-circuit over skills.
    if (_looksLikeNutritionToday(userMessage)) return true;
    if (_looksLikeBodyCompositionQuestion(userMessage, history: history) &&
        !_looksLikeWeightTrend(userMessage)) {
      // Let the dedicated BMI short-circuit answer run.
      return true;
    }
    return false;
  }

  bool _looksLikeWeightTrend(String userMessage) {
    final text = userMessage.trim().toLowerCase();
    return text.contains('روند وزن') ||
        text.contains('تغییر وزن') ||
        text.contains('وزن کم') ||
        text.contains('وزن زیاد') ||
        text.contains('وزنم چطور') ||
        text.contains('وزن من چطور') ||
        (text.contains('وزن') &&
            (text.contains('روند') ||
                text.contains('پیشرفت') ||
                text.contains('هفته') ||
                text.contains('ماه')));
  }

  bool _looksLikeReadiness(String userMessage) {
    final text = userMessage.trim().toLowerCase();
    return text.contains('آمادگی') ||
        text.contains('آمادگیم') ||
        text.contains('آماده') ||
        text.contains('ریکاوری') ||
        text.contains('readiness') ||
        text.contains('recovery');
  }

  bool _looksLikeNutritionToday(String userMessage) {
    final text = userMessage.trim().toLowerCase();
    return text.contains('کالری') ||
        text.contains('پروتئین') ||
        text.contains('شام') ||
        text.contains('ناهار') ||
        text.contains('صبحانه') ||
        text.contains('غذا') ||
        text.contains('تغذیه') ||
        text.contains('ماکرو') ||
        text.contains('چیزی بخورم') ||
        text.contains('چی بخورم') ||
        text.contains('چقدر خوردم') ||
        text.contains('امروز چی خوردم');
  }

  Future<String?> _directNutritionTodayAnswer({
    required CoachIntegrationResult result,
    required String userMessage,
    AIIntent? intent,
  }) async {
    // Intent alone is too broad (e.g. «رژیم میخوام؟»); require today/macro cues.
    if (!_looksLikeNutritionToday(userMessage)) return null;

    var nutrition = Map<String, Object?>.from(result.coachContext.nutrition);

    // Always hit the live engine so the model cannot invent "نتونستم بگیرم".
    try {
      String userId = '';
      try {
        userId =
            AuthHelper.currentUserIdSync ??
            result.coachContext.profile['id']?.toString() ??
            '';
      } on Object {
        userId = result.coachContext.profile['id']?.toString() ?? '';
      }
      final raw = await _toolExecutor.execute(
        name: 'get_nutrition_today',
        userId: userId,
      );
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final live = Map<String, Object?>.from(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
        // Prefer live payload when it has usable nutrition facts.
        if (live['summary_fa'] != null || live['daily_targets'] != null) {
          nutrition = live;
        }
      }
    } on Object {
      // Keep context nutrition.
    }

    final summary = nutrition['summary_fa']?.toString().trim();
    final targets = nutrition['daily_targets'];
    final targetCal = targets is Map
        ? _readInt(targets['calories_kcal'])
        : null;
    final targetPro = targets is Map ? _readInt(targets['protein_g']) : null;
    final maintenanceCal = targets is Map
        ? _readInt(targets['maintenance_kcal'])
        : null;
    final hasActiveGoal = targets is Map && targets['has_active_goal'] == true;
    final today = nutrition['today'];
    final consumed = today is Map ? today['consumed'] : null;
    final remaining = nutrition['remaining'];

    final buffer = StringBuffer();
    if (summary != null && summary.isNotEmpty) {
      buffer.writeln(summary);
    } else if (targetCal != null) {
      if (hasActiveGoal) {
        buffer.writeln(
          'هدف کالری‌ات حدود $targetCal است'
          '${maintenanceCal == null ? '' : ' (برای حفظ وزن حدود $maintenanceCal)'}'
          '${targetPro == null ? '' : '؛ پروتئین هدف حدود $targetPro گرم'}.',
        );
      } else {
        buffer.writeln(
          'نیاز تقریبی روزانه‌ات برای حفظ وزن حدود $targetCal کالری است '
          'و هنوز هدف کالری جدا نگذاشتی'
          '${targetPro == null ? '' : '؛ پروتئین پیشنهادی حدود $targetPro گرم'}.',
        );
      }
      if (consumed is Map) {
        final usedCal = _readInt(consumed['calories_kcal']) ?? 0;
        final usedPro = _readInt(consumed['protein_g']) ?? 0;
        buffer.writeln(
          'امروز تا الان $usedCal کالری'
          '${targetPro == null ? '' : ' و $usedPro گرم پروتئین'} ثبت شده.',
        );
      } else {
        buffer.writeln('امروز هنوز غذایی ثبت نشده.');
      }
    } else {
      // Never fall through to the LLM for nutrition-today questions —
      // it often invents «نتونستم اطلاعات تغذیه رو بگیرم».
      return 'الان عدد دقیق کالری/پروتئین از پروفایل در دسترس نبود. '
          'قد و وزن را در پروفایل چک کن و از بخش تغذیه وعده‌های امروز را '
          'ثبت کن، بعد دوباره همین سوال را بپرس.';
    }

    final remainCal = remaining is Map
        ? _readInt(remaining['calories_kcal'])
        : (consumed is Map && targetCal != null
              ? (targetCal - (_readInt(consumed['calories_kcal']) ?? 0)).clamp(
                  0,
                  targetCal,
                )
              : targetCal);
    final remainPro = remaining is Map
        ? _readInt(remaining['protein_g'])
        : (consumed is Map && targetPro != null
              ? (targetPro - (_readInt(consumed['protein_g']) ?? 0)).clamp(
                  0,
                  targetPro,
                )
              : targetPro);

    final asksDinner =
        userMessage.contains('شام') || userMessage.contains('بخورم');
    if (asksDinner) {
      buffer.writeln();
      if ((remainCal ?? 0) <= 150) {
        buffer.writeln(
          'برای شام جا زیاد نیست؛ یک وعده سبک پروتئینی '
          '(مثلاً سفیده تخم‌مرغ / ماست یونانی / کمی مرغ) با سبزیجات بهتر است.',
        );
      } else {
        buffer.writeln(
          'برای شام حدود ${remainCal ?? '—'} کالری'
          '${remainPro == null ? '' : ' و تا $remainPro گرم پروتئین'} جا داری: '
          'مرغ/ماهی + سبزیجات، و برنج/سیب‌زمینی را متناسب با کالری باقی‌مانده تنظیم کن.',
        );
      }
    } else if ((remainCal ?? 0) > 0) {
      buffer.writeln(
        hasActiveGoal
            ? 'هنوز حدود $remainCal کالری'
                  '${remainPro == null ? '' : ' و $remainPro گرم پروتئین'} تا هدف جا داری.'
            : 'هنوز حدود $remainCal کالری'
                  '${remainPro == null ? '' : ' و $remainPro گرم پروتئین'} '
                  'تا نیاز روزانه جا داری.',
      );
    }

    buffer.writeln(
      'اگر لاگ امروز ناقص است، از بخش تغذیه همان وعده‌ها را ثبت کن تا عدد دقیق‌تر شود.',
    );
    return buffer.toString().trim();
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  bool _looksLikeBodyCompositionQuestion(
    String userMessage, {
    List<ChatMessage> history = const <ChatMessage>[],
  }) {
    final text = userMessage.trim().toLowerCase();
    if (text.isEmpty) return false;
    // Weight *trend* is not a BMI short-circuit question.
    if (_looksLikeWeightTrend(text)) return false;

    const needles = <String>[
      'اضافه وزن',
      'اضافه‌وزن',
      'چاقی',
      'لاغر',
      'کمبود وزن',
      'بی ام آی',
      'بی‌ام‌آی',
      'bmi',
      'چربی بدن',
      'درصد چربی',
      'قد و وزن',
      'اضافه وزن دارم',
      'چاقم',
      'وزنم چند',
      'وزن من چند',
      'چند کیلوام',
      'چند کیلو هستم',
    ];
    for (final needle in needles) {
      if (text.contains(needle)) return true;
    }
    if (text == 'وزنم' || text == 'وزنم؟') return true;
    if (_isShortKgFollowUp(text) && _recentHistoryMentionsBody(history)) {
      return true;
    }
    return false;
  }

  bool _isShortKgFollowUp(String text) {
    final t = text.replaceAll('؟', '').replaceAll('?', '').trim();
    return t == 'چند کیلو' ||
        t == 'چندکیلو' ||
        t == 'چقدر' ||
        t == 'چه قدر' ||
        t == 'چقد';
  }

  bool _recentHistoryMentionsBody(List<ChatMessage> history) {
    final recent = history.length <= 6
        ? history
        : history.sublist(history.length - 6);
    for (final message in recent) {
      final content = message.content.trim().toLowerCase();
      if (content.contains('اضافه وزن') ||
          content.contains('اضافه‌وزن') ||
          content.contains('bmi') ||
          content.contains('بی ام آی') ||
          content.contains('بی‌ام‌آی') ||
          content.contains('چاقی') ||
          content.contains('چاق')) {
        return true;
      }
    }
    return false;
  }

  String? _directBodyMetricsAnswer({
    required CoachIntegrationResult result,
    required String userMessage,
    List<ChatMessage> history = const <ChatMessage>[],
  }) {
    if (!_looksLikeBodyCompositionQuestion(userMessage, history: history)) {
      return null;
    }

    final profile = Map<String, Object?>.from(result.coachContext.profile);
    CoachProfileMetrics.enrich(profile);

    final recentUserMessages = history
        .where((m) => m.type == ChatMessageType.user && !m.isTyping)
        .map((m) => m.content)
        .where((c) => c.trim().isNotEmpty)
        .toList(growable: false);

    final answer = CoachProfileMetrics.answerForQuestion(
      enrichedProfile: profile,
      userMessage: userMessage,
      recentUserMessages: recentUserMessages,
    );
    if (answer != null && answer.isNotEmpty) return answer;

    final height = CoachProfileMetrics.readDouble(
      profile,
      CoachProfileMetrics.heightKeys,
    );
    final weight = CoachProfileMetrics.readDouble(
      profile,
      CoachProfileMetrics.weightKeys,
    );
    if (height == null || weight == null) {
      return 'برای جواب دقیق به سوال اضافه‌وزن/BMI، قد و وزنت را در پروفایل کامل کن '
          '(یا همین‌جا قد به سانتی‌متر و وزن به کیلو را بگو).';
    }
    return null;
  }

  String? _pickLocalText(CoachIntegrationResult result) {
    final entitlement = _entitlementMessage(result);
    if (entitlement != null) return entitlement;

    final pending = result.conversationState?.pendingQuestions;
    if (pending != null && pending.isNotEmpty) {
      final prompt = pending.last.prompt.trim();
      if (prompt.isNotEmpty) {
        return ProductExperienceFormatter.humanizeReason(prompt);
      }
    }

    for (final candidate in <String?>[
      result.decision.followUpQuestion,
      result.responsePlan.localMessage,
      result.decision.localResponse,
    ]) {
      if (candidate == null || candidate.trim().isEmpty) continue;
      final localized = ProductExperienceFormatter.humanizeReason(candidate);
      if (localized.isNotEmpty) return localized;
    }

    return null;
  }

  String? _entitlementMessage(CoachIntegrationResult result) {
    final status = result.decision.status;
    if (status == CoachDecisionStatus.allowed) return null;

    final localized = ProductExperienceFormatter.localizeEntitlementStatus(
      status,
    );
    if (localized.isNotEmpty) return localized;

    final localResponse = result.decision.localResponse;
    if (localResponse == null || localResponse.trim().isEmpty) return null;
    final humanized = ProductExperienceFormatter.humanizeReason(localResponse);
    return humanized.isNotEmpty ? humanized : null;
  }

  String _genericFallback(CoachIntegrationResult result, String userMessage) {
    if (CoachChatProgramPolicy.looksLikeProgramRequest(userMessage)) {
      return CoachChatProgramPolicy.redirectMessage;
    }

    final trimmed = userMessage.trim();
    final normalized = trimmed.toLowerCase();
    if (trimmed == 'سلام' ||
        normalized == 'hello' ||
        normalized == 'hi' ||
        trimmed == 'درود') {
      final firstName = result.coachContext.profile['first_name']
          ?.toString()
          .trim();
      if (firstName != null && firstName.isNotEmpty) {
        return 'سلام $firstName! امروز چطور می‌تونم کمکت کنم؟';
      }
      return 'سلام! من مربی GymAI هستم. درباره تمرین امروز، ریکاوری یا تکنیک بپرس.';
    }

    return 'با داده‌ای که ازت دارم جواب می‌دم. اگر جزئیات بیشتری خواستی بپرس — '
        'مثلاً تمرین امروز، تغذیه، ریکاوری، یا تکنیک حرکت.';
  }
}
