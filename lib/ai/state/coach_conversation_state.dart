import 'package:gymaipro/ai/state/conversation_checkpoint.dart';
import 'package:gymaipro/ai/state/conversation_phase.dart';
import 'package:gymaipro/ai/state/pending_question.dart';
import 'package:gymaipro/ai/state/state_transition.dart';

/// Immutable state package for multi-step coach conversations.
///
/// This model is descriptive only. It does not call OpenAI, mutate app
/// business logic, or change existing runtime behavior.
class CoachConversationState {
  const CoachConversationState({
    required this.id,
    required this.userId,
    required this.flowType,
    required this.currentPhase,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sessionId,
    this.pendingQuestions = const <PendingQuestion>[],
    this.completedCheckpoints = const <ConversationCheckpoint>[],
    this.collectedFields = const <String, Object?>{},
    this.transitionHistory = const <StateTransition>[],
    this.resumable = true,
    this.expiresAt,
    this.confidence = 0,
    this.cancelled = false,
    this.restartCount = 0,
    this.notes = const <String>[],
  });

  /// Restores a state object from repository JSON.
  factory CoachConversationState.fromJson(Map<String, Object?> json) {
    return CoachConversationState(
      id: _requiredString(json, 'id'),
      userId: _requiredString(json, 'userId'),
      sessionId: json['sessionId'] as String?,
      flowType: ConversationFlowType.values.byName(
        _requiredString(json, 'flowType'),
      ),
      currentPhase: ConversationPhase.values.byName(
        _requiredString(json, 'currentPhase'),
      ),
      status: ConversationStateStatus.values.byName(
        _requiredString(json, 'status'),
      ),
      pendingQuestions: _decodePendingQuestions(json['pendingQuestions']),
      completedCheckpoints: _decodeCheckpoints(json['completedCheckpoints']),
      collectedFields: _decodeStringObjectMap(json['collectedFields']),
      transitionHistory: _decodeTransitions(json['transitionHistory']),
      resumable: json['resumable'] as bool? ?? true,
      expiresAt: _parseDate(json['expiresAt']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      cancelled: json['cancelled'] as bool? ?? false,
      restartCount: (json['restartCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(_requiredString(json, 'createdAt')),
      updatedAt: DateTime.parse(_requiredString(json, 'updatedAt')),
      notes: _decodeStringList(json['notes']),
    );
  }

  /// Stable state id.
  final String id;

  /// Owner user id.
  final String userId;

  /// Optional chat session id for future integration.
  final String? sessionId;

  /// Product flow being executed.
  final ConversationFlowType flowType;

  /// Current conversation phase.
  final ConversationPhase currentPhase;

  /// Lifecycle status.
  final ConversationStateStatus status;

  /// Questions still waiting for answers.
  final List<PendingQuestion> pendingQuestions;

  /// Completed checkpoints in order.
  final List<ConversationCheckpoint> completedCheckpoints;

  /// Fields collected during the conversation.
  final Map<String, Object?> collectedFields;

  /// Ordered transition history.
  final List<StateTransition> transitionHistory;

  /// Whether this conversation can be resumed later.
  final bool resumable;

  /// Optional expiration for the whole conversation state.
  final DateTime? expiresAt;

  /// Overall confidence from 0 to 1.
  final double confidence;

  /// Whether the user or system cancelled this flow.
  final bool cancelled;

  /// Number of restarts applied to this flow.
  final int restartCount;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last mutation timestamp.
  final DateTime updatedAt;

  /// Diagnostic notes.
  final List<String> notes;

  /// Whether the state has passed its expiration time.
  bool isExpired({DateTime? now}) {
    final expiresAt = this.expiresAt;
    if (expiresAt == null) return false;
    return (now ?? DateTime.now()).isAfter(expiresAt);
  }

  /// Whether the conversation can be resumed right now.
  bool get canResume {
    if (!resumable || cancelled) return false;
    if (status == ConversationStateStatus.completed ||
        status == ConversationStateStatus.cancelled ||
        status == ConversationStateStatus.expired) {
      return false;
    }
    return !isExpired();
  }

  /// Whether the flow is still active.
  bool get isActive {
    return status == ConversationStateStatus.active ||
        status == ConversationStateStatus.paused;
  }

  /// Returns an updated copy.
  CoachConversationState copyWith({
    String? sessionId,
    ConversationPhase? currentPhase,
    ConversationStateStatus? status,
    List<PendingQuestion>? pendingQuestions,
    List<ConversationCheckpoint>? completedCheckpoints,
    Map<String, Object?>? collectedFields,
    List<StateTransition>? transitionHistory,
    bool? resumable,
    DateTime? expiresAt,
    double? confidence,
    bool? cancelled,
    int? restartCount,
    DateTime? updatedAt,
    List<String>? notes,
  }) {
    return CoachConversationState(
      id: id,
      userId: userId,
      sessionId: sessionId ?? this.sessionId,
      flowType: flowType,
      currentPhase: currentPhase ?? this.currentPhase,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingQuestions: pendingQuestions ?? this.pendingQuestions,
      completedCheckpoints: completedCheckpoints ?? this.completedCheckpoints,
      collectedFields: collectedFields ?? this.collectedFields,
      transitionHistory: transitionHistory ?? this.transitionHistory,
      resumable: resumable ?? this.resumable,
      expiresAt: expiresAt ?? this.expiresAt,
      confidence: confidence ?? this.confidence,
      cancelled: cancelled ?? this.cancelled,
      restartCount: restartCount ?? this.restartCount,
      notes: notes ?? this.notes,
    );
  }

  /// Serializes this state for repository persistence.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'userId': userId,
      'sessionId': sessionId,
      'flowType': flowType.name,
      'currentPhase': currentPhase.name,
      'status': status.name,
      'pendingQuestions': pendingQuestions
          .map(
            (question) => <String, Object?>{
              'id': question.id,
              'prompt': question.prompt,
              'fieldKey': question.fieldKey,
              'phase': question.phase.name,
              'priority': question.priority.name,
              'askedAt': question.askedAt?.toIso8601String(),
              'expiresAt': question.expiresAt?.toIso8601String(),
              'metadata': question.metadata,
            },
          )
          .toList(growable: false),
      'completedCheckpoints': completedCheckpoints
          .map(
            (checkpoint) => <String, Object?>{
              'id': checkpoint.id,
              'phase': checkpoint.phase.name,
              'completedAt': checkpoint.completedAt.toIso8601String(),
              'collectedFieldKeys': checkpoint.collectedFieldKeys,
              'notes': checkpoint.notes,
              'confidence': checkpoint.confidence,
            },
          )
          .toList(growable: false),
      'collectedFields': collectedFields,
      'transitionHistory': transitionHistory
          .map(
            (transition) => <String, Object?>{
              'id': transition.id,
              'fromPhase': transition.fromPhase.name,
              'toPhase': transition.toPhase.name,
              'reason': transition.reason.name,
              'occurredAt': transition.occurredAt.toIso8601String(),
              'trigger': transition.trigger,
              'notes': transition.notes,
            },
          )
          .toList(growable: false),
      'resumable': resumable,
      'expiresAt': expiresAt?.toIso8601String(),
      'confidence': confidence,
      'cancelled': cancelled,
      'restartCount': restartCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
    };
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException(
        'Missing or invalid $key in CoachConversationState JSON.',
      );
    }
    return value;
  }

