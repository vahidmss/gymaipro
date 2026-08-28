// صفحه چت - نسخه بهبود یافته
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/models/message_send_status.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/chat/services/chat_cache_service.dart';
import 'package:gymaipro/chat/services/chat_media_upload_service.dart';
import 'package:gymaipro/chat/services/chat_presence_service.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/chat/services/chat_unread_sync_bus.dart';
import 'package:gymaipro/chat/widgets/chat_app_bar_widget.dart';
import 'package:gymaipro/chat/widgets/chat_hub_ui.dart';
import 'package:gymaipro/chat/widgets/chat_message_bubble.dart';
import 'package:gymaipro/chat/widgets/chat_scroll_to_bottom_button.dart';
import 'package:gymaipro/chat/widgets/error_boundary_widget.dart';
import 'package:gymaipro/chat/widgets/message_input_widget.dart';
import 'package:gymaipro/core/user_presence.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/services/app_feedback_service.dart';
import 'package:gymaipro/services/presence_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
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
  /// Live inserts get a one-shot entrance animation (not historical load).
  final Set<String> _entranceMessageIds = {};
  final Map<String, MessageSendStatus> _messageStatuses = {};
  final Map<String, _PendingChatMedia> _pendingMediaByTempId = {};
  bool _showJumpToBottom = false;
  bool _hasUnseenIncomingWhileScrolled = false;
  Timer? _metricsDebounceTimer;
  final ChatCacheService _chatCache = ChatCacheService();
  final ChatMediaUploadService _mediaUpload = ChatMediaUploadService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScrollPositionChanged);
    // برای جلوگیری از قفل شدن انیمیشن‌های ورودی/کیبورد،
    // مقداردهی اولیه‌ی سنگین را به بعد از اولین فریم موکول می‌کنیم.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(AppFeedbackService.instance.ensureInitialized());
        _initializeChat();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScrollPositionChanged);
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
        _otherUserLastSeen = UserPresence.effectiveLastSeen(
          lastSeenRaw: otherUserResponse['last_seen_at'],
          lastActiveRaw: otherUserResponse['last_active_at'],
        );
        _updateOnlineStatus();
      });
    } catch (_) {}
  }

  void _updateOnlineStatus() {
    final globallyOnline = UserPresence.isOnline(
      lastSeenAt: _otherUserLastSeen,
    );
    _isOtherUserOnline = globallyOnline || _peerIsActiveInChat;
  }

  Future<void> _refreshPeerPresence() async {
    final convId = _conversationId;
    if (convId == null || convId.isEmpty) return;
    final active = await _presenceService.getActiveUsersInConversation(convId);
    if (!mounted) return;
    SafeSetState.call(this, () {
      _peerIsActiveInChat = active.contains(widget.otherUserId);
      _updateOnlineStatus();
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
            SafeSetState.call(this, () {
              _peerIsActiveInChat = isActive;
              if (isActive) {
                _otherUserLastSeen = DateTime.now();
              }
              _updateOnlineStatus();
            });
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
      if (_currentUserId == null) return;
      if (isOnline) {
        await PresenceService.instance.bumpForeground(source: 'chat');
      } else {
        await PresenceService.instance.markBackground(source: 'chat');
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
              _entranceMessageIds.add(message.id);
              unawaited(AppFeedbackService.instance.messageReceived());
              _syncMessagesCache();
              _handleIncomingWhileViewing();
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
          _handleIncomingWhileViewing();
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

  Future<void> _sendMessage({String? overrideText, String? retryTempId}) async {
    if (!mounted || !_messageController.isSafe) return;
    final senderId = _currentUserId;
    if (senderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای ارسال پیام دوباره وارد شوید')),
      );
      return;
    }
    final message = (overrideText ?? _messageController.safeText).trim();
    if (message.isEmpty || (_isSending && retryTempId == null)) return;

    final tempId =
        retryTempId ?? DateTime.now().millisecondsSinceEpoch.toString();

    if (retryTempId == null) {
      final tempMessage = ChatMessage(
        id: tempId,
        senderId: senderId,
        receiverId: widget.otherUserId,
        message: message,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      SafeSetState.call(this, () {
        _isSending = true;
        _messageIds.add(tempId);
        _entranceMessageIds.add(tempId);
        _messageStatuses[tempId] = MessageSendStatus.sending;
        _messages.add(tempMessage);
      });
      unawaited(AppFeedbackService.instance.messageSent());

      if (_messageController.isSafe) {
        _messageController.safeClear();
      }
      _scrollToBottom();
    } else {
      SafeSetState.call(this, () {
        _isSending = true;
        _messageStatuses[tempId] = MessageSendStatus.sending;
      });
      unawaited(AppFeedbackService.instance.lightImpact());
    }

    try {
      final sentMessage = await _chatService.sendMessage(
        receiverId: widget.otherUserId,
        message: message,
      );

      final displayMessage = _peerIsActiveInChat
          ? sentMessage.copyWith(isRead: true)
          : sentMessage;

      SafeSetState.call(this, () {
        _messageIds.remove(tempId);
        _messageStatuses.remove(tempId);
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = displayMessage;
        } else if (!_messageIds.contains(sentMessage.id)) {
          _messages.add(displayMessage);
        }
        _messageIds.add(sentMessage.id);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
      _syncMessagesCache();
    } catch (e) {
      SafeSetState.call(this, () {
        _messageStatuses[tempId] = MessageSendStatus.failed;
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
                unawaited(
                  _sendMessage(overrideText: message, retryTempId: tempId),
                );
              },
            ),
          ),
        );
      }
    } finally {
      SafeSetState.call(this, () => _isSending = false);
    }
  }

  void _retryFailedMessage(ChatMessage message) {
    final pending = _pendingMediaByTempId[message.id];
    if (pending != null) {
      unawaited(
        _sendMediaMessage(
          file: pending.file,
          messageType: pending.messageType,
          attachmentName: pending.attachmentName,
          attachmentType: pending.attachmentType,
          durationSeconds: pending.durationSeconds,
          retryTempId: message.id,
        ),
      );
      return;
    }
    unawaited(
      _sendMessage(overrideText: message.message, retryTempId: message.id),
    );
  }

  Future<void> _sendMediaMessage({
    required File file,
    required String messageType,
    String? attachmentName,
    String? attachmentType,
    int? durationSeconds,
    String? retryTempId,
  }) async {
    if (!mounted || _currentUserId == null) return;
    if (_isSending && retryTempId == null) return;

    final tempId =
        retryTempId ?? 'media_${DateTime.now().millisecondsSinceEpoch}';
    final size = await file.length();

    if (retryTempId == null) {
      final tempMessage = ChatMessage(
        id: tempId,
        senderId: _currentUserId!,
        receiverId: widget.otherUserId,
        message: '',
        messageType: messageType,
        attachmentUrl: null,
        attachmentName: attachmentName ?? file.path.split(RegExp(r'[\\/]')).last,
        attachmentType: attachmentType,
        attachmentSize: size,
        durationSeconds: durationSeconds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      SafeSetState.call(this, () {
        _isSending = true;
        _messageIds.add(tempId);
        _entranceMessageIds.add(tempId);
        _messageStatuses[tempId] = MessageSendStatus.sending;
        _messages.add(tempMessage);
        _pendingMediaByTempId[tempId] = _PendingChatMedia(
          file: file,
          messageType: messageType,
          attachmentName: attachmentName,
          attachmentType: attachmentType,
          durationSeconds: durationSeconds,
        );
      });
      unawaited(AppFeedbackService.instance.messageSent());
      _scrollToBottom();
    } else {
      SafeSetState.call(this, () {
        _isSending = true;
        _messageStatuses[tempId] = MessageSendStatus.sending;
      });
    }

    try {
      // Ensure conversation exists so private storage path can use conversation_id.
      if (_conversationId == null || _conversationId!.isEmpty) {
        final conversation = await _chatService.getConversationByUserId(
          widget.otherUserId,
        );
        if (conversation != null) {
          _conversationId = conversation.id;
        }
      }

      late final String url;
      if (messageType == 'voice') {
        url = await _mediaUpload.uploadVoiceFile(
          file,
          conversationId: _conversationId,
        );
      } else if (messageType == 'image') {
        url = await _mediaUpload.uploadImage(
          XFile(file.path),
          conversationId: _conversationId,
        );
      } else {
        url = await _mediaUpload.uploadFile(
          file,
          conversationId: _conversationId,
        );
      }

      final sent = await _chatService.sendMessage(
        receiverId: widget.otherUserId,
        message: '',
        messageType: messageType,
        attachmentUrl: url,
        attachmentType: attachmentType,
        attachmentName: attachmentName ??
            file.path.split(RegExp(r'[\\/]')).last,
        attachmentSize: size,
        durationSeconds: durationSeconds,
      );

      if (_conversationId == null || _conversationId!.isEmpty) {
        final conversation = await _chatService.getConversationByUserId(
          widget.otherUserId,
        );
        _conversationId = conversation?.id;
      }

      final display = _peerIsActiveInChat
          ? sent.copyWith(isRead: true)
          : sent;

      SafeSetState.call(this, () {
        _messageIds.remove(tempId);
        _messageStatuses.remove(tempId);
        _pendingMediaByTempId.remove(tempId);
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = display;
        } else if (!_messageIds.contains(sent.id)) {
          _messages.add(display);
        }
        _messageIds.add(sent.id);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
      _syncMessagesCache();
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    } catch (e) {
      SafeSetState.call(this, () {
        _messageStatuses[tempId] = MessageSendStatus.failed;
      });
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      SafeSetState.call(this, () => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage({ImageSource source = ImageSource.gallery}) async {
    try {
      if (kIsWeb) {
        await _pickAndSendImageOnWeb();
        return;
      }

      // Samsung PhotoPicker often crashes; prefer stable document picker for gallery.
      if (source == ImageSource.gallery && !kIsWeb && Platform.isAndroid) {
        final ok = await _pickAndSendImageViaFilePicker();
        if (ok) return;
      }

      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        requestFullMetadata: false,
      );
      if (picked == null) return;
      if (!mounted) return;
      await _sendMediaMessage(
        file: File(picked.path),
        messageType: 'image',
        attachmentName: picked.name,
        attachmentType: picked.mimeType ?? 'image/jpeg',
      );
    } catch (e) {
      debugPrint('pick image failed: $e');
      if (source == ImageSource.gallery && mounted && !kIsWeb) {
        final ok = await _pickAndSendImageViaFilePicker();
        if (ok) return;
      }
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(context, 'خطا در انتخاب تصویر');
      }
    }
  }

  /// Safari/web: use bytes — filesystem paths from pickers are unreliable.
  Future<void> _pickAndSendImageOnWeb() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      requestFullMetadata: false,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    await _sendMediaBytes(
      bytes: bytes,
      messageType: 'image',
      attachmentName: picked.name.isNotEmpty ? picked.name : 'image.jpg',
      attachmentType: picked.mimeType ?? 'image/jpeg',
    );
  }

  Future<void> _sendMediaBytes({
    required List<int> bytes,
    required String messageType,
    String? attachmentName,
    String? attachmentType,
  }) async {
    if (!mounted || _currentUserId == null) return;
    if (_isSending) return;

    final tempId = 'media_${DateTime.now().millisecondsSinceEpoch}';
    final name = attachmentName ?? 'file.bin';
    final tempMessage = ChatMessage(
      id: tempId,
      senderId: _currentUserId!,
      receiverId: widget.otherUserId,
      message: '',
      messageType: messageType,
      attachmentUrl: null,
      attachmentName: name,
      attachmentType: attachmentType,
      attachmentSize: bytes.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    SafeSetState.call(this, () {
      _isSending = true;
      _messageIds.add(tempId);
      _entranceMessageIds.add(tempId);
      _messageStatuses[tempId] = MessageSendStatus.sending;
      _messages.add(tempMessage);
    });
    unawaited(AppFeedbackService.instance.messageSent());
    _scrollToBottom();

    try {
      if (_conversationId == null || _conversationId!.isEmpty) {
        final conversation = await _chatService.getConversationByUserId(
          widget.otherUserId,
        );
        if (conversation != null) {
          _conversationId = conversation.id;
        }
      }

      final url = await _mediaUpload.uploadBytes(
        bytes: bytes,
        mediaKind: messageType == 'image' ? 'image' : 'file',
        filename: name,
        conversationId: _conversationId,
      );

      final sent = await _chatService.sendMessage(
        receiverId: widget.otherUserId,
        message: '',
        messageType: messageType,
        attachmentUrl: url,
        attachmentType: attachmentType,
        attachmentName: name,
        attachmentSize: bytes.length,
      );

      if (_conversationId == null || _conversationId!.isEmpty) {
        final conversation = await _chatService.getConversationByUserId(
          widget.otherUserId,
        );
        _conversationId = conversation?.id;
      }

      final display = _peerIsActiveInChat ? sent.copyWith(isRead: true) : sent;

      SafeSetState.call(this, () {
        _messageIds.remove(tempId);
        _messageStatuses.remove(tempId);
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = display;
        } else if (!_messageIds.contains(sent.id)) {
          _messages.add(display);
        }
        _messageIds.add(sent.id);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
      _syncMessagesCache();
    } catch (e) {
      SafeSetState.call(this, () {
        _messageStatuses[tempId] = MessageSendStatus.failed;
      });
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      SafeSetState.call(this, () => _isSending = false);
    }
  }

  /// Gallery via FilePicker document UI — avoids Samsung PhotoPicker crash.
  Future<bool> _pickAndSendImageViaFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'heic',
          'heif',
          'bmp',
        ],
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return true; // cancelled
      final picked = result.files.single;
      final path = picked.path;
      if (path == null || path.isEmpty) {
        if (mounted) {
          WidgetSafetyUtils.safeShowSnackBar(context, 'مسیر فایل نامعتبر است');
        }
        return true;
      }
      if (!mounted) return true;
      final ext = (picked.extension ?? 'jpeg').toLowerCase();
      await _sendMediaMessage(
        file: File(path),
        messageType: 'image',
        attachmentName: picked.name,
        attachmentType: 'image/$ext',
      );
      return true;
    } catch (e) {
      debugPrint('gallery file_picker failed: $e');
      return false;
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final picked = result.files.single;
        final bytes = picked.bytes;
        if (bytes == null || bytes.isEmpty) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'روی وب‌اپ این فایل قابل خواندن نبود. فرمت دیگری امتحان کنید.',
          );
          return;
        }
        final name = picked.name;
        final ext = (picked.extension ?? '').toLowerCase();
        final isImage = _isImageExtension(ext) ||
            (picked.extension == null && _isImageFileName(name));
        if (!mounted) return;
        await _sendMediaBytes(
          bytes: bytes,
          messageType: isImage ? 'image' : 'file',
          attachmentName: name,
          attachmentType: isImage
              ? 'image/${ext.isEmpty ? 'jpeg' : ext}'
              : (picked.extension ?? 'application/octet-stream'),
        );
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final path = picked.path;
      if (path == null || path.isEmpty) {
        WidgetSafetyUtils.safeShowSnackBar(context, 'مسیر فایل نامعتبر است');
        return;
      }
      final name = picked.name;
      final ext = (picked.extension ?? '').toLowerCase();
      final isImage = _isImageExtension(ext) ||
          (picked.extension == null && _isImageFileName(name));
      if (!mounted) return;
      await _sendMediaMessage(
        file: File(path),
        messageType: isImage ? 'image' : 'file',
        attachmentName: name,
        attachmentType: isImage
            ? 'image/${ext.isEmpty ? 'jpeg' : ext}'
            : (picked.extension ?? 'application/octet-stream'),
      );
    } catch (_) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(context, 'خطا در انتخاب فایل');
      }
    }
  }

  bool _isImageExtension(String ext) {
    const images = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
      'heif',
      'bmp',
    };
    return images.contains(ext);
  }

  bool _isImageFileName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot >= name.length - 1) return false;
    return _isImageExtension(name.substring(dot + 1).toLowerCase());
  }

  void _onScrollPositionChanged() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final away = pos.pixels - pos.minScrollExtent;
    final show = away > 140;
    if (show != _showJumpToBottom) {
      SafeSetState.call(this, () => _showJumpToBottom = show);
    }
    if (!show && _hasUnseenIncomingWhileScrolled) {
      SafeSetState.call(this, () => _hasUnseenIncomingWhileScrolled = false);
    }
  }

  bool _isNearBottom({double threshold = 140}) {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return (pos.pixels - pos.minScrollExtent) <= threshold;
  }

  void _handleIncomingWhileViewing() {
    if (_isNearBottom()) {
      _scrollToBottom();
      return;
    }
    SafeSetState.call(this, () {
      _showJumpToBottom = true;
      _hasUnseenIncomingWhileScrolled = true;
    });
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
      if (_showJumpToBottom || _hasUnseenIncomingWhileScrolled) {
        SafeSetState.call(this, () {
          _showJumpToBottom = false;
          _hasUnseenIncomingWhileScrolled = false;
        });
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
              child: Stack(
                children: [
                  ErrorBoundaryWidget(
                    child: _buildMessagesList(),
                    onRetry: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _initializeChat();
                    },
                  ),
                  if (_showJumpToBottom)
                    Positioned(
                      left: 16.w,
                      bottom: 12.h,
                      child: ChatScrollToBottomButton(
                        unreadHint: _hasUnseenIncomingWhileScrolled,
                        onPressed: () {
                          unawaited(AppFeedbackService.instance.selection());
                          _scrollToBottom();
                          if (_shouldAutoMarkAsRead()) {
                            _scheduleMarkAsRead();
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            MessageInputWidget(
              controller: _messageController,
              onSendPressed: () {
                unawaited(_sendMessage());
              },
              onAttachmentPressed: _showAttachmentOptions,
              onVoiceRecorded: kIsWeb
                  ? null
                  : (file, duration) => _sendMediaMessage(
                        file: file,
                        messageType: 'voice',
                        durationSeconds: duration,
                        attachmentName: 'voice.m4a',
                        attachmentType: 'audio/mp4',
                      ),
              isSending: _isSending,
              voiceEnabled: !kIsWeb,
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
          final animateEntrance = _entranceMessageIds.remove(message.id);
          final sendStatus = isMe ? _messageStatuses[message.id] : null;

          final bubble = ChatMessageBubble(
            key: ValueKey<String>('bubble_${message.id}'),
            message: message,
            isMe: isMe,
            isGrouped: _isGroupedWithNext(messageIndex),
            sendStatus: sendStatus,
            onLongPress: () => _showMessageOptions(message),
            onRetryFailed: sendStatus == MessageSendStatus.failed
                ? () => _retryFailedMessage(message)
                : null,
          );

          final animatedBubble = animateEntrance
              ? bubble
                  .animate()
                  .fadeIn(duration: 180.ms, curve: Curves.easeOut)
                  .slideY(
                    begin: isMe ? 0.12 : 0.08,
                    end: 0,
                    duration: 220.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1),
                    duration: 220.ms,
                    curve: Curves.easeOutCubic,
                  )
              : bubble;

          return Column(
            key: ValueKey<String>(message.id),
            children: [
              if (_showDateHeader(messageIndex))
                _buildDateChip(message.createdAt),
              animatedBubble,
            ],
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isGroupedWithNext(int messageIndex) {
    if (messageIndex >= _messages.length - 1) return false;
    final curr = _messages[messageIndex];
    final next = _messages[messageIndex + 1];
    if (curr.senderId != next.senderId) return false;
    if (!_isSameDay(curr.createdAt, next.createdAt)) return false;
    return next.createdAt.difference(curr.createdAt).inMinutes < 3;
  }

  bool _showDateHeader(int messageIndex) {
    if (messageIndex <= 0) return true;
    return !_isSameDay(
      _messages[messageIndex].createdAt,
      _messages[messageIndex - 1].createdAt,
    );
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
    final isMine = message.senderId == _currentUserId;

    unawaited(
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
            if (isMine)
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
                  unawaited(Clipboard.setData(ClipboardData(text: message.message)));
                  unawaited(AppFeedbackService.instance.selection());
                  if (mounted) {
                    WidgetSafetyUtils.safeShowSnackBar(
                      context,
                      'پیام کپی شد',
                    );
                  }
                },
              ),
            ),
            if (isMine)
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
                    unawaited(_deleteMessage(message));
                  },
                ),
              ),
          ],
        ),
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
    unawaited(AppFeedbackService.instance.selection());
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
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
                SizedBox(height: 14.h),
                Text(
                  'ارسال رسانه',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!kIsWeb)
                      _attachChip(
                        icon: LucideIcons.camera,
                        label: 'دوربین',
                        onTap: () {
                          Navigator.pop(context);
                          unawaited(
                            _pickAndSendImage(source: ImageSource.camera),
                          );
                        },
                      ),
                    _attachChip(
                      icon: LucideIcons.image,
                      label: 'گالری',
                      onTap: () {
                        Navigator.pop(context);
                        unawaited(_pickAndSendImage());
                      },
                    ),
                    _attachChip(
                      icon: LucideIcons.file,
                      label: 'فایل',
                      onTap: () {
                        Navigator.pop(context);
                        unawaited(_pickAndSendFile());
                      },
                    ),
                    if (!kIsWeb)
                      _attachChip(
                        icon: LucideIcons.mic,
                        label: 'ویس',
                        onTap: () {
                          Navigator.pop(context);
                          WidgetSafetyUtils.safeShowSnackBar(
                            context,
                            'دکمه میکروفون را نگه دارید',
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _attachChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Column(
          children: [
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: context.goldGradientColors),
              ),
              child: Icon(icon, color: AppTheme.onGoldColor, size: 22.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
                fontSize: 12.sp,
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

class _PendingChatMedia {
  const _PendingChatMedia({
    required this.file,
    required this.messageType,
    this.attachmentName,
    this.attachmentType,
    this.durationSeconds,
  });

  final File file;
  final String messageType;
  final String? attachmentName;
  final String? attachmentType;
  final int? durationSeconds;
}
