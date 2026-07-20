import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/features/product_experience/domain/program_modify_coach_voice.dart';
import 'package:gymaipro/features/product_experience/domain/program_modify_options.dart';

/// Best-effort short AI coaching tip for modify proposals (non-blocking fallback).
class ProgramModifyAiAdvisor {
  ProgramModifyAiAdvisor({OpenAIService? openAIService})
    : _openAI = openAIService ?? OpenAIService();

  final OpenAIService _openAI;

  Future<String?> advise({
    required ProgramModifyGoal goal,
    required String programName,
    String? exerciseName,
    String? reasonLabel,
    String? outcomeSummary,
    bool softRefused = false,
  }) async {
    try {
      final prompt = ProgramModifyCoachVoice.aiAdvicePrompt(
        goal: goal,
        programName: programName,
        exerciseName: exerciseName,
        reasonLabel: reasonLabel,
        outcomeSummary: outcomeSummary,
        softRefused: softRefused,
      );
      final text = await _openAI
          .sendCompletion(
            messages: <Map<String, String>>[
              <String, String>{
                'role': 'system',
                'content':
                    'تو مربی GymAI هستی. فقط فارسی، کوتاه، بدون مقدمه اضافه.',
              },
              <String, String>{'role': 'user', 'content': prompt},
            ],
            temperature: 0.6,
            maxTokens: 180,
            requestTimeout: const Duration(seconds: 8),
          )
          .timeout(const Duration(seconds: 9));
      final cleaned = text.trim();
      if (cleaned.isEmpty) return null;
      return cleaned;
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('ProgramModifyAiAdvisor skipped: $error');
      }
      return null;
    }
  }
}
