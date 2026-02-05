import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/friendship_models.dart';
import 'package:gymaipro/my_club/screens/friendship_search_screen.dart';
import 'package:gymaipro/my_club/services/friendship_service.dart';
import 'package:gymaipro/my_club/widgets/unified_empty_state.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MyFriendsScreen extends StatefulWidget {
  const MyFriendsScreen({super.key});

  @override
  State<MyFriendsScreen> createState() => _MyFriendsScreenState();
}

class _MyFriendsScreenState extends State<MyFriendsScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<UserProfile> _friends = [];
  List<FriendshipRequest> _receivedRequests = [];
  List<FriendshipRequest> _sentRequests = [];
  int _receivedRequestsCount = 0;

  // Stream subscriptions for real-time updates
  StreamSubscription<List<UserProfile>>? _friendsSubscription;
  StreamSubscription<List<FriendshipRequest>>? _requestsSubscription;

  // Tab controller
  TabController? _tabController;

  // Auto-refresh timer (refresh every 30 seconds when visible)
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _loadFriends(showCache: true);
    _setupRealTimeUpdates();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _friendsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshData(forceRefresh: true);
    }
  }

  void _setupRealTimeUpdates() {
    try {
      // Listen to friends changes
      _friendsSubscription = FriendshipService.watchFriends().listen(
        (friends) {
          if (mounted) {
            SafeSetState.call(this, () {
              _friends = friends;
            });
            // Update cache silently
            _updateCache();
          }
        },
        onError: (Object error) {
          debugPrint('Error in friends stream: $error');
        },
      );

      // Listen to received requests changes
      _requestsSubscription = FriendshipService.watchReceivedRequests().listen(
        (requests) {
          if (mounted) {
            SafeSetState.call(this, () {
              _receivedRequests = requests;
              _receivedRequestsCount = requests.length;
            });
            // Update cache silently
            _updateCache();
          }
        },
        onError: (Object error) {
          debugPrint('Error in requests stream: $error');
        },
      );
    } catch (e) {
      debugPrint('Error setting up real-time updates: $e');
    }
  }

  void _startAutoRefresh() {
    // Auto-refresh every 30 seconds when screen is visible
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted &&
          SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
        // Only refresh if screen is visible and not currently refreshing
        if (!_isRefreshing && !_isLoading) {
          _refreshData(forceRefresh: false, silent: true);
        }
      }
    });
  }

  Future<void> _loadFriends({bool showCache = false}) async {
    if (!showCache) {
      SafeSetState.call(this, () => _isLoading = true);
    }

    // 1) Try cache-first only on initial load
    if (showCache) {
      final cached = await CacheService.getJsonMap('friends_screen_cache');
      if (cached != null) {
        final friends = (cached['friends'] as List<dynamic>? ?? [])
            .map(
              (e) => UserProfile.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
              ),
            )
            .toList();
        final received = (cached['received'] as List<dynamic>? ?? [])
            .map(
              (e) => FriendshipRequest.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
              ),
            )
            .toList();
        final sent = (cached['sent'] as List<dynamic>? ?? [])
            .map(
              (e) => FriendshipRequest.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
              ),
            )
            .toList();
        SafeSetState.call(this, () {
          _friends = friends;
          _receivedRequests = received;
          _sentRequests = sent;
          _receivedRequestsCount = received.length;
          _isLoading = false;
        });
      } else {
        SafeSetState.call(this, () => _isLoading = true);
      }
    }

    try {
      // Load fresh data from API
      final friends = await FriendshipService.getFriends();
      final receivedRequests = await FriendshipService.getReceivedRequests();
      final sentRequests = await FriendshipService.getSentRequests();

      SafeSetState.call(this, () {
        _friends = friends;
        _receivedRequests = receivedRequests;
        _sentRequests = sentRequests;
        _receivedRequestsCount = receivedRequests.length;
        _isLoading = false;
        _isRefreshing = false;
      });

      // Update cache
      await _updateCache();
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _isRefreshing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری دوستان: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (_isRefreshing && !forceRefresh) return;

    if (!silent) {
      SafeSetState.call(this, () => _isRefreshing = true);
    }

    try {
      // Invalidate cache on manual refresh
      if (forceRefresh) {
        await CacheService.clear('friends_screen_cache');
      }

      // Load fresh data
      final friends = await FriendshipService.getFriends();
      final receivedRequests = await FriendshipService.getReceivedRequests();
      final sentRequests = await FriendshipService.getSentRequests();

      SafeSetState.call(this, () {
        _friends = friends;
        _receivedRequests = receivedRequests;
        _sentRequests = sentRequests;
        _receivedRequestsCount = receivedRequests.length;
        _isRefreshing = false;
      });

      // Update cache
      await _updateCache();
    } catch (e) {
      SafeSetState.call(this, () => _isRefreshing = false);
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در به‌روزرسانی: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateCache() async {
    try {
      await CacheService.setJson('friends_screen_cache', {
        'friends': _friends
            .map(
              (f) => {
                'id': f.id,
                'username': f.username,
                'full_name': f.fullName,
                'avatar_url': f.avatarUrl,
                'is_online': f.isOnline,
              },
            )
            .toList(),
        'received': _receivedRequests
            .map(
              (r) => {
                'id': r.id,
                'requester_id': r.requesterId,
                'requested_id': r.requestedId,
                'message': r.message,
                'status': r.status,
                'created_at': r.createdAt.toIso8601String(),
                'requester': {
                  'username': r.requesterUsername,
                  'full_name': r.requesterFullName,
                  'avatar_url': r.requesterAvatar,
                },
                'friend': null,
              },
            )
            .toList(),
        'sent': _sentRequests
            .map(
              (r) => {
                'id': r.id,
                'requester_id': r.requesterId,
                'requested_id': r.requestedId,
                'message': r.message,
                'status': r.status,
                'created_at': r.createdAt.toIso8601String(),
                'requester': null,
                'friend': {
                  'username': r.requestedUsername,
                  'full_name': r.requestedFullName,
                  'avatar_url': r.requestedAvatar,
                },
              },
            )
            .toList(),
      });
    } catch (e) {
      debugPrint('Error updating cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            : Column(
                children: [
                  Container(
                    color: context.cardColor,
                    child: TabBar(
                      controller: _tabController!,
                      indicatorColor: AppTheme.goldColor,
                      labelColor: AppTheme.goldColor,
                      unselectedLabelColor: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppTheme.lightTextSecondary.withValues(alpha: 0.6),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      tabs: [
                        const Tab(text: 'دوستان'),
                        Tab(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Text('درخواست‌ها'),
                              if (_receivedRequestsCount > 0)
                                Positioned(
                                  right: -8,
                                  top: -4,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 4.r,
                                          offset: Offset(0.w, 2.h),
                                        ),
                                      ],
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _receivedRequestsCount > 99
                                            ? '99+'
                                            : '$_receivedRequestsCount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.bold,
                                          height: 1.h,
                                          fontFamily: AppTheme.fontFamily,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Tab(text: 'ارسال شده'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController!,
                      children: [
                        _buildFriendsList(),
                        _buildReceivedRequests(),
                        _buildSentRequests(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return RefreshIndicator(
      onRefresh: () => _refreshData(forceRefresh: true),
      color: AppTheme.goldColor,
      child: _friends.isEmpty
          ? _buildEmptyFriendsState()
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _friends.length + (_isRefreshing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _friends.length && _isRefreshing) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.goldColor,
                      ),
                    ),
                  );
                }
                final friend = _friends[index];
                return _FriendCard(
                  friend: friend,
                  onChat: () => _openChat(friend),
                  onViewProfile: () => _viewProfile(friend),
                  onRemove: () => _removeFriend(friend),
                );
              },
            ),
    );
  }

  Widget _buildReceivedRequests() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: () => _refreshData(forceRefresh: true),
      color: AppTheme.goldColor,
      child: _receivedRequests.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.userCheck,
                        size: 64.sp,
                        color: isDark
                            ? Colors.grey[600]
                            : AppTheme.lightTextSecondary.withValues(
                                alpha: 0.5,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'درخواست دوستی ندارید',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _receivedRequests.length + (_isRefreshing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _receivedRequests.length && _isRefreshing) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.goldColor,
                      ),
                    ),
                  );
                }
                final request = _receivedRequests[index];
                return _PendingRequestCard(
                  request: request,
                  onAccept: () => _acceptRequest(request),
                  onReject: () => _rejectRequest(request),
                );
              },
            ),
    );
  }

  Widget _buildSentRequests() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: () => _refreshData(forceRefresh: true),
      color: AppTheme.goldColor,
      child: _sentRequests.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.userPlus,
                        size: 64.sp,
                        color: isDark
                            ? Colors.grey[600]
                            : AppTheme.lightTextSecondary.withValues(
                                alpha: 0.5,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'درخواست ارسال شده ندارید',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _sentRequests.length + (_isRefreshing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _sentRequests.length && _isRefreshing) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.goldColor,
                      ),
                    ),
                  );
                }
                final request = _sentRequests[index];
                return _SentRequestCard(
                  request: request,
                  onCancel: () => _cancelRequest(request),
                );
              },
            ),
    );
  }

  Widget _buildEmptyFriendsState() {
    return UnifiedEmptyState(
      icon: LucideIcons.users,
      title: 'هنوز دوستی ندارید',
      subtitle:
          'برای شروع، از بخش جستجو دوستان جدید پیدا کنید و با آن‌ها ارتباط برقرار کنید',
      actionText: 'جستجوی دوستان',
      actionIcon: LucideIcons.search,
      onAction: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const FriendshipSearchScreen(),
        ),
      ),
    );
  }

  void _openChat(UserProfile friend) {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'otherUserId': friend.id,
        'otherUserName': friend.fullName ?? friend.username,
      },
    );
  }

  void _viewProfile(UserProfile friend) {
    Navigator.pushNamed(context, '/user-profile', arguments: friend.id);
  }

  Future<void> _removeFriend(UserProfile friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف دوست'),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید این دوست را حذف کنید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await FriendshipService.removeFriend(friend.id);
        await CacheService.clear('friends_screen_cache');
        _refreshData(forceRefresh: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('دوست حذف شد'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در حذف دوست: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _acceptRequest(FriendshipRequest request) async {
    try {
      // تایید درخواست
      await FriendshipService.acceptFriendRequest(request.id);

      // پاک کردن کش
      await CacheService.clear('friends_screen_cache');

      // کمی صبر می‌کنیم تا trigger دیتابیس دوستی را ایجاد کند
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // رفرش داده‌ها با retry mechanism
      await _refreshDataWithRetry(
        maxRetries: 3,
        retryDelay: const Duration(milliseconds: 500),
      );

      // هدایت به تب دوستان برای نمایش دوست جدید
      if (mounted && _tabController != null) {
        _tabController!.animateTo(0); // تب دوستان
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('درخواست دوستی پذیرفته شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در پذیرش درخواست: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// رفرش داده‌ها با retry mechanism برای اطمینان از دریافت داده‌های جدید
  Future<void> _refreshDataWithRetry({
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async {
    int retryCount = 0;
    bool success = false;

    while (retryCount < maxRetries && !success) {
      try {
        SafeSetState.call(this, () => _isRefreshing = true);

        // بارگذاری داده‌های تازه
        final friends = await FriendshipService.getFriends();
        final receivedRequests = await FriendshipService.getReceivedRequests();
        final sentRequests = await FriendshipService.getSentRequests();

        SafeSetState.call(this, () {
          _friends = friends;
          _receivedRequests = receivedRequests;
          _sentRequests = sentRequests;
          _receivedRequestsCount = receivedRequests.length;
          _isRefreshing = false;
        });

        // به‌روزرسانی کش
        await _updateCache();

        success = true;
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint(
            'Retry $retryCount/$maxRetries: Error refreshing friends: $e',
          );
          await Future<void>.delayed(retryDelay);
        } else {
          SafeSetState.call(this, () => _isRefreshing = false);
          rethrow;
        }
      }
    }
  }

  Future<void> _rejectRequest(FriendshipRequest request) async {
    try {
      await FriendshipService.rejectFriendRequest(request.id);

      await CacheService.clear('friends_screen_cache');
      _refreshData(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('درخواست دوستی رد شد'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در رد درخواست: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRequest(FriendshipRequest request) async {
    try {
      await FriendshipService.cancelFriendRequest(request.id);
      await CacheService.clear('friends_screen_cache');
      _refreshData(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('درخواست لغو شد'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در لغو درخواست: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.onChat,
    required this.onViewProfile,
    required this.onRemove,
  });
  final UserProfile friend;
  final VoidCallback onChat;
  final VoidCallback onViewProfile;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: friend.isOnline
              ? Colors.green.withValues(alpha: 0.3)
              : isDark
              ? Colors.grey[700]!
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: friend.isOnline
                ? Colors.green.withValues(alpha: 0.1)
                : isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.goldColor.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and info
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.goldColor,
                        AppTheme.goldColor.withValues(alpha: 0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        blurRadius: 8.r,
                        offset: Offset(0.w, 2.h),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.transparent,
                        backgroundImage: friend.avatarUrl != null
                            ? NetworkImage(friend.avatarUrl!)
                            : null,
                        child: friend.avatarUrl == null
                            ? Icon(
                                LucideIcons.user,
                                color: Colors.black,
                                size: 24.sp,
                              )
                            : null,
                      ),
                      if (friend.isOnline)
                        Positioned(
                          right: 2.w,
                          bottom: 2.h,
                          child: Container(
                            width: 14.w,
                            height: 14.h,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1F1F1F),
                                width: 2.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.5),
                                  blurRadius: 4.r,
                                  offset: Offset(0.w, 1.h),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.fullName ?? friend.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: context.textColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${friend.username}',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 14.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (friend.isOnline)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6.w,
                                height: 6.h,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'آنلاین',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.goldColor,
                          AppTheme.goldColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.3),
                          blurRadius: 4.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onChat,
                      icon: const Icon(LucideIcons.messageCircle, size: 16),
                      label: const Text('چت'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppTheme.onGoldColor,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewProfile,
                    icon: const Icon(LucideIcons.user, size: 16),
                    label: const Text('پروفایل'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(LucideIcons.userMinus, size: 16),
                  label: const Text('حذف'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 16.w,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });
  final FriendshipRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.orange,
                  backgroundImage: request.requesterAvatar != null
                      ? NetworkImage(request.requesterAvatar!)
                      : null,
                  child: request.requesterAvatar == null
                      ? const Icon(LucideIcons.user, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterFullName ??
                            request.requesterUsername ??
                            'کاربر ناشناس',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: context.textColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      if (request.requesterUsername != null)
                        Text(
                          '@${request.requesterUsername}',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      Text(
                        'درخواست دوستی',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDateTime(request.createdAt),
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]
                      : AppTheme.lightDividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  request.message!,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : context.textSecondary,
                    fontSize: 14.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('پذیرش'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(LucideIcons.x, size: 16),
                    label: const Text('رد'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'همین الان';
        }
        return '${difference.inMinutes} دقیقه پیش';
      }
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
    }
  }
}

class _SentRequestCard extends StatelessWidget {
  const _SentRequestCard({required this.request, required this.onCancel});
  final FriendshipRequest request;
  final VoidCallback onCancel;

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'همین الان';
        }
        return '${difference.inMinutes} دقیقه پیش';
      }
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue,
                  backgroundImage: request.requestedAvatar != null
                      ? NetworkImage(request.requestedAvatar!)
                      : null,
                  child: request.requestedAvatar == null
                      ? const Icon(LucideIcons.user, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requestedFullName ??
                            request.requestedUsername ??
                            'کاربر ناشناس',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: context.textColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      if (request.requestedUsername != null)
                        Text(
                          '@${request.requestedUsername}',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      Text(
                        'در انتظار پاسخ',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDateTime(request.createdAt),
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]
                      : AppTheme.lightDividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  request.message!,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : context.textSecondary,
                    fontSize: 14.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(LucideIcons.x, size: 16),
                    label: const Text('لغو درخواست'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
