/// Supported coach personality presets for future prompt rendering.
enum PromptPersonalityType {
  neutral,
  supportive,
  direct,
  premiumCoach,
  educational,
  motivational,
}

/// Personality metadata for a prompt package.
class PromptPersonality {
  const PromptPersonality({
    required this.type,
    required this.title,
    required this.description,
    this.languageCode = 'fa',
  });

  /// Default GymAI coach personality.
  static const gymAiCoach = PromptPersonality(
    type: PromptPersonalityType.premiumCoach,
    title: 'GymAI Coach',
    description: 'Supportive, precise, premium fitness coach.',
  );

  /// Personality type.
  final PromptPersonalityType type;

  /// Human-readable title.
  final String title;

  /// Tone description.
  final String description;

  /// Language code used by future renderers.
  final String languageCode;
}
