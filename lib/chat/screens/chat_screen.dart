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
    final message = _messageController.text.trim();
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

    _messageController.clear();
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
      });
    } catch (e) {
      // Remove temp message on error
      SafeSetState.call(this, () {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال پیام: $e'),
            backgroundColor: AppTheme.goldColor,
            action: SnackBarAction(
              label: 'تلاش مجدد',
              textColor: AppTheme.textColor,
              onPressed: _sendMessage,
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

  // اضافه کردن پیام بدون تکرار
  void _addMessageIfNotExists(ChatMessage message) {
    // بررسی وجود پیام بر اساس ID و محتوا
    final exists = _messages.any(
      (m) =>
          m.id == message.id ||
          (m.senderId == message.senderId &&
              m.message == message.message &&
              m.createdAt.difference(message.createdAt).abs().inSeconds < 5),
    );

    if (!exists) {
      SafeSetState.call(this, () {
        _messages.add(message);
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.backgroundColor,
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
            const CircularProgressIndicator(color: AppTheme.goldColor),
            const SizedBox(height: 16),
            Text(
              'در حال بارگذاری پیام‌ها...',
              style: TextStyle(color: AppTheme.bodyStyle.color),
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
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTheme.headingStyle.copyWith(fontSize: 16.sp),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('تلاش مجدد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.textColor,
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
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                LucideIcons.messageCircle,
                color: AppTheme.goldColor.withValues(alpha: 0.5),
                size: 64.sp,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'هنوز پیامی ارسال نشده',
              style: AppTheme.headingStyle.copyWith(fontSize: 18.sp),
            ),
            const SizedBox(height: 8),
            Text(
              'شروع به گفتگو کنید',
              style: AppTheme.bodyStyle.copyWith(fontSize: 14.sp),
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
          final bool showLoadMore =
              _hasMoreMessages && index == (_messages.length);
          if (showLoadMore) {
            return _buildLoadMoreIndicator();
          }

          final int listCount = _messages.length;
          final int logicalIndex = index;
          final int messageIndex = (listCount - 1) - logicalIndex;
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
                icon: const Icon(
                  LucideIcons.chevronUp,
                  color: AppTheme.goldColor,
                ),
                label: const Text(
                  'بارگذاری پیام‌های بیشتر',
                  style: TextStyle(color: AppTheme.goldColor),
                ),
              ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                LucideIcons.search,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'جستجو در گفتگو',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // Search feature not implemented yet
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.bell,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'تنظیمات اعلان',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // Notification settings not implemented yet
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.trash2,
                color: AppTheme.goldColor,
              ),
              title: const Text(
                'حذف گفتگو',
                style: TextStyle(color: AppTheme.goldColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteConversation();
              },
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
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                LucideIcons.edit,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'ویرایش',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _editMessageDialog(message);
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.copy,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'کپی',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // Copy feature not implemented yet
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.trash2,
                color: AppTheme.goldColor,
              ),
              title: const Text(
                'حذف',
                style: TextStyle(color: AppTheme.goldColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
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
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'ویرایش پیام',
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: AppTheme.textColor),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != message.message) {
                Navigator.pop(context);
                await _editMessage(message, newText);
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                LucideIcons.image,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'عکس',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // Image picker not implemented yet
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.file,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'فایل',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // File picker not implemented yet
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.mic,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'صوت',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // Voice recording not implemented yet
              },
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
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'حذف گفتگو',
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید این گفتگو را حذف کنید؟',
          style: TextStyle(color: AppTheme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
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
                    SnackBar(content: Text('خطا در حذف گفتگو: $e')),
                  );
                }
              } finally {
                if (mounted) Navigator.of(context).pop();
              }
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: AppTheme.goldColor),
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
