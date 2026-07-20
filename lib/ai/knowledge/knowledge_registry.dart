import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/knowledge/knowledge_category.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/knowledge_requirement.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';

/// Shared atomic knowledge requirements.
class KnowledgeRequirements {
  const KnowledgeRequirements._();

  static const profileBasics = KnowledgeRequirement(
    id: 'profile_basics',
    title: 'Profile Basics',
    description: 'Age, height, weight, and basic athlete profile fields.',
    category: KnowledgeCategory.profile,
    required: true,
    priority: ContextPriority.required,
    providerKey: AIContextProviderKey.profile,
    fallbackStrategy: KnowledgeFallbackStrategy.askFollowUp,
    validationRuleId: 'profile_basics_present',
  );

  static const goals = KnowledgeRequirement(
    id: 'goals',
    title: 'Goals',
    description: 'Primary fitness or nutrition goal.',
    category: KnowledgeCategory.goals,
    required: true,
    priority: ContextPriority.required,
    providerKey: AIContextProviderKey.goals,
    fallbackStrategy: KnowledgeFallbackStrategy.askFollowUp,
    validationRuleId: 'goals_present',
  );

  static const restrictions = KnowledgeRequirement(
    id: 'restrictions',
    title: 'Restrictions',
    description: 'Injuries, limitations, contraindications, or medical notes.',
    category: KnowledgeCategory.medical,
    required: true,
    priority: ContextPriority.high,
    providerKey: AIContextProviderKey.restrictions,
    fallbackStrategy: KnowledgeFallbackStrategy.askFollowUp,
    validationRuleId: 'restrictions_checked',
  );

  static const equipment = KnowledgeRequirement(
    id: 'equipment',
    title: 'Equipment',
    description: 'Available gym or home equipment.',
    category: KnowledgeCategory.equipment,
    required: false,
    priority: ContextPriority.medium,
    providerKey: AIContextProviderKey.equipment,
    fallbackStrategy: KnowledgeFallbackStrategy.useLocalDefault,
    validationRuleId: 'equipment_known',
  );

  static const activeProgram = KnowledgeRequirement(
    id: 'active_program',
    title: 'Active Program',
    description: 'Current selected workout program and active session state.',
    category: KnowledgeCategory.workout,
    required: true,
    priority: ContextPriority.required,
    providerKey: AIContextProviderKey.activeProgram,
    fallbackStrategy: KnowledgeFallbackStrategy.askFollowUp,
    validationRuleId: 'active_program_present',
  );

  static const workoutHistory = KnowledgeRequirement(
    id: 'workout_history',
    title: 'Workout History',
    description: 'Logged workout sessions and training consistency.',
    category: KnowledgeCategory.workout,
    required: true,
    priority: ContextPriority.required,
    providerKey: AIContextProviderKey.workoutHistory,
    fallbackStrategy: KnowledgeFallbackStrategy.askFollowUp,
    validationRuleId: 'workout_history_present',
  );

  static const currentQuestion = KnowledgeRequirement(
    id: 'current_question',
    title: 'Current Question',
    description: 'The user message currently being handled.',
    category: KnowledgeCategory.app,
    required: true,
    priority: ContextPriority.required,
    providerKey: AIContextProviderKey.currentQuestion,
    fallbackStrategy: KnowledgeFallbackStrategy.askFollowUp,
    validationRuleId: 'current_question_present',
  );

  static const heatmap = KnowledgeRequirement(
    id: 'weekly_heatmap',
    title: 'Weekly Heatmap',
    description: 'Recent muscle coverage and imbalance signals.',
    category: KnowledgeCategory.heatmap,
    required: true,
    priority: ContextPriority.high,
    providerKey: AIContextProviderKey.heatmap,
    fallbackStrategy: KnowledgeFallbackStrategy.continueWithoutIt,
    validationRuleId: 'heatmap_available',
  );

  static const recoverySignals = KnowledgeRequirement(
    id: 'recovery_signals',
    title: 'Recovery Signals',
    description: 'Rest, workload, soreness, and readiness signals.',
    category: KnowledgeCategory.recovery,
    required: false,
    priority: ContextPriority.medium,
    providerKey: AIContextProviderKey.recovery,
    fallbackStrategy: KnowledgeFallbackStrategy.continueWithoutIt,
    validationRuleId: 'recovery_signals_available',
  );

  static const nutritionProfile = KnowledgeRequirement(
    id: 'nutrition_profile',
    title: 'Nutrition Profile',
    description: 'Nutrition preferences, goals, and dietary restrictions.',
    category: KnowledgeCategory.nutrition,
    required: true,
    priority: ContextPriority.high,
    providerKey: AIContextProviderKey.nutrition,
    fallbackStrategy: KnowledgeFallbackStrategy.askFollowUp,
    validationRuleId: 'nutrition_profile_present',
  );

