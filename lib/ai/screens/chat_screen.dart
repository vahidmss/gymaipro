import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/ai/services/ai_chat_availability.dart';
import 'package:gymaipro/ai/services/ai_chat_service.dart';
import 'package:gymaipro/ai/services/message_rate_limiter_service.dart';
import 'package:gymaipro/services/app_access_control_service.dart';
import 'package:gymaipro/widgets/feature_unavailable_view.dart';
import 'package:gymaipro/ai/widgets/chat_bubble.dart';
import 'package:gymaipro/ai/widgets/typing_indicator.dart';
import 'package:gymaipro/services/ai_trainer_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

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
  DateTime? _lastBackupDate;
  double _lastKeyboardHeight = 0;
  RateLimitStats? _rateLimitStats;
  bool _welcomeMessageAdded =
      false; // جلوگیری از اضافه کردن چندباره پیام خوش‌آمدگویی

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    AppAccessControlService.instance.refreshConfig();
    _initializeChat();
    _loadLastBackupDate();
    _loadRateLimitStats();

    // اضافه کردن listener برای اسکرول خودکار هنگام باز شدن کیبورد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupKeyboardListener();
    });
  }

  /// تنظیم listener برای کیبورد
  void _setupKeyboardListener() {
    // استفاده از MediaQuery برای تشخیص تغییرات کیبورد
    // این در build method انجام می‌شود
  }

  /// بارگذاری تاریخ آخرین بک‌آپ
  Future<void> _loadLastBackupDate() async {
    try {
      final lastBackup = await _chatService.getLastBackupDate();
      if (mounted) {
        setState(() {
          _lastBackupDate = lastBackup;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading last backup date: $e');
      }
    }
  }

  /// بارگذاری آمار محدودیت پیام
  Future<void> _loadRateLimitStats() async {
    try {
      final stats = await _chatService.getRateLimitStats();
      if (mounted) {
        setState(() {
          _rateLimitStats = stats;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading rate limit stats: $e');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // بارگذاری مجدد تاریخچه وقتی صفحه دوباره باز می‌شود
    if (_currentSessionId != null && _messages.isEmpty) {
      _loadChatHistory();
    }
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
      await AITrainerService.ensureAITrainerExists();

      // ایجاد یا دریافت session فعلی
      _currentSessionId = await _getOrCreateCurrentSession();

      // Reset flag برای پیام خوش‌آمدگویی
      _welcomeMessageAdded = false;

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
      SafeSetState.call(this, () {
        _messages.clear();
        _messages.addAll(messages);
      });

      // پس از بارگذاری تاریخچه، روی جدیدترین پیام (انتهای لیست) اسکرول کن
      _scrollToBottom();

      // اگر پیامی وجود ندارد و هنوز پیام خوش‌آمدگویی اضافه نشده، اضافه کن
      if (_messages.isEmpty && !_welcomeMessageAdded) {
        _welcomeMessageAdded = true;
        _addWelcomeMessage();
        _scrollToBottom();
      }
    } catch (e) {
      _addErrorMessage('خطا در بارگذاری تاریخچه چت');
    }
  }

  /// اضافه کردن پیام خوش‌آمدگویی
  Future<void> _addWelcomeMessage() async {
    // دریافت نام کاربر برای شخصی‌سازی پیام
    String userName = '';
    try {
      userName = await _chatService.getUserFirstName();
    } catch (_) {
      // در صورت خطا، بدون نام ادامه بده
    }

    // ساخت پیام خوش‌آمدگویی شخصی‌سازی شده
    final hour = DateTime.now().hour;
    String greeting = '';
    String emoji = '👋';

    if (hour >= 5 && hour < 12) {
      greeting = 'صبح بخیر';
      emoji = '🌅';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'ظهر بخیر';
      emoji = '☀️';
    } else if (hour >= 17 && hour < 20) {
      greeting = 'عصر بخیر';
      emoji = '🌆';
    } else {
      greeting = 'شب بخیر';
      emoji = '🌙';
    }

    final friendlyName = userName.isNotEmpty ? userName : 'عزیزم';
    final welcomeContent = userName.isNotEmpty
        ? '$greeting $friendlyName! $emoji\n\nخوش اومدی! من ${AppConfig.gymAiDisplayName} هستم، مربی ورزشی و متخصص تغذیهٔ هوش مصنوعی‌ات. خیلی خوشحالم که اینجایی و آماده‌ام تا کمکت کنم به اهداف فیتنس برسی! 💪\n\nچیزی هست که می‌خوای ازم بپرسی یا راهنمایی می‌خوای؟'
        : '$greeting! $emoji\n\nخوش اومدی! من ${AppConfig.gymAiDisplayName} هستم، مربی ورزشی و متخصص تغذیهٔ هوش مصنوعی‌ات. خیلی خوشحالم که اینجایی و آماده‌ام تا کمکت کنم به اهداف فیتنس برسی! 💪\n\nچیزی هست که می‌خوای ازم بپرسی یا راهنمایی می‌خوای؟';

    final welcomeMessage = ChatMessage.ai(content: welcomeContent);
    SafeSetState.call(this, () {
      _messages.add(welcomeMessage);
    });
  }

  /// اضافه کردن پیام خطا
  void _addErrorMessage(String error) {
    final errorMessage = ChatMessage.ai(
      content:
          'متأسفانه در حال حاضر نمی‌تونم پاسخ بدم. لطفاً دوباره تلاش کنید. ❌',
    );
    SafeSetState.call(this, () {
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

    // بررسی محدودیت قبل از ارسال
    try {
      final limitCheck = await _chatService.checkMessageLimit(
        _currentSessionId!,
      );
      if (!limitCheck.canSend) {
        // نمایش پیام خطای محدودیت
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          limitCheck.message ?? 'شما به محدودیت پیام رسیده‌اید',
          backgroundColor: AppTheme.fatColor,
          duration: const Duration(seconds: 4),
        );
        // به‌روزرسانی آمار
        await _loadRateLimitStats();
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking rate limit: $e');
      }
      // در صورت خطا، ادامه بده
    }

    // اضافه کردن پیام کاربر به UI
    final userMessage = ChatMessage.user(content: text);
    SafeSetState.call(this, () {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // اضافه کردن نشانگر تایپ
      final typingMessage = ChatMessage.typing();
      SafeSetState.call(this, () {
        _messages.add(typingMessage);
      });
      _scrollToBottom();
      _typingAnimationController.safeRepeat();

      // ارسال پیام و دریافت پاسخ از سرویس
      final aiResponse = await _chatService.sendMessage(
        sessionId: _currentSessionId!,
        content: text,
      );

      // بارگذاری مجدد تاریخچه کامل از حافظه داخلی
      final updatedMessages = await _chatService.getChatMessages(
        _currentSessionId!,
      );

      // حذف نشانگر تایپ و به‌روزرسانی لیست پیام‌ها از حافظه داخلی
      SafeSetState.call(this, () {
        _messages.removeWhere((m) => m.isTyping);

        // استفاده از پیام‌های بارگذاری شده از حافظه داخلی (شامل همه پیام‌ها)
        _messages.clear();
        _messages.addAll(updatedMessages);

        // اگر برنامه تمرینی در پاسخ بود، محتوای آخرین پیام را تغییر بده
        final String programJson = _extractProgramJson(aiResponse.content);
        if (programJson.isNotEmpty) {
          // پیدا کردن آخرین پیام AI و تغییر محتوای آن
          for (int i = _messages.length - 1; i >= 0; i--) {
            if (_messages[i].type == ChatMessageType.ai) {
              _messages[i] = ChatMessage.ai(
                content:
                    'برنامه تمرینی شما ساخته و ذخیره شد. می‌توانید آن را از بخش برنامه‌های من مشاهده کنید.',
                id: _messages[i].id,
              );
              break;
            }
          }

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
                    // Update the last AI message with error content if save fails
                    for (int i = _messages.length - 1; i >= 0; i--) {
                      if (_messages[i].type == ChatMessageType.ai) {
                        _messages[i] = ChatMessage.ai(
                          content:
                              'متأسفانه در ذخیره برنامه تمرینی خطایی رخ داد. لطفاً دوباره تلاش کنید.',
                          id: _messages[i].id,
                        );
                        break;
                      }
                    }
                  });
                }
              });
        }

        _isLoading = false;
      });

      // به‌روزرسانی آمار محدودیت (با تاخیر کوتاه برای اطمینان از ذخیره در دیتابیس)
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _loadRateLimitStats();

      _typingAnimationController.safeStop();
      _scrollToBottom();
    } catch (e) {
      // حذف نشانگر تایپ و اضافه کردن پیام خطا
      String errorMessage = 'متأسفانه خطایی رخ داد. لطفاً دوباره تلاش کنید. 😔';

      if (e.toString().contains('RateLimitException')) {
        errorMessage = e.toString().replaceAll('RateLimitException: ', '');
        // به‌روزرسانی آمار
        await _loadRateLimitStats();
      } else if (e.toString().contains('OPENAI_API_KEY') ||
          e.toString().contains('کلید API')) {
        errorMessage =
            'کلید API هوش مصنوعی تنظیم نشده است. لطفاً با پشتیبانی تماس بگیرید.';
      } else if (e.toString().contains('Insufficient Balance') ||
          e.toString().contains('insufficient_quota') ||
          e.toString().contains('402')) {
        errorMessage =
            'اعتبار حساب DeepSeek تمام شده. از platform.deepseek.com شارژ کن یا کلید جدید بساز.';
      } else if (e.toString().contains('اتصال به اینترنت') ||
          e.toString().contains('از این دستگاه وصل نشدم') ||
          e.toString().contains('زمان‌بر شد')) {
        errorMessage =
            'به سرویس هوش مصنوعی وصل نشدم. اینترنت یا VPN گوشیت را چک کن و دوباره امتحان کن.';
      }

      SafeSetState.call(this, () {
        _messages.removeWhere((m) => m.isTyping);
        _messages.add(ChatMessage.ai(content: errorMessage));
        _isLoading = false;
      });

      _typingAnimationController.safeStop();
      _scrollToBottom();
    }
  }

  /// اسکرول به پایین
  void _scrollToBottom({bool smooth = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (smooth) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  /// نمایش بنر آمار محدودیت پیام
  Widget _buildRateLimitBanner() {
    if (_rateLimitStats == null) return const SizedBox.shrink();

    final stats = _rateLimitStats!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyPercent = stats.dailyUsagePercent;
    final isNearLimit = dailyPercent >= 80;

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isNearLimit
            ? AppTheme.fatColor.withValues(alpha: isDark ? 0.2 : 0.15)
            : AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isNearLimit
              ? AppTheme.fatColor.withValues(alpha: 0.4)
              : AppTheme.goldColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNearLimit ? LucideIcons.alertCircle : LucideIcons.messageSquare,
            color: isNearLimit ? AppTheme.fatColor : AppTheme.goldColor,
            size: 18.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildLimitProgress(
              'محدودیت روزانه',
              stats.dailyUsed,
              stats.dailyLimit,
              dailyPercent,
              isNearLimit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitProgress(
    String label,
    int used,
    int limit,
    double percent,
    bool isWarning,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 11.sp,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$used / $limit',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 11.sp,
                color: isWarning ? AppTheme.fatColor : context.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 5.h,
            backgroundColor: isDark
                ? AppTheme.darkTextColor.withValues(alpha: 0.1)
                : AppTheme.veryDarkBackground.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isWarning ? AppTheme.fatColor : AppTheme.goldColor,
            ),
          ),
        ),
      ],
    );
  }

  /// نمایش بنر راهنمای ذخیره و بارگذاری از دیتابیس
  Widget _buildBackupBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.all(12.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.goldColor.withValues(alpha: 0.15)
            : AppTheme.goldColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, color: AppTheme.goldColor, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💾 ذخیره و بارگذاری از دیتابیس',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.goldColor : context.textColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (_lastBackupDate != null)
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 12.sp,
                            color: context.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'آخرین بک‌آپ: ${_formatBackupDate(_lastBackupDate!)}',
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'هنوز بک‌آپی ذخیره نشده است',
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          fontSize: 11.sp,
                          color: context.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showBackupDialog,
                  icon: Icon(LucideIcons.cloud, size: 16.sp),
                  label: Text(
                    'ذخیره',
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.goldColor,
                    side: const BorderSide(color: AppTheme.goldColor),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _lastBackupDate != null
                      ? _showLoadConfirmationDialog
                      : null,
                  icon: Icon(LucideIcons.download, size: 16.sp),
                  label: Text(
                    'بارگذاری',
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkTextColor,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lastBackupDate != null
                        ? AppTheme.goldColor
                        : AppTheme.darkGreySeparator,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// فرمت تاریخ بک‌آپ برای نمایش (شمسی)
  String _formatBackupDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    final monthNames = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    return '${jalali.day} ${monthNames[jalali.month]} ${jalali.year}';
  }

  /// نمایش دیالوگ ذخیره در دیتابیس
  Future<void> _showBackupDialog() async {
    if (_currentSessionId == null) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.cloud, color: AppTheme.goldColor, size: 24.sp),
            SizedBox(width: 12.w),
            Text(
              'ذخیره در دیتابیس',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'با ذخیره چت در دیتابیس:',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            SizedBox(height: 12.h),
            _buildFeatureItem('✅ چت‌های شما در ابر ذخیره می‌شوند'),
            _buildFeatureItem(
              '✅ می‌توانید در دستگاه‌های دیگر هم به آن‌ها دسترسی داشته باشید',
            ),
            _buildFeatureItem('✅ در صورت حذف اپلیکیشن، چت‌های شما حفظ می‌شوند'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: AppTheme.goldColor,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'نکته: چت‌های شما همیشه در حافظه داخلی دستگاه ذخیره می‌شوند. ذخیره در دیتابیس فقط برای بک‌آپ و دسترسی از دستگاه‌های دیگر است.',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 11.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'انصراف',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _backupChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text(
              'ذخیره',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                color: AppTheme.darkTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                color: context.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ذخیره چت در دیتابیس
  Future<void> _backupChat() async {
    if (_currentSessionId == null) return;

    try {
      SafeSetState.call(this, () {
        _isLoading = true;
      });

      await _chatService.backupChatToDatabase(_currentSessionId!);

      // به‌روزرسانی تاریخ آخرین بک‌آپ
      await _loadLastBackupDate();

      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          '✅ چت با موفقیت در دیتابیس ذخیره شد',
          backgroundColor: AppTheme.successColor,
        );
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          '❌ خطا در ذخیره چت: $e',
          backgroundColor: AppTheme.errorColor,
        );
      }
    } finally {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
        });
      }
    }
  }

  /// نمایش دیالوگ تایید بارگذاری
  Future<void> _showLoadConfirmationDialog() async {
    try {
      SafeSetState.call(this, () {
        _isLoading = true;
      });

      final backupInfo = await _chatService.getBackupInfo();

      if (!mounted) return;
      SafeSetState.call(this, () {
        _isLoading = false;
      });

      if (backupInfo == null) {
        if (mounted) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'چت ذخیره شده‌ای در دیتابیس یافت نشد',
            backgroundColor: AppTheme.fatColor,
          );
        }
        return;
      }

      final backupDate = backupInfo['backup_date'] as DateTime;
      final totalMessages = backupInfo['total_messages'] as int;

      WidgetSafetyUtils.safeShowDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(
                LucideIcons.download,
                color: AppTheme.goldColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'تایید بارگذاری',
                style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اطلاعات زیر از دیتابیس بارگذاری می‌شود:',
                style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      LucideIcons.messageSquare,
                      'تعداد پیام‌ها',
                      '$totalMessages پیام',
                    ),
                    SizedBox(height: 8.h),
                    _buildInfoRow(
                      LucideIcons.calendar,
                      'تاریخ بک‌آپ',
                      _formatBackupDate(backupDate),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.fatColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppTheme.fatColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      color: AppTheme.fatColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'توجه: چت‌های فعلی شما با اطلاعات دیتابیس جایگزین می‌شوند',
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          fontSize: 11.sp,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'انصراف',
                style: TextStyle(
    fontFamily: AppTheme.fontFamily,color: context.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _loadAllChatsFromDatabase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text(
                'بارگذاری',
                style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                  color: AppTheme.darkTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
        });
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          '❌ خطا در دریافت اطلاعات: $e',
          backgroundColor: AppTheme.errorColor,
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppTheme.goldColor),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            fontSize: 12.sp,
            color: context.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
      ],
    );
  }

  /// بارگذاری تمام چت‌ها از دیتابیس
  Future<void> _loadAllChatsFromDatabase() async {
    try {
      SafeSetState.call(this, () {
        _isLoading = true;
      });

      final loadedCount = await _chatService.loadAllChatsFromDatabase();

      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          '✅ $loadedCount چت با موفقیت از دیتابیس بارگذاری شد',
          backgroundColor: AppTheme.successColor,
        );

        // بارگذاری مجدد لیست session ها
        final sessions = await _chatService.getChatSessions();
        if (sessions.isNotEmpty) {
          _currentSessionId = sessions.first.id;
          await _loadChatHistory();
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          '❌ خطا در بارگذاری چت‌ها: $e',
          backgroundColor: AppTheme.errorColor,
        );
      }
    } finally {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
        });
      }
    }
  }

  /// پاک کردن چت
  Future<void> _clearChat() async {
    if (_currentSessionId == null) return;

    try {
      SafeSetState.call(this, () {
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

      SafeSetState.call(this, () {
        _messages.clear();
        _isLoading = false;
        _welcomeMessageAdded = false; // Reset flag
      });

      if (!_welcomeMessageAdded) {
        _welcomeMessageAdded = true;
        _addWelcomeMessage();
      }
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

      SafeSetState.call(this, () {
        _messages.clear();
        _isLoading = false;
        _welcomeMessageAdded = false; // Reset flag
      });
      if (!_welcomeMessageAdded) {
        _welcomeMessageAdded = true;
        _addWelcomeMessage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppAccessConfig>(
      valueListenable: AppAccessControlService.instance.configNotifier,
      builder: (context, access, _) {
        if (!isGymAiChatAvailable(access)) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('چت ${AppConfig.gymAiDisplayName}'),
            ),
            body: Padding(
              padding: EdgeInsets.all(20.w),
              child: FeatureUnavailableView(
                title: 'چت ${AppConfig.gymAiDisplayName}',
                description: gymAiChatUnavailableMessage(access),
              ),
            ),
          );
        }
        return _buildChatBody(context);
      },
    );
  }

  Widget _buildChatBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // اسکرول خودکار هنگام باز شدن کیبورد (فقط اگر تغییر کرده باشد)
    if (keyboardHeight > 0 && keyboardHeight != _lastKeyboardHeight) {
      _lastKeyboardHeight = keyboardHeight;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom(smooth: false);
        }
      });
    } else if (keyboardHeight == 0) {
      _lastKeyboardHeight = 0;
    }

    // بارگذاری مجدد تاریخچه وقتی صفحه دوباره build می‌شود
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _currentSessionId != null &&
          _messages.isEmpty &&
          !_isLoading &&
          _isConnected) {
        _loadChatHistory();
      }
    });

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.headerBackgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: context.headerBackgroundColor,
          elevation: 0,
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
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                      blurRadius: 8.r,
                      offset: Offset(0.w, 2.h),
                    ),
                  ],
                ),
                child: Icon(LucideIcons.bot, color: AppTheme.darkTextColor, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مربی هوش مصنوعی',
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.goldColor : context.textColor,
                    ),
                  ),
                  Text(
                    _isConnected ? 'آنلاین' : 'آفلاین',
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _clearChat,
              icon: Icon(
                LucideIcons.trash2,
                color: isDark ? AppTheme.goldColor : context.textColor,
              ),
              tooltip: 'پاک کردن چت',
            ),
          ],
        ),
        body: Column(
          children: [
            // نمایش آمار محدودیت پیام
            if (_rateLimitStats != null) _buildRateLimitBanner(),
            // بنر راهنمای ذخیره در دیتابیس
            if (_messages.isNotEmpty) _buildBackupBanner(),
            // لیست پیام‌ها
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        top: 16.h,
                        bottom: 16.h,
                      ),
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
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  blurRadius: 16.r,
                  spreadRadius: 2.r,
                ),
              ],
            ),
            child: Icon(
              LucideIcons.messageCircle,
              color: AppTheme.darkTextColor,
              size: 40.sp,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'مربی هوش مصنوعی شما',
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'سوالات خود را در مورد ورزش و تغذیه بپرسید',
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// نوار ورودی پیام
  Widget _buildMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
            width: 1.w,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0.w, -2.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark ? context.backgroundColor : context.cardColor,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.3 : 0.5,
                    ),
                    width: 1.5.w,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'پیام خود را بنویسید...',
                    hintStyle: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                      fontSize: 14.sp,
                    ),
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
            SizedBox(width: 12.w),
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
                  color: _isLoading ? AppTheme.darkGreySeparator : null,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: _isLoading
                      ? null
                      : [
                          BoxShadow(
                            color: AppTheme.goldColor.withValues(alpha: 0.3),
                            blurRadius: 8.r,
                            offset: Offset(0.w, 2.h),
                          ),
                        ],
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.darkTextColor,
                          ),
                        ),
                      )
                    : Icon(LucideIcons.send, color: AppTheme.darkTextColor, size: 20.sp),
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
        name:
            '${AppConfig.gymAiDisplayName}(${DateTime.now().toLocal().toString().split(' ').first})',
        sessions: sessions.cast<WorkoutSession>(),
      );

      // دریافت شناسه AI Trainer (ایجاد در صورت عدم وجود)
      final aiTrainerId = await AITrainerService.ensureAITrainerExists();

      final saved = await WorkoutProgramService().createProgram(
        program,
        trainerId: aiTrainerId,
        autoSend: true, // برنامه‌های AI بلافاصله ارسال می‌شوند
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
