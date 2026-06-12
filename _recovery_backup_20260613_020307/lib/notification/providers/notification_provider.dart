import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/notification/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider برای مدیریت state اعلان‌ها
/// شامل realtime updates، pagination، filtering و search
class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  // State variables
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  int _unreadCount = 0;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;

  // Filtering & Search
  NotificationType? _selectedFilter;
  String _searchQuery = '';
  bool _showOnlyUnread = false;

  // Realtime subscription
  RealtimeChannel? _realtimeChannel;

  // Getters
  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;
  NotificationType? get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  bool get showOnlyUnread => _showOnlyUnread;

  /// Grouped notifications by date
  Map<String, List<NotificationItem>> get groupedNotifications {
    final Map<String, List<NotificationItem>> grouped = {};

    for (final notification in _notifications) {
      final dateKey = _getDateKey(notification.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }

    return grouped;
  }

  /// Filtered notifications based on current filters
  List<NotificationItem> get filteredNotifications {
    var filtered = _notifications;

    // Filter by type
    if (_selectedFilter != null) {
      filtered = filtered.where((n) => n.type == _selectedFilter).toList();
    }

    // Filter by read status
    if (_showOnlyUnread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((n) {
        return n.title.toLowerCase().contains(query) ||
            n.message.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  NotificationProvider() {
    _initializeRealtime();
  }

  /// Initialize realtime subscription
  void _initializeRealtime() {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      _realtimeChannel = client
          .channel('notifications_${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) {
              _handleRealtimeUpdate(payload);
            },
          )
          .subscribe();

      debugPrint('✅ Realtime notifications subscription initialized');
    } catch (e) {
      debugPrint('❌ Error initializing realtime: $e');
    }
  }

  /// Handle realtime updates
  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    try {
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          final newRecord = payload.newRecord;
          final notification = NotificationItem.fromJson(
            Map<String, dynamic>.from(newRecord),
          );
          // جلوگیری از duplicate - بررسی وجود notification
          final exists = _notifications.any((n) => n.id == notification.id);
          if (!exists) {
            _notifications.insert(0, notification);
            if (!notification.isRead) {
              _unreadCount++;
            }
            notifyListeners();
          }
          break;

        case PostgresChangeEvent.update:
          final newRecord = payload.newRecord;
          final updatedNotification = NotificationItem.fromJson(
            Map<String, dynamic>.from(newRecord),
          );
          final index = _notifications.indexWhere(
            (n) => n.id == updatedNotification.id,
          );
          if (index != -1) {
            final wasRead = _notifications[index].isRead;
            _notifications[index] = updatedNotification;
            if (!wasRead && updatedNotification.isRead) {
              _unreadCount = (_unreadCount - 1)
                  .clamp(0, double.infinity)
                  .toInt();
            } else if (wasRead && !updatedNotification.isRead) {
              _unreadCount++;
            }
            notifyListeners();
          }
          break;

        case PostgresChangeEvent.delete:
          final oldRecord = payload.oldRecord;
          final deletedId = oldRecord['id'] as String;
          final index = _notifications.indexWhere((n) => n.id == deletedId);
          if (index != -1) {
            if (!_notifications[index].isRead) {
              _unreadCount = (_unreadCount - 1)
                  .clamp(0, double.infinity)
                  .toInt();
            }
            _notifications.removeAt(index);
            notifyListeners();
          }
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('❌ Error handling realtime update: $e');
    }
  }

  /// Load initial notifications
  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    try {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      notifyListeners();

      if (refresh) {
        _currentPage = 0;
        _hasMore = true;
      }

      final result = await _repository.getNotifications(
        page: 0,
        pageSize: _pageSize,
        filter: _selectedFilter,
        showOnlyUnread: _showOnlyUnread,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      _notifications = result.notifications;
      _unreadCount = result.unreadCount;
      _hasMore = result.hasMore;
      _currentPage = 0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      debugPrint('❌ Error loading notifications: $e');
      notifyListeners();
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final nextPage = _currentPage + 1;
      final result = await _repository.getNotifications(
        page: nextPage,
        pageSize: _pageSize,
        filter: _selectedFilter,
        showOnlyUnread: _showOnlyUnread,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      _notifications.addAll(result.notifications);
      _hasMore = result.hasMore;
      _currentPage = nextPage;

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      debugPrint('❌ Error loading more notifications: $e');
      notifyListeners();
    }
  }

  /// Refresh notifications count
  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing unread count: $e');
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final success = await _repository.markAsRead(notificationId);
      if (success) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index].isRead = true;
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final count = await _repository.markAllAsRead();
      if (count > 0) {
        for (final notification in _notifications) {
          notification.isRead = true;
        }
        _unreadCount = 0;
        notifyListeners();
      }
      return count;
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
      return 0;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final success = await _repository.deleteNotification(notificationId);
      if (success) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          if (!_notifications[index].isRead) {
            _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          }
          _notifications.removeAt(index);
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all read notifications
  Future<int> deleteReadNotifications() async {
    try {
      final deletedIds = await _repository.deleteReadNotifications();
      if (deletedIds.isNotEmpty) {
        _notifications.removeWhere((n) => deletedIds.contains(n.id));
        notifyListeners();
      }
      return deletedIds.length;
    } catch (e) {
      debugPrint('❌ Error deleting read notifications: $e');
      return 0;
    }
  }

  /// Set filter
  void setFilter(NotificationType? type) {
    if (_selectedFilter != type) {
      _selectedFilter = type;
      loadNotifications(refresh: true);
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      loadNotifications(refresh: true);
    }
  }

  /// Toggle show only unread
  void toggleShowOnlyUnread() {
    _showOnlyUnread = !_showOnlyUnread;
    loadNotifications(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    _selectedFilter = null;
    _searchQuery = '';
    _showOnlyUnread = false;
    loadNotifications(refresh: true);
  }

  /// Get date key for grouping
  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(notificationDate).inDays;

    if (difference == 0) {
      return 'امروز';
    } else if (difference == 1) {
      return 'دیروز';
    } else if (difference < 7) {
      return 'این هفته';
    } else if (difference < 30) {
      return 'این ماه';
    } else {
      // Format: "1403/01/15"
      final persianMonths = [
        '',
        'فروردین',
        'اردیبهشت',
        'خرداد',
        'تیر',
        'مرداد',
        'شهریور',
        'مهر',
        'آبان',
        'آذر',
        'دی',
        'بهمن',
        'اسفند',
      ];
      return '${date.day} ${persianMonths[date.month]} ${date.year}';
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
