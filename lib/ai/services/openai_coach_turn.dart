import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/config/ai_engine_config.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/services/openai_client_rate_limiter.dart';
import 'package:gymaipro/ai/services/openai_http_client.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/ai/tools/coach_chat_tool_definitions.dart';
import 'package:gymaipro/ai/tools/coach_chat_tool_executor.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// One coach chat OpenAI turn: optional tool loop, then streamed/plain text.
class OpenAiCoachTurn {
  OpenAiCoachTurn({
    ChatSettings? settings,
    CoachChatToolExecutor? toolExecutor,
  }) : _settings =
           settings ??
           const ChatSettings(
             maxTokens: 2000,
             streamResponse: true,
           ),
       _toolExecutorOrNull = toolExecutor;

  final ChatSettings _settings;
  final CoachChatToolExecutor? _toolExecutorOrNull;
  CoachChatToolExecutor? _lazyToolExecutor;

  CoachChatToolExecutor get _toolExecutor =>
      _toolExecutorOrNull ??
      (_lazyToolExecutor ??= CoachChatToolExecutor());

  static const int _maxToolRounds = 3;
  static const int _directMaxAttempts = 3;

  /// Runs tool-enabled chat and yields text deltas (one chunk for non-stream).
  Stream<String> run({
    required String userId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    bool enableTools = true,
  }) async* {
    final apiMessages = _buildMessages(messages, systemPrompt);
    var working = List<Map<String, dynamic>>.from(apiMessages);

    if (enableTools) {
      for (var round = 0; round < _maxToolRounds; round++) {
        final turn = await _requestTurn(
          messages: working,
          tools: CoachChatToolDefinitions.tools,
          stream: false,
        );
        if (turn.toolCalls.isEmpty) {
          final text = turn.content.trim();
          if (text.isNotEmpty) {
            yield* _emitTyped(text);
          }
          return;
        }

        working = <Map<String, dynamic>>[
          ...working,
          <String, dynamic>{
            'role': 'assistant',
            'content': turn.content.isEmpty ? null : turn.content,
            'tool_calls': turn.toolCalls
                .map((call) => call.toJson())
                .toList(growable: false),
          },
          for (final call in turn.toolCalls)
            <String, dynamic>{
              'role': 'tool',
              'tool_call_id': call.id,
              'content': await _toolExecutor.execute(
                name: call.name,
                userId: userId,
                arguments: call.arguments,
              ),
            },
        ];
      }
    }

    if (_settings.streamResponse) {
      yield* _streamFinal(messages: working);
      return;
    }

    final finalTurn = await _requestTurn(
      messages: working,
      tools: null,
      stream: false,
    );
    if (finalTurn.content.trim().isNotEmpty) {
      yield* _emitTyped(finalTurn.content);
    }
  }

  /// Soft typing effect for already-complete text (no second API round-trip).
  Stream<String> _emitTyped(String text) async* {
    if (!_settings.streamResponse || text.length < 24) {
      yield text;
      return;
    }
    const step = 18;
    for (var i = 0; i < text.length; i += step) {
      final end = (i + step > text.length) ? text.length : i + step;
      yield text.substring(i, end);
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }
  }