  static List<PendingQuestion> _decodePendingQuestions(Object? raw) {
    if (raw is! List<Object?>) return const <PendingQuestion>[];
    final questions = <PendingQuestion>[];
    for (final entry in raw) {
      if (entry is! Map<Object?, Object?>) continue;
      final map = entry.map((key, value) => MapEntry(key.toString(), value));
      final id = map['id'];
      final prompt = map['prompt'];
      final fieldKey = map['fieldKey'];
      final phase = map['phase'];
      if (id is! String || prompt is! String || fieldKey is! String) continue;
      if (phase is! String) continue;
      final priorityRaw = map['priority'];
      final priorityName = priorityRaw is String
          ? priorityRaw
          : PendingQuestionPriority.required.name;
      questions.add(
        PendingQuestion(
          id: id,
          prompt: prompt,
          fieldKey: fieldKey,
          phase: ConversationPhase.values.byName(phase),
          priority: PendingQuestionPriority.values.byName(priorityName),
          askedAt: _parseDate(map['askedAt']),
          expiresAt: _parseDate(map['expiresAt']),
          metadata: _decodeStringObjectMap(map['metadata']),
        ),
      );
    }
    return List<PendingQuestion>.unmodifiable(questions);
  }

  static List<ConversationCheckpoint> _decodeCheckpoints(Object? raw) {
    if (raw is! List<Object?>) return const <ConversationCheckpoint>[];
    final checkpoints = <ConversationCheckpoint>[];
    for (final entry in raw) {
      if (entry is! Map<Object?, Object?>) continue;
      final map = entry.map((key, value) => MapEntry(key.toString(), value));
      final id = map['id'];
      final phase = map['phase'];
      final completedAt = map['completedAt'];
      if (id is! String || phase is! String || completedAt is! String) continue;
      checkpoints.add(
        ConversationCheckpoint(
          id: id,
          phase: ConversationPhase.values.byName(phase),
          completedAt: DateTime.parse(completedAt),
          collectedFieldKeys: _decodeStringList(map['collectedFieldKeys']),
          notes: _decodeStringList(map['notes']),
          confidence: (map['confidence'] as num?)?.toDouble() ?? 1,
        ),
      );
    }
    return List<ConversationCheckpoint>.unmodifiable(checkpoints);
  }

  static List<StateTransition> _decodeTransitions(Object? raw) {
    if (raw is! List<Object?>) return const <StateTransition>[];
    final transitions = <StateTransition>[];
    for (final entry in raw) {
      if (entry is! Map<Object?, Object?>) continue;
      final map = entry.map((key, value) => MapEntry(key.toString(), value));
      final id = map['id'];
      final fromPhase = map['fromPhase'];
      final toPhase = map['toPhase'];
      final reason = map['reason'];
      final occurredAt = map['occurredAt'];
      if (id is! String ||
          fromPhase is! String ||
          toPhase is! String ||
          reason is! String ||
          occurredAt is! String) {
        continue;
      }
      transitions.add(
        StateTransition(
          id: id,
          fromPhase: ConversationPhase.values.byName(fromPhase),
          toPhase: ConversationPhase.values.byName(toPhase),
          reason: StateTransitionReason.values.byName(reason),
          occurredAt: DateTime.parse(occurredAt),
          trigger: map['trigger'] as String?,
          notes: _decodeStringList(map['notes']),
        ),
      );
    }
    return List<StateTransition>.unmodifiable(transitions);
  }

  static Map<String, Object?> _decodeStringObjectMap(Object? raw) {
    if (raw is! Map<Object?, Object?>) return const <String, Object?>{};
    return Map<String, Object?>.unmodifiable(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static List<String> _decodeStringList(Object? raw) {
    if (raw is! List<Object?>) return const <String>[];
    return List<String>.unmodifiable(raw.map((value) => value.toString()));
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.parse(raw);
  }
}
