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

/// تب دوستان — الگوی اپ‌های حرفه‌ای:
/// یک لیست واحد + بنر درخواست‌ها در بالا + جستجو داخل تب (بدون TabBar تو در تو).
class MyFriendsScreen extends StatefulWidget {
  const MyFriendsScreen({super.key});

  @override
  State<MyFriendsScreen> createState() => _MyFriendsScreenState();
}

class _MyFriendsScreenState extends State<MyFriendsScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<UserProfile> _friends = [];
  List<FriendshipRequest> _receivedRequests = [];
  List<FriendshipRequest> _sentRequests = [];

  StreamSubscription<List<UserProfile>>? _friendsSubscription;
  StreamSubscription<List<FriendshipRequest>>? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFriends(showCache: true);
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _friendsSubscription?.cancel();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshData(forceRefresh: true, silent: true));
    }
  }

  void _setupRealTimeUpdates() {
    try {
      _friendsSubscription = FriendshipService.watchFriends().listen(
        (friends) {
          if (mounted) {
            SafeSetState.call(this, () => _friends = friends);
            unawaited(_updateCache());
          }
        },
        onError: (Object error) {
          debugPrint('Error in friends stream: $error');
        },
      );

      _requestsSubscription = FriendshipService.watchReceivedRequests().listen(
        (requests) {
          if (mounted) {
            SafeSetState.call(this, () => _receivedRequests = requests);
            unawaited(_updateCache());
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
          _isLoading = false;
        });
      } else {
        SafeSetState.call(this, () => _isLoading = true);
      }
    }

    try {
      final friends = await FriendshipService.getFriends();
      final receivedRequests = await FriendshipService.getReceivedRequests();
      final sentRequests = await FriendshipService.getSentRequests();

      SafeSetState.call(this, () {
        _friends = friends;
        _receivedRequests = receivedRequests;
        _sentRequests = sentRequests;
        _isLoading = false;
        _isRefreshing = false;
      });

      await _updateCache();
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _isRefreshing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری دوستان: $e',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppTheme.errorColor,
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
      if (forceRefresh) {
        await CacheService.clear('friends_screen_cache');
      }

      final friends = await FriendshipService.getFriends();
      final receivedRequests = await FriendshipService.getReceivedRequests();
      final sentRequests = await FriendshipService.getSentRequests();

      SafeSetState.call(this, () {
        _friends = friends;
        _receivedRequests = receivedRequests;
        _sentRequests = sentRequests;
        _isRefreshing = false;
      });

      await _updateCache();
    } catch (e) {
      SafeSetState.call(this, () => _isRefreshing = false);
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در به‌روزرسانی: $e',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppTheme.errorColor,
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

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const FriendshipSearchScreen(),
      ),
    ).then((_) {
      if (mounted) unawaited(_refreshData(forceRefresh: true, silent: true));
    });
  }

  Future<void> _openRequestsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return _RequestsSheet(
          received: _receivedRequests,
          sent: _sentRequests,
          onAccept: _acceptRequest,
          onReject: _rejectRequest,
          onCancel: _cancelRequest,
        );
      },
    );
    if (mounted) unawaited(_refreshData(forceRefresh: true, silent: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    final hasRequests =
        _receivedRequests.isNotEmpty || _sentRequests.isNotEmpty;
    final isEmpty = _friends.isEmpty && !hasRequests;

    return RefreshIndicator(
      onRefresh: () => _refreshData(forceRefresh: true),
      color: AppTheme.goldColor,
      child: isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                UnifiedEmptyState(
                  icon: LucideIcons.users,
                  title: 'هنوز دوستی ندارید',
                  subtitle:
                      'با نام کاربری دوست‌تان را پیدا کنید و درخواست دوستی بفرستید',
                  actionText: 'جستجوی دوستان',
                  actionIcon: LucideIcons.search,
                  onAction: _openSearch,
                ),
              ],
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
              children: [
                _SearchEntryCard(onTap: _openSearch),
                SizedBox(height: 12.h),
                if (hasRequests) ...[
                  _RequestsBanner(
                    receivedCount: _receivedRequests.length,
                    sentCount: _sentRequests.length,
                    onTap: _openRequestsSheet,
                  ),
                  SizedBox(height: 16.h),
                ],
                Row(
                  children: [
                    Text(
                      'دوستان',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${_friends.length}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.goldColor,
                        ),
                      ),
                    ),
                    if (_isRefreshing) ...[
                      SizedBox(width: 10.w),
                      SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(
                          color: AppTheme.goldColor,
                          strokeWidth: 2,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 10.h),
                if (_friends.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Text(
                      'هنوز دوستی در لیست نیست. درخواست‌های در انتظار را از بالا ببینید.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        color: context.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._friends.map(
                    (friend) => _FriendCard(
                      friend: friend,
                      onChat: () => _openChat(friend),
                      onViewProfile: () => _viewProfile(friend),
                      onRemove: () => _removeFriend(friend),
                    ),
                  ),
              ],
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
        backgroundColor: context.cardColor,
        title: Text(
          'حذف دوست',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
          ),
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید این دوست را حذف کنید؟',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'لغو',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await FriendshipService.removeFriend(friend.id);
        await CacheService.clear('friends_screen_cache');
        await _refreshData(forceRefresh: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'دوست حذف شد',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'خطا در حذف دوست: $e',
                style: const TextStyle(fontFamily: AppTheme.fontFamily),
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _acceptRequest(FriendshipRequest request) async {
    try {
      await FriendshipService.acceptFriendRequest(request.id);
      await CacheService.clear('friends_screen_cache');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await _refreshDataWithRetry();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'درخواست دوستی پذیرفته شد',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در پذیرش درخواست: $e',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _refreshDataWithRetry({
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async {
    var retryCount = 0;
    var success = false;

    while (retryCount < maxRetries && !success) {
      try {
        SafeSetState.call(this, () => _isRefreshing = true);
        final friends = await FriendshipService.getFriends();
        final receivedRequests = await FriendshipService.getReceivedRequests();
        final sentRequests = await FriendshipService.getSentRequests();

        SafeSetState.call(this, () {
          _friends = friends;
          _receivedRequests = receivedRequests;
          _sentRequests = sentRequests;
          _isRefreshing = false;
        });
        await _updateCache();
        success = true;
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
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
      await _refreshData(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'درخواست دوستی رد شد',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در رد درخواست: $e',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _cancelRequest(FriendshipRequest request) async {
    try {
      await FriendshipService.cancelFriendRequest(request.id);
      await CacheService.clear('friends_screen_cache');
      await _refreshData(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'درخواست لغو شد',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در لغو درخواست: $e',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

class _SearchEntryCard extends StatelessWidget {
  const _SearchEntryCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.28 : 0.35),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(
                  LucideIcons.search,
                  size: 18.sp,
                  color: AppTheme.goldColor,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'جستجو با نام کاربری...',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                      color: context.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.userPlus,
                  size: 18.sp,
                  color: AppTheme.goldColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestsBanner extends StatelessWidget {
  const _RequestsBanner({
    required this.receivedCount,
    required this.sentCount,
    required this.onTap,
  });

  final int receivedCount;
  final int sentCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = receivedCount > 0
        ? 'درخواست‌های دوستی'
        : 'درخواست‌های ارسال‌شده';
    final subtitle = receivedCount > 0
        ? '$receivedCount درخواست در انتظار'
        : '$sentCount درخواست در انتظار پاسخ';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.userPlus,
                    size: 18.sp,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: context.textColor,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.sp,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (receivedCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      receivedCount > 99 ? '99+' : '$receivedCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                SizedBox(width: 6.w),
                Icon(
                  LucideIcons.chevronLeft,
                  size: 18.sp,
                  color: context.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestsSheet extends StatefulWidget {
  const _RequestsSheet({
    required this.received,
    required this.sent,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
  });

  final List<FriendshipRequest> received;
  final List<FriendshipRequest> sent;
  final Future<void> Function(FriendshipRequest) onAccept;
  final Future<void> Function(FriendshipRequest) onReject;
  final Future<void> Function(FriendshipRequest) onCancel;

  @override
  State<_RequestsSheet> createState() => _RequestsSheetState();
}

class _RequestsSheetState extends State<_RequestsSheet> {
  late List<FriendshipRequest> _received;
  late List<FriendshipRequest> _sent;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _received = List<FriendshipRequest>.from(widget.received);
    _sent = List<FriendshipRequest>.from(widget.sent);
  }

  Future<void> _handleAccept(FriendshipRequest request) async {
    if (_busyIds.contains(request.id)) return;
    setState(() => _busyIds.add(request.id));
    try {
      await widget.onAccept(request);
      if (!mounted) return;
      setState(() {
        _received.removeWhere((r) => r.id == request.id);
        _busyIds.remove(request.id);
      });
    } catch (_) {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  Future<void> _handleReject(FriendshipRequest request) async {
    if (_busyIds.contains(request.id)) return;
    setState(() => _busyIds.add(request.id));
    try {
      await widget.onReject(request);
      if (!mounted) return;
      setState(() {
        _received.removeWhere((r) => r.id == request.id);
        _busyIds.remove(request.id);
      });
    } catch (_) {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  Future<void> _handleCancel(FriendshipRequest request) async {
    if (_busyIds.contains(request.id)) return;
    setState(() => _busyIds.add(request.id));
    try {
      await widget.onCancel(request);
      if (!mounted) return;
      setState(() {
        _sent.removeWhere((r) => r.id == request.id);
        _busyIds.remove(request.id);
      });
    } catch (_) {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'درخواست‌های دوستی',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: context.textColor,
              ),
            ),
            SizedBox(height: 14.h),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.62,
              ),
              child: _received.isEmpty && _sent.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: Text(
                        'درخواستی وجود ندارد',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textSecondary,
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        if (_received.isNotEmpty) ...[
                          _sheetSection('ورودی'),
                          SizedBox(height: 8.h),
                          ..._received.map(
                            (r) => _PendingRequestCard(
                              request: r,
                              onAccept: _busyIds.contains(r.id)
                                  ? null
                                  : () => unawaited(_handleAccept(r)),
                              onReject: _busyIds.contains(r.id)
                                  ? null
                                  : () => unawaited(_handleReject(r)),
                            ),
                          ),
                        ],
                        if (_sent.isNotEmpty) ...[
                          if (_received.isNotEmpty) SizedBox(height: 12.h),
                          _sheetSection('ارسال‌شده'),
                          SizedBox(height: 8.h),
                          ..._sent.map(
                            (r) => _SentRequestCard(
                              request: r,
                              onCancel: _busyIds.contains(r.id)
                                  ? null
                                  : () => unawaited(_handleCancel(r)),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetSection(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: AppTheme.goldColor,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
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
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: friend.isOnline
              ? Colors.green.withValues(alpha: 0.25)
              : isDark
                  ? Colors.white12
                  : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
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
                      radius: 24.r,
                      backgroundColor:
                          AppTheme.goldColor.withValues(alpha: 0.2),
                      backgroundImage: friend.avatarUrl != null
                          ? NetworkImage(friend.avatarUrl!)
                          : null,
                      child: friend.avatarUrl == null
                          ? Icon(
                              LucideIcons.user,
                              color: context.textSecondary,
                              size: 20.sp,
                            )
                          : null,
                    ),
                    if (friend.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 11.w,
                          height: 11.w,
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
                          fontSize: 15.sp,
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
                          fontSize: 12.5.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onChat,
                  icon: Icon(
                    LucideIcons.messageCircle,
                    size: 20.sp,
                    color: AppTheme.goldColor,
                  ),
                  tooltip: 'پیام',
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    size: 18.sp,
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
                          Text(
                            'پروفایل',
                            style: TextStyle(fontFamily: AppTheme.fontFamily),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.userMinus,
                            size: 18,
                            color: AppTheme.errorColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'حذف دوست',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
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
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: context.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: Colors.orange.withValues(alpha: 0.3),
                  backgroundImage: request.requesterAvatar != null
                      ? NetworkImage(request.requesterAvatar!)
                      : null,
                  child: request.requesterAvatar == null
                      ? const Icon(LucideIcons.user, color: Colors.orange)
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterFullName ??
                            request.requesterUsername ??
                            'کاربر ناشناس',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          color: context.textColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      if (request.requesterUsername != null)
                        Text(
                          '@${request.requesterUsername}',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  _formatRelative(request.createdAt),
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                request.message!,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13.sp,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'پذیرش',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'رد',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
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

class _SentRequestCard extends StatelessWidget {
  const _SentRequestCard({required this.request, required this.onCancel});
  final FriendshipRequest request;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: context.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: Colors.blue.withValues(alpha: 0.25),
                  backgroundImage: request.requestedAvatar != null
                      ? NetworkImage(request.requestedAvatar!)
                      : null,
                  child: request.requestedAvatar == null
                      ? const Icon(LucideIcons.user, color: Colors.blue)
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requestedFullName ??
                            request.requestedUsername ??
                            'کاربر ناشناس',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          color: context.textColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      Text(
                        'در انتظار پاسخ',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatRelative(request.createdAt),
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  'لغو درخواست',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRelative(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      if (difference.inMinutes == 0) return 'همین الان';
      return '${difference.inMinutes} دقیقه پیش';
    }
    return '${difference.inHours} ساعت پیش';
  }
  if (difference.inDays == 1) return 'دیروز';
  if (difference.inDays < 7) return '${difference.inDays} روز پیش';
  return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
}
