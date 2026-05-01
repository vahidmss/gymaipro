import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/friendship_models.dart';
import 'package:gymaipro/my_club/services/friendship_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FriendshipSearchScreen extends StatefulWidget {
  const FriendshipSearchScreen({super.key});

  @override
  State<FriendshipSearchScreen> createState() => _FriendshipSearchScreenState();
}

class _FriendshipSearchScreenState extends State<FriendshipSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  List<UserProfile> _suggestedUsers = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedUsers() async {
    try {
      final users = await FriendshipService.getSuggestedUsers();
      SafeSetState.call(this, () {
        _suggestedUsers = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری پیشنهادات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      SafeSetState.call(this, () {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    SafeSetState.call(this, () {
      _isLoading = true;
    });

    try {
      final users = await FriendshipService.searchUsers(query);
      SafeSetState.call(this, () {
        _searchResults = users;
        _hasSearched = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در جستجو: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      SafeSetState.call(this, () {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: isDark
              ? context.backgroundColor
              : Colors.transparent,
          elevation: 0,
          title: Text(
            'جستجوی دوستان',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              color: AppTheme.goldColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowRight,
              color: AppTheme.goldColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: EdgeInsets.all(16.w),
              child: TextField(
                controller: _searchController,
                onChanged: _searchUsers,
                style: TextStyle(
                  color: context.textColor,
                  fontFamily: AppTheme.fontFamily,
                ),
                decoration: InputDecoration(
                  hintText: 'جستجو بر اساس نام کاربری...',
                  hintStyle: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isDark
                        ? Colors.grey[400]
                        : AppTheme.lightTextSecondary.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    color: AppTheme.goldColor,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            color: isDark
                                ? Colors.grey
                                : AppTheme.lightTextSecondary.withValues(alpha: 0.6),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _searchUsers('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: context.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.grey[600]!
                          : AppTheme.lightDividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.grey[600]!
                          : AppTheme.lightDividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: AppTheme.goldColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    if (_hasSearched) {
      return _buildSearchResults();
    } else {
      return _buildSuggestedUsers();
    }
  }

  Widget _buildSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.search,
              size: 64.sp,
              color: isDark
                  ? Colors.grey[600]
                  : AppTheme.lightTextSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'نتیجه‌ای یافت نشد',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: context.textColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'نام کاربری دیگری امتحان کنید',
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _UserCard(
          user: user,
          onSendRequest: () => _sendFriendRequest(user),
          onViewProfile: () => _viewProfile(user),
        );
      },
    );
  }

  Widget _buildSuggestedUsers() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_suggestedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.users,
              size: 64.sp,
              color: isDark
                  ? Colors.grey[600]
                  : AppTheme.lightTextSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'پیشنهادی نداریم',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: context.textColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'برای پیدا کردن دوستان، نام کاربری آن‌ها را جستجو کنید',
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            'پیشنهادات دوستی',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.goldColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggestedUsers.length,
            itemBuilder: (context, index) {
              final user = _suggestedUsers[index];
              return _UserCard(
                user: user,
                onSendRequest: () => _sendFriendRequest(user),
                onViewProfile: () => _viewProfile(user),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _sendFriendRequest(UserProfile user) async {
    try {
      await FriendshipService.sendFriendRequest(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('درخواست دوستی به ${user.username} ارسال شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال درخواست: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewProfile(UserProfile user) {
    // Navigate to user profile
    Navigator.pushNamed(context, '/user-profile', arguments: user.id);
  }
}

class _UserCard extends StatefulWidget {
  const _UserCard({
    required this.user,
    required this.onSendRequest,
    required this.onViewProfile,
  });
  final UserProfile user;
  final VoidCallback onSendRequest;
  final VoidCallback onViewProfile;

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFriendshipStatus();
  }

  Future<void> _checkFriendshipStatus() async {
    try {
      final status = await FriendshipService.getFriendshipStatus(
        widget.user.id,
      );
      SafeSetState.call(this, () {
        _friendshipStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: widget.onViewProfile,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark
                ? Colors.grey[600]!
                : AppTheme.lightDividerColor.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : AppTheme.goldColor.withValues(alpha: 0.08),
              blurRadius: 4.r,
              offset: Offset(0.w, 2.h),
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
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.goldColor,
                        backgroundImage: widget.user.avatarUrl != null
                            ? NetworkImage(widget.user.avatarUrl!)
                            : null,
                        child: widget.user.avatarUrl == null
                            ? Icon(
                                LucideIcons.user,
                                color: AppTheme.onGoldColor,
                              )
                            : null,
                      ),
                      if (widget.user.isOnline)
                        Positioned(
                          right: 0.w,
                          bottom: 0.h,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.fullName ?? widget.user.username,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                            color: context.textColor,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        Text(
                          '@${widget.user.username}',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        if (widget.user.isOnline)
                          Text(
                            'آنلاین',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildActionButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoading) {
      return SizedBox(
        width: 20.w,
        height: 20.h,
        child: const CircularProgressIndicator(
          color: AppTheme.goldColor,
          strokeWidth: 2,
        ),
      );
    }

    switch (_friendshipStatus) {
      case FriendshipStatus.none:
        return ElevatedButton.icon(
          onPressed: _sendFriendRequest,
          icon: const Icon(LucideIcons.userPlus, size: 16),
          label: const Text('ارسال درخواست'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.goldColor,
            foregroundColor: AppTheme.onGoldColor,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8),
          ),
        );
      case FriendshipStatus.friends:
        return OutlinedButton.icon(
          onPressed: widget.onViewProfile,
          icon: const Icon(LucideIcons.user, size: 16),
          label: const Text('دوستان'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green,
            side: const BorderSide(color: Colors.green),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8),
          ),
        );
      case FriendshipStatus.requestSent:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(LucideIcons.clock, size: 16),
          label: const Text('ارسال شده'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8),
          ),
        );
      case FriendshipStatus.requestReceived:
        return ElevatedButton.icon(
          onPressed: _acceptFriendRequest,
          icon: const Icon(LucideIcons.check, size: 16),
          label: const Text('تایید'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8),
          ),
        );
      case FriendshipStatus.requestRejected:
        return ElevatedButton.icon(
          onPressed: _sendFriendRequest,
          icon: const Icon(LucideIcons.userPlus, size: 16),
          label: const Text('ارسال مجدد'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.goldColor,
            foregroundColor: AppTheme.onGoldColor,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8),
          ),
        );
      case FriendshipStatus.blocked:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(LucideIcons.userX, size: 16),
          label: const Text('بلاک شده'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8),
          ),
        );
    }
  }

  Future<void> _sendFriendRequest() async {
    try {
      await FriendshipService.sendFriendRequest(widget.user.id);
      SafeSetState.call(this, () {
        _friendshipStatus = FriendshipStatus.requestSent;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('درخواست دوستی به ${widget.user.username} ارسال شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال درخواست: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptFriendRequest() async {
    try {
      await FriendshipService.acceptFriendRequestFromRequester(widget.user.id);
      SafeSetState.call(this, () {
        _friendshipStatus = FriendshipStatus.friends;
      });
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
            content: Text('خطا در تایید درخواست: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
