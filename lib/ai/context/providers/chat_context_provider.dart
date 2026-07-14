import 'package:gymaipro/ai/context/coach_context_patch.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides chat-specific context such as the current question.
///
/// Deprecated migration path: profile and preferences context moved to
/// ProfileContextProvider and PreferencesContextProvider. Keep this provider for
/// current-question and future chat-history context only.
@Deprecated(
  'Use granular chat/current-question provider migration for new code.',
)
class ChatContextProvider implements AIContextProvider {
  @Deprecated(
    'Use granular chat/current-question provider migration for new code.',
  )
  ChatContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  // ignore: unused_field
  final AIContextRepository _repository;

  @override
  String get id => 'chat_context_provider';

  @override
  String get name => 'Chat Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.currentQuestion,
    AIContextProviderKey.chatHistory,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.currentQuestion,
    AIContextSection.chat,
  };

  @override
  AIContextProviderMetadata get metadata => AIContextProviderMetadata(
    name: name,
    priority: priority,
    estimatedCost: estimatedCost,
    estimatedLatency: estimatedLatency,
    cacheable: cacheable,
    ttl: ttl,
  );

  @override
  ContextPriority get priority => ContextPriority.high;

  @override
  double get estimatedCost => 0;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 120);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 5);

  @override
  Future<CoachContextPatch> build(AIContextRequest request) async {
    return CoachContextPatch(currentQuestion: request.currentQuestion);
  }
}
