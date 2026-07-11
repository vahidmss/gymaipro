import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/config/ai_engine_config.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/services/openai_client_rate_limiter.dart';
import 'package:gymaipro/ai/services/openai_http_client.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس AI — مسیر proxy (`openai-chat`) یا مستقیم کلاینت بسته به OPENAI_USE_PROXY.
class OpenAIService {
  OpenAIService({ChatSettings? settings})
    : _settings =
          settings ??
          const ChatSettings(
            maxTokens: 2000,
          );

  String get _apiKey => AppConfig.openaiApiKey;

  bool get _useServerProxy => AiEngineConfig.usesServerProxyRoute;

  bool get _canUseDirect =>
      !AppConfig.openaiUseProxy && _apiKey.isNotEmpty;

  final ChatSettings _settings;

  static const int _directMaxAttempts = 3;

  void _ensureCallable() {
    if (_useServerProxy) {
      return;
    }
    if (_apiKey.isEmpty) {
      throw OpenAIException(
        AppConfig.openaiUseProxy
            ? 'OPENAI_USE_PROXY=true است اما proxy در دسترس نیست. '
                  'Edge Function openai-chat را deploy کنید یا OPENAI_USE_PROXY=false بگذارید.'
            : 'کلید OPENAI_API_KEY تنظیم نشده است.\n'
                  'در env.web.json (وب) یا --dart-define-from-file=.env (موبایل) '
                  'OPENAI_API_KEY=... را قرار دهید.\n'
                  'کلید را در داشبورد OpenAI محدود کنید (سقف هزینه + محدودیت مدل).',
      );
    }
  }

  /// Raw chat completion — returns assistant text (for JSON/metadata pipelines).
  Future<String> sendCompletion({
    required List<Map<String, String>> messages,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? responseFormat,
    Duration? requestTimeout,
  }) async {
    _ensureCallable();

    final requestBody = <String, dynamic>{
      'model': model ?? _settings.model,
      'messages': messages,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (responseFormat != null) 'response_format': responseFormat,
    };

    final timeout = requestTimeout ?? const Duration(seconds: 90);
    return _complete(requestBody, timeout);
  }

  /// ارسال پیام به AI
  Future<ChatMessage> sendMessage({
    required List<ChatMessage> messages,
    String? systemPrompt,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          'OpenAI: route=${_useServerProxy ? "server-proxy" : "direct"} '
          'messages=${messages.length}',
        );
      }

      _ensureCallable();

      final requestBody = <String, dynamic>{
        'model': _settings.model,
        'messages': _buildMessages(messages, systemPrompt),
        'temperature': _settings.temperature,
        'max_tokens': _settings.maxTokens,
      };
      if (!_useServerProxy && _settings.streamResponse) {
        requestBody['stream'] = true;
      }

      final timeout = const Duration(seconds: 90);
      final content = await _complete(requestBody, timeout);

      if (kDebugMode) {
        debugPrint(
          'OpenAI: Response received: '
          '${content.substring(0, content.length > 100 ? 100 : content.length)}...',
        );
      }

