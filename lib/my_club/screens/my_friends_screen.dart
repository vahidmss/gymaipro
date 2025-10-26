import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/models/friendship_models.dart';
import 'package:gymaipro/my_club/screens/friendship_search_screen.dart';
import 'package:gymaipro/my_club/services/friendship_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MyFriendsScreen extends StatefulWidget {
  const MyFriendsScreen({super.key});

  @override
  State<MyFriendsScreen> createState() => _MyFriendsScreenState();
}

class _MyFriendsScreenState extends State<MyFriendsScreen> {
  bool _isLoading = true;
  List<UserProfile> _friends = [];
  List<FriendshipRequest> _receivedRequests = [];
  List<FriendshipRequest> _sentRequests = [];
  int _receivedRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    // 1) Try cache-first
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
        _isLoading = false; // no full screen loading if cache exists
      });
    } else {
      SafeSetState.call(this, () => _isLoading = true);
    }
    try {
      // Load friends
      final friends = await FriendshipService.getFriends();

      // Load received requests
      final receivedRequests = await FriendshipService.getReceivedRequests();

      // Load sent requests
      final sentRequests = await FriendshipService.getSentRequests();

      SafeSetState.call(this, () {
        _friends = friends;
        _receivedRequests = receivedRequests;
        _sentRequests = sentRequests;
        _receivedRequestsCount = receivedRequests.length;
        _isLoading = false;
      });
      // 3) Update cache
      await CacheService.setJson('friends_screen_cache', {
        'friends': _friends
            .map(
              (f) => {
                'id': f.id,
                'username': f.username,
                // full name will be rebuilt from first/last if present in future
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
      SafeSetState.call(this, () => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldColor),
            )
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  ColoredBox(
                    color: const Color(0xFF2A2A2A),
                    child: TabBar(
                      indicatorColor: AppTheme.goldColor,
                      labelColor: AppTheme.goldColor,
                      unselectedLabelColor: Colors.grey[400],
                      labelStyle: GoogleFonts.vazirmatn(
                        fontWeight: FontWeight.w600,
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
                                        style: GoogleFonts.vazirmatn(
                                          color: Colors.white,
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.bold,
                                          height: 1.h,
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
    if (_friends.isEmpty) {
      return _buildEmptyFriendsState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return _FriendCard(
          friend: friend,
          onChat: () => _openChat(friend),
          onViewProfile: () => _viewProfile(friend),
          onRemove: () => _removeFriend(friend),
        );
      },
    );
  }

  Widget _buildReceivedRequests() {
    if (_receivedRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.userCheck, size: 64.sp, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'درخواست دوستی ندارید',
              style: GoogleFonts.vazirmatn(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _receivedRequests.length,
      itemBuilder: (context, index) {
        final request = _receivedRequests[index];
        return _PendingRequestCard(
          request: request,
          onAccept: () => _acceptRequest(request),
          onReject: () => _rejectRequest(request),
        );
      },
    );
  }

  Widget _buildSentRequests() {
    if (_sentRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.userPlus, size: 64.sp, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'درخواست ارسال شده ندارید',
              style: GoogleFonts.vazirmatn(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _sentRequests.length,
      itemBuilder: (context, index) {
        final request = _sentRequests[index];
        return _SentRequestCard(
          request: request,
          onCancel: () => _cancelRequest(request),
        );
      },
    );
  }

  Widget _buildEmptyFriendsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 64.sp, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'هنوز دوستی ندارید',
            style: GoogleFonts.vazirmatn(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'برای شروع، از بخش جستجو دوستان جدید پیدا کنید',
            style: GoogleFonts.vazirmatn(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const FriendshipSearchScreen(),
              ),
            ),
            icon: const Icon(LucideIcons.search),
            label: const Text('جستجوی دوستان'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12),
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

        _loadFriends();
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
      await FriendshipService.acceptFriendRequest(request.id);

      SafeSetState.call(this, () {
        _receivedRequestsCount--;
      });
      _loadFriends();
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

  Future<void> _rejectRequest(FriendshipRequest request) async {
    try {
      await FriendshipService.rejectFriendRequest(request.id);

      SafeSetState.call(this, () {
        _receivedRequestsCount--;
      });
      _loadFriends();
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

      _loadFriends();
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: friend.isOnline
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey[700]!,
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: friend.isOnline
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.3),
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
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${friend.username}',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.grey[400],
                          fontSize: 14.sp,
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
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.green,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
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
                        foregroundColor: Colors.black,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
        ),
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
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                      if (request.requesterUsername != null)
                        Text(
                          '@${request.requesterUsername}',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                        ),
                      Text(
                        'درخواست دوستی',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.orange,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDateTime(request.createdAt),
                  style: GoogleFonts.vazirmatn(
                    color: Colors.grey[500],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  request.message!,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.grey[300],
                    fontSize: 14.sp,
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

  String _getRequesterName(Map<String, dynamic>? requesterData) {
    if (requesterData == null) return 'کاربر ناشناس';

    final firstName = (requesterData['first_name'] as String?) ?? '';
    final lastName = (requesterData['last_name'] as String?) ?? '';
    final username = (requesterData['username'] as String?) ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else if (username.isNotEmpty) {
      return username;
    }
    return 'کاربر ناشناس';
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
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
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                      if (request.requestedUsername != null)
                        Text(
                          '@${request.requestedUsername}',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                        ),
                      Text(
                        'در انتظار پاسخ',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.blue,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDateTime(request.createdAt),
                  style: GoogleFonts.vazirmatn(
                    color: Colors.grey[500],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  request.message!,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.grey[300],
                    fontSize: 14.sp,
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
