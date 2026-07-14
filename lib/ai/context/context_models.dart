import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';

/// Context sections that can be produced independently by providers.
enum AIContextSection {
  userProfile,
  goal,
  workout,
  history,
  heatmap,
  equipment,
  restrictions,
  preferences,
  memory,
  currentQuestion,
  apiUsage,
  recovery,
  chat,
}

/// Granular provider capabilities used for intent-based selection.
enum AIContextProviderKey {
  profile,
  goals,
  restrictions,
  activeProgram,
  workoutHistory,
  heatmap,
  equipment,
  memory,
  currentQuestion,
  apiUsage,
  recovery,
  preferences,
  chatHistory,
  nutrition,
  supplements,
  appHelp,
  diagnostics,
}

/// Priority used when deciding which context providers should be selected.
enum ContextPriority { required, high, medium, low, never }

/// Metadata describing a provider before it is executed.
class AIContextProviderMetadata {
  const AIContextProviderMetadata({
    required this.name,
    required this.priority,
    required this.estimatedCost,
    required this.estimatedLatency,
    required this.cacheable,
    required this.ttl,
  });

  /// Human-readable provider name for diagnostics.
  final String name;

  /// Default selection priority.
  final ContextPriority priority;

  /// Relative cost unit. Zero means no paid AI/API cost is expected.
  final double estimatedCost;

  /// Expected provider latency.
  final Duration estimatedLatency;

  /// Whether the provider output can be cached safely.
  final bool cacheable;

  /// Suggested cache TTL.
  final Duration ttl;
}

/// Input passed to context providers.
class AIContextRequest {
  const AIContextRequest({
    required this.userId,
    this.intent = AIIntent.generalChat,
    this.currentQuestion,
    this.source,
    this.metadata = const <String, Object?>{},
    this.memorySnapshot,
  });

  /// Current authenticated user id.
  final String userId;

  /// Detected or caller-provided intent.
  final AIIntent intent;

  /// Current user question, if the context is being built for a prompt.
  final String? currentQuestion;

  /// Source surface such as coach home, chat, progress analysis, or workout log.
  final String? source;

  /// Additional future-safe metadata for providers.
  final Map<String, Object?> metadata;

  /// Optional request-scoped memory snapshot.
  ///
  /// When provided, context assembly uses this snapshot instead of loading
  /// memory again from storage.
  final List<CoachMemory>? memorySnapshot;
}
