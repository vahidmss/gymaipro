import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/services/message_rate_limiter_service.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/ai/services/user_context_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// سرویس مدیریت چت هوش مصنوعی (ذخیره در حافظه داخلی)
class AIChatService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  final OpenAIService _openAIService = OpenAIService();
  final MessageRateLimiterService _rateLimiter = MessageRateLimiterService();

  // کلیدهای SharedPreferences
  static const String _sessionsKey = 'ai_chat_sessions';
  static const String _currentSessionKey = 'ai_chat_current_session_id';

  /// دریافت تمام session های چت کاربر از حافظه داخلی
  /// فقط session های مربوط به کاربر فعلی را برمی‌گرداند
  /// و session های قدیمی کاربران دیگر را پاک می‌کند
  Future<List<AIChatSession>> getChatSessions() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        // اگر کاربر لاگین نیست، هیچ session برنگردان
        return [];
      }

      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionsKey);

      if (sessionsJson == null) {
        return [];
      }

      final sessionsList = jsonDecode(sessionsJson) as List<dynamic>;
      final allSessions = sessionsList
          .map(
            (json) => AIChatSession.fromLocalMap(json as Map<String, dynamic>),
          )
          .toList();

      // جدا کردن session های کاربر فعلی و کاربران دیگر
      final currentUserSessions = allSessions
          .where((session) =>
              session.isActive && session.userId == currentUserId)
          .toList();
      final otherUserSessions = allSessions
          .where((session) => session.userId != currentUserId)
          .toList();

      // اگر session های کاربران دیگر وجود دارند، آن‌ها و پیام‌هایشان را پاک کن
      if (otherUserSessions.isNotEmpty) {
        if (kDebugMode) {
          print(
            'AI Chat: Found ${otherUserSessions.length} sessions from other users, cleaning up...',
          );
        }

        for (final session in otherUserSessions) {
          // پاک کردن پیام‌های session
          final messagesKey = 'ai_chat_messages_${session.id}';
          await prefs.remove(messagesKey);
        }

        // ذخیره فقط session های کاربر فعلی
        final updatedSessionsJson = jsonEncode(
          currentUserSessions.map((s) => s.toLocalMap()).toList(),
        );
        await prefs.setString(_sessionsKey, updatedSessionsJson);

        if (kDebugMode) {
          print(
            'AI Chat: Cleaned up ${otherUserSessions.length} old sessions',
          );
        }
      }

      // مرتب‌سازی و برگرداندن session های کاربر فعلی
      currentUserSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return currentUserSessions;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting chat sessions: $e');
      }
      return [];
    }
  }

  /// ایجاد session جدید در حافظه داخلی
  Future<AIChatSession> createChatSession({String? title}) async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'local_user';
      final now = DateTime.now();
      final sessionId =
          '${now.millisecondsSinceEpoch}_${userId.substring(0, userId.length > 8 ? 8 : userId.length)}';

      final newSession = AIChatSession(
        id: sessionId,
        userId: userId,
        title: title ?? 'چت جدید',
        createdAt: now,
        updatedAt: now,
        isActive: true,
        messageCount: 0,
        lastMessageAt: null,
      );

      // ذخیره session در SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getChatSessions();
      sessions.add(newSession);

      final sessionsJson = jsonEncode(
        sessions.map((s) => s.toLocalMap()).toList(),
      );
      await prefs.setString(_sessionsKey, sessionsJson);

      // ذخیره session فعلی
      await prefs.setString(_currentSessionKey, sessionId);

      // ایجاد فایل پیام‌ها برای این session
      await _saveSessionMessages(sessionId, []);

      if (kDebugMode) {
        print('AI Chat: Created new session: $sessionId');
      }

      return newSession;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating chat session: $e');
      }
      throw Exception('خطا در ایجاد چت جدید: $e');
    }
  }

  /// دریافت پیام‌های یک session از حافظه داخلی
  Future<List<ChatMessage>> getChatMessages(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = 'ai_chat_messages_$sessionId';
      final messagesJson = prefs.getString(messagesKey);

      if (messagesJson == null) {
        return [];
      }

      final messagesList = jsonDecode(messagesJson) as List<dynamic>;

      if (kDebugMode) {
        print(
          'AI Chat: Loaded ${messagesList.length} messages from local storage',
        );
      }

      final messages = messagesList
          .map((json) {
            try {
              return ChatMessage.fromDatabaseMap(json as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) {
                print('AI Chat: Error parsing message: $e, json: $json');
              }
              return null;
            }
          })
          .whereType<ChatMessage>()
          .toList();

      if (kDebugMode) {
        print(
          'AI Chat: Parsed ${messages.length} messages (${messages.where((m) => m.type == ChatMessageType.user).length} user, ${messages.where((m) => m.type == ChatMessageType.ai).length} AI)',
        );
      }

      return messages;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting chat messages: $e');
      }
      return [];
    }
  }

  /// ذخیره پیام‌های یک session در حافظه داخلی
  Future<void> _saveSessionMessages(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = 'ai_chat_messages_$sessionId';
      final messagesJson = jsonEncode(
        messages
            .map(
              (m) => {
                'id': m.id,
                'content': m.content,
                'message_type': m.type == ChatMessageType.user ? 'user' : 'ai',
                'timestamp': m.timestamp.toIso8601String(),
              },
            )
            .toList(),
      );
      await prefs.setString(messagesKey, messagesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving session messages: $e');
      }
    }
  }

  /// ذخیره پیام کاربر در حافظه داخلی
  Future<ChatMessage> saveUserMessage({
    required String sessionId,
    required String content,
  }) async {
    try {
      // دریافت پیام‌های فعلی
      final currentMessages = await getChatMessages(sessionId);

      // ایجاد پیام جدید
      final newMessage = ChatMessage.user(content: content);

      // اضافه کردن پیام جدید
      currentMessages.add(newMessage);

      // ذخیره در حافظه داخلی
      await _saveSessionMessages(sessionId, currentMessages);

      // به‌روزرسانی session
      await _updateSession(sessionId, messageCount: currentMessages.length);

      if (kDebugMode) {
        print('AI Chat: Saved user message, total: ${currentMessages.length}');
      }

      return newMessage;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user message: $e');
      }
      throw Exception('خطا در ذخیره پیام: $e');
    }
  }

  /// ذخیره پاسخ هوش مصنوعی در حافظه داخلی
  Future<ChatMessage> saveAIMessage({
    required String sessionId,
    required String content,
    int tokensUsed = 0,
    String modelUsed = 'gpt-4o-mini',
  }) async {
    try {
      if (kDebugMode) {
        print('AI Chat: Saving AI message, sessionId: $sessionId');
      }

      // دریافت پیام‌های فعلی
      final currentMessages = await getChatMessages(sessionId);

      if (kDebugMode) {
        print(
          'AI Chat: Current messages count before save: ${currentMessages.length}',
        );
      }

      // ایجاد پیام جدید
      final newMessage = ChatMessage.ai(content: content);

      if (kDebugMode) {
        print('AI Chat: New AI message, content length=${content.length}');
      }

      // اضافه کردن پیام جدید
      currentMessages.add(newMessage);

      // ذخیره در حافظه داخلی
      await _saveSessionMessages(sessionId, currentMessages);

      // به‌روزرسانی session
      await _updateSession(sessionId, messageCount: currentMessages.length);

      if (kDebugMode) {
        print('AI Chat: Messages after save: ${currentMessages.length}');
        final aiMessages = currentMessages
            .where((m) => m.type == ChatMessageType.ai)
            .toList();
        print('AI Chat: AI messages count: ${aiMessages.length}');
      }

      return newMessage;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving AI message: $e');
      }
      throw Exception('خطا در ذخیره پاسخ: $e');
    }
  }

  /// به‌روزرسانی اطلاعات session در حافظه داخلی
  Future<void> _updateSession(
    String sessionId, {
    int? messageCount,
    DateTime? lastMessageAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getChatSessions();

      final sessionIndex = sessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex == -1) return;

      final session = sessions[sessionIndex];
      final updatedSession = AIChatSession(
        id: session.id,
        userId: session.userId,
        title: session.title,
        createdAt: session.createdAt,
        updatedAt: DateTime.now(),
        isActive: session.isActive,
        messageCount: messageCount ?? session.messageCount,
        lastMessageAt: lastMessageAt ?? DateTime.now(),
      );

      sessions[sessionIndex] = updatedSession;

      final sessionsJson = jsonEncode(
        sessions.map((s) => s.toLocalMap()).toList(),
      );
      await prefs.setString(_sessionsKey, sessionsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating session: $e');
      }
    }
  }

  /// بررسی محدودیت پیام قبل از ارسال
  Future<RateLimitResult> checkMessageLimit(String sessionId) async {
    try {
      return await _rateLimiter.canSendMessage();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking message limit: $e');
      }
      // در صورت خطا، اجازه ارسال بده
      return const RateLimitResult(canSend: true, remaining: 999);
    }
  }

  /// دریافت آمار محدودیت پیام
  Future<RateLimitStats> getRateLimitStats() async {
    return await _rateLimiter.getStats();
  }

  /// ارسال پیام و دریافت پاسخ
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String content,
  }) async {
    try {
      // بررسی محدودیت قبل از ارسال
      final limitCheck = await checkMessageLimit(sessionId);
      if (!limitCheck.canSend) {
        throw RateLimitException(limitCheck.message ?? 'محدودیت پیام');
      }

      // ذخیره پیام کاربر
      await saveUserMessage(sessionId: sessionId, content: content);

      // ثبت ارسال پیام در rate limiter
      await _rateLimiter.recordMessageSent();

      // دریافت تاریخچه چت (خودکار بهینه‌سازی شده)
      final allMessages = await getChatMessages(sessionId);

      // محدود کردن تعداد پیام‌های ارسالی به OpenAI (2 پیام آخر برای کاهش مصرف و افزایش سرعت)
      // اگر کش خالی بود، فقط پیام خوش‌آمدگویی اولیه کافی است
      final List<ChatMessage> chatHistory = allMessages.isEmpty
          ? <ChatMessage>[]
          : allMessages.length <= 2
          ? allMessages
          : allMessages.sublist(allMessages.length - 2);

      if (kDebugMode) {
        print(
          'AI Chat: Sending ${chatHistory.length} messages to OpenAI (out of ${allMessages.length} total)',
        );
      }

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
      if (e is RateLimitException) {
        rethrow;
      }
      throw Exception('خطا در ارسال پیام: $e');
    }
  }

  /// دریافت نام کاربر برای استفاده در پیام‌های خوش‌آمدگویی
  Future<String> getUserFirstName() async {
    try {
      final userContext = await _getUserContext();
      final profile = userContext['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        final firstName = (profile['first_name'] as String?) ?? '';
        return firstName;
      }
      return '';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user first name: $e');
      }
      return '';
    }
  }

  /// دریافت اطلاعات کاربر برای context (از کش)
  Future<Map<String, dynamic>> _getUserContext() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      // دریافت از کش
      final cachedData = await UserContextCacheService.getCachedUserContext();

      if (cachedData != null) {
        if (kDebugMode) {
          print('AI Chat: Using cached user context');
          final hasConfidential = cachedData['confidential_data'] != null;
          print('AI Chat: Confidential data in cache: $hasConfidential');
          if (hasConfidential) {
            final confData =
                cachedData['confidential_data'] as Map<String, dynamic>?;
            if (confData != null) {
              final hasLifestyle = confData['lifestyle_preferences'] != null;
              print('AI Chat: Lifestyle preferences in cache: $hasLifestyle');
            }
          }
        }
        return cachedData;
      }

      // اگر کش وجود نداشت، از دیتابیس بگیر (fallback)
      if (kDebugMode) {
        print('AI Chat: Cache not found, fetching from database');
      }

      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return {'profile': profileResponse};
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user context: $e');
      }
      return {};
    }
  }

  /// ساخت system prompt با اطلاعات کاربر (از کش)
  Future<String> _buildSystemPrompt(Map<String, dynamic> userContext) async {
    final profile = userContext['profile'] as Map<String, dynamic>?;
    final confidentialData =
        userContext['confidential_data'] as Map<String, dynamic>?;
    final latestWeight = userContext['latest_weight'] as double?;
    final weightStats = userContext['weight_stats'] as Map<String, dynamic>?;
    final userId = _supabase.auth.currentUser?.id;

    String contextInfo = '';

    // استخراج نام کاربر برای استفاده صمیمانه
    String userName = '';
    if (profile != null && userId != null) {
      // اطلاعات شخصی
      final firstName = (profile['first_name'] as String?) ?? '';
      final lastName = (profile['last_name'] as String?) ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        userName = firstName.isNotEmpty ? firstName : lastName;
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

      // استفاده از وزن از کش
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

        // استفاده از آمار وزن از کش (روند از کش - بدون درخواست دیتابیس)
        if (weightStats != null &&
            (weightStats['total_records'] as int? ?? 0) > 0) {
          contextInfo += 'روند وزن: ${weightStats['trend'] ?? 'نامشخص'}\n';
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

      // اطلاعات محرمانه (lifestyle preferences) - اولویت بالاتر از profile
      // اگر اطلاعات در lifestyle موجود باشد، از profile استفاده نمی‌کنیم (برای کاهش تکرار)
      bool hasLifestyleData = false;
      if (confidentialData != null) {
        if (kDebugMode) {
          print('AI Chat: Using confidential data from cache');
        }
        final lifestylePrefs =
            confidentialData['lifestyle_preferences'] as Map<String, dynamic>?;
        if (lifestylePrefs != null && lifestylePrefs.isNotEmpty) {
          hasLifestyleData = true;
          if (kDebugMode) {
            print(
              'AI Chat: Lifestyle preferences available: ${lifestylePrefs.keys.toList()}',
            );
          }
          // اضافه کردن اطلاعات سبک زندگی به context
          final sleepHours = lifestylePrefs['sleep_hours'];
          if (sleepHours != null) {
            contextInfo += 'ساعات خواب: $sleepHours ساعت\n';
            if (kDebugMode) {
              print('AI Chat: Added sleep hours: $sleepHours');
            }
          }
          final activityLevel = lifestylePrefs['activity_level'];
          if (activityLevel != null) {
            contextInfo += 'سطح فعالیت روزانه: $activityLevel\n';
            if (kDebugMode) {
              print('AI Chat: Added activity level: $activityLevel');
            }
          }
          final stressLevel = lifestylePrefs['stress_level'];
          if (stressLevel != null) {
            contextInfo += 'سطح استرس: $stressLevel\n';
            if (kDebugMode) {
              print('AI Chat: Added stress level: $stressLevel');
            }
          }
          // اطلاعات پزشکی و سلامتی
          final medicalConditions = lifestylePrefs['medical_conditions'];
          if (medicalConditions != null &&
              medicalConditions.toString().isNotEmpty) {
            contextInfo += 'شرایط پزشکی (محرمانه): $medicalConditions\n';
          }
          final medications = lifestylePrefs['medications'];
          if (medications != null && medications.toString().isNotEmpty) {
            contextInfo += 'داروهای مصرفی: $medications\n';
          }
          final allergies = lifestylePrefs['allergies'];
          if (allergies != null && allergies.toString().isNotEmpty) {
            contextInfo += 'آلرژی‌ها: $allergies\n';
          }
          // اهداف فیتنس (فقط مهم‌ترین‌ها)
          final targetWeight = lifestylePrefs['target_weight'];
          if (targetWeight != null) {
            contextInfo += 'وزن هدف: $targetWeight کیلوگرم\n';
          }
          final primaryGoals = lifestylePrefs['primary_goals'];
          if (primaryGoals != null && primaryGoals.toString().isNotEmpty) {
            contextInfo += 'اهداف: $primaryGoals\n';
          }

          // سبک زندگی (فقط ضروری‌ها)
          final foodPrefs = lifestylePrefs['food_preferences'];
          if (foodPrefs != null && foodPrefs.toString().isNotEmpty) {
            contextInfo += 'ترجیحات غذایی: $foodPrefs\n';
          }
          final smoking = lifestylePrefs['smoking'];
          if (smoking != null && smoking.toString().isNotEmpty) {
            contextInfo += 'سیگار: $smoking\n';
          }
        } else {
          if (kDebugMode) {
            print(
              'AI Chat: Confidential data exists but no lifestyle preferences found',
            );
          }
        }
      } else {
        if (kDebugMode) {
          print('AI Chat: No confidential data available in cache');
        }
      }

      // اگر اطلاعات lifestyle موجود نبود، از profile استفاده کن (برای کاهش تکرار)
      if (!hasLifestyleData) {
        // شرایط پزشکی از profile
        final medicalConditions =
            profile['medical_conditions'] as List<dynamic>?;
        if (medicalConditions != null && medicalConditions.isNotEmpty) {
          contextInfo += 'شرایط پزشکی: ${medicalConditions.join(', ')}\n';
        }

        // ترجیحات غذایی از profile
        final dietaryPreferences =
            profile['dietary_preferences'] as List<dynamic>?;
        if (dietaryPreferences != null && dietaryPreferences.isNotEmpty) {
          contextInfo += 'ترجیحات غذایی: ${dietaryPreferences.join(', ')}\n';
        }
      }
    }

    // ساخت نام صمیمانه برای استفاده در prompt
    final friendlyName = userName.isNotEmpty ? userName : 'عزیزم';

    // بررسی اینکه آیا اطلاعات کافی وجود دارد یا نه
    final hasUserInfo = contextInfo.trim().isNotEmpty;
    final hasMedicalInfo =
        contextInfo.contains('شرایط پزشکی') ||
        contextInfo.contains('آلرژی') ||
        contextInfo.contains('دارو');
    final hasWeightInfo =
        contextInfo.contains('وزن') || contextInfo.contains('BMI');
    final hasGoals = contextInfo.contains('اهداف');

    // ساخت prompt بهینه بر اساس اطلاعات موجود
    String prompt =
        '''شما جیم‌آی (GymAI) هستید - مربی ورزشی و متخصص تغذیه هوش مصنوعی.

**هویت:** مربی صمیمی و حرفه‌ای. ${userName.isNotEmpty ? 'کاربر را "$userName" صدا بزنید.' : 'از کلمات صمیمانه استفاده کنید.'}''';

    // فقط اگر اطلاعات کاربر وجود داشته باشد، اضافه کن
    if (hasUserInfo) {
      prompt += '\n\n**اطلاعات کاربر:**\n$contextInfo';
    }

    prompt += '\n\n**قوانین:**\n';
    prompt +=
        '1. فقط فیتنس و تغذیه. برای سوالات غیرمرتبط بگویید: "متأسفم $friendlyName، من فقط در زمینه فیتنس می‌تونم کمکت کنم."\n';
    prompt +=
        '2. هرگز برنامه کامل ننویسید. برای دریافت برنامه شخصی‌سازی شده، کاربر را به مربیان متخصص در اپلیکیشن یا بخش هوش مصنوعی برنامه‌ساز راهنمایی کنید.\n';

    // فقط اگر اطلاعات کاربر وجود داشته باشد
    if (hasUserInfo) {
      prompt += '3. از اطلاعات کاربر برای شخصی‌سازی استفاده کنید';
      if (hasWeightInfo) prompt += ' (وزن، BMI)';
      if (hasMedicalInfo) prompt += ' (شرایط پزشکی)';
      if (hasGoals) prompt += ' (اهداف)';
      prompt += '.\n';
    } else {
      prompt += '3. پاسخ‌های عمومی و مفید ارائه دهید.\n';
    }

    prompt +=
        '4. صمیمی، کوتاه، انگیزه‌بخش، با emoji مناسب (💪🎯). همیشه فارسی.\n';

    // فقط اگر اطلاعات پزشکی وجود داشته باشد
    if (hasMedicalInfo) {
      prompt +=
          '5. ایمنی اولویت مطلق. قبل از هر توصیه، شرایط پزشکی را بررسی کنید.\n';
    }

    // بخش برنامه تمرینی فقط اگر لازم باشه (کوتاه‌تر)
    prompt +=
        '\n**برنامه تمرینی:** فقط در صورت اصرار شدید، JSON بین <program_json></program_json> قرار دهید.';

    // بخش قابلیت‌های اپ (کوتاه‌تر)
    prompt +=
        '\n**قابلیت‌های اپ:** گاهی از قابلیت‌های اپ صحبت کنید: مربیان متخصص برای دریافت برنامه شخصی‌سازی شده، هوش مصنوعی برنامه‌ساز، ثبت تمرین. توجه: برنامه‌ساز تمرینی و برنامه‌ساز تغذیه فقط برای مربی‌ها هستند و کاربران عادی به آن‌ها دسترسی ندارند.';

    return prompt;
  }

  /// حذف session از حافظه داخلی
  Future<void> deleteChatSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // حذف پیام‌های session
      final messagesKey = 'ai_chat_messages_$sessionId';
      await prefs.remove(messagesKey);

      // حذف session از لیست
      final sessions = await getChatSessions();
      sessions.removeWhere((s) => s.id == sessionId);

      final sessionsJson = jsonEncode(
        sessions.map((s) => s.toLocalMap()).toList(),
      );
      await prefs.setString(_sessionsKey, sessionsJson);

      // اگر session حذف شده session فعلی بود، آن را پاک کن
      final currentSessionId = prefs.getString(_currentSessionKey);
      if (currentSessionId == sessionId) {
        await prefs.remove(_currentSessionKey);
      }

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

  /// ذخیره تمام چت‌ها در دیتابیس برای بک‌آپ (هر کاربر یک سطر)
  Future<void> backupChatToDatabase(String sessionId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('کاربر وارد نشده است');
      }

      // دریافت تمام session ها و پیام‌هایشان از حافظه داخلی
      final localSessions = await getChatSessions();
      final allSessionsData = <Map<String, dynamic>>[];

      for (final session in localSessions) {
        final messages = await getChatMessages(session.id);
        final messagesJson = messages
            .map(
              (m) => {
                'id': m.id,
                'content': m.content,
                'message_type': m.type == ChatMessageType.user ? 'user' : 'ai',
                'timestamp': m.timestamp.toIso8601String(),
              },
            )
            .toList();

        allSessionsData.add({
          'id': session.id,
          'title': session.title,
          'created_at': session.createdAt.toIso8601String(),
          'updated_at': session.updatedAt.toIso8601String(),
          'message_count': messages.length,
          'last_message_at': session.lastMessageAt?.toIso8601String(),
          'messages': messagesJson,
        });
      }

      // بررسی وجود سطر برای این کاربر
      final existing = await _supabase
          .from('ai_chat_sessions')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // به‌روزرسانی سطر موجود - تمام session ها در یک JSON
        await _supabase
            .from('ai_chat_sessions')
            .update({
              'messages': allSessionsData, // تمام session ها در یک JSON
              'updated_at': DateTime.now().toIso8601String(),
              'last_message_at':
                  allSessionsData.isNotEmpty &&
                      allSessionsData.first['last_message_at'] != null
                  ? allSessionsData.first['last_message_at']
                  : DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        // ایجاد سطر جدید برای این کاربر
        await _supabase.from('ai_chat_sessions').insert({
          'id': const Uuid().v4(),
          'user_id': userId,
          'title': 'چت‌های کاربر',
          'messages': allSessionsData, // تمام session ها در یک JSON
          'message_count': allSessionsData.fold<int>(
            0,
            (sum, session) => sum + (session['message_count'] as int),
          ),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'last_message_at':
              allSessionsData.isNotEmpty &&
                  allSessionsData.first['last_message_at'] != null
              ? allSessionsData.first['last_message_at']
              : DateTime.now().toIso8601String(),
          'is_active': true,
        });
      }

      if (kDebugMode) {
        print(
          'AI Chat: Backed up ${allSessionsData.length} sessions to database for user $userId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error backing up chat to database: $e');
      }
      throw Exception('خطا در ذخیره بک‌آپ: $e');
    }
  }

  /// دریافت آخرین تاریخ بک‌آپ
  Future<DateTime?> getLastBackupDate() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      final response = await _supabase
          .from('ai_chat_sessions')
          .select('updated_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return DateTime.parse(response['updated_at'] as String);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last backup date: $e');
      }
      return null;
    }
  }

  /// دریافت اطلاعات بک‌آپ برای نمایش
  Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      final response = await _supabase
          .from('ai_chat_sessions')
          .select('updated_at, messages')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final sessionsDataRaw = response['messages'];
      List<dynamic> sessionsData;
      if (sessionsDataRaw is List) {
        sessionsData = sessionsDataRaw;
      } else if (sessionsDataRaw is String) {
        try {
          sessionsData = jsonDecode(sessionsDataRaw) as List<dynamic>;
        } catch (e) {
          return null;
        }
      } else {
        return null;
      }

      int totalMessages = 0;
      for (final sessionData in sessionsData) {
        if (sessionData is Map) {
          totalMessages += sessionData['message_count'] as int? ?? 0;
        }
      }

      return {
        'backup_date': DateTime.parse(response['updated_at'] as String),
        'session_count': sessionsData.length,
        'total_messages': totalMessages,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting backup info: $e');
      }
      return null;
    }
  }

  /// بارگذاری تمام چت‌ها از دیتابیس به حافظه داخلی
  Future<int> loadAllChatsFromDatabase() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('کاربر وارد نشده است');
      }

      // دریافت سطر کاربر از دیتابیس (هر کاربر یک سطر)
      final response = await _supabase
          .from('ai_chat_sessions')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) {
          print('AI Chat: No backup found for user');
        }
        return 0;
      }

      final userData = Map<String, dynamic>.from(response);
      final sessionsDataRaw = userData['messages'];

      // sessionsData باید یک لیست از session ها باشد
      List<dynamic> sessionsData;
      if (sessionsDataRaw is List) {
        sessionsData = sessionsDataRaw;
      } else if (sessionsDataRaw is String) {
        try {
          sessionsData = jsonDecode(sessionsDataRaw) as List<dynamic>;
        } catch (e) {
          if (kDebugMode) {
            print('AI Chat: Invalid sessions data format: $e');
          }
          return 0;
        }
      } else {
        if (kDebugMode) {
          print('AI Chat: Invalid sessions data format');
        }
        return 0;
      }

      int loadedCount = 0;
      final prefs = await SharedPreferences.getInstance();

      // پاک کردن session های محلی فعلی
      final existingSessions = await getChatSessions();
      for (final session in existingSessions) {
        final messagesKey = 'ai_chat_messages_${session.id}';
        await prefs.remove(messagesKey);
      }
      await prefs.setString(_sessionsKey, jsonEncode([]));

      // بارگذاری هر session از JSON
      for (final sessionData in sessionsData) {
        try {
          final sessionMap = Map<String, dynamic>.from(
            sessionData as Map<dynamic, dynamic>,
          );
          final messagesJson = _parseMessages(sessionMap['messages']);

          // تبدیل پیام‌ها به ChatMessage
          final messages = messagesJson
              .map((json) {
                try {
                  return ChatMessage.fromDatabaseMap(
                    json as Map<String, dynamic>,
                  );
                } catch (e) {
                  if (kDebugMode) {
                    print('AI Chat: Error parsing message: $e');
                  }
                  return null;
                }
              })
              .whereType<ChatMessage>()
              .toList();

          // ایجاد session در حافظه داخلی
          final localSessionId =
              '${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, userId.length > 8 ? 8 : userId.length)}_$loadedCount';

          final newSession = AIChatSession(
            id: localSessionId,
            userId: userId,
            title: sessionMap['title'] as String? ?? 'چت بارگذاری شده',
            createdAt: DateTime.parse(sessionMap['created_at'] as String),
            updatedAt: DateTime.parse(sessionMap['updated_at'] as String),
            isActive: true,
            messageCount: messages.length,
            lastMessageAt: sessionMap['last_message_at'] != null
                ? DateTime.parse(sessionMap['last_message_at'] as String)
                : null,
          );

          // ذخیره session در SharedPreferences
          final currentSessions = await getChatSessions();
          currentSessions.add(newSession);

          final sessionsJson = jsonEncode(
            currentSessions.map((s) => s.toLocalMap()).toList(),
          );
          await prefs.setString(_sessionsKey, sessionsJson);

          // ذخیره پیام‌ها
          await _saveSessionMessages(localSessionId, messages);

          loadedCount++;
        } catch (e) {
          if (kDebugMode) {
            print('Error loading session: $e');
          }
        }
      }

      if (kDebugMode) {
        print('AI Chat: Loaded $loadedCount sessions from database');
      }

      return loadedCount;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading all chats from database: $e');
      }
      throw Exception('خطا در بارگذاری چت‌ها از دیتابیس: $e');
    }
  }

  /// بارگذاری چت از دیتابیس به حافظه داخلی
  Future<String> loadChatFromDatabase(String databaseSessionId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('کاربر وارد نشده است');
      }

      // دریافت session از دیتابیس
      final response = await _supabase
          .from('ai_chat_sessions')
          .select('*')
          .eq('id', databaseSessionId)
          .eq('user_id', userId)
          .single();

      final sessionData = Map<String, dynamic>.from(response);
      final messagesJson = _parseMessages(sessionData['messages']);

      // تبدیل پیام‌ها به ChatMessage
      final messages = messagesJson
          .map((json) {
            try {
              return ChatMessage.fromDatabaseMap(json as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) {
                print('AI Chat: Error parsing message: $e');
              }
              return null;
            }
          })
          .whereType<ChatMessage>()
          .toList();

      // ایجاد session در حافظه داخلی
      final localSessionId =
          '${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, userId.length > 8 ? 8 : userId.length)}';

      final newSession = AIChatSession(
        id: localSessionId,
        userId: userId,
        title: sessionData['title'] as String? ?? 'چت بارگذاری شده',
        createdAt: DateTime.parse(sessionData['created_at'] as String),
        updatedAt: DateTime.parse(sessionData['updated_at'] as String),
        isActive: true,
        messageCount: messages.length,
        lastMessageAt: sessionData['last_message_at'] != null
            ? DateTime.parse(sessionData['last_message_at'] as String)
            : null,
      );

      // ذخیره session در SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getChatSessions();
      sessions.add(newSession);

      final sessionsJson = jsonEncode(
        sessions.map((s) => s.toLocalMap()).toList(),
      );
      await prefs.setString(_sessionsKey, sessionsJson);

      // ذخیره پیام‌ها
      await _saveSessionMessages(localSessionId, messages);

      // ذخیره mapping بین local session ID و database session ID
      await prefs.setString(
        'ai_chat_db_mapping_$localSessionId',
        databaseSessionId,
      );

      if (kDebugMode) {
        print(
          'AI Chat: Loaded session $databaseSessionId from database to local $localSessionId',
        );
      }

      return localSessionId;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading chat from database: $e');
      }
      throw Exception('خطا در بارگذاری چت از دیتابیس: $e');
    }
  }

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

  /// پاک کردن تمام کش (session ها و پیام‌ها) از حافظه داخلی
  /// این متد همه session ها (فعال و غیرفعال) و تمام پیام‌ها را پاک می‌کند
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      // پیدا کردن و پاک کردن تمام کلیدهای مربوط به AI chat
      final keysToRemove = <String>[];

      // 1. پاک کردن تمام کلیدهای session ها و پیام‌ها
      for (final key in allKeys) {
        if (key.startsWith('ai_chat_')) {
          keysToRemove.add(key);
        }
      }

      // 2. پاک کردن کلیدهای rate limiter
      keysToRemove.add('ai_chat_daily_messages');
      keysToRemove.add('ai_chat_last_reset_date');

      // 3. پاک کردن همه کلیدها
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      if (kDebugMode) {
        print(
          'AI Chat: Cache cleared successfully (${keysToRemove.length} keys removed)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache: $e');
      }
      throw Exception('خطا در پاک کردن کش: $e');
    }
  }

  void dispose() {
    _openAIService.dispose();
  }
}

/// استثنای محدودیت پیام
class RateLimitException implements Exception {
  const RateLimitException(this.message);
  final String message;

  @override
  String toString() => 'RateLimitException: $message';
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

  Map<String, dynamic> toLocalMap() {
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

  factory AIChatSession.fromLocalMap(Map<String, dynamic> map) {
    return AIChatSession(
      id: (map['id'] as String?) ?? '',
      userId: (map['user_id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      isActive: (map['is_active'] as bool?) ?? true,
      messageCount: (map['message_count'] as int?) ?? 0,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
    );
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
