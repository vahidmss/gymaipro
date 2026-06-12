import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/friendship_models.dart';
import 'package:gymaipro/my_club/screens/friendship_search_screen.dart';
import 'package:gymaipro/my_club/services/friendship_service.dart';
import 'package:gymaipro/my_club/widgets/unified_empty_state.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  /// تعداد تب‌ها: دوستان | درخواست‌ها (همیشه با tabs و TabBarView هماهنگ باشد)
  static const int _tabCount = 2;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: _tabCount, vsync: this);
    _loadFriends(showCache: true);
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _friendsSubscription?.cancel();
    _requestsSubscription?.cancel();
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
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController!,
                      children: [
                        _buildFriendsList(),
                        _buildRequestsTab(),
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

  /// تب یکپارچه درخواست‌ها: ورودی + ارسال‌شده (سبک اپ‌های حرفه‌ای)
  Widget _buildRequestsTab() {
    final bothEmpty =
        _receivedRequests.isEmpty && _sentRequests.isEmpty;
    return RefreshIndicator(
      onRefresh: () => _refreshData(forceRefresh: true),
      color: AppTheme.goldColor,
      child: bothEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: UnifiedEmptyState(
                  icon: LucideIcons.userPlus,
                  title: 'درخواست دوستی ندارید',
                  subtitle:
                      'وقتی کسی درخواست دوستی بفرستد یا شما درخواست بفرستید، اینجا نمایش داده می‌شود.',
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                if (_receivedRequests.isNotEmpty) ...[
                  _sectionHeader('درخواست‌های ورودی'),
                  SizedBox(height: 8.h),
                  ..._receivedRequests.map(
                    (request) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _PendingRequestCard(
                        request: request,
                        onAccept: () => _acceptRequest(request),
                        onReject: () => _rejectRequest(request),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
                if (_sentRequests.isNotEmpty) ...[
                  _sectionHeader('ارسال‌شده'),
                  SizedBox(height: 8.h),
                  ..._sentRequests.map(
                    (request) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _SentRequestCard(
                        request: request,
                        onCancel: () => _cancelRequest(request),
                      ),
                    ),
                  ),
                ],
                if (_isRefreshing)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.goldColor),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        color: AppTheme.goldColor,
        fontFamily: AppTheme.fontFamily,
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

/// کارت فشرده دوست — سبک اپ‌های فیتنس: یک ردیف با پیام و منوی بیشتر
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
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: friend.isOnline
              ? Colors.green.withValues(alpha: 0.25)
              : isDark
                  ? Colors.grey[700]!
                  : AppTheme.lightDividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppTheme.goldColor.withValues(alpha: 0.06),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewProfile,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26.r,
                      backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                      backgroundImage: friend.avatarUrl != null
                          ? NetworkImage(friend.avatarUrl!)
                          : null,
                      child: friend.avatarUrl == null
                          ? Icon(
                              LucideIcons.user,
                              color: context.textSecondary,
                              size: 22.sp,
                            )
                          : null,
                    ),
                    if (friend.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12.w,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.cardColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        friend.fullName ?? friend.username,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                          color: context.textColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '@${friend.username}',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (friend.isOnline) ...[
                        SizedBox(height: 4.h),
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
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onChat,
                  icon: Icon(
                    LucideIcons.messageCircle,
                    size: 22.sp,
                    color: AppTheme.goldColor,
                  ),
                  tooltip: 'پیام',
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    size: 20.sp,
                    color: context.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  onSelected: (value) {
                    if (value == 'profile') onViewProfile();
                    if (value == 'remove') onRemove();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(LucideIcons.user, size: 18),
                          SizedBox(width: 8),
                          Text('پروفایل'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(LucideIcons.userMinus, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف دوست', style: TextStyle(color: Colors.red)),
                        ],
                      ),
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
