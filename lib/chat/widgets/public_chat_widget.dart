import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/widgets/chat_hub_ui.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/chat/models/public_chat_message.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:gymaipro/chat/services/public_chat_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/widgets/user_role_badge.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MessageSendStatus { sending, sent, failed }

class PublicChatWidget extends StatefulWidget {
  const PublicChatWidget({super.key});

  @override
  PublicChatWidgetState createState() => PublicChatWidgetState();
}

class PublicChatWidgetState extends State<PublicChatWidget>
    with WidgetsBindingObserver {
  final PublicChatService _service = PublicChatService();
  final AdminService _adminService = AdminService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = true;
  bool _isAdmin = false;
  List<PublicChatMessage> _messages = [];
  late Stream<PublicChatMessage> _subscription;
  StreamSubscription<PublicChatMessage>? _messageSub;

  // برای مدیریت اسکرول و کیبورد
  Timer? _scrollDebounceTimer;
  bool _isKeyboardVisible = false;

  // وضعیت ارسال پیام‌ها (messageId -> status)
  final Map<String, MessageSendStatus> _messageStatuses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // اضافه کردن listener برای focus
    _focusNode.addListener(_onFocusChange);

    _setupSubscription();
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
    } catch (_) {}
  }

  void _setupSubscription() {
    _subscription = _service.subscribeMessages();
    _messageSub = _subscription.listen(
      (msg) {
        // اگر پیام به‌روزرسانی شده و حذف شده باشد، آن را از لیست همه کاربران حذف کن (real-time delete)
        if (msg.isDeleted) {
          SafeSetState.call(this, () {
            _messages.removeWhere((m) => m.id == msg.id);
            _messageStatuses.remove(msg.id);
          });
          return;
        }

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

          }
        });
        // اسکرول به پایین فقط برای پیام‌های جدید
        if (isNewMessage) {
          _scrollToBottom(delay: const Duration(milliseconds: 100));
        }
      },
      onError: (_) {},
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

      final msgs = await _service.getMessages();

      SafeSetState.call(this, () {
        _messages = msgs;
        _isLoading = false;
      });
      // اسکرول به پایین بعد از بارگذاری پیام‌ها
      _scrollToBottom(delay: const Duration(milliseconds: 200));
    } catch (_) {
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
            _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), _scrollToBottom);
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
        } catch (_) {}
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
      final sentMessage = await _service.sendMessage(message: txt);

      // به‌روزرسانی لیست: حذف پیام موقت و اضافه کردن پیام واقعی
      SafeSetState.call(this, () {
        // حذف پیام موقت
        _messages.removeWhere((m) => m.id == tempId);
        _messageStatuses.remove(tempId);

        // اضافه کردن پیام واقعی با وضعیت sent
        if (!_messages.any((m) => m.id == sentMessage.id)) {
          _messages.add(sentMessage);
          _messageStatuses[sentMessage.id] = MessageSendStatus.sent;
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
      // استخراج متن تمیز بدون پیشوند Exception:
      var errorText = e.toString();
      const prefix = 'Exception: ';
      if (errorText.startsWith(prefix)) {
        errorText = errorText.substring(prefix.length).trim();
      }

      // تشخیص بلاک بودن کاربر در چت عمومی با تگ اختصاصی
      const blockTag = '[PUBLIC_CHAT_BLOCK]';
      final isBlockedError = errorText.startsWith(blockTag);
      if (isBlockedError) {
        // تگ را حذف کنیم تا فقط متن دلیل به کاربر نمایش داده شود
        errorText = errorText.substring(blockTag.length).trim();
      }

      if (isBlockedError) {
        // برای بلاک، پیام موقت را کاملاً حذف می‌کنیم و وضعیت failed نشان نمی‌دهیم
        SafeSetState.call(this, () {
          _messages.removeWhere((m) => m.id == tempId);
          _messageStatuses.remove(tempId);
        });
      } else {
        // برای سایر خطاها، پیام را failed می‌کنیم
        SafeSetState.call(this, () {
          _messageStatuses[tempId] = MessageSendStatus.failed;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              // فقط متن خطا، بدون "Exception:"
              errorText.isEmpty ? 'خطا در ارسال پیام' : errorText,
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: context.cardColor,
            // برای خطای بلاک، فقط دکمه بستن (بدون تلاش مجدد)
            action: isBlockedError
                ? SnackBarAction(
                    label: 'بستن',
                    textColor: AppTheme.goldColor,
                    onPressed: () {},
                  )
                : SnackBarAction(
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
    _messageSub?.cancel();
    _scrollDebounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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

    return Column(
      children: [
        _buildRoomHeader(isDark),
        Expanded(
          child: _isLoading
              ? const ChatHubLoadingView(
                  mode: ChatHubLoadingMode.room,
                  title: 'در حال بارگذاری اتاق…',
                  subtitle: 'پیام‌های اخیر همگانی از سرور می‌آید',
                )
              : _messages.isEmpty
                  ? const ChatHubEmptyView(
                      icon: LucideIcons.messagesSquare,
                      title: 'اتاق هنوز ساکت است',
                      subtitle:
                          'اولین پیام را بفرست و گفتگوی ${AppConfig.gymAiDisplayName} را شروع کن',
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshMessages,
                      color: AppTheme.goldColor,
                      edgeOffset: 8,
                      child: GestureDetector(
                        onTap: _focusNode.unfocus,
                        behavior: HitTestBehavior.translucent,
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 16.h),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final messageIndex = _messages.length - 1 - index;
                            final msg = _messages[messageIndex];
                            return Column(
                              key: ValueKey<String>(msg.id),
                              children: [
                                if (_showDateHeader(messageIndex))
                                  _buildDateChip(msg.createdAt),
                                _buildMessageBubble(msg, messageIndex),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
        ),
        _buildInputBar(isDark),
      ],
    );
  }

  Widget _buildRoomHeader(bool isDark) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.goldColor.withValues(alpha: isDark ? 0.14 : 0.1),
            context.cardColor,
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.18),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              LucideIcons.radio,
              size: 18.sp,
              color: AppTheme.goldColor,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اتاق عمومی ${AppConfig.gymAiDisplayName}',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5.sp,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'گفتگوی آزاد ورزشکاران و مربیان — با احترام صحبت کنید',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: context.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '${_messages.length}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.goldColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          top: BorderSide(
            color: context.separatorColor.withValues(alpha: 0.35),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 12,
            offset: Offset(0, -3.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _send,
                  borderRadius: BorderRadius.circular(14.r),
                  child: Ink(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: context.goldGradientColors,
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      LucideIcons.send,
                      color: AppTheme.onGoldColor,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 44.h,
                    maxHeight: 120.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.backgroundColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(
                        alpha: isDark ? 0.2 : 0.22,
                      ),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textDirection: TextDirection.rtl,
                    maxLines: null,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 15.sp,
                      height: 1.45,
                    ),
                    decoration: InputDecoration(
                      hintText: 'پیام همگانی…',
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
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _showDateHeader(int messageIndex) {
    if (messageIndex <= 0) return true;
    return !_isSameDay(
      _messages[messageIndex].createdAt,
      _messages[messageIndex - 1].createdAt,
    );
  }

  bool _showSenderHeader(int messageIndex) {
    if (messageIndex <= 0) return true;
    final prev = _messages[messageIndex - 1];
    final curr = _messages[messageIndex];
    if (!_isSameDay(prev.createdAt, curr.createdAt)) return true;
    if (prev.senderId != curr.senderId) return true;
    return curr.createdAt.difference(prev.createdAt).inMinutes > 4;
  }

  String _dateChipLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'امروز';
    if (day == today.subtract(const Duration(days: 1))) return 'دیروز';
    final j = Jalali.fromDateTime(date);
    return '${j.day} ${j.formatter.mN} ${j.year}';
  }

  Widget _buildDateChip(DateTime date) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            _dateChipLabel(date),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(PublicChatMessage msg, int messageIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrentUser =
        msg.senderId == Supabase.instance.client.auth.currentUser?.id;
    final showHeader = _showSenderHeader(messageIndex);
    final isGrouped = !showHeader;

    final bubble = _isAdmin
        ? GestureDetector(
            onLongPress: () => _showAdminMessageMenu(msg),
            child: _buildMessageContent(
              msg,
              isDark,
              isCurrentUser,
              showHeader: showHeader,
              isGrouped: isGrouped,
            ),
          )
        : _buildMessageContent(
            msg,
            isDark,
            isCurrentUser,
            showHeader: showHeader,
            isGrouped: isGrouped,
          );

    return Padding(
      padding: EdgeInsets.only(
        bottom: isGrouped ? 3.h : 10.h,
        top: showHeader ? 2.h : 0,
      ),
      child: bubble,
    );
  }

  Widget _buildMessageContent(
    PublicChatMessage msg,
    bool isDark,
    bool isCurrentUser, {
    required bool showHeader,
    required bool isGrouped,
  }) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.76;

    return Align(
      alignment: isCurrentUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            SizedBox(
              width: 36.w,
              child: showHeader
                  ? _buildSenderAvatar(msg, size: 34)
                  : SizedBox(width: 34.w),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCurrentUser && showHeader)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, right: 2.w),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.senderName ?? 'کاربر',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: context.textColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (msg.senderRole != null) ...[
                          SizedBox(width: 6.w),
                          UserRoleBadge(
                            role: msg.senderRole!,
                            fontSize: 9.sp,
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: isGrouped ? 8.h : 10.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: isCurrentUser
                        ? LinearGradient(
                            colors: context.goldGradientColors,
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          )
                        : null,
                    color: isCurrentUser
                        ? null
                        : (isDark
                            ? context.cardColor
                            : context.cardColor.withValues(alpha: 0.95)),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(isGrouped ? 14.r : 16.r),
                      topLeft: Radius.circular(isGrouped ? 14.r : 16.r),
                      bottomRight: Radius.circular(
                        isCurrentUser
                            ? (isGrouped ? 14.r : 16.r)
                            : (isGrouped ? 6.r : 5.r),
                      ),
                      bottomLeft: Radius.circular(
                        isCurrentUser
                            ? (isGrouped ? 6.r : 5.r)
                            : (isGrouped ? 14.r : 16.r),
                      ),
                    ),
                    border: isCurrentUser
                        ? null
                        : Border.all(
                            color: AppTheme.goldColor.withValues(
                              alpha: isDark ? 0.14 : 0.2,
                            ),
                          ),
                    boxShadow: isGrouped
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.12 : 0.05,
                              ),
                              blurRadius: 6,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.message,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isCurrentUser
                              ? AppTheme.onGoldColor
                              : context.textColor,
                          fontSize: 14.5.sp,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        textDirection: TextDirection.rtl,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isCurrentUser
                                  ? AppTheme.onGoldColor.withValues(alpha: 0.72)
                                  : context.textSecondary,
                              fontSize: 10.sp,
                            ),
                          ),
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
        ],
      ),
    );
  }

  Widget _buildSenderAvatar(PublicChatMessage msg, {required double size}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/trainer-profile',
        arguments: msg.senderId,
      ),
      child: Container(
        width: size.w,
        height: size.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: ClipOval(
          child: (msg.senderAvatar != null && msg.senderAvatar!.isNotEmpty)
              ? GymaiNetworkImage(
                  imageUrl: msg.senderAvatar!,
                  errorWidget: _buildAvatarFallback(msg.senderName ?? 'کاربر'),
                )
              : _buildAvatarFallback(msg.senderName ?? 'کاربر'),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return DecoratedBox(
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
      builder: (context) => DecoratedBox(
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
              // Block in public chat
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 10.h,
                ),
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    LucideIcons.userX,
                    color: Colors.orange,
                    size: 20.sp,
                  ),
                ),
                title: Text(
                  'بلاک در چت عمومی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.orange,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'کاربر نمی‌تواند در چت همگانی پیام بفرستد',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _blockSenderInPublicChat(msg);
                },
              ),
              Divider(
                height: 1,
                color: AppTheme.goldColor.withValues(alpha: 0.15),
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

  Future<void> _blockSenderInPublicChat(PublicChatMessage msg) async {
    if (!mounted) return;
    final senderId = msg.senderId;
    if (senderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('شناسه فرستنده برای بلاک کردن پیدا نشد'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final TextEditingController reasonController = TextEditingController(
      text:
          'به علت تخلف در چت عمومی، تا ۳ روز از ارسال پیام در چت همگانی مسدود شده‌اید. پس از سه روز در صورت نیاز به پشتیبانی پیام دهید.',
    );
    Duration selectedDuration = const Duration(days: 3);

    final confirmed = await WidgetSafetyUtils.safeShowDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        backgroundColor: dialogContext.cardColor,
        title: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              LucideIcons.userX,
              color: Colors.orange,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'مسدود کردن در چت عمومی',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: dialogContext.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'مدت مسدودیت را انتخاب کنید:',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textColor,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Directionality(
                textDirection: TextDirection.rtl,
                child: DropdownButton<Duration>(
                  value: selectedDuration,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: Duration(days: 1),
                      child: Text('۱ روز'),
                    ),
                    DropdownMenuItem(
                      value: Duration(days: 3),
                      child: Text('۳ روز'),
                    ),
                    DropdownMenuItem(
                      value: Duration(days: 7),
                      child: Text('۷ روز'),
                    ),
                    DropdownMenuItem(
                      value: Duration(days: 30),
                      child: Text('۳۰ روز'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedDuration = value;
                      });
                    }
                  },
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: reasonController,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'متن پیام / دلیل بلاک',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'انصراف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: dialogContext.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text(
              'مسدود کن',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await _adminService.blockUserInPublicChat(
      userId: senderId,
      duration: selectedDuration,
      reason: reasonController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کاربر در چت عمومی مسدود شد'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در مسدود کردن کاربر'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteMessageAsAdmin(PublicChatMessage msg) async {
    if (!mounted) return;

    final confirmed = await WidgetSafetyUtils.safeShowDialog<bool>(
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
            child: const Text(
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

    if (confirmed != true || !mounted) return;

    try {
      // نمایش loading
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'در حال حذف پیام...',
        backgroundColor: AppTheme.goldColor,
        duration: const Duration(seconds: 2),
      );

      // حذف پیام از طریق AdminService
      await _adminService.deletePublicChatMessage(msg.id);

      // حذف از لیست محلی
      SafeSetState.call(this, () {
        _messages.removeWhere((m) => m.id == msg.id);
      });

      if (mounted) {
        final messenger = WidgetSafetyUtils.safeGetScaffoldMessenger(context);
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
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
                const Text(
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
      if (mounted) {
        final messenger = WidgetSafetyUtils.safeGetScaffoldMessenger(context);
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
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
                    style: const TextStyle(
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
