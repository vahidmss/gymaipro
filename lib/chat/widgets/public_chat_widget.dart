import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/models/public_chat_message.dart';
import 'package:gymaipro/chat/services/public_chat_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/widgets/user_role_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicChatWidget extends StatefulWidget {
  const PublicChatWidget({super.key});

  @override
  PublicChatWidgetState createState() => PublicChatWidgetState();
}

class PublicChatWidgetState extends State<PublicChatWidget>
    with TickerProviderStateMixin {
  final PublicChatService _service = PublicChatService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = true;
  bool _isSending = false;
  List<PublicChatMessage> _messages = [];
  late Stream<PublicChatMessage> _subscription;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

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

    _setupSubscription();

    // شروع انیمیشن‌ها
    unawaited(_fadeController.forward());
    unawaited(_slideController.forward());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_loadMessages());
  }

  void _setupSubscription() {
    _subscription = _service.subscribeMessages();
    _subscription.listen(
      (msg) {
        debugPrint('=== CHAT WIDGET: Received new message: ${msg.message} ===');
        SafeSetState.call(this, () {
          // بررسی اینکه پیام قبلاً اضافه نشده باشد
          if (!_messages.any((m) => m.id == msg.id)) {
            _messages.add(msg);
            debugPrint('=== CHAT WIDGET: Added new message to list ===');
          } else {
            debugPrint('=== CHAT WIDGET: Message already exists, skipping ===');
          }
        });
        _scrollToBottom();
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
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  Future<void> _refreshMessages() async {
    await _loadMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final target = _scrollController.position.minScrollExtent;
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final txt = _controller.text.trim();
    if (txt.isEmpty || _isSending) return;

    SafeSetState.call(this, () => _isSending = true);
    _controller.clear();
    _focusNode.unfocus();

    try {
      debugPrint('=== CHAT WIDGET: Sending message: $txt ===');
      final sentMessage = await _service.sendMessage(message: txt);
      debugPrint(
        '=== CHAT WIDGET: Message sent successfully: ${sentMessage.id} ===',
      );

      // اضافه کردن پیام به لیست محلی برای نمایش فوری
      SafeSetState.call(this, () {
        if (!_messages.any((m) => m.id == sentMessage.id)) {
          _messages.add(sentMessage);
          debugPrint('=== CHAT WIDGET: Added sent message to local list ===');
        }
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('=== CHAT WIDGET: Error sending message: $e ===');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال پیام: $e'),
            backgroundColor: AppTheme.goldColor,
          ),
        );
      }
    }

    if (mounted) {
      SafeSetState.call(this, () => _isSending = false);
    }
  }

  // Add this public method
  Future<void> reloadMessages() {
    return _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              // حذف هدر بالای چت
              // Messages Area
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.goldColor,
                        ),
                      )
                    : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.messageCircle,
                              size: 32.sp,
                              color: AppTheme.bodyStyle.color,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'هنوز پیامی ارسال نشده',
                              style: TextStyle(
                                color: AppTheme.bodyStyle.color,
                                fontSize: 12.sp,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'اولین پیام را شما ارسال کنید!',
                              style: TextStyle(
                                color: AppTheme.bodyStyle.color,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshMessages,
                        color: AppTheme.goldColor,
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
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
              // Input Area مینیمال
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16.r),
                    bottomRight: Radius.circular(16.r),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.textColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: AppTheme.goldColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 14.sp,
                            ),
                            decoration: InputDecoration(
                              hintText: 'پیام خود را بنویسید...',
                              hintStyle: TextStyle(
                                color: AppTheme.bodyStyle.color,
                                fontSize: 14.sp,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              suffixIcon: _isSending
                                  ? Padding(
                                      padding: EdgeInsets.all(12.w),
                                      child: SizedBox(
                                        width: 16.w,
                                        height: 16.h,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.goldColor,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _send(),
                            textInputAction: TextInputAction.send,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Material(
                          color: AppTheme.backgroundColor,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20.r),
                            onTap: _send,
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Icon(
                                _isSending
                                    ? LucideIcons.loader2
                                    : LucideIcons.send,
                                color: AppTheme.textColor,
                                size: 18.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(PublicChatMessage msg) {
    final isCurrentUser =
        msg.senderId == Supabase.instance.client.auth.currentUser?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser) ...[
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/trainer-profile',
                  arguments: msg.senderId,
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                  backgroundImage:
                      (msg.senderAvatar != null && msg.senderAvatar!.isNotEmpty)
                      ? NetworkImage(msg.senderAvatar!)
                      : null,
                  child: (msg.senderAvatar == null || msg.senderAvatar!.isEmpty)
                      ? Text(
                          (msg.senderName ?? 'کاربر')[0].toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.goldColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            msg.senderName ?? 'کاربر ناشناس',
                            style: TextStyle(
                              color: AppTheme.textColor.withValues(alpha: 0.8),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (msg.senderRole != null) ...[
                            const SizedBox(width: 4),
                            UserRoleBadge(role: msg.senderRole!, fontSize: 10),
                          ],
                        ],
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? AppTheme.goldColor
                          : AppTheme.textColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16.r).copyWith(
                        bottomLeft: isCurrentUser
                            ? Radius.circular(16.r)
                            : Radius.circular(4.r),
                        bottomRight: isCurrentUser
                            ? Radius.circular(4.r)
                            : Radius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      msg.message,
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${msg.createdAt.hour.toString().padLeft(2, "0")}:${msg.createdAt.minute.toString().padLeft(2, "0")}',
                      style: TextStyle(
                        color: AppTheme.bodyStyle.color,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/trainer-profile',
                  arguments: msg.senderId,
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                  backgroundImage:
                      (msg.senderAvatar != null && msg.senderAvatar!.isNotEmpty)
                      ? NetworkImage(msg.senderAvatar!)
                      : null,
                  child: (msg.senderAvatar == null || msg.senderAvatar!.isEmpty)
                      ? Icon(
                          LucideIcons.user,
                          color: AppTheme.goldColor,
                          size: 18.sp,
                        )
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
