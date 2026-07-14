import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_explanation.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_reason.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_reason_type.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_execution_result.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_facade.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_facade_result.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:gymaipro/features/coach_chat/navigation/coach_chat_route.dart';
import 'package:gymaipro/features/coach_chat/presentation/screens/coach_chat_screen.dart';
import 'package:gymaipro/features/coach_chat/state/coach_chat_state.dart';
import 'package:gymaipro/features/coach_chat/view_models/coach_chat_view_model.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

void main() {
  test('CoachChatFacade.load returns empty conversation', () async {
    final facade = CoachChatFacade(
      seedLoader: const _FakeSeedLoader(),
      previewLoader: _unusedPreviewLoader,
    );

    final result = await facade.load();

    expect(result.state.isEmpty, true);
    expect(result.state.messages, isEmpty);
    expect(result.state.suggestedPrompts, isNotEmpty);
  });

  test('CoachChatFacade maps coach response cards', () async {
    Map<String, Object?>? metadataSeen;
    final facade = CoachChatFacade(
      seedLoader: const _FakeSeedLoader(),
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
      coachLoader: ({
        required userMessage,
        userId = 'preview_user',
        context,
        metadata = const <String, Object?>{},
      }) async {
        metadataSeen = metadata;
        expect(context, isNotNull);
        return _integrationResult();
      },
    );

    final result = await facade.send('تمرین امروز چیه؟');

    expect(metadataSeen?['feature'], 'coach_chat');
    expect(result.message.type, CoachChatMessageType.localSkillResponse);
    expect(result.message.cards, isNotEmpty);
    expect(result.message.text, contains('تمرکز امروز'));
  });

  test('CoachChatViewModel load shows empty state', () async {
    final viewModel = CoachChatViewModel(
      facade: _FakeCoachChatFacade(),
    );

    await viewModel.load();

    expect(viewModel.state.isEmpty, true);
    expect(viewModel.state.messages, isEmpty);
  });

  test('CoachChatViewModel sends user message then coach response', () async {
    final viewModel = CoachChatViewModel(
      facade: _FakeCoachChatFacade(),
    );

    await viewModel.sendMessage('سلام');

    expect(viewModel.state.isLoaded, true);
    expect(viewModel.state.messages.length, 2);
    expect(viewModel.state.messages.first.role, CoachChatMessageRole.user);
    expect(viewModel.state.messages.last.role, CoachChatMessageRole.coach);
  });

  test('CoachChatViewModel exposes thinking while preview is pending', () async {
    final completer = Completer<CoachChatPreviewResponse>();
    final viewModel = CoachChatViewModel(
      facade: _PendingCoachChatFacade(completer),
    );

    unawaited(viewModel.sendMessage('ریکاوری من چطوره؟'));
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.isThinking, true);
    expect(viewModel.state.messages.length, 1);

    completer.complete(_coachResponse());
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.isThinking, false);
    expect(viewModel.state.messages.length, 2);
  });

  testWidgets('CoachChatScreen renders empty state and suggested chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CoachChatScreen(autoLoad: false),
      ),
    );

    expect(find.text(ProductCopy.coachName), findsOneWidget);
    expect(find.textContaining('من مربی هستم'), findsOneWidget);
    expect(find.text('تمرین امروز'), findsOneWidget);
    expect(find.text('ریکاوری'), findsWidgets);
  });

  testWidgets('CoachChatScreen autoLoad shows empty state after facade load', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CoachChatScreen(
          viewModel: CoachChatViewModel(
            facade: _FakeCoachChatFacade(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('من مربی هستم'), findsOneWidget);
    expect(find.text('تمرین امروز'), findsOneWidget);
  });

  testWidgets('CoachChatScreen renders conversation cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CoachChatScreen(
          viewModel: CoachChatViewModel(
            initialState: CoachChatState(
              status: CoachChatStatus.loaded,
              messages: <CoachChatMessage>[
                _userMessage(),
                _coachResponse().message,
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('تمرین امروز چیه؟'), findsOneWidget);
    expect(find.textContaining('تمرکز امروز'), findsOneWidget);
    expect(find.text('دلایل'), findsOneWidget);
  });

  testWidgets('CoachChatScreen renders loading skeleton and error state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CoachChatScreen(
          viewModel: CoachChatViewModel(
            initialState: const CoachChatState.loading(),
          ),
        ),
      ),
    );
    expect(find.byType(ListView), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: CoachChatScreen(
          key: const ValueKey<String>('coach-chat-error'),
          viewModel: CoachChatViewModel(
            initialState: const CoachChatState.error('خطای تست'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('خطای تست'), findsWidgets);
    expect(find.text('تلاش دوباره'), findsWidgets);
  });

  test('CoachChatRoute builds CoachChatScreen route', () {
    final route = CoachChatRoute.build(
      const RouteSettings(name: CoachChatRoute.routeName),
    );

    expect(route.settings.name, CoachChatRoute.routeName);
    expect(CoachChatRoute.routeName, '/coach-chat');
  });
}