  Stream<String> _streamFinal({
    required List<Map<String, dynamic>> messages,
  }) async* {
    try {
      yield* _streamCompletion(messages);
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('OpenAiCoachTurn: stream failed ($error) — fallback');
      }
      final fallback = await _requestTurn(
        messages: messages,
        tools: null,
        stream: false,
      );
      if (fallback.content.trim().isNotEmpty) {
        yield fallback.content;
      }
    }
  }

  Future<_CoachTurnResult> _requestTurn({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, Object?>>? tools,
    required bool stream,
  }) async {
    final body = <String, dynamic>{
      'model': _settings.model,
      'messages': messages,
      'temperature': _settings.temperature,
      'max_tokens': _settings.maxTokens,
      if (tools != null && tools.isNotEmpty) 'tools': tools,
      if (tools != null && tools.isNotEmpty) 'tool_choice': 'auto',
      if (stream) 'stream': true,
    };

    final payload = await _completeJson(body, const Duration(seconds: 90));
    return _CoachTurnResult.fromPayload(payload);
  }

  Stream<String> _streamCompletion(
    List<Map<String, dynamic>> messages,
  ) async* {
    final body = <String, dynamic>{
      'model': _settings.model,
      'messages': messages,
      'temperature': _settings.temperature,
      'max_tokens': _settings.maxTokens,
      'stream': true,
    };

    if (AiEngineConfig.usesServerProxyRoute) {
      yield* _proxyStream(body);
      return;
    }

    try {
      yield* _directStream(body);
    } on Object catch (error) {
      if (_canFallbackToProxy(error)) {
        yield* _proxyStream(body);
        return;
      }
      rethrow;
    }
  }

  Stream<String> _directStream(Map<String, dynamic> body) async* {
    await OpenAiClientRateLimiter.instance.acquire();
    final client = createOpenAiHttpClient();
    try {
      final request = http.Request(
        'POST',
        Uri.parse('${AppConfig.openaiDirectBaseUrl}/v1/chat/completions'),
      );
      request.headers.addAll(<String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.openaiApiKey}',
        'Accept': 'text/event-stream',
      });
      request.body = jsonEncode(body);

      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 90));
      if (streamed.statusCode != 200) {
        final errBody = await streamed.stream.bytesToString();
        throw OpenAIException('خطا در استریم AI: ${_extractError(errBody)}');
      }

      yield* _parseSse(streamed.stream);
    } finally {
      client.close();
    }
  }

  Stream<String> _proxyStream(Map<String, dynamic> body) async* {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw const OpenAIException(
        'برای استفاده از هوش مصنوعی ابتدا وارد حساب کاربری شوید.',
      );
    }

    final client = createOpenAiHttpClient();
    try {
      final request = http.Request(
        'POST',
        Uri.parse('${AppConfig.supabaseUrl}/functions/v1/openai-chat'),
      );
      request.headers.addAll(<String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': AppConfig.supabaseAnonKey,
        'Accept': 'text/event-stream',
      });
      request.body = jsonEncode(body);

      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 90));
      if (streamed.statusCode != 200) {
        final errBody = await streamed.stream.bytesToString();
        throw OpenAIException('خطا در استریم AI: ${_extractError(errBody)}');
      }

      final contentType = streamed.headers['content-type'] ?? '';
      if (contentType.contains('text/event-stream')) {
        yield* _parseSse(streamed.stream);
        return;
      }

      // Proxy may still return a full JSON payload.
      final raw = await streamed.stream.bytesToString();
      final turn = _CoachTurnResult.fromPayload(jsonDecode(raw));
      if (turn.content.trim().isNotEmpty) yield turn.content;
    } finally {
      client.close();
    }
  }

  Stream<String> _parseSse(Stream<List<int>> byteStream) async* {
    final buffer = StringBuffer();
    await for (final chunk in byteStream.transform(utf8.decoder)) {
      buffer.write(chunk);
      var data = buffer.toString();
      while (true) {
        final sep = data.indexOf('\n\n');
        if (sep < 0) {
          final crlf = data.indexOf('\r\n\r\n');
          if (crlf < 0) break;
          final event = data.substring(0, crlf);
          data = data.substring(crlf + 4);
          final delta = _deltaFromSseEvent(event);
          if (delta != null && delta.isNotEmpty) yield delta;
          continue;
        }
        final event = data.substring(0, sep);
        data = data.substring(sep + 2);
        final delta = _deltaFromSseEvent(event);
        if (delta != null && delta.isNotEmpty) yield delta;
      }
      buffer
        ..clear()
        ..write(data);
    }
  }

  String? _deltaFromSseEvent(String event) {
    final lines = event.split(RegExp(r'\r?\n'));
    final payloads = <String>[];
    for (final line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.startsWith('data:')) {
        payloads.add(trimmed.substring(5).trimLeft());
      }
    }
    if (payloads.isEmpty) return null;
    final payload = payloads.join('\n');
    if (payload == '[DONE]') return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) return null;
      final delta = first['delta'];
      if (delta is! Map) return null;
      final content = delta['content']?.toString();
      return content;
    } on Object {
      return null;
    }
  }

  Future<dynamic> _completeJson(
    Map<String, dynamic> body,
    Duration timeout,
  ) async {
    if (AiEngineConfig.usesServerProxyRoute) {
      return _proxyJson(body, timeout);
    }
    try {
      return await _directJson(body, timeout);
    } on Object catch (error) {
      if (_canFallbackToProxy(error)) {
        return _proxyJson(body, timeout);
      }
      rethrow;
    }
  }

  Future<dynamic> _proxyJson(
    Map<String, dynamic> body,
    Duration timeout,
  ) async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      throw const OpenAIException(
        'برای استفاده از هوش مصنوعی ابتدا وارد حساب کاربری شوید.',
      );
    }
    final response = await client.functions
        .invoke('openai-chat', body: body)
        .timeout(timeout);
    return response.data;
  }

  Future<dynamic> _directJson(
    Map<String, dynamic> body,
    Duration timeout,
  ) async {
    await OpenAiClientRateLimiter.instance.acquire();
    Object? lastError;
    for (var attempt = 1; attempt <= _directMaxAttempts; attempt++) {
      http.Client? client;
      try {
        if (attempt > 1) {
          await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
        }
        client = createOpenAiHttpClient();
        final response = await client
            .post(
              Uri.parse(
                '${AppConfig.openaiDirectBaseUrl}/v1/chat/completions',
              ),
              headers: <String, String>{
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${AppConfig.openaiApiKey}',
              },
              body: jsonEncode(body),
            )
            .timeout(timeout);
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
        throw OpenAIException(
          'خطا در ارتباط با AI: ${_extractError(response.body)}',
        );
      } on Object catch (error) {
        lastError = error;
        if (error is OpenAIException || !_isRetryable(error)) rethrow;
        if (attempt == _directMaxAttempts) rethrow;
      } finally {
        client?.close();
      }
    }
    throw lastError ?? const OpenAIException('خطا در اتصال به OpenAI');
  }

  List<Map<String, dynamic>> _buildMessages(
    List<ChatMessage> messages,
    String systemPrompt,
  ) {
    final apiMessages = <Map<String, dynamic>>[];
    if (systemPrompt.trim().isNotEmpty) {
      apiMessages.add(<String, dynamic>{
        'role': 'system',
        'content': systemPrompt,
      });
    }
    for (final message in messages) {
      if (message.isTyping) continue;
      apiMessages.add(<String, dynamic>{
        'role': message.type == ChatMessageType.user ? 'user' : 'assistant',
        'content': message.content,
      });
    }
    return apiMessages;
  }

  bool _canFallbackToProxy(Object error) {
    if (!AppConfig.openaiUseProxy || AiEngineConfig.usesServerProxyRoute) {
      return false;
    }
    return AppConfig.supabaseEdgeFunctionsEnabled &&
        Supabase.instance.client.auth.currentSession != null &&
        _isNetwork(error);
  }

  bool _isNetwork(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('timeout') ||
        text.contains('cancelled') ||
        text.contains('canceled');
  }

  bool _isRetryable(Object error) {
    if (error is OpenAIException) return false;
    final text = error.toString().toLowerCase();
    return text.contains('cancelled') ||
        text.contains('canceled') ||
        text.contains('connection reset') ||
        text.contains('timed out') ||
        text.contains('failed host lookup');
  }

  String _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map) {
          return error['message']?.toString() ?? 'خطای نامشخص';
        }
      }
    } on Object {
      // Fall through.
    }
    return body;
  }
}

