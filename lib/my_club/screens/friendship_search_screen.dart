import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/friendship_models.dart';
import 'package:gymaipro/my_club/services/friendship_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// جستجوی دوستان — الگوی اپ‌های حرفه‌ای:
/// فقط با نام کاربری شناخته‌شده، حداقل ۳ کاراکتر، debounce، بدون لیست کشف کاربران.
class FriendshipSearchScreen extends StatefulWidget {
  const FriendshipSearchScreen({super.key});

  @override
  State<FriendshipSearchScreen> createState() => _FriendshipSearchScreenState();
}

class _FriendshipSearchScreenState extends State<FriendshipSearchScreen> {
  static const _debounceMs = 350;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<UserProfile> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _activeQuery;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    final query = raw.trim();
    _debounce?.cancel();

    if (query.length < FriendshipService.searchMinLength) {
      SafeSetState.call(this, () {
        _searchResults = [];
        _hasSearched = false;
        _isLoading = false;
        _activeQuery = null;
      });
      return;
    }

    SafeSetState.call(this, () => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      unawaited(_searchUsers(query));
    });
  }

  Future<void> _searchUsers(String query) async {
    if (!mounted) return;
    if (query.trim().length < FriendshipService.searchMinLength) return;

    _activeQuery = query;
    SafeSetState.call(this, () => _isLoading = true);

    try {
      final users = await FriendshipService.searchUsers(query);
      if (!mounted || _activeQuery != query) return;
      SafeSetState.call(this, () {
        _searchResults = users;
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || _activeQuery != query) return;
      SafeSetState.call(this, () => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در جستجو: $e',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    SafeSetState.call(this, () {
      _searchResults = [];
      _hasSearched = false;
      _isLoading = false;
      _activeQuery = null;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typed = _searchController.text.trim();
    final needsMoreChars =
        typed.isNotEmpty && typed.length < FriendshipService.searchMinLength;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DecoratedBox(
        decoration: context.pageDecoration,
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
                fontSize: 18.sp,
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                LucideIcons.arrowRight,
                color: isDark ? AppTheme.goldColor : context.textColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    color: context.textColor,
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'نام کاربری را وارد کنید...',
                    hintStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary.withValues(alpha: 0.7),
                      fontSize: 14.sp,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      color: AppTheme.goldColor,
                    ),
                    suffixIcon: typed.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              color: context.textSecondary,
                              size: 18.sp,
                            ),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: context.cardColor,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 14.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(
                        color: AppTheme.goldColor.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white12
                            : AppTheme.lightDividerColor.withValues(
                                alpha: 0.6,
                              ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(
                        color: AppTheme.goldColor,
                        width: 1.5,
                      ),
                    ),
                    helperText: needsMoreChars
                        ? 'حداقل ${FriendshipService.searchMinLength} کاراکتر وارد کنید'
                        : null,
                    helperStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.goldColor.withValues(alpha: 0.85),
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildContent(needsMoreChars: needsMoreChars)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent({required bool needsMoreChars}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    if (_hasSearched) {
      return _buildSearchResults();
    }

    return _buildIdleHint(needsMoreChars: needsMoreChars);
  }

  Widget _buildIdleHint({required bool needsMoreChars}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.goldColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                LucideIcons.search,
                size: 34.sp,
                color: AppTheme.goldColor,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              needsMoreChars
                  ? 'ادامه بدهید...'
                  : 'دوست‌تان را با نام کاربری پیدا کنید',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: context.textColor,
                fontFamily: AppTheme.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'برای حفظ حریم خصوصی، جستجو فقط با حداقل '
              '${FriendshipService.searchMinLength} کاراکتر از نام کاربری انجام می‌شود.',
              style: TextStyle(
                fontSize: 13.sp,
                color: context.textSecondary,
                fontFamily: AppTheme.fontFamily,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.searchX,
                size: 52.sp,
                color: context.textSecondary.withValues(alpha: 0.5),
              ),
              SizedBox(height: 16.h),
              Text(
                'نتیجه‌ای یافت نشد',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'نام کاربری را دقیق‌تر وارد کنید',
                style: TextStyle(
                  color: context.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _UserCard(
          user: user,
          onViewProfile: () => _viewProfile(user),
        );
      },
    );
  }

  void _viewProfile(UserProfile user) {
    Navigator.pushNamed(context, '/user-profile', arguments: user.id);
  }
}

class _UserCard extends StatefulWidget {
  const _UserCard({
    required this.user,
    required this.onViewProfile,
  });
  final UserProfile user;
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

  @override
  void didUpdateWidget(covariant _UserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _isLoading = true;
      _checkFriendshipStatus();
    }
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
    } catch (_) {
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onViewProfile,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark
                  ? Colors.white12
                  : AppTheme.lightDividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24.r,
                      backgroundColor: AppTheme.goldColor.withValues(
                        alpha: 0.2,
                      ),
                      backgroundImage: widget.user.avatarUrl != null
                          ? NetworkImage(widget.user.avatarUrl!)
                          : null,
                      child: widget.user.avatarUrl == null
                          ? Icon(
                              LucideIcons.user,
                              color: context.textSecondary,
                              size: 20.sp,
                            )
                          : null,
                    ),
                    if (widget.user.isOnline)
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
                    children: [
                      Text(
                        widget.user.fullName ?? widget.user.username,
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
                        '@${widget.user.username}',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoading) {
      return SizedBox(
        width: 20.w,
        height: 20.w,
        child: const CircularProgressIndicator(
          color: AppTheme.goldColor,
          strokeWidth: 2,
        ),
      );
    }

    switch (_friendshipStatus) {
      case FriendshipStatus.none:
        return _pillButton(
          label: 'افزودن',
          icon: LucideIcons.userPlus,
          filled: true,
          onPressed: _sendFriendRequest,
        );
      case FriendshipStatus.friends:
        return _pillButton(
          label: 'دوست',
          icon: LucideIcons.userCheck,
          color: Colors.green,
          onPressed: widget.onViewProfile,
        );
      case FriendshipStatus.requestSent:
        return _pillButton(
          label: 'ارسال شد',
          icon: LucideIcons.clock,
          color: Colors.orange,
        );
      case FriendshipStatus.requestReceived:
        return _pillButton(
          label: 'تایید',
          icon: LucideIcons.check,
          filled: true,
          color: Colors.green,
          onPressed: _acceptFriendRequest,
        );
      case FriendshipStatus.requestRejected:
        return _pillButton(
          label: 'ارسال مجدد',
          icon: LucideIcons.userPlus,
          filled: true,
          onPressed: _sendFriendRequest,
        );
      case FriendshipStatus.blocked:
        return _pillButton(
          label: 'مسدود',
          icon: LucideIcons.userX,
          color: AppTheme.errorColor,
        );
    }
  }

  Widget _pillButton({
    required String label,
    required IconData icon,
    Color color = AppTheme.goldColor,
    bool filled = false,
    VoidCallback? onPressed,
  }) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14.sp),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: color == AppTheme.goldColor
              ? AppTheme.onGoldColor
              : Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14.sp),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
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
            content: Text(
              'درخواست دوستی به ${widget.user.username} ارسال شد',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
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
              'خطا در ارسال درخواست: $e',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppTheme.errorColor,
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
              'خطا در تایید درخواست: $e',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
