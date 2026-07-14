import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/intent/intent_keyword_dictionary.dart';
import 'package:gymaipro/ai/intent/intent_rule_definition.dart';
import 'package:gymaipro/ai/intent/intent_rule_type.dart';

/// Central registry of data-driven intent rules.
class IntentRuleRegistry {
  IntentRuleRegistry({List<IntentRuleDefinition>? rules})
    : rules = rules ?? allRules;

  static final List<IntentRuleDefinition> allRules =
      List<IntentRuleDefinition>.unmodifiable(<IntentRuleDefinition>[
        ..._dictionaryKeywordRules(),
        ..._inlineRegexRules(),
        ..._metadataRules(),
      ]);

  final List<IntentRuleDefinition> rules;

  /// Returns rules targeting [intent].
  List<IntentRuleDefinition> rulesForIntent(AIIntent intent) {
    return rules.where((rule) => rule.intent == intent).toList(growable: false);
  }

  static List<IntentRuleDefinition> _dictionaryKeywordRules() {
    final mapped = <IntentRuleDefinition>[];
    for (final entry in IntentKeywordDictionary.entries.entries) {
      mapped.add(
        IntentRuleDefinition(
          id: 'dict_${entry.key}',
          intent: _intentForDictionaryKey(entry.key),
          type: IntentRuleType.keyword,
          weight: 1,
          dictionaryKey: entry.key,
          description: 'Dictionary keyword rule for ${entry.key}.',
        ),
      );
    }
    return mapped;
  }

  static List<IntentRuleDefinition> _inlineRegexRules() {
    return const <IntentRuleDefinition>[
      IntentRuleDefinition(
        id: 'regex_workout_generation',
        intent: AIIntent.workoutGeneration,
        type: IntentRuleType.regex,
        weight: 1.5,
        regexPattern: '(برنامه|plan).*(تمرین|training|workout)',
        description: 'Regex for workout program requests.',
      ),
      IntentRuleDefinition(
        id: 'regex_progress_analysis',
        intent: AIIntent.progressAnalysis,
        type: IntentRuleType.regex,
        weight: 1.4,
        regexPattern: '(تحلیل|analysis).*(پیشرفت|progress)',
        description: 'Regex for progress analysis requests.',
      ),
      IntentRuleDefinition(
        id: 'regex_bug_report',
        intent: AIIntent.bugReport,
        type: IntentRuleType.regex,
        weight: 1.3,
        regexPattern: '(باگ|bug|crash|خطا)',
        description: 'Regex for bug reports.',
      ),
      IntentRuleDefinition(
        id: 'regex_exercise_question',
        intent: AIIntent.exerciseQuestion,
        type: IntentRuleType.regex,
        weight: 1.2,
        regexPattern: '(فرم|form).*(حرکت|exercise)',
        description: 'Regex for exercise technique questions.',
      ),
    ];
  }

  static List<IntentRuleDefinition> _metadataRules() {
    return const <IntentRuleDefinition>[
      IntentRuleDefinition(
        id: 'meta_surface_progress',
        intent: AIIntent.progressAnalysis,
        type: IntentRuleType.metadata,
        weight: 1.6,
        metadataKey: 'surface',
        metadataEquals: 'progress_analysis',
        description: 'Metadata surface hint for progress analysis.',
      ),
      IntentRuleDefinition(
        id: 'meta_surface_workout_generator',
        intent: AIIntent.workoutGeneration,
        type: IntentRuleType.metadata,
        weight: 1.6,
        metadataKey: 'surface',
        metadataEquals: 'workout_generator',
        description: 'Metadata surface hint for workout generation.',
      ),
    ];
  }

  static AIIntent _intentForDictionaryKey(String key) {
    switch (key) {
      case 'workout_generation':
        return AIIntent.workoutGeneration;
      case 'workout_today':
        return AIIntent.workoutToday;
      case 'workout_modification':
        return AIIntent.workoutModification;
      case 'exercise_question':
        return AIIntent.exerciseQuestion;
      case 'workout_question':
        return AIIntent.workoutQuestion;
      case 'progress_analysis':
        return AIIntent.progressAnalysis;
      case 'recovery':
        return AIIntent.recovery;
      case 'nutrition':
        return AIIntent.nutrition;
      case 'supplement':
        return AIIntent.supplement;
      case 'motivation':
        return AIIntent.motivation;
      case 'general_fitness':
        return AIIntent.generalFitness;
      case 'app_help':
        return AIIntent.appHelp;
      case 'bug_report':
        return AIIntent.bugReport;
      case 'feedback':
        return AIIntent.feedback;
      default:
        return AIIntent.generalChat;
    }
  }
}
