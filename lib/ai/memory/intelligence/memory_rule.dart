import 'package:gymaipro/ai/memory/intelligence/memory_extraction_reason.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_namespace.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';

/// Rule-based memory extraction definition.
class MemoryRule {
  const MemoryRule({
    required this.id,
    required this.namespace,
    required this.keyName,
    required this.category,
    required this.importance,
    required this.source,
    required this.triggerPhrases,
    required this.reason,
    this.baseConfidence = 0.65,
    this.expiresAfter,
    this.userEditable = true,
  });

  /// Stable rule id.
  final String id;

  /// Namespace for generated memory key.
  final MemoryNamespace namespace;

  /// Key name inside [namespace].
  final String keyName;

  /// Memory category emitted by this rule.
  final MemoryCategory category;

  /// Default importance emitted by this rule.
  final MemoryImportance importance;

  /// Default source emitted by this rule.
  final MemorySource source;

  /// Lowercase phrases that trigger this rule.
  final List<String> triggerPhrases;

  /// Reason emitted when this rule matches.
  final MemoryExtractionReason reason;

  /// Base confidence before confidence engine adjustments.
  final double baseConfidence;

  /// Optional TTL for temporary memories.
  final Duration? expiresAfter;

  /// Whether user can edit the emitted memory.
  final bool userEditable;

  /// Stable generated memory key.
  String get memoryKey => namespace.key(keyName);

  /// Whether this rule matches [normalizedText].
  bool matches(String normalizedText) {
    for (final phrase in triggerPhrases) {
      if (normalizedText.contains(phrase.toLowerCase())) return true;
    }
    return false;
  }
}

/// Built-in rule set for the first rule-based memory intelligence layer.
class MemoryRules {
  const MemoryRules._();

  /// Default deterministic rules. No NLP or LLM is used.
  static const defaults = <MemoryRule>[
    MemoryRule(
      id: 'goal_weight_loss',
      namespace: MemoryNamespace.goals,
      keyName: 'primary',
      category: MemoryCategory.goal,
      importance: MemoryImportance.high,
      source: MemorySource.user,
      triggerPhrases: <String>['هدفم کاهش وزن', 'میخوام لاغر', 'می‌خوام لاغر'],
      reason: MemoryExtractionReason.explicitGoal,
      baseConfidence: 0.78,
    ),
    MemoryRule(
      id: 'goal_muscle_gain',
      namespace: MemoryNamespace.goals,
      keyName: 'primary',
      category: MemoryCategory.goal,
      importance: MemoryImportance.high,
      source: MemorySource.user,
      triggerPhrases: <String>['عضله سازی', 'عضله‌سازی', 'حجم بگیرم'],
      reason: MemoryExtractionReason.explicitGoal,
      baseConfidence: 0.78,
    ),
    MemoryRule(
      id: 'restriction_injury',
      namespace: MemoryNamespace.restrictions,
      keyName: 'injury',
      category: MemoryCategory.restriction,
      importance: MemoryImportance.critical,
      source: MemorySource.user,
      triggerPhrases: <String>['آسیب', 'درد زانو', 'درد کمر', 'مصدوم'],
      reason: MemoryExtractionReason.restrictionMention,
      baseConfidence: 0.82,
    ),
    MemoryRule(
      id: 'equipment_home',
      namespace: MemoryNamespace.equipment,
      keyName: 'available',
      category: MemoryCategory.equipment,
      importance: MemoryImportance.medium,
      source: MemorySource.user,
      triggerPhrases: <String>['در خانه تمرین', 'تمرین در خانه', 'دمبل دارم'],
      reason: MemoryExtractionReason.equipmentMention,
      baseConfidence: 0.72,
    ),
    MemoryRule(
      id: 'nutrition_preference',
      namespace: MemoryNamespace.nutrition,
      keyName: 'preference',
      category: MemoryCategory.nutrition,
      importance: MemoryImportance.medium,
      source: MemorySource.user,
      triggerPhrases: <String>['رژیم', 'گیاهخوار', 'پروتئین', 'کالری'],
      reason: MemoryExtractionReason.nutritionMention,
      baseConfidence: 0.68,
    ),
    MemoryRule(
      id: 'recovery_signal',
      namespace: MemoryNamespace.recovery,
      keyName: 'current_signal',
      category: MemoryCategory.recovery,
      importance: MemoryImportance.medium,
      source: MemorySource.user,
      triggerPhrases: <String>['خسته‌ام', 'خسته ام', 'کوفتگی', 'ریکاوری'],
      reason: MemoryExtractionReason.recoveryMention,
      baseConfidence: 0.7,
      expiresAfter: Duration(days: 7),
    ),
    MemoryRule(
      id: 'app_feedback',
      namespace: MemoryNamespace.app,
      keyName: 'feedback',
      category: MemoryCategory.app,
      importance: MemoryImportance.low,
      source: MemorySource.user,
      triggerPhrases: <String>['اپ', 'برنامه خراب', 'باگ', 'پیشنهاد'],
      reason: MemoryExtractionReason.appFeedback,
      baseConfidence: 0.62,
      expiresAfter: Duration(days: 30),
    ),
  ];
}
