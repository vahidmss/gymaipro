// صفحه چت - نسخه بهبود یافته
import 'dart:async';

import 'package:flutter/foundation.dart';
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
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';
import 'package:gymaipro/services/app_access_control_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/widgets/feature_unavailable_view.dart';
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
  bool _privateChatEnabled = true;
  bool _isSending = false;
  bool _isAppInForeground = true;
  bool _isHandlingBackNavigation = false;
  final Set<String> _pendingMessageIds = <String>{};
  final Set<String> _failedMessageIds = <String>{};
  final Set<String> _messageIds = <String>{};
  bool _isLoadingMore = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _metricsDebounceTimer;
  Timer? _readReceiptSyncTimer;

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
  late final AppAccessControlService _accessService;

  @override
  void initState() {
    super.initState();
    _accessService = AppAccessControlService.instance;
    _accessService.configNotifier.addListener(_onAccessConfigChanged);
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
    _accessService.configNotifier.removeListener(_onAccessConfigChanged);
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _metricsDebounceTimer?.cancel();
    _readReceiptSyncTimer?.cancel();
    _messageSubscription?.cancel();

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

  bool _isCurrentChatRouteVisible() {
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  bool _shouldAutoMarkAsRead() {
    return mounted && _isAppInForeground && _isCurrentChatRouteVisible();
  }

  @override
  void didChangeMetrics() {
    // Keyboard animation triggers many metric events in a burst.
    // Debounce and avoid long scroll animations during IME transition.
    _metricsDebounceTimer?.cancel();
    _metricsDebounceTimer = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      _scrollToBottom(animate: false);
    });
    super.didChangeMetrics();
  }

  Future<void> _initializeChat() async {
    try {
      final accessConfig = await _accessService.getConfig();
      if (!accessConfig.privateChatEnabled) {
        SafeSetState.call(this, () {
          _privateChatEnabled = false;
          _isLoading = false;
        });
        return;
      }

      _chatService = ChatService();
      _currentUserId = Supabase.instance.client.auth.currentUser?.id;
      _conversationId = widget.initialConversationId;

      if (_currentUserId == null) {
        throw Exception('کاربر احراز هویت نشده');
      }

      // Load data sequentially to ensure proper error handling
      try {
        await _loadOtherUserInfo();
      } catch (_) {}

      // Fast path: show cached messages immediately (like modern messengers).
      final cached = _chatService.getCachedMessages(widget.otherUserId);
      if (cached.isNotEmpty) {
        SafeSetState.call(this, () {
          _messages = cached;
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

      _subscribeToMessages();
      _startReadReceiptSync();
      if (_shouldAutoMarkAsRead()) {
        _markConversationAsRead();
      }

      // ثبت حضور کاربر در چت
      if (_currentUserId != null && _conversationId != null) {
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

  void _onAccessConfigChanged() {
    if (!mounted) return;
    final enabled = _accessService.configNotifier.value.privateChatEnabled;
    if (_privateChatEnabled != enabled) {
      setState(() {
        _privateChatEnabled = enabled;
      });
    }
  }

  Future<void> _loadOtherUserInfo() async {
    try {
      // بارگذاری اطلاعات کاربر مقابل
      final otherUserResponse = await Supabase.instance.client
          .from('profiles')
          .select('role, last_seen_at, avatar_url')
          // در این پروژه ممکن است profiles.id با auth.users.id برابر نباشد،
          // پس هم بر اساس id و هم auth_user_id جستجو می‌کنیم.
          .or(
            'id.eq.${widget.otherUserId},auth_user_id.eq.${widget.otherUserId}',
          )
          .maybeSingle();

      if (otherUserResponse == null) return;

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
        await Supabase.instance.client
            .from('profiles')
            .update({
              'last_seen_at': DateTime.now().toIso8601String(),
              'is_online': isOnline,
            })
            .eq('id', _currentUserId!);
      }
    } catch (_) {}
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    final sw = Stopwatch()..start();
    try {
      if (showLoading) {
        SafeSetState.call(this, () {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      List<ChatMessage> messages;
      if (_conversationId != null && _conversationId!.isNotEmpty) {
        // Fast path: avoid extra lookup when conversation id is already known.
        messages = await _chatService.getMessagesByConversationId(_conversationId!);
      } else {
        await _chatService.ensureConversationExists(widget.otherUserId);
        messages = await _chatService.getMessages(widget.otherUserId);
        // Resolve and cache conversation id once.
        final conversation = await _chatService.getConversationByUserId(
          widget.otherUserId,
        );
        if (conversation != null) {
          _conversationId = conversation.id;
        }
      }

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
      _scrollToBottom();
    } catch (_) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _errorMessage = 'خطا در بارگیری پیام‌ها';
      });
    } finally {
      sw.stop();
      if (kDebugMode) {
        debugPrint('⏱️ chat_load_messages_ms=${sw.elapsedMilliseconds}');
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;
    final sw = Stopwatch()..start();

    try {
      SafeSetState.call(this, () => _isLoadingMore = true);

      final int loadedCount = _messages.length;
      List<ChatMessage> moreMessages;
      if (_conversationId != null && _conversationId!.isNotEmpty) {
        moreMessages = await _chatService.getMessagesByConversationId(
          _conversationId!,
          limit: _messagesPerPage,
          offset: loadedCount,
        );
      } else {
        moreMessages = await _chatService.getMessages(
          widget.otherUserId,
          limit: _messagesPerPage,
          offset: loadedCount,
        );
      }

      if (moreMessages.isNotEmpty) {
        SafeSetState.call(this, () {
          final unique = moreMessages.where((m) => _messageIds.add(m.id)).toList();
          _messages.insertAll(0, unique);
          _hasMoreMessages =
              moreMessages.length >= _messagesPerPage && unique.isNotEmpty;
        });
      } else {
        SafeSetState.call(this, () {
          _hasMoreMessages = false;
        });
      }
    } catch (_) {
      // ignore load-more errors; user can pull-to-refresh
    } finally {
      SafeSetState.call(this, () => _isLoadingMore = false);
      sw.stop();
      if (kDebugMode) {
        debugPrint('⏱️ chat_load_more_ms=${sw.elapsedMilliseconds}');
      }
    }
  }

  void _subscribeToMessages() {
    _messageSubscription = _chatService
        .subscribeToMessages(widget.otherUserId)
        .listen((message) {
          // فقط پیام‌های دیگران را اضافه کن، نه پیام‌های خود کاربر
          if (message.senderId != _currentUserId) {
            final inserted = _addMessageIfNotExists(message);
            // سرویس ممکن است در هر update پیام‌های قدیمی را هم emit کند.
            // فقط برای پیام‌های واقعاً جدید اسکرول/mark-as-read انجام بده.
            if (inserted) {
              _syncMessagesCache();
              _scrollToBottom();
              if (_shouldAutoMarkAsRead()) {
                _markConversationAsRead();
              }
            }
          } else {
            // برای پیام‌های خود کاربر، فقط آپدیت کن
            SafeSetState.call(this, () {
              final index = _messages.indexWhere((m) => m.id == message.id);
              if (index != -1) {
                _messages[index] = message;
              }
            });
            _syncMessagesCache();
          }
        }, onError: (_) {});
  }

  Future<void> _markConversationAsRead() async {
    try {
      // Critical guard: never mark as read unless this exact chat screen
      // is visible in foreground.
      if (!_shouldAutoMarkAsRead()) return;

      // Optimistic badge clear for instant UX.
      if (mounted) {
        try {
          final notifier = Provider.of<ChatUnreadNotifier>(context, listen: false);
          await notifier.ensureInitialized(SupabaseService());
          notifier.clearUnreadCount();
        } catch (_) {}
      }

      // Prefer cached conversation id to avoid an extra network lookup.
      String? conversationId = _conversationId;
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
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  void _startReadReceiptSync() {
    _readReceiptSyncTimer?.cancel();
    _readReceiptSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || !_isAppInForeground || !_isCurrentChatRouteVisible()) {
        return;
      }
      unawaited(_syncReadReceiptsFallback());
    });
  }

  Future<void> _syncReadReceiptsFallback() async {
    try {
      final conversationId = _conversationId;
      final currentUserId = _currentUserId;
      if (conversationId == null ||
          conversationId.isEmpty ||
          currentUserId == null ||
          _messages.isEmpty) {
        return;
      }

      // Lightweight fallback for missed realtime receipt updates.
      final latestMessages = await _chatService.getMessagesByConversationId(
        conversationId,
        limit: 80,
      );
      if (latestMessages.isEmpty || !mounted) return;

      final latestById = <String, ChatMessage>{
        for (final m in latestMessages) m.id: m,
      };
      var changed = false;
      final updated = <ChatMessage>[];
      for (final msg in _messages) {
        final latest = latestById[msg.id];
        if (latest != null &&
            msg.senderId == currentUserId &&
            msg.isRead != latest.isRead) {
          updated.add(msg.copyWith(isRead: latest.isRead, updatedAt: latest.updatedAt));
          changed = true;
        } else {
          updated.add(msg);
        }
      }

      if (!changed) return;
      SafeSetState.call(this, () {
        _messages = updated;
      });
      _syncMessagesCache();
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    if (!mounted || !_messageController.isSafe) return;
    final message = _messageController.safeText.trim();
    if (message.isEmpty || _isSending) return;

    // Create optimistic message
    final tempMessageId =
        'local_${DateTime.now().microsecondsSinceEpoch}_${_messages.length}';
    final tempMessage = ChatMessage(
      id: tempMessageId,
      senderId: _currentUserId!,
      receiverId: widget.otherUserId,
      message: message,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    SafeSetState.call(this, () {
      _isSending = true;
      _pendingMessageIds.add(tempMessageId);
      _failedMessageIds.remove(tempMessageId);
      _messages.add(tempMessage);
        _messageIds.add(tempMessageId);
    });
    _syncMessagesCache();

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
        _pendingMessageIds.remove(tempMessageId);
        _failedMessageIds.remove(tempMessageId);
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messageIds.remove(tempMessageId);
          _messages[index] = sentMessage;
          _messageIds.add(sentMessage.id);
        } else {
          // اگر پیام موقت پیدا نشد، پیام واقعی را اضافه کن
          if (_messageIds.add(sentMessage.id)) {
            _messages.add(sentMessage);
          }
        }
        // مرتب‌سازی بر اساس زمان ایجاد (قدیمی‌ترین اول)
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
      _syncMessagesCache();
    } catch (e) {
      // Keep failed message in list and allow inline retry like modern messengers.
      SafeSetState.call(this, () {
        _pendingMessageIds.remove(tempMessageId);
        _failedMessageIds.add(tempMessageId);
      });
      _syncMessagesCache();

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
              textColor: AppTheme.darkTextColor,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _retryFailedMessage(tempMessageId);
              },
            ),
          ),
        );
      }
    } finally {
      SafeSetState.call(this, () => _isSending = false);
    }
  }

  Future<void> _retryFailedMessage(String messageId) async {
    if (_isSending) return;
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final failedMessage = _messages[index];
    if (failedMessage.message.trim().isEmpty) return;

    SafeSetState.call(this, () {
      _isSending = true;
      _failedMessageIds.remove(messageId);
      _pendingMessageIds.add(messageId);
    });

    try {
      final sentMessage = await _chatService.sendMessage(
        receiverId: widget.otherUserId,
        message: failedMessage.message,
      );

      SafeSetState.call(this, () {
        _pendingMessageIds.remove(messageId);
        _failedMessageIds.remove(messageId);
        final currentIndex = _messages.indexWhere((m) => m.id == messageId);
        if (currentIndex != -1) {
          _messageIds.remove(messageId);
          _messages[currentIndex] = sentMessage;
          _messageIds.add(sentMessage.id);
        } else {
          if (_messageIds.add(sentMessage.id)) {
            _messages.add(sentMessage);
          }
        }
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
      _syncMessagesCache();
    } catch (_) {
      SafeSetState.call(this, () {
        _pendingMessageIds.remove(messageId);
        _failedMessageIds.add(messageId);
      });
      _syncMessagesCache();
    } finally {
      SafeSetState.call(this, () => _isSending = false);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // With reverse: true, انتهای لیست در minScrollExtent است
        final target = _scrollController.position.minScrollExtent;
        final distance = (_scrollController.offset - target).abs();
        if (distance < 2) return;
        if (animate) {
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(target);
        }
      }
    });
  }

  // اضافه کردن پیام بدون تکرار و حفظ ترتیب زمانی
  bool _addMessageIfNotExists(ChatMessage message) {
    if (_messageIds.add(message.id)) {
      SafeSetState.call(this, () {
        _messages.add(message);
        // مرتب‌سازی بر اساس زمان ایجاد (قدیمی‌ترین اول)
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
      _syncMessagesCache();
      return true;
    }
    return false;
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
        _messageIds.remove(message.id);
      });
      _syncMessagesCache();
    } catch (e) {
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
      _syncMessagesCache();
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در ویرایش پیام: $e',
      );
    }
  }

  void _flushReadStateInBackground() {
    unawaited(_markConversationAsRead());
  }

  void _handleBackNavigation() {
    if (!mounted) return;
    if (_isHandlingBackNavigation) return;
    _isHandlingBackNavigation = true;
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      _syncMessagesCache();
      // Telegram/WhatsApp-style UX: navigate immediately, sync read-state async.
      _flushReadStateInBackground();

      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
        return;
      }

      // Defensive fallback: return to chat tab without pushing a new route stack.
      popRootNavigatorOverlays();
      MainNavigationScreen.navigateToTab(NavigationConstants.chatIndex);
    } catch (_) {
      _isHandlingBackNavigation = false;
    }
  }

  void _syncMessagesCache() {
    if (!mounted) return;
    final otherUserId = widget.otherUserId;
    final messages = List<ChatMessage>.from(_messages);
    scheduleMicrotask(() {
      _chatService.saveCachedMessages(otherUserId, messages);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_privateChatEnabled) {
      return const Scaffold(
        body: FeatureUnavailableView(
          title: 'چت خصوصی بسته است',
          description: 'این بخش توسط مدیر سیستم موقتاً غیرفعال شده است.',
        ),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          appBar: ChatAppBarWidget(
            otherUserName: widget.otherUserName,
            otherUserId: widget.otherUserId,
            otherUserRole: _otherUserRole,
            otherUserAvatar: _otherUserAvatar,
            isOtherUserOnline: _isOtherUserOnline,
            otherUserLastSeen: _otherUserLastSeen,
            onBackPressed: _handleBackNavigation,
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
              Container(
                height: 1.h,
                margin: EdgeInsets.symmetric(horizontal: 14.w),
                color: context.separatorColor.withValues(alpha: 0.22),
              ),
              SafeArea(
                top: false,
                child: MessageInputWidget(
                  controller: _messageController,
                  onSendPressed: _sendMessage,
                  onAttachmentPressed: _showAttachmentOptions,
                  isSending: _isSending,
                  useSafeArea: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.goldColor),
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
                fontSize: 14.sp,
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
        padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 12.h),
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
            isSending: _pendingMessageIds.contains(message.id),
            isFailed: _failedMessageIds.contains(message.id),
            onRetryTap: _failedMessageIds.contains(message.id)
                ? () => _retryFailedMessage(message.id)
                : null,
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
          onPopInvokedWithResult: (didPop, _) {
            if (editController.isSafe) {
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
                        style: const TextStyle(fontFamily: AppTheme.fontFamily),
                      ),
                      backgroundColor: context.cardColor,
                    ),
                  );
                }
              } finally {
                if (mounted) Navigator.of(context).pop();
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
