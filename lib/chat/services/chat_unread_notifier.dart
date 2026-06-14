import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/chat/services/chat_cache_service.dart';
import 'package:gymaipro/chat/services/chat_presence_service.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/chat/services/chat_unread_sync_bus.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatUnreadNotifier extends ChangeNotifier {
  int _unreadCount = 0;
  ChatService? _chatService;
  SupabaseService? _supabaseService;
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime? _lastLoadTime;
  Timer? _refreshTimer;
  StreamSubscription<void>? _syncSubscription;
  StreamSubscription<ChatConversation>? _conversationSubscription;
  bool _disposed = false;
  bool _pendingRefresh = false;
  String? _lastInAppNotifiedMessageKey;
  DateTime? _lastGenericInAppNotifyAt;
  DateTime? _lastRealtimeInAppNotifyAt;
  final ChatCacheService _chatCache = ChatCacheService();

  int get unreadCount => _unreadCount;
  bool get isInitialized => _chatService != null && _supabaseService != null;

  void initialize(SupabaseService supabaseService) {
    if (_isInitialized) return;
    _supabaseService = supabaseService;
    _chatService = ChatService();
    _isInitialized = true;
    
    // ????? ???? ???? ??????? ?? ????? ???? Supabase
    // ??? ??? ?????? ?? ?? ?????? Connection closed ??????? ???
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_disposed && _isInitialized) {
        _loadUnreadCount();
      }
    });

    // ???? ????? ???? ??????????? ?????? (??????????)
    _startRefreshTimer();

    // Fast path: external sync events (resume/connectivity fallback) should refresh immediately.
    _syncSubscription?.cancel();
    _syncSubscription = ChatUnreadSyncBus.instance.stream.listen((_) {
      if (_disposed || !_isInitialized || _isLoading) return;
      _loadUnreadCount(force: true);
    });

    _conversationSubscription?.cancel();
    _conversationSubscription = _chatService!.subscribeToConversations().listen((
      conversation,
    ) {
      if (_disposed || !_isInitialized) return;
      unawaited(_handleConversationRealtimeUpdate(conversation));
    });
  }

  Future<void> _loadUnreadCount({bool force = false}) async {
    try {
      // ??? notifier dispose ???? ?? ????? ??? ??????? ??
      if (_disposed) return;
      
      // ??????? ?? ????? ??????
      if (_isLoading) {
        _pendingRefresh = true;
        return;
      }

      // ??????? ?? ???????? ???? ?? ??? ???? ?????
      final now = DateTime.now();
      if (!force &&
          _lastLoadTime != null &&
          now.difference(_lastLoadTime!).inSeconds < 5) {
        return;
      }

      // ??? ?????? ?????? ?? ???????? ???? ??????? ????
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        _unreadCount = await _chatCache.loadUnreadCount();
        if (_unreadCount == 0) {
          final cachedConversations = await _chatCache.loadConversationsDisk();
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            _unreadCount = cachedConversations
                .where((c) => c.hasUnreadForUser(user.id))
                .length;
          }
        }
        _safeNotifyListeners();
        return;
      }

      _isLoading = true;
      _lastLoadTime = now;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || _chatService == null) {
        _unreadCount = 0;
        _isLoading = false;
        _safeNotifyListeners();
        return;
      }

      final conversations = await _chatService!
          .getConversations()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <ChatConversation>[],
          );

      final previousUnreadCount = _unreadCount;
      _unreadCount = conversations
          .where((conv) => conv.hasUnreadForUser(user.id))
          .length;
      unawaited(_chatCache.persistUnreadCount(_unreadCount));
      await _notifyUnreadIncreaseFallback(
        previousUnreadCount: previousUnreadCount,
        currentUnreadCount: _unreadCount,
        conversations: conversations,
        currentUserId: user.id,
      );

      _isLoading = false;
      _safeNotifyListeners();
      if (_pendingRefresh && !_disposed) {
        _pendingRefresh = false;
        unawaited(_loadUnreadCount(force: true));
      }
    } catch (_) {
      _unreadCount = await _chatCache.loadUnreadCount();
      _isLoading = false;
      _safeNotifyListeners();
      if (_pendingRefresh && !_disposed) {
        _pendingRefresh = false;
        unawaited(_loadUnreadCount(force: true));
      }
    }
  }

  // ??? ???? ??????????? ????? ???????? ???????
  Future<void> refreshUnreadCount() async {
    if (!isInitialized) return;
    await _loadUnreadCount();
  }

  // ??? ???? lazy initialization
  Future<void> ensureInitialized(SupabaseService supabaseService) async {
    if (!isInitialized) {
      initialize(supabaseService);
    }
  }

  // ??? ???? ???? ????? (???? ??????? ?????? ???????)
  void markAsRead() {
    if (_unreadCount > 0) {
      _unreadCount--;
      _safeNotifyListeners();
    }
  }

  void clearUnreadCount() {
    if (_unreadCount != 0) {
      _unreadCount = 0;
      _safeNotifyListeners();
    }
  }

  // ??? ???? ?????? ????? (???? ???? ???? ?????? ??????)
  void incrementUnreadCount() {
    _unreadCount++;
    _safeNotifyListeners();
  }

  // ??? ??? ???? notify ???? listeners
  void _safeNotifyListeners() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (_) {}
  }

  // ???? ????? ???? ??????????? ??????
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    // 60s is noticeably lighter on CPU/network while still feeling "live" for unread badges.
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (!_isInitialized || _isLoading) return;
      // ??? ????? ????? ????? ??? ????? ?? poll ????.
      if (Supabase.instance.client.auth.currentUser == null) return;
      _loadUnreadCount();
    });
  }

  // ????? ???? ?????
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _handleConversationRealtimeUpdate(ChatConversation conversation) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Keep unread badge fresh, but do not block notification UX on network call.
    unawaited(_loadUnreadCount(force: true));

    // Only notify for incoming unread messages.
    if (!conversation.hasUnreadForUser(user.id)) {
      if (kDebugMode) {
        debugPrint('ChatRealtimeNotify: skip, no unread for current user');
      }
      return;
    }
    if (conversation.lastMessageSenderId == null ||
        conversation.lastMessageSenderId == user.id) {
      if (kDebugMode) {
        debugPrint('ChatRealtimeNotify: skip, message from self or sender missing');
      }
      return;
    }

    // Avoid duplicates caused by multiple update events for same message.
    final messageKey =
        '${conversation.id}:${conversation.lastMessageAt?.toIso8601String() ?? ''}:${conversation.lastMessageSenderId ?? ''}';
    if (_lastInAppNotifiedMessageKey == messageKey) {
      if (kDebugMode) {
        debugPrint('ChatRealtimeNotify: skip duplicate message key');
      }
      return;
    }

    // If user is already active in this exact conversation, skip in-app notify.
    final activeConversation = await ChatPresenceService().getUserActiveConversation(
      user.id,
    );
    if (activeConversation == conversation.id) {
      if (kDebugMode) {
        debugPrint('ChatRealtimeNotify: skip, user already inside conversation');
      }
      return;
    }

    _lastInAppNotifiedMessageKey = messageKey;
    final peerId = conversation.getOtherUserId(user.id);
    await NotificationService().showInAppChatAlert(
      senderName: conversation.getOtherUserName(user.id),
      message: conversation.lastMessage ?? '',
      conversationId: conversation.id,
      peerId: peerId,
    );
    _lastRealtimeInAppNotifyAt = DateTime.now();
    if (kDebugMode) {
      debugPrint('ChatRealtimeNotify: in-app notification displayed');
    }
  }

  Future<void> _notifyUnreadIncreaseFallback({
    required int previousUnreadCount,
    required int currentUnreadCount,
    required List<ChatConversation> conversations,
    required String currentUserId,
  }) async {
    if (currentUnreadCount <= previousUnreadCount) return;

    // If a realtime chat notification was recently shown, suppress generic fallback
    // to avoid duplicate alerts for the same incoming message.
    if (_lastRealtimeInAppNotifyAt != null &&
        DateTime.now().difference(_lastRealtimeInAppNotifyAt!) <
            const Duration(seconds: 20)) {
      if (kDebugMode) {
        debugPrint('ChatRealtimeNotify: skip generic fallback due to recent realtime alert');
      }
      return;
    }

    final now = DateTime.now();
    if (_lastGenericInAppNotifyAt != null &&
        now.difference(_lastGenericInAppNotifyAt!) <
            const Duration(seconds: 8)) {
      return;
    }

    _lastGenericInAppNotifyAt = now;

    // Prefer showing the actual sender from the newest unread conversation.
    final unreadConversations = conversations
        .where((c) => c.hasUnreadForUser(currentUserId))
        .toList()
      ..sort((a, b) {
        final aAt = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
    final latestUnread = unreadConversations.isNotEmpty ? unreadConversations.first : null;
    final senderName = latestUnread?.getOtherUserName(currentUserId) ?? '?????';
    final conversationId = latestUnread?.id;
    final peerId = latestUnread?.getOtherUserId(currentUserId);

    await NotificationService().showInAppChatAlert(
      senderName: senderName,
      message: currentUnreadCount - previousUnreadCount > 1
          ? '??? ???? ???? ?????? ?????'
          : '?? ???? ???? ?????? ?????',
      conversationId: conversationId,
      peerId: peerId,
    );
    if (kDebugMode) {
      debugPrint('ChatRealtimeNotify: fallback unread increase notification displayed');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopRefreshTimer();
    _syncSubscription?.cancel();
    _conversationSubscription?.cancel();
    super.dispose();
  }
}
