import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';

/// Static product definition for a GymAI intent.
class AIIntentDefinition {
  const AIIntentDefinition({
    required this.intent,
    required this.id,
    required this.title,
    required this.description,
    required this.requiresAI,
    required this.requiredProviders,
    required this.optionalProviders,
    required this.localResponseSupported,
  });

  /// Intent enum value.
  final AIIntent intent;

  /// Stable machine id.
  final String id;

  /// Human-readable title.
  final String title;

  /// Product-level description.
  final String description;

  /// Whether the full response is expected to require AI.
  final bool requiresAI;

  /// Context providers required for a complete response.
  final Set<AIContextProviderKey> requiredProviders;

  /// Context providers that can improve the response when available.
  final Set<AIContextProviderKey> optionalProviders;

  /// Whether a local response can satisfy the intent.
  final bool localResponseSupported;
}

/// Registry for all GymAI Coach v2 intent definitions.
class AIIntentDefinitions {
  const AIIntentDefinitions._();

  /// All known intent definitions keyed by intent.
  static const Map<AIIntent, AIIntentDefinition> byIntent =
      <AIIntent, AIIntentDefinition>{
        AIIntent.workoutGeneration: AIIntentDefinition(
          intent: AIIntent.workoutGeneration,
          id: 'workout_generation',
          title: 'Workout Generation',
          description: 'Create a new personalized workout program.',
          requiresAI: true,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.profile,
            AIContextProviderKey.goals,
            AIContextProviderKey.restrictions,
            AIContextProviderKey.activeProgram,
            AIContextProviderKey.workoutHistory,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.heatmap,
            AIContextProviderKey.memory,
          },
          localResponseSupported: false,
        ),
        AIIntent.workoutToday: AIIntentDefinition(
          intent: AIIntent.workoutToday,
          id: 'workout_today',
          title: 'Workout Today',
          description: 'Show the user what they should train today.',
          requiresAI: false,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.activeProgram,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.workoutHistory,
            AIContextProviderKey.heatmap,
            AIContextProviderKey.profile,
          },
          localResponseSupported: true,
        ),
        AIIntent.workoutModification: AIIntentDefinition(
          intent: AIIntent.workoutModification,
          id: 'workout_modification',
          title: 'Workout Modification',
          description: 'Modify an existing workout plan or session.',
          requiresAI: true,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.activeProgram,
            AIContextProviderKey.workoutHistory,
            AIContextProviderKey.restrictions,
            AIContextProviderKey.profile,
            AIContextProviderKey.goals,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.heatmap,
            AIContextProviderKey.memory,
          },
          localResponseSupported: false,
        ),
        AIIntent.exerciseQuestion: AIIntentDefinition(
          intent: AIIntent.exerciseQuestion,
          id: 'exercise_question',
          title: 'Exercise Question',
          description: 'Answer a question about exercise form or selection.',
          requiresAI: true,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.currentQuestion,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.activeProgram,
            AIContextProviderKey.workoutHistory,
            AIContextProviderKey.profile,
          },
          localResponseSupported: false,
        ),
        AIIntent.workoutQuestion: AIIntentDefinition(
          intent: AIIntent.workoutQuestion,
          id: 'workout_question',
          title: 'Workout Question',
          description: 'Answer a question about training or the current plan.',
          requiresAI: true,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.activeProgram,
            AIContextProviderKey.currentQuestion,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.workoutHistory,
            AIContextProviderKey.heatmap,
            AIContextProviderKey.profile,
          },
          localResponseSupported: false,
        ),
        AIIntent.progressAnalysis: AIIntentDefinition(
          intent: AIIntent.progressAnalysis,
          id: 'progress_analysis',
          title: 'Progress Analysis',
          description: 'Analyze training progress and trend signals.',
          requiresAI: true,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.workoutHistory,
            AIContextProviderKey.heatmap,
            AIContextProviderKey.profile,
            AIContextProviderKey.goals,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.memory,
          },
          localResponseSupported: false,
        ),
        AIIntent.recovery: AIIntentDefinition(
          intent: AIIntent.recovery,
          id: 'recovery',
          title: 'Recovery',
          description: 'Recommend rest, recovery, or readiness guidance.',
          requiresAI: false,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.workoutHistory,
            AIContextProviderKey.heatmap,
            AIContextProviderKey.restrictions,
            AIContextProviderKey.profile,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.recovery,
            AIContextProviderKey.memory,
          },
          localResponseSupported: true,
        ),
        AIIntent.nutrition: AIIntentDefinition(
          intent: AIIntent.nutrition,
          id: 'nutrition',
          title: 'Nutrition',
          description: 'Answer nutrition or meal-planning requests.',
          requiresAI: true,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.profile,
            AIContextProviderKey.goals,
            AIContextProviderKey.restrictions,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.workoutHistory,
            AIContextProviderKey.memory,
            AIContextProviderKey.nutrition,
          },
          localResponseSupported: false,
        ),
        AIIntent.supplement: AIIntentDefinition(
          intent: AIIntent.supplement,
          id: 'supplement',
          title: 'Supplement',
          description: 'Answer supplement safety and usage questions.',
          requiresAI: true,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.profile,
            AIContextProviderKey.restrictions,
            AIContextProviderKey.currentQuestion,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.goals,
            AIContextProviderKey.memory,
            AIContextProviderKey.nutrition,
          },
          localResponseSupported: false,
        ),
        AIIntent.motivation: AIIntentDefinition(
          intent: AIIntent.motivation,
          id: 'motivation',
          title: 'Motivation',
          description: 'Provide motivational coaching based on user progress.',
          requiresAI: true,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.profile,
            AIContextProviderKey.goals,
            AIContextProviderKey.workoutHistory,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.activeProgram,
            AIContextProviderKey.heatmap,
            AIContextProviderKey.memory,
          },
          localResponseSupported: true,
        ),
        AIIntent.generalFitness: AIIntentDefinition(
          intent: AIIntent.generalFitness,
          id: 'general_fitness',
          title: 'General Fitness',
          description: 'Answer general fitness education questions.',
          requiresAI: true,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.currentQuestion,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.profile,
            AIContextProviderKey.goals,
            AIContextProviderKey.restrictions,
          },
          localResponseSupported: false,
        ),
        AIIntent.generalChat: AIIntentDefinition(
          intent: AIIntent.generalChat,
          id: 'general_chat',
          title: 'General Chat',
          description: 'Handle open-ended coach conversation.',
          requiresAI: true,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.currentQuestion,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.profile,
            AIContextProviderKey.preferences,
            AIContextProviderKey.chatHistory,
            AIContextProviderKey.memory,
          },
          localResponseSupported: false,
        ),
        AIIntent.appHelp: AIIntentDefinition(
          intent: AIIntent.appHelp,
          id: 'app_help',
          title: 'App Help',
          description: 'Help the user understand how to use GymAI features.',
          requiresAI: false,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.currentQuestion,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.appHelp,
            AIContextProviderKey.preferences,
          },
          localResponseSupported: true,
        ),
        AIIntent.bugReport: AIIntentDefinition(
          intent: AIIntent.bugReport,
          id: 'bug_report',
          title: 'Bug Report',
          description: 'Capture or route a user-reported product bug.',
          requiresAI: false,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.currentQuestion,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.profile,
            AIContextProviderKey.diagnostics,
          },
          localResponseSupported: true,
        ),
        AIIntent.feedback: AIIntentDefinition(
          intent: AIIntent.feedback,
          id: 'feedback',
          title: 'Feedback',
          description: 'Capture product feedback from the user.',
          requiresAI: false,
          requiredProviders: <AIContextProviderKey>{
            AIContextProviderKey.currentQuestion,
          },
          optionalProviders: <AIContextProviderKey>{
            AIContextProviderKey.profile,
            AIContextProviderKey.preferences,
          },
          localResponseSupported: true,
        ),
      };

  /// Returns the definition for an intent.
  static AIIntentDefinition forIntent(AIIntent intent) {
    return byIntent[intent]!;
  }
}
