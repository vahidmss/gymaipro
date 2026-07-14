import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context_assembler.dart';
import 'package:gymaipro/ai/context/context_builder.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_definitions.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_planner.dart';
import 'package:gymaipro/ai/prompt/prompt_builder.dart';

void main() {
  test('request memory snapshot is projected into context and prompt', () async {
    final timestamp = DateTime(2026);
    final heightMemory = CoachMemory(
      key: 'profile.height',
      value: '182',
      category: MemoryCategory.profile,
      confidence: 0.9,
      importance: MemoryImportance.medium,
      source: MemorySource.inference,
      createdAt: timestamp,
      updatedAt: timestamp,
      editable: true,
      userEditable: true,
      aiGenerated: true,
    );
    final assembler = CoachContextAssembler(
      contextBuilder: AIContextBuilder(),
    );
    const intent = AIIntent.workoutGeneration;

    final context = await assembler.assemble(
      request: AIContextRequest(
        userId: 'user_1',
        intent: intent,
        currentQuestion: 'قدمم ۱۸۲ سانته',
        memorySnapshot: <CoachMemory>[heightMemory],
      ),
      intent: intent,
      selection: AIContextProviderSelection(
        intentDefinition: AIIntentDefinitions.forIntent(intent),
        requiredProviders: const <AIContextProvider>[],
        optionalProviders: const <AIContextProvider>[],
        missingRequiredProviders: const <AIContextProviderKey>{},
        missingOptionalProviders: const <AIContextProviderKey>{},
      ),
      buildTime: timestamp,
    );

    expect(context.profile['height'], 182);
    expect(context.memories, contains(heightMemory));

    const planner = CoachPromptPlanner();
    final promptPlan = planner.plan(
      CoachPromptPlanningRequest(
        coachContext: context,
        createdAt: timestamp,
      ),
    );
    final promptPackage = const PromptBuilder().buildFromPlan(promptPlan);

    expect(promptPackage.memoryKeys, contains('profile.height'));
    expect(
      promptPackage.sections.any((section) => section.id == 'context.profile'),
      isTrue,
    );
  });
}
