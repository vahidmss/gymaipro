import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_facade.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:gymaipro/features/coach_chat/state/coach_chat_state.dart';
import 'package:gymaipro/features/product_experience/product_analytics.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

class CoachChatViewModel extends ChangeNotifier {
  CoachChatViewModel({
    CoachChatFacade? facade,
    CoachChatState initialState = const CoachChatState.empty(),
  }) : _facade = facade,
       _state = initialState;

  final CoachChatFacade? _facade;
  CoachChatState _state;
  bool _loaded = false;
  bool _isDisposed = false;
  int _requestToken = 0;

  CoachChatState get state => _state;

  @override
  void dispose() {
    _isDisposed = true;
    _requestToken++;
    super.dispose();
  }

  Future<void> load() async {
    if (_loaded || _isDisposed) return;
    _loaded = true;
    await _fetch();
  }

  Future<void> refresh() async {
    if (_isDisposed) return;
    _loaded = false;
    await load();
  }

  Future<void> _fetch() async {
    if (_isDisposed) return;
    final token = ++_requestToken;
    _setState(
      CoachChatState(
        status: CoachChatStatus.loading,
        messages: _state.messages,
        suggestedPrompts: _state.suggestedPrompts,
        isThinking: true,
        thinkingSteps: _state.thinkingSteps,
        quota: _state.quota,
      ),
    );
    try {
      final result = await (_facade ?? CoachChatFacade()).load();
      if (_isDisposed || token != _requestToken) return;
      ProductAnalytics.track(ProductAnalyticsEvent.coachChatOpened);
      _setState(result.state);
    } on Object catch (error) {
      if (_isDisposed || token != _requestToken) return;
      _setState(
        CoachChatState(
          status: CoachChatStatus.error,
          messages: _state.messages,
          suggestedPrompts: _state.suggestedPrompts,
          errorMessage: error.toString(),
          thinkingSteps: _state.thinkingSteps,
          quota: _state.quota,
        ),
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _state.isThinking || _isDisposed) return;
    if (!_state.canSendChat) return;

    ProductAnalytics.track(ProductAnalyticsEvent.coachChatMessageSent);

    final userMessage = CoachChatMessage(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      role: CoachChatMessageRole.user,
      type: CoachChatMessageType.normal,
      text: prompt,
      createdAt: DateTime.now(),
    );
    final streamingId = 'coach_stream_${DateTime.now().microsecondsSinceEpoch}';
    final token = ++_requestToken;
    _setState(
      _state.copyWith(
        status: CoachChatStatus.loaded,
        messages: <CoachChatMessage>[..._state.messages, userMessage],
        isThinking: true,
        thinkingSteps: ProductExperienceFormatter.thinkingSteps(null),
        errorMessage: '',
      ),
    );

    var insertedStreamingBubble = false;

    try {
      final history = _state.messages
          .where(
            (message) =>
                message.role == CoachChatMessageRole.user ||
                message.role == CoachChatMessageRole.coach,
          )
          .map(
            (message) => message.role == CoachChatMessageRole.user
                ? ChatMessage.user(content: message.text)
                : ChatMessage.ai(content: message.text),
          )
          .toList(growable: false);

      final response = await (_facade ?? CoachChatFacade()).send(
        prompt,
        history: history,
        onPartialText: (partial) {
          if (_isDisposed || token != _requestToken) return;
          if (!insertedStreamingBubble) {
            insertedStreamingBubble = true;
            _setState(
              _state.copyWith(
                isThinking: false,
                messages: <CoachChatMessage>[
                  ..._state.messages,
                  CoachChatMessage(
                    id: streamingId,
                    role: CoachChatMessageRole.coach,
                    type: CoachChatMessageType.aiResponse,
                    text: partial,
                    createdAt: DateTime.now(),
                    isStreaming: true,
                  ),
                ],
              ),
            );
            return;
          }
          final messages = List<CoachChatMessage>.from(_state.messages);
          final index = messages.indexWhere((m) => m.id == streamingId);
          if (index < 0) return;
          messages[index] = messages[index].copyWith(
            text: partial,
            isStreaming: true,
          );
          _setState(_state.copyWith(messages: messages, isThinking: false));
        },
      );
      if (_isDisposed || token != _requestToken) return;

      final messages = List<CoachChatMessage>.from(_state.messages);
      final streamIndex = messages.indexWhere((m) => m.id == streamingId);
      if (streamIndex >= 0) {
        messages[streamIndex] = response.message.copyWith(
          id: streamingId,
          isStreaming: false,
        );
      } else {
        messages.add(response.message.copyWith(isStreaming: false));
      }

      final quota = await (_facade ?? CoachChatFacade()).loadQuota();
      if (_isDisposed || token != _requestToken) return;

      _setState(
        _state.copyWith(
          status: CoachChatStatus.loaded,
          messages: messages,
          isThinking: false,
          thinkingSteps: response.thinkingSteps,
          errorMessage: '',
          quota: quota,
        ),
      );
      if (_isDisposed || token != _requestToken) return;
      await (_facade ?? CoachChatFacade()).persistMessages(_state.messages);
    } on Object catch (error) {
      if (_isDisposed || token != _requestToken) return;
      final messages = List<CoachChatMessage>.from(_state.messages)
        ..removeWhere((m) => m.id == streamingId && m.isStreaming);
      _setState(
        _state.copyWith(
          status: CoachChatStatus.error,
          messages: messages,
          isThinking: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> sendSuggestedPrompt(CoachChatSuggestedPrompt prompt) {
    return sendMessage(prompt.prompt);
  }

  void retryLast() {
    if (_isDisposed) return;
    final lastUserMessage = _state.messages.reversed
        .where((message) => message.role == CoachChatMessageRole.user)
        .firstOrNull;
    if (lastUserMessage == null) return;
    _setState(_state.copyWith(status: CoachChatStatus.loaded, errorMessage: ''));
    unawaited(sendMessage(lastUserMessage.text));
  }

  void _setState(CoachChatState state) {
    if (_isDisposed) return;
    _state = state;
    notifyListeners();
  }
}
