import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/features/product_experience/domain/coach_decision_lock.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_snapshot.dart';

/// Short coach narrative from locked session facts (cite-or-silence).
class SessionAnalysisNarrativeService {
  SessionAnalysisNarrativeService({OpenAIService? openAi})
    : _openAi = openAi ?? OpenAIService();

  final OpenAIService _openAi;

  /// Returns Persian coach copy, or null if LLM fails (UI falls back to debrief).
  Future<String?> narrate(SessionAnalysisSnapshot snapshot) async {
    try {
      final lockJson = jsonEncode(snapshot.decisionLock);
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content':
              '${CoachDecisionLock.systemRule}\n'
              'You are GymAI session debrief coach. '
              'Write Persian like a real gym coach talking to one person. '
              'Warm, direct, a bit casual. Use «تو». Short sentences. '
              'Not a system report. No English. No jargon '
              '(no Decision Card, lock, volume ratio, CTA). '
              'Max 5 short lines. '
              'Cover: what went well, skipped moves (program was heavy — '
              'not user shame), what to do next session. '
              'Do not invent kg/reps. Do not write a full program rewrite. '
              'If a decision has incomplete_volume=true or '
              'logged set_count < prescribed_set_count: NEVER tell them to add kg. '
              'Tell them to complete all prescribed sets at working_weight_kg. '
              'If action is hold, do not say to increase next session. '
              'If first_session is true, completing the prescribed work IS success — do not invent a need to add kg. '
              'Users should not always chase heavier loads; cite action as written. '
              'For next-session loads, cite target_line / next_weight_kg only. '
              'No markdown headings. No emoji.',
        },
        {
          'role': 'user',
          'content':
              'decisions.lock:\n$lockJson\n\n'
              'Session: ${snapshot.focus} · '
              '${snapshot.completedExercises}/${snapshot.plannedExercises} exercises · '
              '${snapshot.completedSets}/${snapshot.totalSets} sets · '
              'volume ${snapshot.totalVolumeKg.round()}kg'
              '${snapshot.estimatedCaloriesKcal != null ? ' · ~${snapshot.estimatedCaloriesKcal} kcal' : ''}.\n'
              'Write the debrief now.',
        },
      ];

      final text = await _openAi.sendCompletion(
        messages: messages,
        temperature: 0.4,
        maxTokens: 420,
        requestTimeout: const Duration(seconds: 25),
      );
      final cleaned = text.trim();
      if (cleaned.isEmpty) return null;
      return cleaned;
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[SessionAnalysisNarrative] $error');
      }
      return null;
    }
  }
}
