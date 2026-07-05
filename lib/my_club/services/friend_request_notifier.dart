import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart' show ChatUnreadNotifier;
import 'package:gymaipro/core/lifecycle_observer.dart';
import 'package:gymaipro/models/friendship_models.dart';
import 'package:gymaipro/my_club/services/friendship_service.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/notification/services/notification_sync_bus.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// مثل [ChatUnreadNotifier]: روی دستگاه گیرنده poll می‌کند و نوتیف tray می‌دهد.
class FriendRequestNotifier extends ChangeNotifier {
  int _pendingCount = 0;
  final Set<String> _knownRequestIds = {};
  bool _baselineSet = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _disposed = false;
  bool _pendingRefresh = false;
  Timer? _refreshTimer;
  StreamSubscription<void>? _syncSubscription;
  DateTime? _lastLocalNotifyAt;
  String? _lastNotifiedRequestId;

  int get pendingCount => _pendingCount;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!_disposed) {
        unawaited(_loadPending(force: true));
      }
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 18), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (!_isInitialized || _isLoading) return;
      // در پس‌زمینه poll نکن تا دیتا/باتری هدر نرود (به‌ویژه روی وب).
      if (LifecycleObserver.isAppInBackground) return;
      if (Supabase.instance.client.auth.currentUser == null) return;
      unawaited(_loadPending());
    });

    _syncSubscription?.cancel();
    _syncSubscription = NotificationSyncBus.instance.stream.listen((_) {
      if (_disposed || !_isInitialized) return;
      unawaited(_loadPending(force: true));
    });
  }

  Future<void> refreshPending({bool force = true}) async {
    if (!_isInitialized) return;
    await _loadPending(force: force);
  }

  Future<void> _loadPending({bool force = false}) async {
    if (_disposed) return;
    if (_isLoading) {
      _pendingRefresh = true;
      return;
    }

    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) return;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _isLoading = true;
      final requests = await FriendshipService.getReceivedRequests().timeout(
        const Duration(seconds: 12),
        onTimeout: () => <FriendshipRequest>[],
      );

      if (!_baselineSet) {
        _knownRequestIds
          ..clear()
          ..addAll(requests.map((r) => r.id).where((id) => id.isNotEmpty));
        _pendingCount = requests.length;
        _baselineSet = true;
        _safeNotifyListeners();
        return;
      }

      final newRequests = requests
          .where((r) => r.id.isNotEmpty && !_knownRequestIds.contains(r.id))
          .toList();

      if (newRequests.isNotEmpty) {
        for (final request in newRequests) {
          await _showLocalForRequest(request);
        }
      } else if (force && requests.length > _pendingCount && requests.isNotEmpty) {
        await _showLocalForRequest(requests.first);
      }

      _knownRequestIds
        ..clear()
        ..addAll(requests.map((r) => r.id).where((id) => id.isNotEmpty));
      _pendingCount = requests.length;
      _safeNotifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FriendRequestNotifier load error: $e');
      }
    } finally {
      _isLoading = false;
      if (_pendingRefresh && !_disposed) {
        _pendingRefresh = false;
        unawaited(_loadPending(force: true));
      }
    }
  }

  Future<void> _showLocalForRequest(FriendshipRequest request) async {
    if (request.id == _lastNotifiedRequestId &&
        _lastLocalNotifyAt != null &&
        DateTime.now().difference(_lastLocalNotifyAt!) <
            const Duration(seconds: 25)) {
      return;
    }

    final displayName = _displayNameFromRequest(request);
    final body = '$displayName می‌خواهد با شما دوست شود';

    await NotificationService().showInAppFriendRequestAlert(
      title: 'درخواست دوستی جدید',
      body: body,
      requestId: request.id,
      requesterId: request.requesterId,
    );

    _lastNotifiedRequestId = request.id;
    _lastLocalNotifyAt = DateTime.now();
    if (kDebugMode) {
      debugPrint('FriendRequestNotifier: tray notification for ${request.id}');
    }
  }

  String _displayNameFromRequest(FriendshipRequest request) {
    final full = request.requesterFullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final username = request.requesterUsername?.trim();
    if (username != null && username.isNotEmpty) return username;
    return 'کاربر';
  }

  void _safeNotifyListeners() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }
}
