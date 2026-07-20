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
    _setState(const CoachChatState.loading());
    try {
      final result = await (_facade ?? CoachChatFacade()).load();
      if (_isDisposed || token != _requestToken) return;
      ProductAnalytics.track(ProductAnalyticsEvent.coachChatOpened);
      _setState(result.state);
    } on Object catch (error) {
      if (_isDisposed || token != _requestToken) return;
      _setState(CoachChatState.error(error.toString()));
    }
  }

  Future<void> sendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _state.isThinking || _isDisposed) return;

    ProductAnalytics.track(ProductAnalyticsEvent.coachChatMessageSent);

    final userMessage = CoachChatMessage(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      role: CoachChatMessageRole.user,
      type: CoachChatMessageType.normal,
      text: prompt,
      createdAt: DateTime.now(),
    );
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
      );
      if (_isDisposed || token != _requestToken) return;
      _setState(
        _state.copyWith(
          status: CoachChatStatus.loaded,
          messages: <CoachChatMessage>[
            ..._state.messages,
            response.message,
          ],
          isThinking: false,
          thinkingSteps: response.thinkingSteps,
          errorMessage: '',
        ),
      );
      if (_isDisposed || token != _requestToken) return;
      await (_facade ?? CoachChatFacade()).persistMessages(_state.messages);
    } on Object catch (error) {
      if (_isDisposed || token != _requestToken) return;
      _setState(
        _state.copyWith(
          status: CoachChatStatus.error,
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
