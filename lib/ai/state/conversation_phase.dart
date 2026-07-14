import 'package:gymaipro/ai/context/intent_detector.dart';

/// Product flows that can span multiple coach turns.
enum ConversationFlowType {
  workoutGeneration,
  progressAnalysis,
  onboarding,
  general,
}

/// Lifecycle status for a coach conversation state.
enum ConversationStateStatus { active, paused, completed, cancelled, expired }

/// High-level phase within a multi-step coach conversation.
enum ConversationPhase {
  notStarted,
  greeting,
  collectingProfile,
  collectingGoals,
  collectingRestrictions,
  collectingEquipment,
  collectingProgressData,
  reviewingCollectedData,
  awaitingConfirmation,
  readyToExecute,
  completed,
  cancelled,
  expired,
}

/// Maps a flow type to its default starting phase.
extension ConversationFlowDefaults on ConversationFlowType {
  /// First phase used when a flow starts.
  ConversationPhase get initialPhase {
    switch (this) {
      case ConversationFlowType.workoutGeneration:
        return ConversationPhase.collectingProfile;
      case ConversationFlowType.progressAnalysis:
        return ConversationPhase.collectingProgressData;
      case ConversationFlowType.onboarding:
        return ConversationPhase.greeting;
      case ConversationFlowType.general:
        return ConversationPhase.notStarted;
    }
  }

  /// Optional intent alignment for future integration.
  AIIntent? get alignedIntent {
    switch (this) {
      case ConversationFlowType.workoutGeneration:
        return AIIntent.workoutGeneration;
      case ConversationFlowType.progressAnalysis:
        return AIIntent.progressAnalysis;
      case ConversationFlowType.onboarding:
        return null;
      case ConversationFlowType.general:
        return AIIntent.generalChat;
    }
  }
}

/// Ordered phases for each supported flow.
extension ConversationFlowPhases on ConversationFlowType {
  /// Canonical phase order for checkpoint progression.
  List<ConversationPhase> get phaseOrder {
    switch (this) {
      case ConversationFlowType.workoutGeneration:
        return const <ConversationPhase>[
          ConversationPhase.collectingProfile,
          ConversationPhase.collectingGoals,
          ConversationPhase.collectingRestrictions,
          ConversationPhase.collectingEquipment,
          ConversationPhase.reviewingCollectedData,
          ConversationPhase.awaitingConfirmation,
          ConversationPhase.readyToExecute,
          ConversationPhase.completed,
        ];
      case ConversationFlowType.progressAnalysis:
        return const <ConversationPhase>[
          ConversationPhase.collectingProgressData,
          ConversationPhase.reviewingCollectedData,
          ConversationPhase.awaitingConfirmation,
          ConversationPhase.readyToExecute,
          ConversationPhase.completed,
        ];
      case ConversationFlowType.onboarding:
        return const <ConversationPhase>[
          ConversationPhase.greeting,
          ConversationPhase.collectingProfile,
          ConversationPhase.collectingGoals,
          ConversationPhase.collectingRestrictions,
          ConversationPhase.reviewingCollectedData,
          ConversationPhase.completed,
        ];
      case ConversationFlowType.general:
        return const <ConversationPhase>[
          ConversationPhase.notStarted,
          ConversationPhase.readyToExecute,
          ConversationPhase.completed,
        ];
    }
  }
}