class _FakeSeedLoader implements CoachPreviewSeedProvider {
  const _FakeSeedLoader();

  @override
  Future<CoachPreviewSeed> load({
    required AIIntent intent,
    required String message,
  }) async {
    return CoachPreviewSeed(
      userId: 'user_1',
      context: _context(),
      message: message,
      intent: intent,
    );
  }
}

class _FakeCoachChatFacade extends CoachChatFacade {
  _FakeCoachChatFacade()
    : super(
        previewLoader: _unusedPreviewLoader,
        programResolver: CoachProgramResolver(programLoader: (_) async => null),
      );

  @override
  Future<CoachChatFacadeResult> load() async {
    return const CoachChatFacadeResult(
      state: CoachChatState.empty(),
    );
  }

  @override
  Future<CoachChatPreviewResponse> send(
    String prompt, {
    List<ChatMessage> history = const <ChatMessage>[],
  }) async {
    return _coachResponse();
  }

  @override
  Future<void> persistMessages(List<CoachChatMessage> messages) async {}
}

class _PendingCoachChatFacade extends CoachChatFacade {
  _PendingCoachChatFacade(this.completer)
    : super(
        previewLoader: _unusedPreviewLoader,
        programResolver: CoachProgramResolver(programLoader: (_) async => null),
      );

  final Completer<CoachChatPreviewResponse> completer;

  @override
  Future<CoachChatPreviewResponse> send(
    String prompt, {
    List<ChatMessage> history = const <ChatMessage>[],
  }) {
    return completer.future;
  }

  @override
  Future<void> persistMessages(List<CoachChatMessage> messages) async {}
}

Never _unusedPreviewLoader({
  required String userMessage,
  String userId = 'preview_user',
  CoachContext? context,
  Map<String, Object?> metadata = const <String, Object?>{},
}) {
  throw UnimplementedError();
}

CoachChatMessage _userMessage() {
  return CoachChatMessage(
    id: 'user_1',
    role: CoachChatMessageRole.user,
    type: CoachChatMessageType.normal,
    text: 'تمرین امروز چیه؟',
    createdAt: DateTime(2026, 7, 13),
  );
}

CoachChatPreviewResponse _coachResponse() {
  return CoachChatPreviewResponse(
    message: CoachChatMessage(
      id: 'coach_1',
      role: CoachChatMessageRole.coach,
      type: CoachChatMessageType.localSkillResponse,
      text: 'تمرکز امروز: Pull Day',
      createdAt: DateTime(2026, 7, 13),
      cards: const <CoachChatMessageCard>[
        CoachChatMessageCard(
          type: CoachChatCardType.reason,
          title: 'Reasons',
          items: <String>['Recovery is ready.'],
        ),
      ],
    ),
  );
}

CoachIntegrationResult _integrationResult() {
  return CoachIntegrationResult.local(
    intent: AIIntent.workoutToday,
    coachContext: _context(),
    skillExecution: const CoachSkillExecutionResult(
      skillId: 'workout_today_skill',
      response: CoachSkillResponse(
        confidence: 0.9,
        requiresAI: false,
        message: 'تمرکز امروز: Pull Day',
        reasons: <SkillReason>[
          SkillReason(
            type: SkillReasonType.recoveryStatus,
            message: 'Recovery is ready.',
          ),
        ],
        explanation: SkillExplanation(
          summary: 'Explainability',
          bullets: <String>['Preview used today workout context.'],
        ),
        nextActions: <String>['Open Workout Today'],
      ),
      executionTime: Duration(milliseconds: 1),
      success: true,
    ),
    processingTime: const Duration(milliseconds: 1),
    logs: const [],
    pipelineMode: CoachPipelineMode.runtime,
  );
}

CoachContext _context() {
  return CoachContext(
    intent: AIIntent.workoutToday,
    metadata: CoachContextMetadata(
      buildTime: DateTime(2026, 7, 13),
      sourceCount: 1,
      missingProviders: const {},
      confidence: 0.9,
      contextVersion: CoachContext.contextVersion,
    ),
  );
}