class _CoachTurnResult {
  const _CoachTurnResult({
    required this.content,
    required this.toolCalls,
  });

  factory _CoachTurnResult.fromPayload(dynamic payload) {
    dynamic decoded = payload;
    if (decoded is String) {
      decoded = jsonDecode(decoded);
    }
    if (decoded is! Map) {
      throw const OpenAIException('پاسخ نامعتبر از سرور AI');
    }
    final map = Map<String, dynamic>.from(decoded);
    final error = map['error'];
    if (error != null) {
      if (error is Map) {
        throw OpenAIException(
          error['message']?.toString() ?? 'خطای نامشخص سرور AI',
        );
      }
      throw OpenAIException(error.toString());
    }
    final choices = map['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const OpenAIException('پاسخ خالی از سرور AI');
    }
    final first = choices.first;
    if (first is! Map) {
      throw const OpenAIException('ساختار پاسخ AI نامعتبر است');
    }
    final message = first['message'];
    if (message is! Map) {
      throw const OpenAIException('پیام AI یافت نشد');
    }
    final content = message['content']?.toString() ?? '';
    final rawCalls = message['tool_calls'];
    final toolCalls = <_ToolCall>[];
    if (rawCalls is List) {
      for (final item in rawCalls) {
        if (item is! Map) continue;
        final id = item['id']?.toString() ?? '';
        final function = item['function'];
        if (function is! Map) continue;
        final name = function['name']?.toString() ?? '';
        if (id.isEmpty || name.isEmpty) continue;
        toolCalls.add(
          _ToolCall(
            id: id,
            name: name,
            arguments: _parseArgs(function['arguments']),
          ),
        );
      }
    }
    return _CoachTurnResult(content: content, toolCalls: toolCalls);
  }

  final String content;
  final List<_ToolCall> toolCalls;

  static Map<String, Object?> _parseArgs(Object? raw) {
    if (raw is Map) {
      return Map<String, Object?>.from(raw);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, Object?>.from(decoded);
      } on Object {
        return const <String, Object?>{};
      }
    }
    return const <String, Object?>{};
  }
}

class _ToolCall {
  const _ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;
  final Map<String, Object?> arguments;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': 'function',
    'function': <String, dynamic>{
      'name': name,
      'arguments': jsonEncode(arguments),
    },
  };
}