  static const supplements = KnowledgeRequirement(
    id: 'supplements',
    title: 'Supplement Context',
    description: 'Supplement request, medical restrictions, and user goals.',
    category: KnowledgeCategory.nutrition,
    required: false,
    priority: ContextPriority.medium,
    providerKey: AIContextProviderKey.supplements,
    fallbackStrategy: KnowledgeFallbackStrategy.askFollowUp,
    validationRuleId: 'supplement_context_present',
  );

  static const memory = KnowledgeRequirement(
    id: 'memory',
    title: 'Coach Memory',
    description: 'Long-lived user preferences and previous coach insights.',
    category: KnowledgeCategory.memory,
    required: false,
    priority: ContextPriority.low,
    providerKey: AIContextProviderKey.memory,
    fallbackStrategy: KnowledgeFallbackStrategy.continueWithoutIt,
    validationRuleId: 'memory_available',
  );

  static const preferences = KnowledgeRequirement(
    id: 'preferences',
    title: 'Preferences',
    description: 'Coaching style, schedule, and preferred training format.',
    category: KnowledgeCategory.profile,
    required: false,
    priority: ContextPriority.medium,
    providerKey: AIContextProviderKey.preferences,
    fallbackStrategy: KnowledgeFallbackStrategy.continueWithoutIt,
    validationRuleId: 'preferences_available',
  );

  static const chatHistory = KnowledgeRequirement(
    id: 'chat_history',
    title: 'Chat History',
    description: 'Previous coach conversation context or summary.',
    category: KnowledgeCategory.memory,
    required: false,
    priority: ContextPriority.low,
    providerKey: AIContextProviderKey.chatHistory,
    fallbackStrategy: KnowledgeFallbackStrategy.continueWithoutIt,
    validationRuleId: 'chat_history_available',
  );

  static const appHelp = KnowledgeRequirement(
    id: 'app_help',
    title: 'App Help Knowledge',
    description: 'Static product help and feature guidance.',
    category: KnowledgeCategory.app,
    required: false,
    priority: ContextPriority.medium,
    providerKey: AIContextProviderKey.appHelp,
    fallbackStrategy: KnowledgeFallbackStrategy.useLocalDefault,
    validationRuleId: 'app_help_available',
  );

  static const diagnostics = KnowledgeRequirement(
    id: 'diagnostics',
    title: 'Diagnostics',
    description: 'Client, app, and environment diagnostics for bug reports.',
    category: KnowledgeCategory.app,
    required: false,
    priority: ContextPriority.low,
    providerKey: AIContextProviderKey.diagnostics,
    fallbackStrategy: KnowledgeFallbackStrategy.continueWithoutIt,
    validationRuleId: 'diagnostics_available',
  );

  static const apiUsage = KnowledgeRequirement(
    id: 'api_usage',
    title: 'API Usage',
    description: 'AI usage, entitlement, or rate-limit state.',
    category: KnowledgeCategory.usage,
    required: false,
    priority: ContextPriority.low,
    providerKey: AIContextProviderKey.apiUsage,
    fallbackStrategy: KnowledgeFallbackStrategy.continueWithoutIt,
    validationRuleId: 'api_usage_available',
  );
}

/// Registry for all current and planned Coach knowledge nodes.
class KnowledgeRegistry {
  const KnowledgeRegistry._();