      return ChatMessage.ai(content: content);
    } on OpenAIException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OpenAI: Exception: $e');
      }
      if (_isNetworkError(e)) {
        throw OpenAIException(_networkErrorMessage(e));
      }
      throw OpenAIException('خطای غیرمنتظره: $e');
    }
  }

  Future<String> _complete(
    Map<String, dynamic> requestBody,
    Duration timeout,
  ) async {
    if (_useServerProxy) {
      return _proxyCompletion(requestBody, timeout);
    }

    try {
      return await _directCompletion(requestBody, timeout);
    } catch (e) {
      if (_canFallbackToProxy(e)) {
        if (kDebugMode) {
          debugPrint(
            'OpenAI: direct route failed ($e) — falling back to server-proxy',
          );
        }
        return _proxyCompletion(requestBody, timeout);
      }
      rethrow;
    }
  }

  Future<String> _proxyCompletion(
    Map<String, dynamic> requestBody,
    Duration timeout,
  ) async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      throw const OpenAIException(
        'برای استفاده از هوش مصنوعی ابتدا وارد حساب کاربری شوید.',
      );
    }

    final response = await client.functions
        .invoke('openai-chat', body: requestBody)
        .timeout(timeout);

    return _parseCompletionPayload(response.data);
  }

  Future<String> _directCompletion(
    Map<String, dynamic> requestBody,
    Duration timeout,
  ) async {
    await OpenAiClientRateLimiter.instance.acquire();

    final baseUrl = AppConfig.openaiDirectBaseUrl;
    Object? lastError;

    for (var attempt = 1; attempt <= _directMaxAttempts; attempt++) {
      http.Client? client;
      try {
        if (attempt > 1) {
          final delayMs = 400 * attempt;
          if (kDebugMode) {
            debugPrint('OpenAI: direct retry $attempt/$_directMaxAttempts');
          }
          await Future<void>.delayed(Duration(milliseconds: delayMs));
        }

        client = createOpenAiHttpClient();
        final response = await client
            .post(
              Uri.parse('$baseUrl/v1/chat/completions'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          return _parseCompletionPayload(response.body);
        }

        final errorMessage = _extractErrorMessage(response.body);
        throw OpenAIException(
          'خطا در ارتباط با AI: $errorMessage',
        );
      } catch (e) {
        lastError = e;
        if (e is OpenAIException || !_isRetryableNetworkError(e)) {
          rethrow;
        }
        if (attempt == _directMaxAttempts) {
          rethrow;
        }
      } finally {
        client?.close();
      }
    }

    throw lastError ?? const OpenAIException('خطا در اتصال به OpenAI');
  }

  String _parseCompletionPayload(dynamic payload) {
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

    final content = message['content']?.toString();
    if (content == null || content.isEmpty) {
      throw const OpenAIException('متن پاسخ AI خالی است');
    }
    return content;
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded['error']?['message']?.toString() ?? 'خطای نامشخص';
      }
    } catch (_) {}
    return body;
  }

  bool _isNetworkError(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('timeout') ||
        text.contains('cancelled') ||
        text.contains('canceled');
  }

  bool _isRetryableNetworkError(Object e) {
    if (e is OpenAIException) return false;
    final text = e.toString().toLowerCase();
    return text.contains('cancelled') ||
        text.contains('canceled') ||
        text.contains('already closed') ||
        text.contains('connection reset') ||
        text.contains('broken pipe') ||
        text.contains('timed out') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable');
  }

  bool _canFallbackToProxy(Object e) {
    if (!AppConfig.openaiUseProxy || _useServerProxy || !_isNetworkError(e)) {
      return false;
    }
    return AppConfig.supabaseEdgeFunctionsEnabled &&
        Supabase.instance.client.auth.currentSession != null;
  }

  String _networkErrorMessage(Object e) {
    final text = e.toString().toLowerCase();
    if (text.contains('cancelled') || text.contains('canceled')) {
      return 'اتصال به OpenAI قطع شد. لطفاً دوباره تلاش کنید.';
    }
    if (text.contains('timeout') || text.contains('timed out')) {
      return 'پاسخ OpenAI زمان‌بر شد. دوباره تلاش کنید.';
    }
    return 'خطا در اتصال به OpenAI. اینترنت را بررسی کنید و دوباره امتحان کنید.';
  }

  List<Map<String, String>> _buildMessages(
    List<ChatMessage> messages,
    String? systemPrompt,
  ) {
    final apiMessages = <Map<String, String>>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      apiMessages.add({'role': 'system', 'content': systemPrompt});
    }

    for (final message in messages) {
      if (!message.isTyping) {
        apiMessages.add({
          'role': message.type == ChatMessageType.user ? 'user' : 'assistant',
          'content': message.content,
        });
      }
    }

    return apiMessages;
  }

  Future<http.Response> _getDirect(
    Uri uri, {
    required Duration timeout,
  }) async {
    final client = createOpenAiHttpClient();
    try {
      return await client
          .get(
            uri,
            headers: {'Authorization': 'Bearer $_apiKey'},
          )
          .timeout(timeout);
    } finally {
      client.close();
    }
  }

  /// تست اتصال — روی proxy فقط نشست کاربر را بررسی می‌کند.
  Future<bool> testConnection() async {
    try {
      if (_useServerProxy) {
        return Supabase.instance.client.auth.currentSession != null;
      }
      if (!_canUseDirect) return false;

      final baseUrl = AppConfig.openaiDirectBaseUrl;
      final response = await _getDirect(
        Uri.parse('$baseUrl/v1/models'),
        timeout: const Duration(seconds: 30),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OpenAI: Connection test failed: $e');
      }
      return false;
    }
  }

  Future<List<String>> getAvailableModels() async {
    if (_useServerProxy) {
      return [AppConfig.aiDefaultModel, AppConfig.aiReasoningModel];
    }

    try {
      final baseUrl = AppConfig.openaiDirectBaseUrl;
      final response = await _getDirect(
        Uri.parse('$baseUrl/v1/models'),
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final models = <String>[];
        for (final model in data['data'] as List<dynamic>) {
          final modelId = (model as Map<String, dynamic>)['id'] as String;
          if (modelId.startsWith('gpt-') ||
              modelId.startsWith('o1') ||
              modelId.startsWith('o3')) {
            models.add(modelId);
          }
        }
        return models;
      }
      throw const OpenAIException('خطا در دریافت مدل‌ها');
    } catch (e) {
      throw OpenAIException('خطا در دریافت مدل‌ها: $e');
    }
  }

  void dispose() {}
}

