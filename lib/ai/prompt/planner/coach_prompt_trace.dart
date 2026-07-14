import 'package:gymaipro/ai/prompt/planner/coach_prompt_priority.dart';

/// Trace for one prompt planning section.
class CoachPromptSectionTrace {
  const CoachPromptSectionTrace({
    required this.sectionId,
    required this.priority,
    required this.estimatedTokens,
    this.removed = false,
    this.compressed = false,
    this.reason,
  });

  final String sectionId;
  final CoachPromptPriority priority;
  final int estimatedTokens;
  final bool removed;
  final bool compressed;
  final String? reason;
}

/// Full prompt planning trace.
class CoachPromptTrace {
  const CoachPromptTrace({
    required this.sectionTraces,
    required this.executionTime,
  });

  final List<CoachPromptSectionTrace> sectionTraces;
  final Duration executionTime;
}
