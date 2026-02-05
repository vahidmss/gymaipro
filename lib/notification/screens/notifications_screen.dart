import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/notification/providers/notification_provider.dart';
import 'package:gymaipro/notification/widgets/notification_card.dart';
import 'package:gymaipro/notification/widgets/notification_filter_chip.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<NotificationProvider>().setSearchQuery(
              _searchController.text,
            );
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final provider = context.read<NotificationProvider>();
      if (!provider.isLoadingMore && provider.hasMore) {
        provider.loadMoreNotifications();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.notifications.isEmpty) {
                    return _buildLoadingState();
                  }

                  if (provider.hasError) {
                    return _buildErrorState(provider);
                  }

                  final filteredNotifications = provider.filteredNotifications;
                  final grouped = _groupNotifications(filteredNotifications);

                  if (grouped.isEmpty) {
                    return _buildEmptyState(
                      hasFilters: provider.selectedFilter != null ||
                          provider.showOnlyUnread ||
                          provider.searchQuery.isNotEmpty,
                      onClearFilters: () => provider.clearFilters(),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadNotifications(refresh: true),
                    color: AppTheme.goldColor,
                    backgroundColor: context.cardColor,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      itemCount:
                          grouped.length + (provider.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == grouped.length) {
                          return _buildLoadingMoreIndicator();
                        }

                        final entry = grouped.entries.elementAt(index);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateHeader(entry.key),
                            SizedBox(height: 12.h),
                            ...entry.value.map(
                              (notification) => Padding(
                                padding: EdgeInsets.only(bottom: 6.h),
                                child: NotificationCard(
                                  notification: notification,
                                  onTap: () => _handleNotificationTap(
                                    notification,
                                    provider,
                                  ),
                                  onMarkAsRead: () =>
                                      provider.markAsRead(notification.id),
                                  onDelete: () => provider.deleteNotification(
                                    notification.id,
                                  ),
                                ),
                              ),
                            ),
                            if (index < grouped.length - 1)
                              SizedBox(height: 8.h),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: context.separatorColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              LucideIcons.arrowRight,
              color: AppTheme.goldColor,
              size: 24.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'اعلان‌ها',
              style: GoogleFonts.vazirmatn(
                color: context.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.moreVertical,
                  color: AppTheme.goldColor,
                  size: 22.sp,
                ),
                color: context.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all',
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          LucideIcons.checkCheck,
                          size: 18.sp,
                          color: context.textColor,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'علامت‌گذاری همه',
                          style: GoogleFonts.vazirmatn(
                            color: context.textColor,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_read',
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          LucideIcons.trash2,
                          size: 18.sp,
                          color: AppTheme.errorColor,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'حذف خوانده شده‌ها',
                          style: GoogleFonts.vazirmatn(
                            color: AppTheme.errorColor,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          LucideIcons.settings,
                          size: 18.sp,
                          color: context.textColor,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'تنظیمات',
                          style: GoogleFonts.vazirmatn(
                            color: context.textColor,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'mark_all':
                      _confirmMarkAllAsRead(provider);
                      break;
                    case 'delete_read':
                      _confirmDeleteRead(provider);
                      break;
                    case 'settings':
                      Navigator.pushNamed(context, '/notification-settings');
                      break;
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isSearchExpanded ? 56.h : 0,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: _isSearchExpanded
          ? TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.vazirmatn(
                color: context.textColor,
                fontSize: 14.sp,
              ),
              decoration: InputDecoration(
                hintText: 'جستجو در اعلان‌ها...',
                hintStyle: GoogleFonts.vazirmatn(
                  color: context.textSecondary,
                  fontSize: 14.sp,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: context.textSecondary,
                    size: 20.sp,
                  ),
                  onPressed: () {
                    _searchDebounce?.cancel();
                    setState(() {
                      _isSearchExpanded = false;
                      _searchController.clear();
                    });
                    context.read<NotificationProvider>().setSearchQuery('');
                  },
                ),
                filled: true,
                fillColor: context.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(color: AppTheme.goldColor, width: 2),
                ),
              ),
              // Search is handled by _onSearchChanged with debounce
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 56.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                // Search button (rightmost)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearchExpanded = !_isSearchExpanded;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: _isSearchExpanded
                          ? AppTheme.goldColor
                          : context.cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.search,
                      color: _isSearchExpanded
                          ? AppTheme.onGoldColor
                          : AppTheme.goldColor,
                      size: 18.sp,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // All filter (most important)
                NotificationFilterChip(
                  label: 'همه',
                  isSelected: provider.selectedFilter == null,
                  onTap: () => provider.setFilter(null),
                ),
                SizedBox(width: 8.w),
                // Unread filter
                NotificationFilterChip(
                  label: 'خوانده نشده',
                  isSelected: provider.showOnlyUnread,
                  icon: LucideIcons.bell,
                  onTap: () => provider.toggleShowOnlyUnread(),
                ),
                // Type filters - only show types that exist in notifications
                ..._getAvailableNotificationTypes(provider.notifications).map(
                  (type) => Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: NotificationFilterChip(
                      label: _getTypeLabel(type),
                      isSelected: provider.selectedFilter == type,
                      onTap: () => provider.setFilter(type),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// دریافت انواع اعلان‌های موجود در لیست (برای نمایش فیلترها)
  List<NotificationType> _getAvailableNotificationTypes(
    List<NotificationItem> notifications,
  ) {
    final availableTypes = <NotificationType>{};
    for (final notification in notifications) {
      availableTypes.add(notification.type);
    }

    // ترتیب استاندارد بر اساس اهمیت
    final orderedTypes = [
      NotificationType.message,
      NotificationType.workout,
      NotificationType.achievement,
      NotificationType.payment,
      NotificationType.reminder,
      NotificationType.welcome,
      NotificationType.system,
    ];

    // فقط انواع موجود را برگردان
    return orderedTypes.where((type) => availableTypes.contains(type)).toList();
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.welcome:
        return 'خوش‌آمدگویی';
      case NotificationType.workout:
        return 'تمرین';
      case NotificationType.reminder:
        return 'یادآوری';
      case NotificationType.achievement:
        return 'دستاورد';
      case NotificationType.message:
        return 'پیام';
      case NotificationType.payment:
        return 'پرداخت';
      case NotificationType.system:
        return 'سیستم';
    }
  }

  Map<String, List<NotificationItem>> _groupNotifications(
    List<NotificationItem> notifications,
  ) {
    final Map<String, List<NotificationItem>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final notification in notifications) {
      final notificationDate = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );
      final difference = today.difference(notificationDate).inDays;

      String key;
      if (difference == 0) {
        key = 'امروز';
      } else if (difference == 1) {
        key = 'دیروز';
      } else if (difference < 7) {
        key = 'این هفته';
      } else if (difference < 30) {
        key = 'این ماه';
      } else {
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
        key =
            '${notification.timestamp.day} ${persianMonths[notification.timestamp.month]} ${notification.timestamp.year}';
      }

      grouped.putIfAbsent(key, () => []).add(notification);
    }

    return grouped;
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: context.separatorColor.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              date,
              style: GoogleFonts.vazirmatn(
                color: context.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: context.separatorColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: AppTheme.goldColor,
        strokeWidth: 3.w,
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.goldColor,
          strokeWidth: 2.w,
        ),
      ),
    );
  }

  Widget _buildErrorState(NotificationProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 64.sp,
              color: AppTheme.errorColor.withValues(alpha: 0.7),
            ),
            SizedBox(height: 24.h),
            Text(
              'خطا در بارگذاری اعلان‌ها',
              style: GoogleFonts.vazirmatn(
                color: context.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              provider.errorMessage ?? 'لطفاً دوباره تلاش کنید',
              style: GoogleFonts.vazirmatn(
                color: context.textSecondary,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => provider.loadNotifications(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.onGoldColor,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'تلاش مجدد',
                style: GoogleFonts.vazirmatn(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    bool hasFilters = false,
    VoidCallback? onClearFilters,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? LucideIcons.filterX : LucideIcons.bellOff,
              size: 72.sp,
              color: AppTheme.goldColor.withValues(alpha: 0.4),
            ),
            SizedBox(height: 32.h),
            Text(
              hasFilters
                  ? 'هیچ اعلانی با این فیلترها پیدا نشد'
                  : 'هیچ اعلانی وجود ندارد',
              style: GoogleFonts.vazirmatn(
                color: context.textColor,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              hasFilters
                  ? 'لطفاً فیلترها را تغییر دهید یا پاک کنید'
                  : 'وقتی اعلان جدیدی دریافت کنید،\nاینجا نمایش داده می‌شود',
              style: GoogleFonts.vazirmatn(
                color: context.textSecondary,
                fontSize: 15.sp,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters && onClearFilters != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: onClearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: AppTheme.onGoldColor,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'پاک کردن فیلترها',
                  style: GoogleFonts.vazirmatn(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(
    NotificationItem notification,
    NotificationProvider provider,
  ) {
    // علامت‌گذاری به عنوان خوانده شده
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Navigation بر اساس نوع و داده‌های نوتیفیکیشن
    _navigateBasedOnNotification(notification);
  }

  /// Navigation هوشمند بر اساس نوع و داده‌های نوتیفیکیشن
  void _navigateBasedOnNotification(NotificationItem notification) {
    if (!mounted) return;

    try {
      // اولویت 1: استفاده از actionUrl اگر وجود داشته باشد
      if (notification.actionUrl != null &&
          notification.actionUrl!.isNotEmpty) {
        _safeNavigate(notification.actionUrl!);
        return;
      }

      // اولویت 2: Navigation بر اساس نوع نوتیفیکیشن و data
      final data = notification.data;
      switch (notification.type) {
        case NotificationType.message:
          // Navigation به صفحه چت
          final peerId = data['peer_id']?.toString() ??
              data['sender_id']?.toString();
          final peerName = data['peer_name']?.toString() ??
              data['sender_name']?.toString() ??
              'کاربر';
          final conversationId = data['conversation_id']?.toString();

          if (peerId != null && peerId.isNotEmpty) {
            _safeNavigate(
              '/chat',
              arguments: {
                'otherUserId': peerId,
                'otherUserName': peerName,
                if (conversationId != null) 'conversationId': conversationId,
              },
            );
          }
          break;

        case NotificationType.payment:
          // Navigation به صفحه پرداخت یا داشبورد
          final route = data['route']?.toString();
          if (route != null && route.isNotEmpty) {
            _safeNavigate(route);
          } else {
            _safeNavigate('/dashboard');
          }
          break;

        case NotificationType.workout:
          // Navigation به صفحه تمرین
          final workoutId = data['workout_id']?.toString();
          final programId = data['program_id']?.toString();

          if (workoutId != null && workoutId.isNotEmpty) {
            _safeNavigate(
              '/workout-detail',
              arguments: {'workoutId': workoutId},
            );
          } else if (programId != null && programId.isNotEmpty) {
            _safeNavigate(
              '/workout-program',
              arguments: {'programId': programId},
            );
          } else {
            _safeNavigate('/workouts');
          }
          break;

        case NotificationType.achievement:
          // Navigation به صفحه دستاوردها
          final achievementId = data['achievement_id']?.toString();
          if (achievementId != null && achievementId.isNotEmpty) {
            _safeNavigate(
              '/achievements',
              arguments: {'achievementId': achievementId},
            );
          } else {
            _safeNavigate('/achievements');
          }
          break;

        case NotificationType.reminder:
          // Navigation به صفحه مربوطه بر اساس data
          final reminderType = data['reminder_type']?.toString();
          if (reminderType == 'workout') {
            _safeNavigate('/workouts');
          } else if (reminderType == 'meal') {
            _safeNavigate('/meal-plan');
          } else {
            _safeNavigate('/dashboard');
          }
          break;

        case NotificationType.welcome:
        case NotificationType.system:
          // برای انواع دیگر، به داشبورد برو
          _safeNavigate('/dashboard');
          break;
      }
    } catch (e) {
      debugPrint('❌ Error navigating from notification: $e');
      _safeNavigate('/dashboard');
    }
  }

  /// Navigation ایمن با error handling
  void _safeNavigate(String route, {Map<String, dynamic>? arguments}) {
    if (!mounted) return;

    try {
      Navigator.pushNamed(context, route, arguments: arguments);
    } catch (e) {
      debugPrint('❌ Navigation error to $route: $e');
      // تلاش برای بازگشت به داشبورد
      try {
        if (mounted && route != '/dashboard') {
          Navigator.pushNamed(context, '/dashboard');
        }
      } catch (_) {
        // اگر navigation هم خطا داد، هیچ کاری نکن
      }
    }
  }

  Future<void> _confirmMarkAllAsRead(NotificationProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            width: 1.5.w,
          ),
        ),
        title: Text(
          'علامت‌گذاری همه',
          style: GoogleFonts.vazirmatn(
            color: context.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید تمام اعلان‌ها را به عنوان خوانده شده علامت‌گذاری کنید؟',
          style: GoogleFonts.vazirmatn(
            color: context.textSecondary,
            fontSize: 14.sp,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'انصراف',
              style: GoogleFonts.vazirmatn(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'تایید',
              style: GoogleFonts.vazirmatn(
                color: AppTheme.goldColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final count = await provider.markAllAsRead();
      if (mounted && count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$count اعلان به عنوان خوانده شده علامت‌گذاری شد',
              style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.goldColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteRead(NotificationProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            width: 1.5.w,
          ),
        ),
        title: Text(
          'حذف اعلان‌های خوانده شده',
          style: GoogleFonts.vazirmatn(
            color: context.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید تمام اعلان‌های خوانده شده را حذف کنید؟',
          style: GoogleFonts.vazirmatn(
            color: context.textSecondary,
            fontSize: 14.sp,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'انصراف',
              style: GoogleFonts.vazirmatn(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'حذف',
              style: GoogleFonts.vazirmatn(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final count = await provider.deleteReadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 0
                  ? '$count اعلان خوانده شده حذف شد'
                  : 'هیچ اعلان خوانده شده‌ای برای حذف وجود ندارد',
              style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w600),
            ),
            backgroundColor: count > 0
                ? AppTheme.goldColor
                : AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    }
  }
}
