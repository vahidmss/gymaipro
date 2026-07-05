import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/chat/services/chat_cache_service.dart';
import 'package:gymaipro/chat/services/chat_presence_service.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/chat/services/chat_unread_sync_bus.dart';
import 'package:gymaipro/core/lifecycle_observer.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/notification/push_notification_policy.dart';
import 'package:gymaipro/notification/services/push_health_monitor.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final Map<String, int> _knownUnreadByConversation = {};

  /// Timestamp of the newest message we've already surfaced (tray/push) per
  /// conversation, persisted to disk. This is what lets us alert exactly once
  /// per new message — even when the app was closed and no push arrived — while
  /// never re-alerting already-seen messages on the next cold start.
  final Map<String, DateTime> _lastNotifiedAtByConversation = {};

  /// Short window after the user reads/leaves a conversation during which we
  /// suppress trays, to kill the stray notification that used to appear right
  /// after exiting a chat (mark-read vs unread-recompute race).
  final Map<String, DateTime> _conversationReadGraceUntil = {};
  static const Duration _readGrace = Duration(seconds: 12);
  bool _persistLoaded = false;
  bool _hadPersistedData = false;
  bool _baselineSeeded = false;
  static const String _kLastNotifiedPrefsKey = 'chat_last_notified_at_v1';

  final ChatCacheService _chatCache = ChatCacheService();

  int get unreadCount => _unreadCount;
  bool get isInitialized => _chatService != null && _supabaseService != null;

  void initialize(SupabaseService supabaseService) {
    if (_isInitialized) return;
    _supabaseService = supabaseService;
    _chatService = ChatService();
    _isInitialized = true;

    unawaited(_ensurePersistLoaded());

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_disposed && _isInitialized) {
        _loadUnreadCount();
      }
    });

    _startRefreshTimer();

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
      if (_disposed) return;

      if (_isLoading) {
        _pendingRefresh = true;
        return;
      }

      final now = DateTime.now();
      if (!force &&
          _lastLoadTime != null &&
          now.difference(_lastLoadTime!).inSeconds < 5) {
        return;
      }

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

      _unreadCount = conversations
          .where((conv) => conv.hasUnreadForUser(user.id))
          .length;
      unawaited(_chatCache.persistUnreadCount(_unreadCount));
      await _processPerConversationUnreadChanges(
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

  Future<void> refreshUnreadCount() async {
    if (!isInitialized) return;
    await _loadUnreadCount();
  }

  Future<void> ensureInitialized(SupabaseService supabaseService) async {
    if (!isInitialized) {
      initialize(supabaseService);
    }
  }

  void markAsRead() {
    if (_unreadCount > 0) {
      _unreadCount--;
      _safeNotifyListeners();
    }
  }

  /// Call when the user reads a conversation so poll/fallback does not
  /// re-notify stale unread.
  void acknowledgeConversationRead(String conversationId) {
    _markConversationSeen(conversationId);
    markAsRead();
  }

  /// Call when the user leaves a chat screen. Marks the conversation seen and
  /// opens a short grace window so no stray tray fires during the mark-read
  /// sync race. Does NOT touch the unread count (the read flow already does).
  void noteConversationLeft(String conversationId) {
    if (conversationId.isEmpty) return;
    _markConversationSeen(conversationId);
  }

  void _markConversationSeen(String conversationId) {
    _knownUnreadByConversation[conversationId] = 0;
    _conversationReadGraceUntil[conversationId] =
        DateTime.now().add(_readGrace);
    _lastNotifiedAtByConversation[conversationId] = DateTime.now();
    unawaited(_persistLastNotified());
  }

  bool _isWithinReadGrace(String conversationId) {
    final until = _conversationReadGraceUntil[conversationId];
    return until != null && DateTime.now().isBefore(until);
  }

  /// True when the conversation's newest message is from the peer and newer
  /// than the last message we already surfaced for it.
  bool _hasUnnotifiedMessage(ChatConversation c, String userId) {
    if (!c.hasUnreadForUser(userId)) return false;
    final sender = c.lastMessageSenderId;
    if (sender == null || sender == userId) return false;
    final lastAt = c.lastMessageAt;
    if (lastAt == null) return false;
    final notifiedAt = _lastNotifiedAtByConversation[c.id];
    return notifiedAt == null || lastAt.isAfter(notifiedAt);
  }

  Future<void> _ensurePersistLoaded() async {
    if (_persistLoaded) return;
    _persistLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kLastNotifiedPrefsKey);
      if (raw == null || raw.isEmpty) return;
      _hadPersistedData = true;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      decoded.forEach((key, value) {
        final t = DateTime.tryParse(value.toString());
        if (t == null) return;
        // Never clobber a fresher in-memory marker set before load finished.
        final existing = _lastNotifiedAtByConversation[key];
        if (existing == null || t.isAfter(existing)) {
          _lastNotifiedAtByConversation[key] = t;
        }
      });
    } catch (_) {}
  }

  Future<void> _persistLastNotified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _lastNotifiedAtByConversation.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      );
      await prefs.setString(_kLastNotifiedPrefsKey, jsonEncode(map));
    } catch (_) {}
  }

  void clearUnreadCount() {
    if (_unreadCount != 0) {
      _unreadCount = 0;
      _safeNotifyListeners();
    }
  }

  void incrementUnreadCount() {
    _unreadCount++;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (_) {}
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (!_isInitialized || _isLoading) return;
      // در پس‌زمینه poll نکن تا دیتا/باتری هدر نرود (به‌ویژه روی وب).
      if (LifecycleObserver.isAppInBackground) return;
      if (Supabase.instance.client.auth.currentUser == null) return;
      _loadUnreadCount();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Per-conversation unread tracking based on a persisted "last notified"
  /// timestamp. This surfaces messages received while the app was away (even
  /// with no push) exactly once, and never re-alerts already-seen messages.
  Future<void> _processPerConversationUnreadChanges({
    required List<ChatConversation> conversations,
    required String currentUserId,
  }) async {
    await _ensurePersistLoaded();

    // First run ever (no persisted markers): establish a silent baseline so we
    // don't dump a pile of trays for old, already-known unread messages. Only
    // messages arriving after this point will alert.
    if (!_hadPersistedData && !_baselineSeeded) {
      for (final conversation in conversations) {
        _knownUnreadByConversation[conversation.id] =
            conversation.getUnreadCount(currentUserId);
        final lastAt = conversation.lastMessageAt;
        if (lastAt != null) {
          _lastNotifiedAtByConversation[conversation.id] = lastAt;
        }
      }
      _baselineSeeded = true;
      unawaited(_persistLastNotified());
      if (kDebugMode) {
        debugPrint('ChatRealtimeNotify: unread baseline seeded (no tray)');
      }
      return;
    }

    // Don't decide push-vs-in-app until we actually know if FCM can reach this
    // device. Otherwise, right after a cold open we could show an in-app tray
    // for a message FCM already delivered → duplicate. Probe once, then
    // re-evaluate immediately so the fallback isn't delayed a full poll cycle.
    if (PushNotificationPolicy.isFcmPushEnabled &&
        PushHealthMonitor.instance.lastProbeAt == null) {
      for (final conversation in conversations) {
        _knownUnreadByConversation[conversation.id] =
            conversation.getUnreadCount(currentUserId);
      }
      unawaited(
        PushHealthMonitor.instance.refresh().then((_) {
          if (!_disposed) unawaited(_loadUnreadCount(force: true));
        }),
      );
      return;
    }

    final pushHealthy = PushHealthMonitor.instance.canReceivePushNow;
    final activeConversation = pushHealthy
        ? null
        : await ChatPresenceService().getUserActiveConversation(currentUserId);

    var markersChanged = false;
    for (final conversation in conversations) {
      _knownUnreadByConversation[conversation.id] =
          conversation.getUnreadCount(currentUserId);

      if (!_hasUnnotifiedMessage(conversation, currentUserId)) continue;

      // Push healthy on this device → FCM shows the tray. Just advance the
      // marker so the in-app fallback won't re-alert the same message later.
      if (pushHealthy) {
        _lastNotifiedAtByConversation[conversation.id] =
            conversation.lastMessageAt!;
        markersChanged = true;
        continue;
      }

      // User is inside this conversation → mark seen, no tray.
      if (activeConversation == conversation.id) {
        _lastNotifiedAtByConversation[conversation.id] =
            conversation.lastMessageAt!;
        markersChanged = true;
        continue;
      }

      if (_isWithinReadGrace(conversation.id)) continue;

      await _showTrayForConversation(
        conversation: conversation,
        currentUserId: currentUserId,
        source: 'poll',
      );
      markersChanged = true;
    }

    if (markersChanged) unawaited(_persistLastNotified());

    // Conversations removed from list → drop stale in-memory delta entries.
    final liveIds = conversations.map((c) => c.id).toSet();
    _knownUnreadByConversation.removeWhere((id, _) => !liveIds.contains(id));
  }

  Future<void> _handleConversationRealtimeUpdate(ChatConversation conversation) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    unawaited(_loadUnreadCount(force: true));
    await _ensurePersistLoaded();

    if (!_hasUnnotifiedMessage(conversation, user.id)) {
      if (kDebugMode) {
        debugPrint('ChatRealtimeNotify: skip, no new message for current user');
      }
      return;
    }

    // Push healthy → FCM handles the tray; advance marker to avoid re-alerting.
    if (PushHealthMonitor.instance.canReceivePushNow) {
      _lastNotifiedAtByConversation[conversation.id] =
          conversation.lastMessageAt!;
      unawaited(_persistLastNotified());
      return;
    }

    if (_isWithinReadGrace(conversation.id)) {
      if (kDebugMode) {
        debugPrint('ChatRealtimeNotify: skip, within read grace');
      }
      return;
    }

    final messageKey =
        '${conversation.id}:${conversation.lastMessageAt?.toIso8601String() ?? ''}:${conversation.lastMessageSenderId ?? ''}';
    if (_lastInAppNotifiedMessageKey == messageKey) {
      if (kDebugMode) {
        debugPrint('ChatRealtimeNotify: skip duplicate message key');
      }
      return;
    }

    final activeConversation = await ChatPresenceService().getUserActiveConversation(
      user.id,
    );
    if (activeConversation == conversation.id) {
      _lastNotifiedAtByConversation[conversation.id] =
          conversation.lastMessageAt!;
      unawaited(_persistLastNotified());
      if (kDebugMode) {
        debugPrint('ChatRealtimeNotify: skip, user already inside conversation');
      }
      return;
    }

    await _showTrayForConversation(
      conversation: conversation,
      currentUserId: user.id,
      source: 'realtime',
      messageKey: messageKey,
    );
  }

  Future<void> _showTrayForConversation({
    required ChatConversation conversation,
    required String currentUserId,
    required String source,
    String? messageKey,
  }) async {
    if (_lastRealtimeInAppNotifyAt != null &&
        DateTime.now().difference(_lastRealtimeInAppNotifyAt!) <
            const Duration(seconds: 20)) {
      if (kDebugMode) {
        debugPrint('ChatRealtimeNotify: skip tray — recent alert ($source)');
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
    if (messageKey != null) {
      _lastInAppNotifiedMessageKey = messageKey;
    }
    _knownUnreadByConversation[conversation.id] =
        conversation.getUnreadCount(currentUserId);

    final peerId = conversation.getOtherUserId(currentUserId);
    await NotificationService().showInAppChatAlert(
      senderName: conversation.getOtherUserName(currentUserId),
      message: conversation.lastMessage ?? '',
      conversationId: conversation.id,
      peerId: peerId,
      senderId: conversation.lastMessageSenderId,
      messageAt: conversation.lastMessageAt?.toIso8601String(),
    );
    _lastRealtimeInAppNotifyAt = DateTime.now();
    // Remember we've surfaced up to this message so we never re-alert it,
    // including after a cold restart.
    _lastNotifiedAtByConversation[conversation.id] =
        conversation.lastMessageAt ?? DateTime.now();
    unawaited(_persistLastNotified());
    if (kDebugMode) {
      debugPrint('ChatRealtimeNotify: tray displayed ($source)');
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