class OpenAIException implements Exception {
  const OpenAIException(this.message);
  final String message;

  @override
  String toString() => 'OpenAIException: $message';
}

class GymAIPrompts {
  static const String defaultPrompt = '''
شما یک مربی ورزشی و متخصص تغذیه هوش مصنوعی هستید که به کاربران در زمینه‌های زیر کمک می‌کنید:

1. **برنامه‌ریزی تمرینی**: طراحی برنامه‌های تمرینی متناسب با سطح و اهداف کاربر
2. **تغذیه ورزشی**: راهنمایی در مورد رژیم غذایی مناسب برای ورزشکاران
3. **تکنیک‌های تمرین**: آموزش صحیح انجام حرکات ورزشی
4. **انگیزه و مشاوره**: ارائه انگیزه و راهنمایی برای رسیدن به اهداف

**قوانین مهم:**
- همیشه پاسخ‌های خود را به فارسی ارائه دهید
- از اصطلاحات تخصصی ورزشی استفاده کنید اما توضیح دهید
- ایمنی کاربر را در اولویت قرار دهید
- در صورت نیاز به مشاوره پزشکی، کاربر را به پزشک ارجاع دهید
- پاسخ‌های خود را کوتاه و مفید نگه دارید
- از emoji مناسب استفاده کنید

**سبک پاسخ‌دهی:**
- دوستانه و انگیزه‌بخش
- علمی اما قابل فهم
- عملی و قابل اجرا
- مثبت و تشویق‌کننده
''';

  static const String workoutPrompt = '''
شما یک مربی ورزشی حرفه‌ای هستید. در پاسخ‌های خود:

1. **برنامه‌ریزی**: برنامه‌های تمرینی متناسب با سطح کاربر ارائه دهید
2. **تکنیک**: نحوه صحیح انجام حرکات را توضیح دهید
3. **ایمنی**: نکات ایمنی مهم را ذکر کنید
4. **پیشرفت**: راه‌های بهبود و پیشرفت را پیشنهاد دهید

همیشه سطح تجربه کاربر را در نظر بگیرید و برنامه‌های مناسب ارائه دهید.
''';

  static const String nutritionPrompt = '''
شما یک متخصص تغذیه ورزشی هستید. در پاسخ‌های خود:

1. **رژیم غذایی**: برنامه‌های غذایی متناسب با اهداف ورزشی ارائه دهید
2. **مکمل‌ها**: در مورد مکمل‌های ورزشی راهنمایی کنید
3. **هیدراتاسیون**: اهمیت آب و مایعات را توضیح دهید
4. **زمان‌بندی**: زمان مناسب مصرف غذا و مکمل‌ها را مشخص کنید

همیشه نیازهای فردی کاربر را در نظر بگیرید و توصیه‌های عملی ارائه دهید.
''';
}
