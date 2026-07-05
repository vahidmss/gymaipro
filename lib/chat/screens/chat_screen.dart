// صفحه چت - نسخه بهبود یافته
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/chat/services/chat_cache_service.dart';
import 'package:gymaipro/chat/services/chat_presence_service.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/chat/services/chat_unread_sync_bus.dart';
import 'package:gymaipro/chat/widgets/chat_app_bar_widget.dart';
import 'package:gymaipro/chat/widgets/chat_hub_ui.dart';
import 'package:gymaipro/chat/widgets/chat_message_bubble.dart';
import 'package:gymaipro/chat/widgets/error_boundary_widget.dart';
import 'package:gymaipro/chat/widgets/message_input_widget.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.otherUserId,
    required this.otherUserName,
    this.initialConversationId,
    super.key,
  });
  final String otherUserId;
  final String otherUserName;
  final String? initialConversationId;

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
  RealtimeChannel? _peerPresenceChannel;
  Timer? _messageSyncTimer;
  Timer? _markReadDebounceTimer;

  // User state
  String? _currentUserId;
  String? _otherUserRole;
  String? _otherUserAvatar;
  bool _isOtherUserOnline = false;
  DateTime? _otherUserLastSeen;

  // Chat presence
  final ChatPresenceService _presenceService = ChatPresenceService();
  String? _conversationId;

  // Captured so dispose() can notify without touching a deactivated context.
  ChatUnreadNotifier? _unreadNotifier;

  // Error handling
  String? _errorMessage;
  bool _hasMoreMessages = true;
  bool _isAppInForeground = true;
  bool _peerIsActiveInChat = false;
  static const int _messagesPerPage = 20;
  final Set<String> _messageIds = {};
  Timer? _metricsDebounceTimer;
  final ChatCacheService _chatCache = ChatCacheService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // برای جلوگیری از قفل شدن انیمیشن‌های ورودی/کیبورد،
    // مقداردهی اولیه‌ی سنگین را به بعد از اولین فریم موکول می‌کنیم.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeChat();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _peerPresenceChannel?.unsubscribe();
    _messageSyncTimer?.cancel();
    _markReadDebounceTimer?.cancel();
    _metricsDebounceTimer?.cancel();

    // اطلاع به نوتیفایر که کاربر از این گفتگو خارج شد تا در بازهٔ کوتاهِ
    // همگام‌سازیِ mark-read نوتیف اشتباه برای پیام‌های همین الان خوانده‌شده نیاید.
    if (_conversationId != null && _conversationId!.isNotEmpty) {
      _unreadNotifier?.noteConversationLeft(_conversationId!);
    }

    // حذف حضور کاربر از چت
    if (_currentUserId != null && _conversationId != null) {
      unawaited(
        _presenceService.markUserAsInactiveInChat(
          userId: _currentUserId!,
          conversationId: _conversationId!,
        ),
      );
    }

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
      _isAppInForeground = true;
      _updateUserPresence(true);
      unawaited(_syncNewMessagesQuietly());
      // از سرگیری heartbeat
      if (_currentUserId != null && _conversationId != null) {
        _presenceService.startHeartbeat(
          userId: _currentUserId!,
          conversationId: _conversationId!,
        );
      }
    } else if (state == AppLifecycleState.paused) {
      _isAppInForeground = false;
      _updateUserPresence(false);
      // توقف سریع heartbeat و inactive کردن رکورد
      if (_conversationId != null) {
        _presenceService.stopHeartbeat(conversationId: _conversationId!);
      }
      if (_currentUserId != null && _conversationId != null) {
        unawaited(
          _presenceService.markUserAsInactiveInChat(
            userId: _currentUserId!,
            conversationId: _conversationId!,
          ),
        );
      }
    }
  }

  @override
  void didChangeMetrics() {
    _metricsDebounceTimer?.cancel();
    _metricsDebounceTimer = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      _scrollToBottom(animate: false);
    });
    super.didChangeMetrics();
  }

  bool _isCurrentChatRouteVisible() {
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  bool _shouldAutoMarkAsRead() {
    return mounted && _isAppInForeground && _isCurrentChatRouteVisible();
  }

  void _syncMessagesCache() {
    _chatService.saveCachedMessages(widget.otherUserId, _messages);
  }

  Future<void> _initializeChat() async {
    try {
      _chatService = ChatService();
      _currentUserId = Supabase.instance.client.auth.currentUser?.id;
      _conversationId = widget.initialConversationId;

      if (mounted) {
        try {
          _unreadNotifier =
              Provider.of<ChatUnreadNotifier>(context, listen: false);
        } catch (_) {}
      }

      if (_currentUserId == null) {
        throw Exception('کاربر احراز هویت نشده');
      }

      try {
        await _loadOtherUserInfo();
      } catch (_) {}

      // نمایش فوری از کش (حافظه یا دیسک)
      var cached = _chatService.getCachedMessages(widget.otherUserId);
      if (cached.isEmpty) {
        cached = await _chatCache.loadMessagesDisk(widget.otherUserId);
      }
      if (cached.isNotEmpty) {
        SafeSetState.call(this, () {
          _messages = cached;
          _messageIds
            ..clear()
            ..addAll(cached.map((m) => m.id));
          _isLoading = false;
          _errorMessage = null;
          _hasMoreMessages = true;
        });
        _scrollToBottom(animate: false);
      }

      try {
        await _loadMessages(showLoading: cached.isEmpty);
      } catch (_) {
        SafeSetState.call(this, () {
          _isLoading = false;
          _errorMessage = 'خطا در بارگیری پیام‌ها';
        });
        return;
      }

      try {
        await _setupPresence();
      } catch (_) {}

      try {
        await _refreshPeerPresence();
      } catch (_) {}
      _subscribeToPeerPresence();

      _subscribeToMessages();
      _startMessageSyncFallback();
      _scheduleMarkAsRead();

      // ثبت حضور کاربر در چت
      if (_currentUserId != null && _conversationId != null) {
        unawaited(
          NotificationService().cancelChatTrayForConversation(_conversationId),
        );
        await _presenceService.markUserAsActiveInChat(
          userId: _currentUserId!,
          conversationId: _conversationId!,
        );
      }
      // شروع heartbeat برای آپدیت دوره‌ای last_seen
      if (_currentUserId != null && _conversationId != null) {
        _presenceService.startHeartbeat(
          userId: _currentUserId!,
          conversationId: _conversationId!,
        );
      }
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _errorMessage = 'خطا در راه‌اندازی چت: $e';
      });
    }
  }

  Future<void> _loadOtherUserInfo() async {
    try {
      final otherUserResponse =
          await UserProfileService.fetchProfile(widget.otherUserId);

      if (otherUserResponse == null) return;

      SafeSetState.call(this, () {
        _otherUserRole = otherUserResponse['role'] as String?;
        _otherUserAvatar = otherUserResponse['avatar_url'] as String?;
        _otherUserLastSeen = otherUserResponse['last_seen_at'] != null
            ? DateTime.parse(otherUserResponse['last_seen_at'] as String)
            : null;
        _updateOnlineStatus();
      });
    } catch (_) {}
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

  Future<void> _refreshPeerPresence() async {
    final convId = _conversationId;
    if (convId == null || convId.isEmpty) return;
    final active = await _presenceService.getActiveUsersInConversation(convId);
    if (!mounted) return;
    SafeSetState.call(this, () {
      _peerIsActiveInChat = active.contains(widget.otherUserId);
    });
  }

  void _subscribeToPeerPresence() {
    _peerPresenceChannel?.unsubscribe();
    final convId = _conversationId;
    if (convId == null || convId.isEmpty) return;

    _peerPresenceChannel = Supabase.instance.client
        .channel('peer_presence_$convId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_presence',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: convId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isEmpty) return;
            final userId = record['user_id'] as String?;
            if (userId != widget.otherUserId) return;
            final isActive = record['is_active'] as bool? ?? false;
            SafeSetState.call(this, () => _peerIsActiveInChat = isActive);
          },
        )
        .subscribe();
  }

  void _scheduleMarkAsRead() {
    if (!_shouldAutoMarkAsRead()) return;
    _markReadDebounceTimer?.cancel();
    _markReadDebounceTimer = Timer(const Duration(milliseconds: 80), () {
      unawaited(_markConversationAsRead());
    });
  }

  void _applyMessageUpdate(ChatMessage message) {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index == -1) return;
    final existing = _messages[index];
    if (existing.isRead == message.isRead &&
        existing.isDeleted == message.isDeleted &&
        existing.message == message.message) {
      return;
    }
    SafeSetState.call(this, () {
      _messages[index] = message;
    });
    _syncMessagesCache();
  }

  Future<void> _setupPresence() async {
    try {
      // Simple presence tracking - just update last_seen
      await _updateUserPresence(true);

      // پاک کردن حضورهای قدیمی
      await _presenceService.cleanupOldPresence();
    } catch (_) {}
  }

  Future<void> _updateUserPresence(bool isOnline) async {
    try {
      if (_currentUserId != null) {
        await SimpleProfileService.updateProfile({
          'last_seen_at': DateTime.now().toIso8601String(),
          'is_online': isOnline,
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    try {
      if (showLoading) {
        SafeSetState.call(this, () {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      List<ChatMessage> messages;
      if (_conversationId != null && _conversationId!.isNotEmpty) {
        messages = await _chatService.getMessagesByConversationId(
          _conversationId!,
          limit: _messagesPerPage,
        );
      } else {
        await _chatService.ensureConversationExists(widget.otherUserId);
        messages = await _chatService.getMessages(
          widget.otherUserId,
          limit: _messagesPerPage,
        );
        final conversation = await _chatService.getConversationByUserId(
          widget.otherUserId,
        );
        if (conversation != null) {
          _conversationId = conversation.id;
        }
      }

      unawaited(
        NotificationService().cancelChatTrayForConversation(_conversationId),
      );

      SafeSetState.call(this, () {
        _messages = messages;
        _messageIds
          ..clear()
          ..addAll(messages.map((m) => m.id));
        _isLoading = false;
        _errorMessage = null;
        _hasMoreMessages = messages.length >= _messagesPerPage;
      });
      _syncMessagesCache();
      _scrollToBottom(animate: !showLoading);
    } catch (_) {
      SafeSetState.call(this, () {
        _isLoading = false;
        if (_messages.isEmpty) {
          _errorMessage = 'خطا در بارگیری پیام‌ها';
        }
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    try {
      SafeSetState.call(this, () => _isLoadingMore = true);

      final loadedCount = _messages.length;
      List<ChatMessage> moreMessages;
      if (_conversationId != null && _conversationId!.isNotEmpty) {
        moreMessages = await _chatService.getMessagesByConversationId(
          _conversationId!,
          limit: _messagesPerPage,
          loadedFromEnd: loadedCount,
        );
      } else {
        moreMessages = await _chatService.getMessages(
          widget.otherUserId,
          limit: _messagesPerPage,
          loadedFromEnd: loadedCount,
        );
      }

      if (moreMessages.isNotEmpty) {
        SafeSetState.call(this, () {
          final unique =
              moreMessages.where((m) => _messageIds.add(m.id)).toList();
          _messages.insertAll(0, unique);
          _hasMoreMessages =
              moreMessages.length >= _messagesPerPage && unique.isNotEmpty;
        });
        _syncMessagesCache();
      } else {
        SafeSetState.call(this, () => _hasMoreMessages = false);
      }
    } catch (_) {
      // ignore
    } finally {
      SafeSetState.call(this, () => _isLoadingMore = false);
    }
  }

  void _subscribeToMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = _chatService
        .subscribeToMessages(
          widget.otherUserId,
          conversationId: _conversationId,
        )
        .listen((message) {
          if (message.senderId != _currentUserId) {
            final inserted = _addMessageIfNotExists(message);
            if (inserted) {
              _syncMessagesCache();
              _scrollToBottom();
              ChatUnreadSyncBus.instance.ping();
              _scheduleMarkAsRead();
            } else {
              _applyMessageUpdate(message);
            }
          } else {
            SafeSetState.call(this, () {
              final index = _messages.indexWhere((m) => m.id == message.id);
              if (index != -1) {
                _messages[index] = message;
              } else {
                _mergeOrAddOwnMessage(message);
              }
            });
            _syncMessagesCache();
          }
        }, onError: (_) {});
  }

  void _startMessageSyncFallback() {
    _messageSyncTimer?.cancel();
    // Lightweight poll when realtime is flaky (common on some networks/devices).
    _messageSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_isAppInForeground || !mounted) return;
      unawaited(_syncNewMessagesQuietly());
    });
  }

  Future<void> _syncNewMessagesQuietly() async {
    if (!mounted || _isLoading) return;
    try {
      final List<ChatMessage> latest;
      if (_conversationId != null && _conversationId!.isNotEmpty) {
        latest = await _chatService.getMessagesByConversationId(
          _conversationId!,
        );
      } else {
        latest = await _chatService.getMessages(
          widget.otherUserId,
        );
      }

      var anyNew = false;
      var anyUpdated = false;
      for (final message in latest) {
        if (_addMessageIfNotExists(message)) {
          anyNew = true;
        } else {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1 && _messages[index].isRead != message.isRead) {
            SafeSetState.call(this, () {
              _messages[index] = message;
            });
            anyUpdated = true;
          }
        }
      }
      if (anyNew || anyUpdated) {
        _syncMessagesCache();
        if (anyNew) {
          _scrollToBottom();
          ChatUnreadSyncBus.instance.ping();
        }
        if (anyNew && _shouldAutoMarkAsRead()) {
          _scheduleMarkAsRead();
        }
      }
    } catch (_) {}
  }

  Future<void> _markConversationAsRead() async {
    try {
      if (!_shouldAutoMarkAsRead()) return;

      if (mounted) {
        try {
          final notifier =
              Provider.of<ChatUnreadNotifier>(context, listen: false);
          await notifier.ensureInitialized(SupabaseService());
          if (_conversationId != null && _conversationId!.isNotEmpty) {
            notifier.acknowledgeConversationRead(_conversationId!);
          } else {
            notifier.markAsRead();
          }
        } catch (_) {}
      }

      var conversationId = _conversationId;
      if (conversationId == null || conversationId.isEmpty) {
        final conversation = await _chatService.getConversationByUserId(
          widget.otherUserId,
        );
        conversationId = conversation?.id;
        if (conversationId != null && conversationId.isNotEmpty) {
          _conversationId = conversationId;
        }
      }

      if (conversationId != null && conversationId.isNotEmpty) {
        await _chatService.markConversationAsRead(conversationId);
        ChatUnreadSyncBus.instance.ping();
        if (mounted) {
          try {
            final notifier =
                Provider.of<ChatUnreadNotifier>(context, listen: false);
            await notifier.refreshUnreadCount();
          } catch (_) {}
        }
      }
    } catch (_) {}
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
      _messageIds.add(tempMessage.id);
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

      final displayMessage = _peerIsActiveInChat
          ? sentMessage.copyWith(isRead: true)
          : sentMessage;

      // Replace temp message with real message
      SafeSetState.call(this, () {
        _messageIds.remove(tempMessage.id);
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = displayMessage;
        } else if (!_messageIds.contains(sentMessage.id)) {
          _messages.add(displayMessage);
        }
        _messageIds.add(sentMessage.id);
        // مرتب‌سازی بر اساس زمان ایجاد (قدیمی‌ترین اول)
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
      _syncMessagesCache();
    } catch (e) {
      // Remove temp message on error
      SafeSetState.call(this, () {
        _messageIds.remove(tempMessage.id);
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });

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

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.minScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  bool _addMessageIfNotExists(ChatMessage message) {
    if (_messageIds.contains(message.id)) return false;
    SafeSetState.call(this, () {
      _messageIds.add(message.id);
      _messages.add(message);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
    return true;
  }

  /// Realtime may deliver the server message before send() replaces the optimistic bubble.
  void _mergeOrAddOwnMessage(ChatMessage message) {
    if (_messageIds.contains(message.id)) return;

    final pendingIndex = _messages.indexWhere((m) {
      if (m.senderId != _currentUserId || m.id == message.id) return false;
      if (m.message != message.message) return false;
      return message.createdAt.difference(m.createdAt).inSeconds.abs() < 60;
    });

    if (pendingIndex != -1) {
      _messageIds.remove(_messages[pendingIndex].id);
      _messages[pendingIndex] = message;
      _messageIds.add(message.id);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return;
    }

    _messageIds.add(message.id);
    _messages.add(message);
    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> _refreshMessages() async {
    await _loadMessages();
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      await _chatService.deleteMessage(message.id);

      // Update local state immediately
      SafeSetState.call(this, () {
        _messageIds.remove(message.id);
        _messages.removeWhere((m) => m.id == message.id);
      });
    } catch (e) {
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در حذف پیام: $e',
      );
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
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در ویرایش پیام: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Theme(
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
    ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const ChatHubLoadingView(
        subtitle: 'پیام‌های شما از سرور به‌روز می‌شود',
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
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('تلاش مجدد'),
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
            key: ValueKey<String>(message.id),
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
                icon: Icon(LucideIcons.chevronUp, color: context.textColor),
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
                leading: const Icon(LucideIcons.search, color: AppTheme.goldColor),
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
                leading: const Icon(LucideIcons.bell, color: AppTheme.goldColor),
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
                leading: const Icon(LucideIcons.trash2, color: AppTheme.goldColor),
                title: const Text(
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
                leading: const Icon(LucideIcons.edit, color: AppTheme.goldColor),
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
                leading: const Icon(LucideIcons.copy, color: AppTheme.goldColor),
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
                leading: const Icon(LucideIcons.trash2, color: AppTheme.goldColor),
                title: const Text(
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
        // کنترل امن دیالوگ و dispose کردن TextEditingController
        return PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop && editController.isSafe) {
              editController.dispose();
            }
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
                  borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (editController.isSafe) {
                    editController.dispose();
                  }
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
                    return;
                  }
                  final newText = editController.safeText.trim();
                  if (newText.isNotEmpty && newText != message.message) {
                    Navigator.pop(context);
                    await _editMessage(message, newText);
                  }
                  if (editController.isSafe) {
                    editController.dispose();
                  }
                },
                child: const Text(
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
    );
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
                leading: const Icon(LucideIcons.image, color: AppTheme.goldColor),
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
                leading: const Icon(LucideIcons.file, color: AppTheme.goldColor),
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
                leading: const Icon(LucideIcons.mic, color: AppTheme.goldColor),
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
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final cardColor = context.cardColor;
              navigator.pop();
              try {
                final conversation = await _chatService.getConversationByUserId(
                  widget.otherUserId,
                );
                if (conversation != null) {
                  await _chatService.deleteConversation(conversation.id);
                }
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'خطا در حذف گفتگو: $e',
                      style: const TextStyle(fontFamily: AppTheme.fontFamily),
                    ),
                    backgroundColor: cardColor,
                  ),
                );
              } finally {
                navigator.pop();
              }
            },
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: Color.fromRGBO(212, 175, 55, 1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
