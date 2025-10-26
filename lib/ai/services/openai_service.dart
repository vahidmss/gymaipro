import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:http/http.dart' as http;

/// سرویس OpenAI برای ارتباط با API
class OpenAIService {
  OpenAIService({ChatSettings? settings})
    : _settings =
          settings ??
          const ChatSettings(
            maxTokens: 2000, // افزایش برای JSON کامل
          );
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');

  final http.Client _client = http.Client();
  final ChatSettings _settings;

  /// ارسال پیام به OpenAI
  Future<ChatMessage> sendMessage({
    required List<ChatMessage> messages,
    String? systemPrompt,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw const OpenAIException('کلید OPENAI_API_KEY تنظیم نشده است');
      }
      if (kDebugMode) {
        print('OpenAI: Sending message with ${messages.length} messages');
      }

      final requestBody = {
        'model': _settings.model,
        'messages': _buildMessages(messages, systemPrompt),
        'temperature': _settings.temperature,
        'max_tokens': _settings.maxTokens,
        'stream': _settings.streamResponse,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('OpenAI: Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final content =
            (responseData['choices'] as List<dynamic>)[0]['message']['content']
                as String;

        if (kDebugMode) {
          print(
            'OpenAI: Response received: ${content.substring(0, content.length > 100 ? 100 : content.length)}...',
          );
        }

        return ChatMessage.ai(content: content);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'خطای نامشخص';

        if (kDebugMode) {
          print('OpenAI: Error ${response.statusCode}: $errorMessage');
        }

        throw OpenAIException('خطا در ارتباط با OpenAI: $errorMessage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('OpenAI: Exception: $e');
      }

      if (e is SocketException) {
        throw const OpenAIException('خطا در اتصال به اینترنت');
      } else if (e is OpenAIException) {
        rethrow;
      } else {
        throw OpenAIException('خطای غیرمنتظره: $e');
      }
    }
  }

  /// ساخت لیست پیام‌ها برای API
  List<Map<String, String>> _buildMessages(
    List<ChatMessage> messages,
    String? systemPrompt,
  ) {
    final apiMessages = <Map<String, String>>[];

    // اضافه کردن system prompt
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      apiMessages.add({'role': 'system', 'content': systemPrompt});
    }

    // اضافه کردن پیام‌های چت
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

  /// تست اتصال به API
  Future<bool> testConnection() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/models'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('OpenAI: Connection test failed: $e');
      }
      return false;
    }
  }

  /// دریافت لیست مدل‌های موجود
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/models'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final models = <String>[];

        final List<dynamic> items = data['data'] as List<dynamic>;
        for (final dynamic model in items) {
          final String modelId =
              (model as Map<String, dynamic>)['id'] as String;
          if (modelId.startsWith('gpt-')) {
            models.add(modelId);
          }
        }

        return models;
      } else {
        throw const OpenAIException('خطا در دریافت مدل‌ها');
      }
    } catch (e) {
      if (kDebugMode) {
        print('OpenAI: Error getting models: $e');
      }
      throw OpenAIException('خطا در دریافت مدل‌ها: $e');
    }
  }

  /// بستن کلاینت
  void dispose() {
    _client.close();
  }
}

/// استثنای مخصوص OpenAI
class OpenAIException implements Exception {
  const OpenAIException(this.message);
  final String message;

  @override
  String toString() => 'OpenAIException: $message';
}

/// System prompt برای چت ورزشی
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
