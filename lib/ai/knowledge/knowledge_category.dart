/// High-level knowledge domains used by GymAI Coach.
enum KnowledgeCategory {
  profile,
  goals,
  workout,
  recovery,
  nutrition,
  medical,
  equipment,
  progress,
  heatmap,
  memory,
  app,
  subscription,
  usage,
}

/// Stable external names for architecture docs and future analytics.
extension KnowledgeCategoryName on KnowledgeCategory {
  /// Product-facing category name.
  String get title {
    switch (this) {
      case KnowledgeCategory.profile:
        return 'Profile';
      case KnowledgeCategory.goals:
        return 'Goals';
      case KnowledgeCategory.workout:
        return 'Workout';
      case KnowledgeCategory.recovery:
        return 'Recovery';
      case KnowledgeCategory.nutrition:
        return 'Nutrition';
      case KnowledgeCategory.medical:
        return 'Medical';
      case KnowledgeCategory.equipment:
        return 'Equipment';
      case KnowledgeCategory.progress:
        return 'Progress';
      case KnowledgeCategory.heatmap:
        return 'Heatmap';
      case KnowledgeCategory.memory:
        return 'Memory';
      case KnowledgeCategory.app:
        return 'App';
      case KnowledgeCategory.subscription:
        return 'Subscription';
      case KnowledgeCategory.usage:
        return 'Usage';
    }
  }
}
