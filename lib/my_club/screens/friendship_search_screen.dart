import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          'جستجوی دوستان',
          style: GoogleFonts.vazirmatn(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight),
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
              style: GoogleFonts.vazirmatn(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'جستجو بر اساس نام کاربری...',
                hintStyle: GoogleFonts.vazirmatn(color: Colors.grey[400]),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: AppTheme.goldColor,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppTheme.goldColor),
                ),
              ),
            ),
          ),
          // Content
          Expanded(child: _buildContent()),
        ],
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
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.search, size: 64.sp, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'نتیجه‌ای یافت نشد',
              style: GoogleFonts.vazirmatn(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'نام کاربری دیگری امتحان کنید',
              style: GoogleFonts.vazirmatn(color: Colors.grey[500]),
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
    if (_suggestedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 64.sp, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'پیشنهادی نداریم',
              style: GoogleFonts.vazirmatn(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'برای پیدا کردن دوستان، نام کاربری آن‌ها را جستجو کنید',
              style: GoogleFonts.vazirmatn(color: Colors.grey[500]),
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
            style: GoogleFonts.vazirmatn(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[600]!),
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
                          ? const Icon(LucideIcons.user, color: Colors.black)
                          : null,
                    ),
                    if (widget.user.isOnline)
                      Positioned(
                        right: 0.w,
                        bottom: 0.h,
                        child: Container(
                          width: 12.w,
                          height: 12.h,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: Color(0xFF2A2A2A), width: 2),
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
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                      Text(
                        '@${widget.user.username}',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.grey[400],
                          fontSize: 14.sp,
                        ),
                      ),
                      if (widget.user.isOnline)
                        Text(
                          'آنلاین',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.green,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
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
            foregroundColor: Colors.black,
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
            foregroundColor: Colors.black,
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
      // This would need to be implemented in the service
      // For now, just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('این ویژگی در نسخه بعدی اضافه خواهد شد'),
            backgroundColor: Colors.orange,
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
