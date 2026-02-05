// صفحه چت - نسخه بهبود یافته
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/chat/services/chat_presence_service.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/chat/widgets/chat_app_bar_widget.dart';
import 'package:gymaipro/chat/widgets/chat_message_bubble.dart';
import 'package:gymaipro/chat/widgets/error_boundary_widget.dart';
import 'package:gymaipro/chat/widgets/message_input_widget.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.otherUserId,
    required this.otherUserName,
    super.key,
  });
  final String otherUserId;
  final String otherUserName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late ChatService _chatService;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMore = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Real-time subscriptions
  StreamSubscription<ChatMessage>? _messageSubscription;

  // User state
  String? _currentUserId;
  String? _otherUserRole;
  String? _otherUserAvatar;
  bool _isOtherUserOnline = false;
  DateTime? _otherUserLastSeen;

  // Chat presence
  final ChatPresenceService _presenceService = ChatPresenceService();
  String? _conversationId;

  // Error handling
  String? _errorMessage;
  bool _hasMoreMessages = true;
  static const int _messagesPerPage = 20;

  @override
  void initState() {
    super.initState();
    debugPrint('=== CHAT SCREEN: initState called ===');
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();

    // حذف حضور کاربر از چت
    _markUserAsInactiveInChat();

    // توقف heartbeat
    if (_conversationId != null) {
      _presenceService.stopHeartbeat(conversationId: _conversationId!);
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateUserPresence(true);
      // از سرگیری heartbeat
      if (_currentUserId != null && _conversationId != null) {
        _presenceService.startHeartbeat(
          userId: _currentUserId!,
          conversationId: _conversationId!,
        );
      }
    } else if (state == AppLifecycleState.paused) {
      _updateUserPresence(false);
      // توقف سریع heartbeat و inactive کردن رکورد
      if (_conversationId != null) {
        _presenceService.stopHeartbeat(conversationId: _conversationId!);
      }
      _markUserAsInactiveInChat();
    }
  }

  @override
  void didChangeMetrics() {
    // هنگام تغییر اندازه (باز/بسته شدن کیبورد) اسکرول کن به آخر
    _scrollToBottom();
    super.didChangeMetrics();
  }

  Future<void> _initializeChat() async {
    try {
      _chatService = ChatService();
      _currentUserId = Supabase.instance.client.auth.currentUser?.id;

      if (_currentUserId == null) {
        throw Exception('کاربر احراز هویت نشده');
      }

      // Load data sequentially to ensure proper error handling
      try {
        await _loadOtherUserInfo();
      } catch (e) {
        debugPrint('Error loading other user info: $e');
      }

      try {
        await _loadMessages();
      } catch (e) {
        debugPrint('Error loading messages: $e');
        SafeSetState.call(this, () {
          _isLoading = false;
          _errorMessage = 'خطا در بارگیری پیام‌ها';
        });
        return;
      }

      try {
        await _setupPresence();
      } catch (e) {
        debugPrint('Error setting up presence: $e');
      }

      _subscribeToMessages();
      _markConversationAsRead();

      // ثبت حضور کاربر در چت
      await _markUserAsActiveInChat();
      // شروع heartbeat برای آپدیت دوره‌ای last_seen
      if (_currentUserId != null && _conversationId != null) {
        _presenceService.startHeartbeat(
          userId: _currentUserId!,
          conversationId: _conversationId!,
        );
      }
    } catch (e) {
      debugPrint('Error in _initializeChat: $e');
      SafeSetState.call(this, () {
        _isLoading = false;
        _errorMessage = 'خطا در راه‌اندازی چت: $e';
      });
    }
  }

  Future<void> _loadOtherUserInfo() async {
    try {
      // بارگذاری اطلاعات کاربر مقابل
      final otherUserResponse = await Supabase.instance.client
          .from('profiles')
          .select('role, last_seen_at, avatar_url')
          .eq('id', widget.otherUserId)
          .single();

      // بارگذاری آواتار کاربر فعلی (در حال حاضر استفاده نمی‌شود)
      // Current user avatar loading not needed for now

      SafeSetState.call(this, () {
        _otherUserRole = otherUserResponse['role'] as String?;
        _otherUserAvatar = otherUserResponse['avatar_url'] as String?;
        _otherUserLastSeen = otherUserResponse['last_seen_at'] != null
            ? DateTime.parse(otherUserResponse['last_seen_at'] as String)
            : null;
        _updateOnlineStatus();
      });
    } catch (e) {
      debugPrint('Error loading other user info: $e');
    }
  }

  void _updateOnlineStatus() {
    if (_otherUserLastSeen == null) {
      _isOtherUserOnline = false;
      return;
    }

    final now = DateTime.now();
    final difference = now.difference(_otherUserLastSeen!);
    _isOtherUserOnline =
        difference.inMinutes < 5; // Online if seen in last 5 minutes
  }

  Future<void> _setupPresence() async {
    try {
      // Simple presence tracking - just update last_seen
      await _updateUserPresence(true);

      // پاک کردن حضورهای قدیمی
      await _presenceService.cleanupOldPresence();
    } catch (e) {
      debugPrint('Error setting up presence: $e');
    }
  }

  Future<void> _updateUserPresence(bool isOnline) async {
    try {
      if (_currentUserId != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'last_seen_at': DateTime.now().toIso8601String(),
              'is_online': isOnline,
            })
            .eq('id', _currentUserId!);
      }
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      debugPrint('=== CHAT SCREEN: Starting to load messages ===');
      SafeSetState.call(this, () {
        _isLoading = true;
        _errorMessage = null;
      });

      // اطمینان از وجود مکالمه
      await _chatService.ensureConversationExists(widget.otherUserId);

      final messages = await _chatService.getMessages(widget.otherUserId);
      debugPrint('=== CHAT SCREEN: Loaded ${messages.length} messages ===');

      // دریافت conversation ID
      final conversation = await _chatService.getConversationByUserId(
        widget.otherUserId,
      );
      if (conversation != null) {
        _conversationId = conversation.id;
      }

      SafeSetState.call(this, () {
        _messages = messages;
        _isLoading = false;
        _hasMoreMessages = messages.length >= _messagesPerPage;
      });

      debugPrint(
        '=== CHAT SCREEN: Messages loaded successfully, _isLoading: false ===',
      );
      _scrollToBottom();
    } catch (e) {
      debugPrint('=== CHAT SCREEN: Error loading messages: $e ===');
      SafeSetState.call(this, () {
        _isLoading = false;
        _errorMessage = 'خطا در بارگیری پیام‌ها';
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    try {
      SafeSetState.call(this, () => _isLoadingMore = true);

      final moreMessages = await _chatService.getMessages(widget.otherUserId);

      if (moreMessages.isNotEmpty) {
        SafeSetState.call(this, () {
          _messages.insertAll(0, moreMessages);
          _hasMoreMessages = moreMessages.length >= _messagesPerPage;
        });
      } else {
        SafeSetState.call(this, () {
          _hasMoreMessages = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    } finally {
      SafeSetState.call(this, () => _isLoadingMore = false);
    }
  }

  void _subscribeToMessages() {
    _messageSubscription = _chatService
        .subscribeToMessages(widget.otherUserId)
        .listen(
          (message) {
            // فقط پیام‌های دیگران را اضافه کن، نه پیام‌های خود کاربر
            if (message.senderId != _currentUserId) {
              _addMessageIfNotExists(message);
              _scrollToBottom();
              _markConversationAsRead();
            } else {
              // برای پیام‌های خود کاربر، فقط آپدیت کن
              SafeSetState.call(this, () {
                final index = _messages.indexWhere((m) => m.id == message.id);
                if (index != -1) {
                  _messages[index] = message;
                }
              });
            }
          },
          onError: (Object error) {
            debugPrint('Message subscription error: $error');
          },
        );
  }

  Future<void> _markConversationAsRead() async {
    try {
      // ابتدا مکالمه را پیدا کن
      final conversation = await _chatService.getConversationByUserId(
        widget.otherUserId,
      );
      if (conversation != null) {
        await _chatService.markConversationAsRead(conversation.id);

        // به‌روزرسانی ChatUnreadNotifier
        if (mounted) {
          try {
            final notifier = Provider.of<ChatUnreadNotifier>(
              context,
              listen: false,
            );
            // initialize with an instance; notifier ignores it internally
            await notifier.ensureInitialized(SupabaseService());
            await notifier.refreshUnreadCount();
          } catch (e) {
            debugPrint('=== CHAT SCREEN: Provider not available: $e ===');
          }
        }
      }
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (!mounted || !_messageController.isSafe) return;
    final message = _messageController.safeText.trim();
    if (message.isEmpty || _isSending) return;

    // Create optimistic message
    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId!,
      receiverId: widget.otherUserId,
      message: message,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    SafeSetState.call(this, () {
      _isSending = true;
      _messages.add(tempMessage);
    });

    if (_messageController.isSafe) {
      _messageController.safeClear();
    }
    _scrollToBottom();

    try {
      final sentMessage = await _chatService.sendMessage(
        receiverId: widget.otherUserId,
        message: message,
      );

      // Replace temp message with real message
      SafeSetState.call(this, () {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = sentMessage;
        } else {
          // اگر پیام موقت پیدا نشد، پیام واقعی را اضافه کن
          _messages.add(sentMessage);
        }
        // مرتب‌سازی بر اساس زمان ایجاد (قدیمی‌ترین اول)
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
    } catch (e) {
      // Remove temp message on error
      SafeSetState.call(this, () {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });

      debugPrint('=== CHAT SCREEN: Error sending message: $e ===');

      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage.isNotEmpty ? errorMessage : 'خطا در ارسال پیام',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
              ),
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'تلاش مجدد',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _sendMessage();
              },
            ),
          ),
        );
      }
    } finally {
      SafeSetState.call(this, () => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // With reverse: true, انتهای لیست در minScrollExtent است
        final target = _scrollController.position.minScrollExtent;
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // اضافه کردن پیام بدون تکرار و حفظ ترتیب زمانی
  void _addMessageIfNotExists(ChatMessage message) {
    // بررسی وجود پیام بر اساس ID
    final exists = _messages.any((m) => m.id == message.id);

    if (!exists) {
      SafeSetState.call(this, () {
        _messages.add(message);
        // مرتب‌سازی بر اساس زمان ایجاد (قدیمی‌ترین اول)
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
    }
  }

  Future<void> _refreshMessages() async {
    await _loadMessages();
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      await _chatService.deleteMessage(message.id);

      // Update local state immediately
      SafeSetState.call(this, () {
        _messages.removeWhere((m) => m.id == message.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در حذف پیام: $e')));
      }
    }
  }

  Future<void> _editMessage(ChatMessage message, String newText) async {
    try {
      await _chatService.editMessage(message.id, newText);

      // Update local state immediately
      SafeSetState.call(this, () {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            message: newText,
            updatedAt: DateTime.now(),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در ویرایش پیام: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(scaffoldBackgroundColor: context.backgroundColor),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: context.backgroundColor,
        appBar: ChatAppBarWidget(
          otherUserName: widget.otherUserName,
          otherUserRole: _otherUserRole,
          otherUserAvatar: _otherUserAvatar,
          isOtherUserOnline: _isOtherUserOnline,
          otherUserLastSeen: _otherUserLastSeen,
          onBackPressed: () => Navigator.of(context).pop(),
          onMorePressed: _showChatOptions,
        ),
        body: Column(
          children: [
            Expanded(
              child: ErrorBoundaryWidget(
                child: _buildMessagesList(),
                onRetry: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeChat();
                },
              ),
            ),
            MessageInputWidget(
              controller: _messageController,
              onSendPressed: _sendMessage,
              onAttachmentPressed: _showAttachmentOptions,
              isSending: _isSending,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    debugPrint(
      '=== CHAT SCREEN: Building messages list, _isLoading: $_isLoading, _messages.length: ${_messages.length} ===',
    );

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.goldColor),
            SizedBox(height: 16.h),
            Text(
              'در حال بارگذاری پیام‌ها...',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              color: AppTheme.goldColor.withValues(alpha: 0.5),
              size: 64.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: context.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: Icon(LucideIcons.refreshCw),
              label: Text('تلاش مجدد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.onGoldColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                LucideIcons.messageCircle,
                color: AppTheme.goldColor.withValues(alpha: 0.5),
                size: 64.sp,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'هنوز پیامی ارسال نشده',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: context.textColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'شروع به گفتگو کنید',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMessages,
      color: AppTheme.goldColor,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.all(16.w),
        itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
        itemBuilder: (context, index) {
          // در حالت reverse، اندیس 0 یعنی آخرین پیام
          // پیام‌ها به ترتیب صعودی (قدیمی‌ترین اول) هستند
          // با reverse: true، جدیدترین پیام در index 0 نمایش داده می‌شود
          final bool showLoadMore =
              _hasMoreMessages && index == (_messages.length);
          if (showLoadMore) {
            return _buildLoadMoreIndicator();
          }

          // در reverse ListView، index 0 = آخرین پیام (جدیدترین)
          // پس باید از انتهای لیست شروع کنیم
          final int messageIndex = (_messages.length - 1) - index;
          final message = _messages[messageIndex];
          final isMe = message.senderId == _currentUserId;

          return ChatMessageBubble(
            message: message,
            isMe: isMe,
            onLongPress: () => _showMessageOptions(message),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(color: AppTheme.goldColor)
            : TextButton.icon(
                onPressed: _loadMoreMessages,
                icon: Icon(
                  LucideIcons.chevronUp,
                  color: context.textColor,
                ),
                label: Text(
                  'بارگذاری پیام‌های بیشتر',
                  style: TextStyle(color: context.textColor),
                ),
              ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.separatorColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(LucideIcons.search, color: AppTheme.goldColor),
                title: Text(
                  'جستجو در گفتگو',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Search feature not implemented yet
                },
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(LucideIcons.bell, color: AppTheme.goldColor),
                title: Text(
                  'تنظیمات اعلان',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Notification settings not implemented yet
                },
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(LucideIcons.trash2, color: AppTheme.goldColor),
                title: Text(
                  'حذف گفتگو',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteConversation();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(ChatMessage message) {
    if (message.senderId != _currentUserId) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.separatorColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(LucideIcons.edit, color: AppTheme.goldColor),
                title: Text(
                  'ویرایش',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editMessageDialog(message);
                },
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(LucideIcons.copy, color: AppTheme.goldColor),
                title: Text(
                  'کپی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Copy feature not implemented yet
                },
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(LucideIcons.trash2, color: AppTheme.goldColor),
                title: Text(
                  'حذف',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editMessageDialog(ChatMessage message) {
    final editController = TextEditingController(text: message.message);

    showDialog<void>(
      context: context,
      builder: (context) {
        // Dispose controller when dialog is closed
        return WillPopScope(
          onWillPop: () async {
            editController.dispose();
            return true;
          },
          child: AlertDialog(
            backgroundColor: context.cardColor,
            title: Text(
              'ویرایش پیام',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            content: TextField(
              controller: editController,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: context.separatorColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.goldColor, width: 2),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  editController.dispose();
                  Navigator.pop(context);
                },
                child: Text(
                  'لغو',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (!editController.isSafe) {
                    editController.dispose();
                    return;
                  }
                  final newText = editController.safeText.trim();
                  if (newText.isNotEmpty && newText != message.message) {
                    Navigator.pop(context);
                    await _editMessage(message, newText);
                  }
                  editController.dispose();
                },
                child: Text(
                  'ذخیره',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Ensure controller is disposed even if dialog is dismissed
      if (editController.isSafe) {
        editController.dispose();
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.separatorColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(LucideIcons.image, color: AppTheme.goldColor),
                title: Text(
                  'عکس',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Image picker not implemented yet
                },
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(LucideIcons.file, color: AppTheme.goldColor),
                title: Text(
                  'فایل',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // File picker not implemented yet
                },
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(LucideIcons.mic, color: AppTheme.goldColor),
                title: Text(
                  'صوت',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Voice recording not implemented yet
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteConversation() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(
          'حذف گفتگو',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید این گفتگو را حذف کنید؟',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'لغو',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final conversation = await _chatService.getConversationByUserId(
                  widget.otherUserId,
                );
                if (conversation != null) {
                  await _chatService.deleteConversation(conversation.id);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'خطا در حذف گفتگو: $e',
                        style: TextStyle(fontFamily: AppTheme.fontFamily),
                      ),
                      backgroundColor: context.cardColor,
                    ),
                  );
                }
              } finally {
                if (mounted) Navigator.of(context).pop();
              }
            },
            child: Text(
              'حذف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.goldColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ثبت حضور کاربر در چت
  Future<void> _markUserAsActiveInChat() async {
    if (_currentUserId != null && _conversationId != null) {
      await _presenceService.markUserAsActiveInChat(
        userId: _currentUserId!,
        conversationId: _conversationId!,
      );
    }
  }

  /// حذف حضور کاربر از چت
  Future<void> _markUserAsInactiveInChat() async {
    if (_currentUserId != null && _conversationId != null) {
      await _presenceService.markUserAsInactiveInChat(
        userId: _currentUserId!,
        conversationId: _conversationId!,
      );
    }
  }
}
