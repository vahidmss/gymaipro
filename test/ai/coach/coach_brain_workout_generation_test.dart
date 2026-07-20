import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/coach/coach_brain.dart';
import 'package:gymaipro/ai/coach/coach_rules.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/knowledge_registry.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_trace.dart';

void main() {
  group('CoachBrain workout generation guided Q&A', () {
    test('asks for age first when profile is incomplete', () {
      final decision = const CoachBrain().decide(
        context: _context(
          profile: const <String, Object?>{'first_name': 'وحید'},
        ),
        knowledgeResult: _knowledge(),
      );

      expect(decision.shouldCallAI, isFalse);
      expect(decision.requiresFollowUp, isTrue);
      expect(decision.followUpQuestion, CoachRules.followUpPromptFor('age'));
      expect(decision.missingData, contains('age'));
    });

    test('asks for equipment after profile and goal are present', () {
      final decision = const CoachBrain().decide(
        context: _context(
          profile: const <String, Object?>{
            'first_name': 'وحید',
            'age': 28,
            'height': 178,
            'weight': 80,
            'goal': 'عضله‌سازی',
          },
          goals: const <String>['عضله‌سازی'],
        ),
        knowledgeResult: _knowledge(),
      );

      expect(decision.shouldCallAI, isFalse);
      expect(decision.followUpQuestion, CoachRules.followUpPromptFor('equipment'));
      expect(decision.missingData, contains('equipment'));
    });

    test('allows AI when generation fields are complete', () {
      final decision = const CoachBrain().decide(
        context: _context(
          profile: const <String, Object?>{
            'first_name': 'وحید',
            'age': 28,
            'height': 178,
            'weight': 80,
            'goal': 'عضله‌سازی',
          },
          goals: const <String>['عضله‌سازی'],
          equipment: const <String>['باشگاه'],
        ),
        knowledgeResult: _knowledge(),
      );

      expect(decision.shouldCallAI, isTrue);
      expect(decision.missingData, isEmpty);
      expect(decision.followUpQuestion, isNull);
    });
  });
}

CoachContext _context({
  Map<String, Object?> profile = const <String, Object?>{},
  List<String> goals = const <String>[],
  List<String> equipment = const <String>[],
}) {
  return CoachContext(
    intent: AIIntent.workoutGeneration,
    profile: profile,
    goals: goals,
    equipment: equipment,
    metadata: CoachContextMetadata(
      buildTime: DateTime(2026, 7, 16),
      sourceCount: 1,
      missingProviders: const {},
      confidence: 0.9,
      contextVersion: CoachContext.contextVersion,
    ),
  );
}

CoachKnowledgeResult _knowledge() {
  final node = KnowledgeRegistry.nodes['workout_generation']!;
  return CoachKnowledgeResult(
    selectedNode: node,
    candidateNodes: <KnowledgeNode>[node],
    confidence: 0.9,
    reasons: const <String>['test'],
    trace: CoachKnowledgeTrace(
      nodeTraces: const <CoachKnowledgeNodeTrace>[],
      executionTime: const Duration(milliseconds: 1),
      selectedNodeId: node.id,
      usedFallback: false,
    ),
  );
}
