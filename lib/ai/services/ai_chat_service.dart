import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت چت هوش مصنوعی (JSON Approach)
class AIChatService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  final OpenAIService _openAIService = OpenAIService();

  /// تبدیل messages به List<dynamic>
  List<dynamic> _parseMessages(dynamic messagesData) {
    if (messagesData is String) {
      try {
        return jsonDecode(messagesData) as List<dynamic>;
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing messages JSON: $e');
        }
        return [];
      }
    } else if (messagesData is List) {
      return messagesData;
    } else {
      return [];
    }
  }

  /// دریافت تمام session های چت کاربر
  Future<List<AIChatSession>> getChatSessions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('کاربر وارد نشده است');

      final response = await _supabase
          .from('ai_chat_sessions')
          .select(
            'id, title, created_at, updated_at, message_count, last_message_at',
          )
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('updated_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => AIChatSession.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting chat sessions: $e');
      }
      throw Exception('خطا در دریافت چت‌ها: $e');
    }
  }

  /// ایجاد session جدید
  Future<AIChatSession> createChatSession({String? title}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('کاربر وارد نشده است');

      final response = await _supabase
          .from('ai_chat_sessions')
          .insert({
            'user_id': userId,
            'title': title ?? 'چت جدید',
            'messages': <dynamic>[],
            'message_count': 0,
          })
          .select()
          .single();

      return AIChatSession.fromMap(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating chat session: $e');
      }
      throw Exception('خطا در ایجاد چت جدید: $e');
    }
  }

  /// دریافت پیام‌های یک session
  Future<List<ChatMessage>> getChatMessages(String sessionId) async {
    try {
      // دریافت پیام‌ها از دیتابیس
      final response = await _supabase
          .from('ai_chat_sessions')
          .select('messages')
          .eq('id', sessionId)
          .single();

      final messagesJson = _parseMessages(response['messages']);

      if (messagesJson.isEmpty) return [];

      // تبدیل به ChatMessage
      return messagesJson
          .map(
            (json) => ChatMessage.fromDatabaseMap(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting chat messages: $e');
      }
      throw Exception('خطا در دریافت پیام‌ها: $e');
    }
  }

  /// ذخیره پیام کاربر
  Future<ChatMessage> saveUserMessage({
    required String sessionId,
    required String content,
  }) async {
    try {
      // دریافت پیام‌های فعلی
      final existing = await _supabase
          .from('ai_chat_sessions')
          .select('messages, message_count')
          .eq('id', sessionId)
          .maybeSingle();

      if (existing == null) {
        throw Exception('Session not found for saving user message');
      }

      final currentMessages = _parseMessages(existing['messages']);
      final messageCount = existing['message_count'] as int;

      // ایجاد پیام جدید
      final newMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': content,
        'message_type': 'user',
        'timestamp': DateTime.now().toIso8601String(),
        'tokens_used': 0,
        'model_used': 'user',
      };

      // اضافه کردن پیام جدید
      currentMessages.add(newMessage);

      // به‌روزرسانی session
      final updatedUser = await _supabase
          .from('ai_chat_sessions')
          .update({
            'messages': currentMessages,
            'message_count': messageCount + 1,
            'updated_at': DateTime.now().toIso8601String(),
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .maybeSingle();

      if (updatedUser == null) {
        throw Exception('Update failed: no rows affected (user message)');
      }

      // ایجاد ChatMessage برای بازگشت
      return ChatMessage.user(content: content);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user message: $e');
      }
      throw Exception('خطا در ذخیره پیام: $e');
    }
  }

  /// ذخیره پاسخ هوش مصنوعی
  Future<ChatMessage> saveAIMessage({
    required String sessionId,
    required String content,
    int tokensUsed = 0,
    String modelUsed = 'gpt-4o-mini',
  }) async {
    try {
      // دریافت پیام‌های فعلی
      final existing = await _supabase
          .from('ai_chat_sessions')
          .select('messages, message_count, total_tokens_used')
          .eq('id', sessionId)
          .maybeSingle();

      if (existing == null) {
        throw Exception('Session not found for saving AI message');
      }

      final currentMessages = _parseMessages(existing['messages']);
      final messageCount = existing['message_count'] as int;
      final totalTokensUsed = (existing['total_tokens_used'] ?? 0) as int;

      // ایجاد پیام جدید
      final newMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': content,
        'message_type': 'ai',
        'timestamp': DateTime.now().toIso8601String(),
        'tokens_used': tokensUsed,
        'model_used': modelUsed,
      };

      // اضافه کردن پیام جدید
      currentMessages.add(newMessage);

      // به‌روزرسانی session
      final updatedAI = await _supabase
          .from('ai_chat_sessions')
          .update({
            'messages': currentMessages,
            'message_count': messageCount + 1,
            'total_tokens_used': totalTokensUsed + tokensUsed,
            'updated_at': DateTime.now().toIso8601String(),
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .maybeSingle();

      if (updatedAI == null) {
        throw Exception('Update failed: no rows affected (ai message)');
      }

      // ایجاد ChatMessage برای بازگشت
      return ChatMessage.ai(content: content);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving AI message: $e');
      }
      throw Exception('خطا در ذخیره پاسخ: $e');
    }
  }

  /// ارسال پیام و دریافت پاسخ
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String content,
  }) async {
    try {
      // ذخیره پیام کاربر
      await saveUserMessage(sessionId: sessionId, content: content);

      // دریافت تاریخچه چت (خودکار بهینه‌سازی شده)
      final chatHistory = await getChatMessages(sessionId);

      // دریافت اطلاعات کاربر برای context
      final userContext = await _getUserContext();

      // ارسال به OpenAI
      final aiResponse = await _openAIService.sendMessage(
        messages: chatHistory,
        systemPrompt: await _buildSystemPrompt(userContext),
      );

      // ذخیره پاسخ هوش مصنوعی
      await saveAIMessage(sessionId: sessionId, content: aiResponse.content);

      // خلاصه‌سازی خودکار غیرفعال

      return aiResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      throw Exception('خطا در ارسال پیام: $e');
    }
  }

  /// دریافت اطلاعات کاربر برای context
  Future<Map<String, dynamic>> _getUserContext() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      // دریافت پروفایل کاربر
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return {'profile': profileResponse};
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user context: $e');
      }
      return {};
    }
  }

  /// ساخت system prompt با اطلاعات کاربر
  Future<String> _buildSystemPrompt(Map<String, dynamic> userContext) async {
    final profile = userContext['profile'] as Map<String, dynamic>?;
    final userId = _supabase.auth.currentUser?.id;

    String contextInfo = '';

    if (profile != null && userId != null) {
      // اطلاعات شخصی
      final firstName = (profile['first_name'] as String?) ?? '';
      final lastName = (profile['last_name'] as String?) ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        contextInfo += 'نام کاربر: $firstName $lastName\n';
      }

      // جنسیت
      final gender = (profile['gender'] as String?) ?? '';
      if (gender.isNotEmpty) {
        contextInfo += 'جنسیت: $gender\n';
      }

      // سن (محاسبه از تاریخ تولد)
      final birthDate = profile['birth_date'] as String?;
      if (birthDate != null) {
        try {
          final birth = DateTime.parse(birthDate);
          final age = DateTime.now().year - birth.year;
          contextInfo += 'سن: $age سال\n';
        } catch (e) {
          // ignore
        }
      }

      // اطلاعات فیزیکی
      final height = profile['height'] as double?;
      if (height != null) {
        contextInfo += 'قد: $height سانتی‌متر\n';
      }

      // دریافت آخرین وزن از جدول weekly_weight_records
      final latestWeight = await WeeklyWeightService.getLatestWeight(userId);
      if (latestWeight != null) {
        contextInfo += 'وزن فعلی: $latestWeight کیلوگرم\n';

        // محاسبه BMI اگر قد و وزن موجود باشد
        if (height != null) {
          final bmi = latestWeight / ((height / 100) * (height / 100));
          contextInfo += 'BMI: ${bmi.toStringAsFixed(1)}\n';

          // تفسیر BMI
          String bmiCategory = '';
          if (bmi < 18.5) {
            bmiCategory = 'کم‌وزن';
          } else if (bmi < 25) {
            bmiCategory = 'طبیعی';
          } else if (bmi < 30) {
            bmiCategory = 'اضافه وزن';
          } else {
            bmiCategory = 'چاق';
          }
          contextInfo += 'وضعیت وزن: $bmiCategory\n';
        }

        // دریافت آمار وزن برای اطلاعات بیشتر
        final weightStats = await WeeklyWeightService.getWeightStats(userId);
        if ((weightStats['total_records'] as int) > 0) {
          contextInfo +=
              'میانگین وزن: ${weightStats['average_weight'].toStringAsFixed(1)} کیلوگرم\n';
          contextInfo += 'روند وزن: ${weightStats['trend']}\n';
        }
      } else {
        // اگر آخرین وزن وجود نداشت، از پروفایل بگیر
        final weight = profile['weight'];
        if (weight != null) {
          contextInfo += 'وزن: $weight کیلوگرم\n';

          // محاسبه BMI از وزن پروفایل
          if (height != null) {
            final bmi = weight / ((height / 100) * (height / 100));
            contextInfo += 'BMI: ${bmi.toStringAsFixed(1)}\n';
          }
        }
      }

      // سطح تجربه
      final experienceLevel = (profile['experience_level'] as String?) ?? '';
      if (experienceLevel.isNotEmpty) {
        contextInfo += 'سطح تجربه: $experienceLevel\n';
      }

      // اهداف ورزشی
      final fitnessGoals = profile['fitness_goals'] as List<dynamic>?;
      if (fitnessGoals != null && fitnessGoals.isNotEmpty) {
        contextInfo += 'اهداف ورزشی: ${fitnessGoals.join(', ')}\n';
      }

      // شرایط پزشکی
      final medicalConditions = profile['medical_conditions'] as List<dynamic>?;
      if (medicalConditions != null && medicalConditions.isNotEmpty) {
        contextInfo += 'شرایط پزشکی: ${medicalConditions.join(', ')}\n';
      }

      // ترجیحات غذایی
      final dietaryPreferences =
          profile['dietary_preferences'] as List<dynamic>?;
      if (dietaryPreferences != null && dietaryPreferences.isNotEmpty) {
        contextInfo += 'ترجیحات غذایی: ${dietaryPreferences.join(', ')}\n';
      }
    }

    // Load detailed exercise information for better AI recommendations
    String availableExerciseNames = '';
    String detailedExerciseInfo = '';
    try {
      final allExercises = await ExerciseService().getExercises();
      if (allExercises.isNotEmpty) {
        availableExerciseNames = allExercises
            .map((e) => e.name.trim())
            .join(', ');

        // Create detailed exercise info for AI context
        final exerciseDetails = <String>[];
        for (final ex in allExercises.take(50)) {
          // Limit for token efficiency
          final details = StringBuffer();
          details.write(ex.name);
          if (ex.mainMuscle.isNotEmpty) details.write(' (${ex.mainMuscle}');
          if (ex.equipment.isNotEmpty) details.write(', ${ex.equipment}');
          if (ex.difficulty.isNotEmpty) details.write(', ${ex.difficulty}');
          details.write(')');
          exerciseDetails.add(details.toString());
        }
        detailedExerciseInfo = exerciseDetails.join(', ');
      }
    } catch (_) {}

    return '''
شما یک مربی ورزشی و متخصص تغذیه هوش مصنوعی هستید که به کاربران در زمینه‌های زیر کمک می‌کنید:

1. **برنامه‌ریزی تمرینی**: طراحی برنامه‌های تمرینی متناسب با سطح و اهداف کاربر
2. **تغذیه ورزشی**: راهنمایی در مورد رژیم غذایی مناسب برای ورزشکاران
3. **تکنیک‌های تمرین**: آموزش صحیح انجام حرکات ورزشی با استفاده از اطلاعات دقیق تمرینات
4. **انگیزه و مشاوره**: ارائه انگیزه و راهنمایی برای رسیدن به اهداف

**اطلاعات کاربر:**
$contextInfo

**قوانین مهم:**
- همیشه پاسخ‌های خود را به فارسی ارائه دهید
- از اصطلاحات تخصصی ورزشی استفاده کنید اما توضیح دهید
- ایمنی کاربر را در اولویت قرار دهید
- در صورت نیاز به مشاوره پزشکی، کاربر را به پزشک ارجاع دهید
- پاسخ‌های خود را کوتاه و مفید نگه دارید
- از emoji مناسب استفاده کنید
- بر اساس اطلاعات کاربر، توصیه‌های شخصی‌سازی شده ارائه دهید

**سبک پاسخ‌دهی:**
- دوستانه و انگیزه‌بخش
- علمی اما قابل فهم
- عملی و قابل اجرا
- مثبت و تشویق‌کننده

IMPORTANT FOR WORKOUT PROGRAM OUTPUT:
When the user asks for a workout program:
1) اگر اطلاعات ضروری ناکامل است، حداکثر 3-5 پرسش کوتاه و هدفمند برای تکمیل اطلاعات بپرس (مثلاً سابقه آسیب، روزهای در دسترس، تجهیزات، هدف اصلی، محدودیت‌ها). از اطلاعات کاربر که قبلاً داری استفاده کن و فقط خلاها را بپرس.
2) وقتی اطلاعات کافی شد، یک پیام خیلی کوتاه فارسی (1-2 خط) بده که «برنامه ساخته شد و ذخیره شد؛ از بخش ثبت تمرین می‌توانید انتخاب و اجرا کنید.»
3) CRITICAL: Then include ONLY the COMPLETE JSON between <program_json> and </program_json> tags. The JSON MUST be complete and valid - do not truncate it. Use this exact schema:
<program_json>
{
  "program_name": "string (short name)",
  "sessions": [
    {
      "day": "روز 1",
      "exercises": [
        {
          "type": "normal" | "superset",
          "tag": "سینه|پشت|پا|سرشانه|بازو|شکم|سرینی|کاردیو|کل بدن",
          "style": "sets_reps" | "sets_time",
          // For type=normal
          "exercise_name": "نام تمرین دقیق از فهرست موجود در اپ",
          "sets": [ { "reps": 10, "weight": null } ]
          // For type=superset: use
          // "exercises": [ { "exercise_name": "...", "sets": [{"reps": 12}] } ]
        }
      ]
    }
  ]
}
</program_json>
Rules:
- Use Persian for names and tags.
- You MUST choose exercise_name only from this list of available app exercises: [$availableExerciseNames]. Use the detailed exercise info for context: $detailedExerciseInfo. If a name is not present, pick the closest match from this list.
- Keep 3–5 exercises per session, 3–4 sets each. Use realistic reps/time.
- هرگز برنامه کامل را در متن گفتگو نمایش نده؛ فقط پیام تایید کوتاه + بلاک JSON بین تگ‌ها را بفرست.
- اصول علمی و به‌روز تمرین‌نویسی را رعایت کن: حجم مناسب، شدت منطقی، تقدم حرکات پایه، تعادل بین عضلات متقابل، و ریکاوری. برای مبتدیان از 3 ست و برای متوسط 3–4 ست استفاده کن؛ شدت/تکرار را با هدف (افزایش قدرت/حجم/چربی‌سوزی) تطبیق بده.
- در صورت درخواست برنامه (تمرینی/غذایی)، اگر پروفایل کاربر ناقص است، مودبانه پیشنهاد بده «اطلاعات پروفایل‌تان را کامل کنید تا برنامه دقیق‌تری بگیرید»، و در عین حال همین‌جا با چند سوال کوتاه اطلاعات لازم را جمع‌آوری کن.
''';
  }

  /// حذف session
  Future<void> deleteChatSession(String sessionId) async {
    try {
      // حذف کامل session از دیتابیس
      await _supabase.from('ai_chat_sessions').delete().eq('id', sessionId);

      if (kDebugMode) {
        print('Chat session deleted successfully: $sessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting chat session: $e');
      }
      throw Exception('خطا در حذف چت: $e');
    }
  }

  /// دریافت تنظیمات چت کاربر
  Future<AIChatSettings> getChatSettings() async {
    // حذف وابستگی به جدول ai_chat_settings: همیشه تنظیمات پیش‌فرض را برگردان
    return AIChatSettings.defaultSettings();
  }

  /// به‌روزرسانی تنظیمات چت
  Future<void> updateChatSettings(AIChatSettings settings) async {
    // حذف وابستگی به جدول ai_chat_settings: بدون ذخیره در دیتابیس (no-op)
    if (kDebugMode) {
      print(
        'AIChatSettings persistence disabled (no-op). Using runtime defaults.',
      );
    }
  }

  void dispose() {
    _openAIService.dispose();
  }
}

