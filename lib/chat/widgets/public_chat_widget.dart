import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/models/public_chat_message.dart';
import 'package:gymaipro/chat/services/public_chat_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/widgets/user_role_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MessageSendStatus { sending, sent, failed }

class PublicChatWidget extends StatefulWidget {
  const PublicChatWidget({super.key});

  @override
  PublicChatWidgetState createState() => PublicChatWidgetState();
}

class PublicChatWidgetState extends State<PublicChatWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final PublicChatService _service = PublicChatService();
  final AdminService _adminService = AdminService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = true;
  bool _isAdmin = false;
  List<PublicChatMessage> _messages = [];
  late Stream<PublicChatMessage> _subscription;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // برای مدیریت اسکرول و کیبورد
  Timer? _scrollDebounceTimer;
  bool _isKeyboardVisible = false;

  // وضعیت ارسال پیام‌ها (messageId -> status)
  final Map<String, MessageSendStatus> _messageStatuses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // انیمیشن‌ها
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.w, 0.3.h),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // اضافه کردن listener برای focus
    _focusNode.addListener(_onFocusChange);

    _setupSubscription();

    // شروع انیمیشن‌ها
    unawaited(_fadeController.safeForward());
    unawaited(_slideController.safeForward());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_loadMessages());
    unawaited(_checkAdminStatus());
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _adminService.isAdmin();
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isAdmin = isAdmin);
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
  }

  void _setupSubscription() {
    _subscription = _service.subscribeMessages();
    _subscription.listen(
      (msg) {
        debugPrint('=== CHAT WIDGET: Received new message: ${msg.message} ===');
        bool isNewMessage = false;
        final isCurrentUser =
            msg.senderId == Supabase.instance.client.auth.currentUser?.id;

        SafeSetState.call(this, () {
          // بررسی اینکه پیام قبلاً اضافه نشده باشد
          if (!_messages.any((m) => m.id == msg.id)) {
            _messages.add(msg);
            isNewMessage = true;

            // اگر پیام از کاربر فعلی است و قبلاً در حال ارسال بود، وضعیت را به sent تغییر بده
            if (isCurrentUser) {
              // بررسی اینکه آیا پیام موقتی با همین متن وجود دارد
              final tempMessage = _messages.firstWhere(
                (m) => m.id.startsWith('temp_') && m.message == msg.message,
                orElse: () => PublicChatMessage(
                  id: '',
                  senderId: '',
                  message: '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );

              if (tempMessage.id.isNotEmpty) {
                // حذف پیام موقت
                _messages.removeWhere((m) => m.id == tempMessage.id);
                _messageStatuses.remove(tempMessage.id);
              }

              // اضافه کردن وضعیت sent برای پیام جدید
              _messageStatuses[msg.id] = MessageSendStatus.sent;

              // بعد از 2 ثانیه، تیک را مخفی کن
              Timer(const Duration(seconds: 2), () {
                if (mounted) {
                  SafeSetState.call(this, () {
                    _messageStatuses.remove(msg.id);
                  });
                }
              });
            }

            debugPrint('=== CHAT WIDGET: Added new message to list ===');
          } else {
            debugPrint('=== CHAT WIDGET: Message already exists, skipping ===');
          }
        });
        // اسکرول به پایین فقط برای پیام‌های جدید
        if (isNewMessage) {
          _scrollToBottom(delay: const Duration(milliseconds: 100));
        }
      },
      onError: (Object error) {
        debugPrint('=== CHAT WIDGET: Subscription error: $error ===');
      },
    );
  }

  Future<void> _loadMessages() async {
    try {
      SafeSetState.call(this, () => _isLoading = true);

      // اگر آفلاین هستیم، شبکه را صدا نزنیم
      if (!ConnectivityService.instance.isConnected) {
        SafeSetState.call(this, () {
          _messages = [];
          _isLoading = false;
        });
        return;
      }

      // اضافه کردن debug برای بررسی مشکل
      await _service.debugMessages();

      final msgs = await _service.getMessages();
      debugPrint('Loaded ${msgs.length} messages');

      SafeSetState.call(this, () {
        _messages = msgs;
        _isLoading = false;
      });
      // اسکرول به پایین بعد از بارگذاری پیام‌ها
      _scrollToBottom(delay: const Duration(milliseconds: 200));
    } catch (e) {
      debugPrint('Error loading messages: $e');
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  Future<void> _refreshMessages() async {
    await _loadMessages();
  }

  void _scrollToBottom({Duration? delay}) {
    // لغو timer قبلی اگر وجود داشت
    _scrollDebounceTimer?.cancel();

    void performScroll() {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;

        try {
          final position = _scrollController.position;
          if (position.isScrollingNotifier.value) {
            // اگر در حال اسکرول است، صبر کن
            _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
              _scrollToBottom();
            });
            return;
          }

          final target = position.minScrollExtent;
          final current = position.pixels;

          // فقط اگر فاصله قابل توجهی وجود دارد، اسکرول کن
          if ((target - current).abs() > 10) {
            _scrollController.animateTo(
              target,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        } catch (e) {
          debugPrint('Error scrolling to bottom: $e');
        }
      });
    }

    if (delay != null) {
      _scrollDebounceTimer = Timer(delay, performScroll);
    } else {
      performScroll();
    }
  }

  Future<void> _send() async {
    if (!mounted || !_controller.isSafe) return;
    final txt = _controller.safeText.trim();
    if (txt.isEmpty) return;

    // ایجاد پیام موقت برای نمایش فوری
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    final tempMessage = PublicChatMessage(
      id: tempId,
      senderId: currentUserId,
      message: txt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // اضافه کردن پیام موقت به لیست با وضعیت sending
    SafeSetState.call(this, () {
      _messages.add(tempMessage);
      _messageStatuses[tempId] = MessageSendStatus.sending;
    });

    // پاک کردن فیلد ورودی (بدون بستن کیبورد)
    _controller.clear();

    // اسکرول به پایین
    _scrollToBottom(delay: const Duration(milliseconds: 100));

    try {
      debugPrint('=== CHAT WIDGET: Sending message: $txt ===');
      final sentMessage = await _service.sendMessage(message: txt);
      debugPrint(
        '=== CHAT WIDGET: Message sent successfully: ${sentMessage.id} ===',
      );

      // به‌روزرسانی لیست: حذف پیام موقت و اضافه کردن پیام واقعی
      SafeSetState.call(this, () {
        // حذف پیام موقت
        _messages.removeWhere((m) => m.id == tempId);
        _messageStatuses.remove(tempId);

        // اضافه کردن پیام واقعی با وضعیت sent
        if (!_messages.any((m) => m.id == sentMessage.id)) {
          _messages.add(sentMessage);
          _messageStatuses[sentMessage.id] = MessageSendStatus.sent;
          debugPrint('=== CHAT WIDGET: Added sent message to local list ===');
        }
      });

      // اسکرول به پایین
      _scrollToBottom(delay: const Duration(milliseconds: 150));

      // بعد از 2 ثانیه، تیک را مخفی کن (اختیاری)
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          SafeSetState.call(this, () {
            _messageStatuses.remove(sentMessage.id);
          });
        }
      });
    } catch (e) {
      debugPrint('=== CHAT WIDGET: Error sending message: $e ===');

      // تغییر وضعیت به failed
      SafeSetState.call(this, () {
        _messageStatuses[tempId] = MessageSendStatus.failed;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در ارسال پیام: $e',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: context.cardColor,
            action: SnackBarAction(
              label: 'تلاش مجدد',
              textColor: AppTheme.goldColor,
              onPressed: () {
                // حذف پیام failed و تلاش مجدد
                SafeSetState.call(this, () {
                  _messages.removeWhere((m) => m.id == tempId);
                  _messageStatuses.remove(tempId);
                });
                if (_controller.isSafe && mounted) {
                  _controller.safeSetText(txt);
                  _send();
                }
              },
            ),
          ),
        );
      }
    }
  }

  // Add this public method
  Future<void> reloadMessages() {
    return _loadMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollDebounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // هنگام تغییر اندازه صفحه (باز/بسته شدن کیبورد)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      final wasKeyboardVisible = _isKeyboardVisible;
      _isKeyboardVisible = keyboardHeight > 0;

      // اگر کیبورد باز شد، به پایین اسکرول کن
      if (_isKeyboardVisible && !wasKeyboardVisible) {
        _scrollToBottom(delay: const Duration(milliseconds: 100));
      }
    });
  }

  void _onFocusChange() {
    // هنگام focus شدن TextField، به پایین اسکرول کن
    if (_focusNode.hasFocus) {
      _scrollToBottom(delay: const Duration(milliseconds: 300));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Messages Area - بدون کادر اصلی
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.goldColor,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'در حال بارگذاری...',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textSecondary,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: context.goldGradientColors
                                      .map((c) => c.withValues(alpha: 0.15))
                                      .toList(),
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.goldColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                LucideIcons.messageCircle,
                                size: 48.sp,
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              'هنوز پیامی ارسال نشده',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: context.textColor,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'اولین پیام را شما ارسال کنید و گفتگو را شروع کنید',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: context.textSecondary,
                                fontSize: 14.sp,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshMessages,
                      color: AppTheme.goldColor,
                      child: GestureDetector(
                        onTap: () {
                          // با لمس لیست، focus را از TextField بردار
                          _focusNode.unfocus();
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: 16.w,
                            right: 16.w,
                            top: 20.h,
                            bottom: 20.h,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            // reverse=true: اندیس 0 یعنی آخرین پیام
                            final int listCount = _messages.length;
                            final int messageIndex = (listCount - 1) - index;
                            final msg = _messages[messageIndex];
                            return _buildMessageBubble(msg);
                          },
                        ),
                      ),
                    ),
            ),
            // Input Area حرفه‌ای
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.05 : 0.1,
                    ),
                    blurRadius: 10,
                    offset: Offset(0, -2.h),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // دکمه ارسال (همیشه فعال)
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: context.goldGradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 0,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24.r),
                            onTap: _send,
                            child: Center(
                              child: Icon(
                                LucideIcons.send,
                                color: AppTheme.onGoldColor,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // فیلد ورودی
                      Expanded(
                        child: Container(
                          constraints: BoxConstraints(
                            minHeight: 48.h,
                            maxHeight: 120.h,
                          ),
                          decoration: BoxDecoration(
                            color: context.backgroundColor,
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(
                              color: AppTheme.goldColor.withValues(
                                alpha: isDark ? 0.25 : 0.35,
                              ),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldColor.withValues(
                                  alpha: isDark ? 0.05 : 0.08,
                                ),
                                blurRadius: 8,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            textDirection: TextDirection.rtl,
                            maxLines: null,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            enableInteractiveSelection: true,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textColor,
                              fontSize: 15.sp,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: 'پیام خود را بنویسید...',
                              hintStyle: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: context.textSecondary,
                                fontSize: 15.sp,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 14.h,
                              ),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _send(),
                            textInputAction: TextInputAction.send,
                            onChanged: (_) {
                              // هنگام تایپ، اگر نزدیک به پایین هستیم، اسکرول کن
                              if (_scrollController.hasClients) {
                                final position = _scrollController.position;
                                final distanceFromBottom =
                                    position.maxScrollExtent - position.pixels;
                                if (distanceFromBottom < 100) {
                                  _scrollToBottom();
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(PublicChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrentUser =
        msg.senderId == Supabase.instance.client.auth.currentUser?.id;

    // برای ادمین: Long press menu برای حذف پیام
    if (_isAdmin) {
      return GestureDetector(
        onLongPress: () => _showAdminMessageMenu(msg),
        child: _buildMessageContent(msg, isDark, isCurrentUser),
      );
    }

    return _buildMessageContent(msg, isDark, isCurrentUser);
  }

  Widget _buildMessageContent(
    PublicChatMessage msg,
    bool isDark,
    bool isCurrentUser,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 2.h),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // آواتار کاربر فعلی (سمت راست)
          if (isCurrentUser) ...[
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/trainer-profile',
                arguments: msg.senderId,
              ),
              child: Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: context.goldGradientColors),
                  border: Border.all(
                    color: AppTheme.onGoldColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: ClipOval(
                  child:
                      (msg.senderAvatar != null && msg.senderAvatar!.isNotEmpty)
                      ? Image.network(
                          msg.senderAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              LucideIcons.user,
                              color: AppTheme.onGoldColor,
                              size: 14.sp,
                            );
                          },
                        )
                      : Icon(
                          LucideIcons.user,
                          color: AppTheme.onGoldColor,
                          size: 14.sp,
                        ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
          ],
          // محتوای پیام
          Expanded(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                // نام کاربر و نقش (فقط برای پیام‌های دیگران)
                if (!isCurrentUser)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.senderName ?? 'کاربر ناشناس',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: context.textColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (msg.senderRole != null) ...[
                          SizedBox(width: 4.w),
                          UserRoleBadge(
                            role: msg.senderRole!,
                            fontSize: 9.sp,
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 1.h,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                // حباب پیام
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: isCurrentUser
                        ? LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: context.goldGradientColors,
                          )
                        : null,
                    color: isCurrentUser ? null : context.cardColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16.r),
                      topLeft: Radius.circular(16.r),
                      bottomRight: isCurrentUser
                          ? Radius.circular(16.r)
                          : Radius.circular(4.r),
                      bottomLeft: isCurrentUser
                          ? Radius.circular(4.r)
                          : Radius.circular(16.r),
                    ),
                    border: isCurrentUser
                        ? null
                        : Border.all(
                            color: AppTheme.goldColor.withValues(
                              alpha: isDark ? 0.25 : 0.35,
                            ),
                            width: 1,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(
                          alpha: isDark ? 0.1 : 0.15,
                        ),
                        blurRadius: 8.r,
                        spreadRadius: 0,
                        offset: Offset(0.w, 2.h),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // متن پیام
                      Text(
                        msg.message,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isCurrentUser
                              ? AppTheme.onGoldColor
                              : context.textColor,
                          fontSize: 14.sp,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      SizedBox(height: 4.h),
                      // زمان و وضعیت ارسال
                      Row(
                        textDirection: TextDirection.rtl,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${msg.createdAt.hour.toString().padLeft(2, "0")}:${msg.createdAt.minute.toString().padLeft(2, "0")}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isCurrentUser
                                  ? AppTheme.onGoldColor.withValues(alpha: 0.7)
                                  : context.textSecondary,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Indicator وضعیت ارسال (فقط برای پیام‌های کاربر)
                          if (isCurrentUser) ...[
                            SizedBox(width: 4.w),
                            _buildMessageStatusIndicator(msg.id),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // آواتار کاربر (فقط برای پیام‌های دیگران - سمت چپ)
          if (!isCurrentUser) ...[
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/trainer-profile',
                arguments: msg.senderId,
              ),
              child: Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: context.goldGradientColors
                        .map<Color>((c) => c.withValues(alpha: 0.2))
                        .toList(),
                  ),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: ClipOval(
                  child:
                      (msg.senderAvatar != null && msg.senderAvatar!.isNotEmpty)
                      ? Image.network(
                          msg.senderAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarFallback(
                              msg.senderName ?? 'کاربر',
                            );
                          },
                        )
                      : _buildAvatarFallback(msg.senderName ?? 'کاربر'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: context.goldGradientColors),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppTheme.onGoldColor,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageStatusIndicator(String messageId) {
    final status = _messageStatuses[messageId];

    if (status == null) {
      // اگر وضعیتی وجود ندارد، چیزی نمایش نده
      return const SizedBox.shrink();
    }

    switch (status) {
      case MessageSendStatus.sending:
        return SizedBox(
          width: 12.w,
          height: 12.h,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.onGoldColor.withValues(alpha: 0.6),
            ),
          ),
        );
      case MessageSendStatus.sent:
        return Icon(
          LucideIcons.check,
          size: 12.sp,
          color: AppTheme.onGoldColor.withValues(alpha: 0.7),
        );
      case MessageSendStatus.failed:
        return GestureDetector(
          onTap: () {
            // تلاش مجدد برای ارسال
            final message = _messages.firstWhere((m) => m.id == messageId);
            SafeSetState.call(this, () {
              _messages.removeWhere((m) => m.id == messageId);
              _messageStatuses.remove(messageId);
            });
            if (_controller.isSafe && mounted) {
              _controller.safeSetText(message.message);
              _send();
            }
          },
          child: Icon(
            LucideIcons.alertCircle,
            size: 12.sp,
            color: Colors.red.withValues(alpha: 0.8),
          ),
        );
    }
  }

  void _showAdminMessageMenu(PublicChatMessage msg) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Message preview
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      LucideIcons.messageCircle,
                      size: 20.sp,
                      color: AppTheme.goldColor,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'پیام از: ${msg.senderName ?? "کاربر ناشناس"}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            msg.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: AppTheme.goldColor.withValues(alpha: 0.2),
              ),
              // Delete button
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    LucideIcons.trash2,
                    color: Colors.red,
                    size: 20.sp,
                  ),
                ),
                title: Text(
                  'حذف پیام',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.red,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessageAsAdmin(msg);
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMessageAsAdmin(PublicChatMessage msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        backgroundColor: context.cardColor,
        title: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              LucideIcons.alertTriangle,
              color: Colors.orange,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'تأیید حذف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید این پیام را حذف کنید؟\n\nاین عمل قابل بازگشت نیست.',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'انصراف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'حذف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // نمایش loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              textDirection: TextDirection.rtl,
              children: [
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'در حال حذف پیام...',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.goldColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // حذف پیام از طریق AdminService
      await _adminService.deletePublicChatMessage(msg.id);

      // حذف از لیست محلی
      SafeSetState.call(this, () {
        _messages.removeWhere((m) => m.id == msg.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'پیام با موفقیت حذف شد',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'خطا در حذف پیام: $e',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