  static const nodes = <String, KnowledgeNode>{
    'workout_generation': KnowledgeNode(
      id: 'workout_generation',
      intent: AIIntent.workoutGeneration,
      title: 'Workout Generation',
      description: 'Redirect out of chat to dedicated program request flows.',
      requiredKnowledge: <KnowledgeRequirement>[],
      optionalKnowledge: <KnowledgeRequirement>[],
      missingBehaviour: KnowledgeMissingBehaviour.continueWithLowerConfidence,
      recommendedFollowUp:
          'برای ساخت برنامه از بخش مربیان یا درخواست برنامه مربی هوشمند استفاده کن.',
      defaultAction: CoachAction.localResponse,
      requiresAI: false,
    ),
    'workout_today': KnowledgeNode(
      id: 'workout_today',
      intent: AIIntent.workoutToday,
      title: 'Workout Today',
      description: 'Show the user what to train today.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.activeProgram,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.workoutHistory,
        KnowledgeRequirements.heatmap,
        KnowledgeRequirements.recoverySignals,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.askFollowUp,
      recommendedFollowUp: 'اول یک برنامه فعال انتخاب یا بساز.',
      defaultAction: CoachAction.showProgram,
      requiresAI: false,
    ),
    'workout_modification': KnowledgeNode(
      id: 'workout_modification',
      intent: AIIntent.workoutModification,
      title: 'Program Modification',
      description: 'Modify an active program or workout session.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.activeProgram,
        KnowledgeRequirements.workoutHistory,
        KnowledgeRequirements.restrictions,
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.goals,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.equipment,
        KnowledgeRequirements.heatmap,
        KnowledgeRequirements.memory,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.askFollowUp,
      recommendedFollowUp: 'کدام بخش برنامه را می‌خواهی تغییر بدهم؟',
      defaultAction: CoachAction.callOpenAI,
      requiresAI: true,
    ),
    'program_review': KnowledgeNode(
      id: 'program_review',
      title: 'Program Review',
      description: 'Review an existing workout program for quality and fit.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.activeProgram,
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.goals,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.workoutHistory,
        KnowledgeRequirements.heatmap,
        KnowledgeRequirements.restrictions,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.askFollowUp,
      recommendedFollowUp: 'برنامه‌ای که می‌خواهی بررسی شود را مشخص کن.',
      defaultAction: CoachAction.callOpenAI,
      requiresAI: true,
    ),
    'exercise_question': KnowledgeNode(
      id: 'exercise_question',
      intent: AIIntent.exerciseQuestion,
      title: 'Exercise Question',
      description: 'Answer form, technique, or exercise-selection questions.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.currentQuestion,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.activeProgram,
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.restrictions,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.askFollowUp,
      recommendedFollowUp: 'نام حرکت یا سوال تمرینی‌ات را دقیق‌تر بنویس.',
      defaultAction: CoachAction.callOpenAI,
      requiresAI: true,
    ),
    'workout_question': KnowledgeNode(
      id: 'workout_question',
      intent: AIIntent.workoutQuestion,
      title: 'Workout Question',
      description: 'Answer questions about training or the active program.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.currentQuestion,
        KnowledgeRequirements.activeProgram,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.workoutHistory,
        KnowledgeRequirements.heatmap,
        KnowledgeRequirements.profileBasics,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.askFollowUp,
      recommendedFollowUp: 'سوالت درباره کدام تمرین یا جلسه است؟',
      defaultAction: CoachAction.callOpenAI,
      requiresAI: true,
    ),
    'progress_analysis': KnowledgeNode(
      id: 'progress_analysis',
      intent: AIIntent.progressAnalysis,
      title: 'Progress Analysis',
      description: 'Analyze training progress and trends.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.workoutHistory,
        KnowledgeRequirements.heatmap,
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.goals,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.memory,
        KnowledgeRequirements.apiUsage,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.askFollowUp,
      recommendedFollowUp: 'برای تحلیل بهتر، چند جلسه تمرین ثبت کن.',
      defaultAction: CoachAction.showProgress,
      requiresAI: true,
    ),
    'heatmap_explanation': KnowledgeNode(
      id: 'heatmap_explanation',
      title: 'Heatmap Explanation',
      description: 'Explain muscle heatmap patterns and gaps.',
      requiredKnowledge: <KnowledgeRequirement>[KnowledgeRequirements.heatmap],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.activeProgram,
        KnowledgeRequirements.workoutHistory,
        KnowledgeRequirements.goals,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.routeToLocalFallback,
      recommendedFollowUp: 'برای توضیح هیت‌مپ، ابتدا حداقل یک تمرین ثبت کن.',
      defaultAction: CoachAction.showHeatmap,
      requiresAI: false,
    ),
    'recovery': KnowledgeNode(
      id: 'recovery',
      intent: AIIntent.recovery,
      title: 'Recovery',
      description: 'Recommend rest or recovery guidance.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.workoutHistory,
        KnowledgeRequirements.heatmap,
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.restrictions,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.recoverySignals,
        KnowledgeRequirements.memory,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.continueWithLowerConfidence,
      recommendedFollowUp: 'سطح خستگی یا درد عضلانی امروزت چقدر است؟',
      defaultAction: CoachAction.showRecovery,
      requiresAI: false,
    ),
    'nutrition': KnowledgeNode(
      id: 'nutrition',
      intent: AIIntent.nutrition,
      title: 'Nutrition',
      description:
          'Answer light nutrition questions; never deliver full meal plans in chat.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.goals,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.restrictions,
        KnowledgeRequirements.nutritionProfile,
        KnowledgeRequirements.workoutHistory,
        KnowledgeRequirements.memory,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.continueWithLowerConfidence,
      recommendedFollowUp:
          'برای برنامه غذایی کامل از بخش مربیان استفاده کن؛ چت رژیم کامل نمی‌دهد.',
      defaultAction: CoachAction.callOpenAI,
      requiresAI: true,
    ),
    'supplement': KnowledgeNode(
      id: 'supplement',
      intent: AIIntent.supplement,
      title: 'Supplement',
      description: 'Answer supplement safety and usage questions.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.currentQuestion,
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.restrictions,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.goals,
        KnowledgeRequirements.supplements,
        KnowledgeRequirements.memory,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.askFollowUp,
      recommendedFollowUp: 'نام مکمل و شرایط پزشکی یا محدودیت‌هایت را بنویس.',
      defaultAction: CoachAction.callOpenAI,
      requiresAI: true,
    ),
    'motivation': KnowledgeNode(
      id: 'motivation',
      intent: AIIntent.motivation,
      title: 'Motivation',
      description: 'Provide contextual motivation.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.goals,
        KnowledgeRequirements.workoutHistory,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.activeProgram,
        KnowledgeRequirements.heatmap,
        KnowledgeRequirements.memory,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.continueWithLowerConfidence,
      recommendedFollowUp: 'هدفت را بگو تا انگیزه دقیق‌تر بدهم.',
      defaultAction: CoachAction.localResponse,
      requiresAI: true,
    ),
    'general_fitness': KnowledgeNode(
      id: 'general_fitness',
      intent: AIIntent.generalFitness,
      title: 'General Fitness',
      description: 'Answer general fitness education questions.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.currentQuestion,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.goals,
        KnowledgeRequirements.restrictions,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.askFollowUp,
      recommendedFollowUp: 'سوال فیتنس خودت را واضح‌تر بنویس.',
      defaultAction: CoachAction.callOpenAI,
      requiresAI: true,
    ),
    'general_chat': KnowledgeNode(
      id: 'general_chat',
      intent: AIIntent.generalChat,
      title: 'General Chat',
      description: 'Handle open-ended coach conversation.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.currentQuestion,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.preferences,
        KnowledgeRequirements.chatHistory,
        KnowledgeRequirements.memory,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.askFollowUp,
      recommendedFollowUp: 'دوست داری درباره تمرین، تغذیه یا پیشرفت صحبت کنیم؟',
      defaultAction: CoachAction.callOpenAI,
      requiresAI: true,
    ),
    'app_help': KnowledgeNode(
      id: 'app_help',
      intent: AIIntent.appHelp,
      title: 'App Help',
      description: 'Help users understand GymAI features.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.currentQuestion,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.appHelp,
        KnowledgeRequirements.preferences,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.routeToLocalFallback,
      recommendedFollowUp: 'دقیقاً با کدام بخش اپ مشکل داری؟',
      defaultAction: CoachAction.localResponse,
      requiresAI: false,
    ),
    'bug_report': KnowledgeNode(
      id: 'bug_report',
      intent: AIIntent.bugReport,
      title: 'Bug Report',
      description: 'Capture product bug reports.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.currentQuestion,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.diagnostics,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.routeToLocalFallback,
      recommendedFollowUp: 'چه اتفاقی افتاد و در کدام صفحه بودی؟',
      defaultAction: CoachAction.localResponse,
      requiresAI: false,
    ),
    'feedback': KnowledgeNode(
      id: 'feedback',
      intent: AIIntent.feedback,
      title: 'Feedback',
      description: 'Capture product feedback.',
      requiredKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.currentQuestion,
      ],
      optionalKnowledge: <KnowledgeRequirement>[
        KnowledgeRequirements.profileBasics,
        KnowledgeRequirements.preferences,
      ],
      missingBehaviour: KnowledgeMissingBehaviour.routeToLocalFallback,
      recommendedFollowUp: 'بازخوردت را با جزئیات بیشتری بنویس.',
      defaultAction: CoachAction.localResponse,
      requiresAI: false,
    ),
  };

  static final nodesByIntent = <AIIntent, KnowledgeNode>{
    AIIntent.workoutGeneration: nodes['workout_generation']!,
    AIIntent.workoutToday: nodes['workout_today']!,
    AIIntent.workoutModification: nodes['workout_modification']!,
    AIIntent.exerciseQuestion: nodes['exercise_question']!,
    AIIntent.workoutQuestion: nodes['workout_question']!,
    AIIntent.progressAnalysis: nodes['progress_analysis']!,
    AIIntent.recovery: nodes['recovery']!,
    AIIntent.nutrition: nodes['nutrition']!,
    AIIntent.supplement: nodes['supplement']!,
    AIIntent.motivation: nodes['motivation']!,
    AIIntent.generalFitness: nodes['general_fitness']!,
    AIIntent.generalChat: nodes['general_chat']!,
    AIIntent.appHelp: nodes['app_help']!,
    AIIntent.bugReport: nodes['bug_report']!,
    AIIntent.feedback: nodes['feedback']!,
  };
}
