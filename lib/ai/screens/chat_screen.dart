import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/services/ai_chat_service.dart';
import 'package:gymaipro/ai/widgets/chat_bubble.dart';
import 'package:gymaipro/ai/widgets/typing_indicator.dart';
import 'package:gymaipro/services/ai_trainer_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/services/workout_program_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final AIChatService _chatService = AIChatService();

  bool _isLoading = false;
  bool _isConnected = false;
  String? _currentSessionId;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  /// اولیه‌سازی چت
  Future<void> _initializeChat() async {
    try {
      // اطمینان از وجود AI Trainer
      await AITrainerService.createAITrainerIfNotExists();

      // ایجاد یا دریافت session فعلی
      _currentSessionId = await _getOrCreateCurrentSession();

      // بارگذاری پیام‌های قبلی
      await _loadChatHistory();

      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      _addErrorMessage('خطا در اتصال به سرویس چت');
    }
  }

  /// دریافت یا ایجاد session فعلی
  Future<String> _getOrCreateCurrentSession() async {
    try {
      // دریافت آخرین session فعال
      final sessions = await _chatService.getChatSessions();

      if (sessions.isNotEmpty) {
        return sessions.first.id;
      } else {
        // ایجاد session جدید
        final newSession = await _chatService.createChatSession();
        return newSession.id;
      }
    } catch (e) {
      // در صورت خطا، session جدید ایجاد کن
      final newSession = await _chatService.createChatSession();
      return newSession.id;
    }
  }

  /// بارگذاری تاریخچه چت
  Future<void> _loadChatHistory() async {
    if (_currentSessionId == null) return;

    try {
      final messages = await _chatService.getChatMessages(_currentSessionId!);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });

      // پس از بارگذاری تاریخچه، روی جدیدترین پیام (انتهای لیست) اسکرول کن
      _scrollToBottom();

      // اگر پیامی وجود ندارد، پیام خوش‌آمدگویی اضافه کن
      if (_messages.isEmpty) {
        _addWelcomeMessage();
        _scrollToBottom();
      }
    } catch (e) {
      _addErrorMessage('خطا در بارگذاری تاریخچه چت');
    }
  }

  /// اضافه کردن پیام خوش‌آمدگویی
  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage.ai(
      content:
          'سلام! 👋 من مربی ورزشی و متخصص تغذیه هوش مصنوعی شما هستم. چطور می‌تونم کمکتون کنم؟',
    );
    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  /// اضافه کردن پیام خطا
  void _addErrorMessage(String error) {
    final errorMessage = ChatMessage.ai(
      content:
          'متأسفانه در حال حاضر نمی‌تونم پاسخ بدم. لطفاً دوباره تلاش کنید. ❌',
    );
    setState(() {
      _messages.add(errorMessage);
    });
  }

  /// ارسال پیام
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // اطمینان از وجود سشن
    if (_currentSessionId == null) {
      _currentSessionId = await _getOrCreateCurrentSession();
    } else {
      try {
        // اگر سشن حذف شده باشد، این فراخوانی خطا می‌دهد و سشن جدید می‌سازیم
        await _chatService.getChatMessages(_currentSessionId!);
      } catch (_) {
        _currentSessionId = await _getOrCreateCurrentSession();
      }
    }

    if (_currentSessionId == null) return;

    // اضافه کردن پیام کاربر به UI
    final userMessage = ChatMessage.user(content: text);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // اضافه کردن نشانگر تایپ
      final typingMessage = ChatMessage.typing();
      setState(() {
        _messages.add(typingMessage);
      });
      _scrollToBottom();
      _typingAnimationController.repeat();

      // ارسال پیام و دریافت پاسخ از سرویس
      final aiResponse = await _chatService.sendMessage(
        sessionId: _currentSessionId!,
        content: text,
      );

      // حذف نشانگر تایپ و اضافه کردن پاسخ
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        String cleanedContent = _cleanAIResponseForDisplay(aiResponse.content);
        final String programJson = _extractProgramJson(aiResponse.content);

        if (programJson.isNotEmpty) {
          // For programs, show success message immediately
          cleanedContent =
              'برنامه تمرینی شما ساخته و ذخیره شد. می‌توانید آن را از بخش "برنامه‌ساز تمرینی" انتخاب کنید.';

          // Save program in background
          _saveAIProgram(programJson)
              .then((_) {
                if (kDebugMode) {
                  print('AI plan: program saved successfully');
                }
              })
              .catchError((Object e) {
                if (kDebugMode) {
                  print('AI plan: error while saving plan: $e');
                }
                if (mounted) {
                  setState(() {
                    // Update the last message with error content only if save fails
                    final lastMessageIndex = _messages.length - 1;
                    if (lastMessageIndex >= 0) {
                      _messages[lastMessageIndex] = ChatMessage.ai(
                        content:
                            'متأسفانه در ذخیره برنامه تمرینی خطایی رخ داد. لطفاً دوباره تلاش کنید.',
                      );
                    }
                  });
                }
              });
        }
        _messages.add(ChatMessage.ai(content: cleanedContent));
        _isLoading = false;
      });

      _typingAnimationController.stop();
      _scrollToBottom();
    } catch (e) {
      // حذف نشانگر تایپ و اضافه کردن پیام خطا
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _messages.add(
          ChatMessage.ai(
            content: 'متأسفانه خطایی رخ داد. لطفاً دوباره تلاش کنید. 😔',
          ),
        );
        _isLoading = false;
      });

      _typingAnimationController.stop();
      _scrollToBottom();
    }
  }

  /// اسکرول به پایین
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// پاک کردن چت
  Future<void> _clearChat() async {
    if (_currentSessionId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // حذف session فعلی
      await _chatService.deleteChatSession(_currentSessionId!);

      if (kDebugMode) {
        print('Session deleted: $_currentSessionId');
      }

      // ایجاد session جدید
      _currentSessionId = await _getOrCreateCurrentSession();

      if (kDebugMode) {
        print('New session created: $_currentSessionId');
      }

      setState(() {
        _messages.clear();
        _isLoading = false;
      });

      _addWelcomeMessage();
    } catch (e) {
      if (kDebugMode) {
        print('Error in _clearChat: $e');
      }

      // در صورت خطا، session جدید ایجاد کن
      try {
        _currentSessionId = await _getOrCreateCurrentSession();
      } catch (e2) {
        if (kDebugMode) {
          print('Error creating new session: $e2');
        }
      }

      setState(() {
        _messages.clear();
        _isLoading = false;
      });
      _addWelcomeMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.goldColor, AppTheme.darkGold],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(LucideIcons.bot, color: Colors.white, size: 20.sp),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مربی هوش مصنوعی',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _isConnected ? 'آنلاین' : 'آفلاین',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _clearChat,
              icon: const Icon(LucideIcons.trash2),
              tooltip: 'پاک کردن چت',
            ),
          ],
        ),
        body: Column(
          children: [
            // لیست پیام‌ها
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16.w),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: message.isTyping
                              ? TypingIndicator(
                                  animationController:
                                      _typingAnimationController,
                                )
                              : ChatBubble(message: message),
                        );
                      },
                    ),
            ),
            // نوار ورودی پیام
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  /// نمایش حالت خالی
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.goldColor, AppTheme.darkGold],
              ),
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: Icon(
              LucideIcons.messageCircle,
              color: Colors.white,
              size: 40.sp,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'مربی هوش مصنوعی شما',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سوالات خود را در مورد ورزش و تغذیه بپرسید',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// نوار ورودی پیام
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'پیام خود را بنویسید...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? null
                      : const LinearGradient(
                          colors: [AppTheme.goldColor, AppTheme.darkGold],
                        ),
                  color: _isLoading ? Colors.grey : null,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(LucideIcons.send, color: Colors.white, size: 20.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractProgramJson(String text) {
    // Try to find <program_json>...</program_json> tags (flexible, case-insensitive, allow spaces)
    final programJsonRegex = RegExp(
      r'<\s*program_json\s*>([\s\S]*?)<\s*/\s*program_json\s*>',
      caseSensitive: false,
      dotAll: true,
    );
    final match = programJsonRegex.firstMatch(text);
    if (match != null && match.group(1) != null) {
      if (kDebugMode) {
        print('AI plan: detected program_json tags');
        print('AI plan: extracted JSON: ${match.group(1)!.trim()}');
      }
      return match.group(1)!.trim();
    }

    // Try to find JSON inside Markdown code fences ```json ... ``` or untyped ``` ... ```
    final codeFenceJsonRegex = RegExp(
      r'```(?:json)?\s*(\{[\s\S]*?\})\s*```',
      caseSensitive: false,
      dotAll: true,
    );
    final codeMatch = codeFenceJsonRegex.firstMatch(text);
    if (codeMatch != null && codeMatch.group(1) != null) {
      if (kDebugMode) print('AI plan: detected JSON inside code fences');
      return codeMatch.group(1)!.trim();
    }

    // Try to find bare JSON object that likely contains a plan (has "sessions" key)
    final bareJsonRegex = RegExp(
      r'(\{[\s\S]*?"sessions"[\s\S]*?\})',
      dotAll: true,
    );
    final bareMatch = bareJsonRegex.firstMatch(text);
    if (bareMatch != null && bareMatch.group(1) != null) {
      if (kDebugMode) print('AI plan: detected bare JSON with sessions');
      return bareMatch.group(1)!.trim();
    }

    return '';
  }

  String _cleanAIResponseForDisplay(String text) {
    // Remove <program_json>...</program_json> tags (case-insensitive, flexible)
    final programJsonRegex = RegExp(
      r'<\s*program_json\s*>[\s\S]*?<\s*/\s*program_json\s*>',
      caseSensitive: false,
      dotAll: true,
    );
    var cleanedText = text.replaceAll(programJsonRegex, '').trim();

    // Remove Markdown code fences ``` ... ```
    final codeFenceRegex = RegExp(
      r'```[\s\S]*?```',
      caseSensitive: false,
      multiLine: true,
    );
    cleanedText = cleanedText.replaceAll(codeFenceRegex, '').trim();

    // Remove bare JSON that likely contains a plan (has "sessions" key)
    final sessionsJsonRegex = RegExp(
      r'\{[\s\S]*?"sessions"[\s\S]*?\}',
      multiLine: true,
    );
    cleanedText = cleanedText.replaceAll(sessionsJsonRegex, '').trim();

    if (cleanedText.isEmpty) {
      cleanedText =
          'برنامه ساخته شد و ذخیره شد. از بخش ثبت تمرین/رژیم می‌توانید انتخاب کنید.';
    }
    return cleanedText;
  }

  String _fixIncompleteJson(String jsonText) {
    // First, try to find the last complete object/array
    String cleaned = jsonText.trim();

    // Remove any trailing commas before closing braces/brackets
    cleaned = cleaned.replaceAll(RegExp(r',\s*([}\]])'), r'$1');

    // Count opening and closing braces to determine what's missing
    int openBraces = 0;
    int openBrackets = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < cleaned.length; i++) {
      final char = cleaned[i];

      if (char == r'\' && !escaped) {
        escaped = true;
        continue;
      }

      if (char == '"' && !escaped) {
        inString = !inString;
      }

      if (!inString) {
        if (char == '{') {
          openBraces++;
        } else if (char == '}') {
          openBraces--;
        } else if (char == '[') {
          openBrackets++;
        } else if (char == ']') {
          openBrackets--;
        }
      }

      escaped = false;
    }

    // Add missing closing characters
    String fixed = cleaned;
    for (int i = 0; i < openBrackets; i++) {
      fixed += ']';
    }
    for (int i = 0; i < openBraces; i++) {
      fixed += '}';
    }

    if (kDebugMode && fixed != jsonText) {
      print(
        'AI plan: Fixed incomplete JSON by adding $openBrackets ] and $openBraces }',
      );
    }

    return fixed;
  }

  bool _isValidJsonStructure(String jsonText) {
    try {
      if (kDebugMode) {
        print('AI plan: Validating JSON structure...');
      }

      // Basic validation - check if it has required fields
      if (!jsonText.contains('"program_name"') ||
          !jsonText.contains('"sessions"')) {
        if (kDebugMode) {
          print('AI plan: Missing required fields - program_name or sessions');
        }
        return false;
      }

      // Try to parse and validate structure
      final data = jsonDecode(jsonText);
      if (data is! Map<String, dynamic>) {
        if (kDebugMode) {
          print('AI plan: JSON is not a Map');
        }
        return false;
      }

      // Check required fields
      if (!data.containsKey('program_name') || !data.containsKey('sessions')) {
        if (kDebugMode) {
          print('AI plan: Missing required keys in parsed data');
        }
        return false;
      }

      final sessions = data['sessions'];
      if (sessions is! List || sessions.isEmpty) {
        if (kDebugMode) {
          print('AI plan: Sessions is not a valid list or is empty');
        }
        return false;
      }

      // Check first session structure
      final firstSession = sessions[0];
      if (firstSession is! Map<String, dynamic>) {
        if (kDebugMode) {
          print('AI plan: First session is not a Map');
        }
        return false;
      }

      // Check for session name (either 'session_name' or 'day')
      final bool hasSessionName =
          firstSession.containsKey('session_name') ||
          firstSession.containsKey('day');

      if (!hasSessionName || !firstSession.containsKey('exercises')) {
        if (kDebugMode) {
          print('AI plan: First session missing session_name/day or exercises');
          print('AI plan: Available keys: ${firstSession.keys.toList()}');
        }
        return false;
      }

      if (kDebugMode) {
        print('AI plan: JSON structure is valid');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AI plan: JSON validation error: $e');
      }
      return false;
    }
  }

  Future<void> _saveAIProgram(String jsonText) async {
    try {
      // Try to fix incomplete JSON by adding missing closing braces
      final String fixedJson = _fixIncompleteJson(jsonText);

      // Validate JSON structure before parsing
      if (!_isValidJsonStructure(fixedJson)) {
        throw const FormatException('JSON structure is invalid or incomplete');
      }

      final Map<String, dynamic> data =
          jsonDecode(fixedJson) as Map<String, dynamic>;
      if (kDebugMode) {
        print('AI plan: JSON parsed successfully for saving');
      }
      // Map exercise_name -> exercise_id using ExerciseService list
      final exercises = await ExerciseService().getExercises();
      if (kDebugMode) {
        print('AI plan: loaded ${exercises.length} exercises for mapping');
      }
      int? lookupId(String name) {
        String norm(String s) => s
            .replaceAll('\u200c', ' ')
            .replaceAll('‌', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim()
            .toLowerCase();
        final normalizedName = norm(name);
        for (final e in exercises) {
          if (norm(e.name) == normalizedName) return e.id;
        }
        for (final e in exercises) {
          final n = norm(e.name);
          if (normalizedName.isNotEmpty &&
              (n.contains(normalizedName) || normalizedName.contains(n))) {
            return e.id;
          }
        }
        return null;
      }

      // Transform schema to builder schema
      final sessions = (data['sessions'] as List<dynamic>? ?? []).map((s) {
        final sessionMap = s as Map;
        final day =
            sessionMap['session_name']?.toString() ??
            sessionMap['day']?.toString() ??
            'روز 1';
        final exList = (s['exercises'] as List<dynamic>? ?? []).map((ex) {
          final exMap = ex as Map<String, dynamic>;
          final type = exMap['type']?.toString() ?? 'normal';
          final tag = exMap['tag']?.toString() ?? '';
          final style =
              (exMap['style']?.toString() ?? 'sets_reps') == 'sets_time'
              ? ExerciseStyle.setsTime
              : ExerciseStyle.setsReps;

          if (type == 'superset') {
            final items = (exMap['exercises'] as List<dynamic>? ?? []).map((
              item,
            ) {
              final nm = (item as Map)['exercise_name']?.toString() ?? '';
              final id = lookupId(nm);
              if (id == null) return null;
              final rawSets = item['sets'] as List<dynamic>? ?? [];
              final sets = (rawSets.isEmpty ? [<String, dynamic>{}] : rawSets)
                  .map(
                    (st) => ExerciseSet(
                      reps: ((st as Map<String, dynamic>)['reps']) as int?,
                      timeSeconds: st['time_seconds'] as int?,
                      weight: (st['weight'] is num)
                          ? (st['weight'] as num).toDouble()
                          : null,
                    ),
                  )
                  .toList();
              return SupersetItem(exerciseId: id, sets: sets, style: style);
            }).toList();
            final filteredItems = items.whereType<SupersetItem>().toList();
            if (filteredItems.isEmpty) return null;
            return SupersetExercise(
              tag: tag,
              style: style,
              exercises: filteredItems,
            );
          } else {
            final nm = exMap['exercise_name']?.toString() ?? '';
            final id = lookupId(nm);
            if (id == null) return null;
            final rawSets = exMap['sets'] as List<dynamic>? ?? [];
            final sets = (rawSets.isEmpty ? [<String, dynamic>{}] : rawSets)
                .map(
                  (st) => ExerciseSet(
                    reps: ((st as Map<String, dynamic>)['reps']) as int?,
                    timeSeconds: st['time_seconds'] as int?,
                    weight: (st['weight'] is num)
                        ? (st['weight'] as num).toDouble()
                        : null,
                  ),
                )
                .toList();
            return NormalExercise(
              exerciseId: id,
              tag: tag,
              style: style,
              sets: sets,
            );
          }
        }).toList();
        final filtered = exList.whereType<WorkoutExercise>().toList();
        return WorkoutSession(day: day, exercises: filtered);
      }).toList();

      final program = WorkoutProgram(
        name: 'جیم‌آی(${DateTime.now().toLocal().toString().split(' ').first})',
        sessions: sessions.cast<WorkoutSession>(),
      );

      // دریافت شناسه AI Trainer (ایجاد در صورت عدم وجود)
      final aiTrainerId = await AITrainerService.ensureAITrainerExists();

      final saved = await WorkoutProgramService().createProgram(
        program,
        trainerId: aiTrainerId,
      );

      if (kDebugMode) {
        print(
          'AI plan: program saved with id ${saved.id} by trainer ${aiTrainerId ?? "user"}',
        );
      }

      // به‌روزرسانی آمار AI Trainer
      if (aiTrainerId != null) {
        await AITrainerService.updateAITrainerStats(programCount: 1);
      }
      // Program saved successfully - no navigation needed
    } catch (e) {
      if (kDebugMode) {
        print('AI plan: error while saving plan: $e');
      }
      // Ignore if not valid JSON
    }
  }
}