/// مدل session چت
class AIChatSession {
  AIChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.messageCount,
    this.lastMessageAt,
  });

  factory AIChatSession.fromMap(Map<String, dynamic> map) {
    return AIChatSession(
      id: (map['id'] as String?) ?? '',
      userId: (map['user_id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isActive: (map['is_active'] as bool?) ?? true,
      messageCount: (map['message_count'] as int?) ?? 0,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
    );
  }
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int messageCount;
  final DateTime? lastMessageAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'message_count': messageCount,
      'last_message_at': lastMessageAt?.toIso8601String(),
    };
  }
}

/// مدل تنظیمات چت
class AIChatSettings {
  AIChatSettings({
    required this.id,
    required this.userId,
    required this.model,
    required this.temperature,
    required this.maxTokens,
    required this.systemPrompt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIChatSettings.fromMap(Map<String, dynamic> map) {
    return AIChatSettings(
      id: (map['id'] as String?) ?? '',
      userId: (map['user_id'] as String?) ?? '',
      model: (map['default_model'] as String?) ?? 'gpt-4o-mini',
      temperature: (map['default_temperature'] as double?) ?? 0.7,
      maxTokens: (map['default_max_tokens'] as int?) ?? 800,
      systemPrompt: (map['system_prompt'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory AIChatSettings.defaultSettings() {
    final now = DateTime.now();
    return AIChatSettings(
      id: '',
      userId: '',
      model: 'gpt-4o-mini',
      temperature: 0.7,
      maxTokens: 800,
      systemPrompt: 'شما یک مربی ورزشی و متخصص تغذیه هوش مصنوعی هستید.',
      createdAt: now,
      updatedAt: now,
    );
  }
  final String id;
  final String userId;
  final String model;
  final double temperature;
  final int maxTokens;
  final String systemPrompt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'default_model': model,
      'default_temperature': temperature,
      'default_max_tokens': maxTokens,
      'system_prompt': systemPrompt,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
