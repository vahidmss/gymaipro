import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/notification/services/notification_data_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final notifications =
          await NotificationDataService.getUserNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'اعلان‌ها',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: AppTheme.goldColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck, color: AppTheme.goldColor),
            onPressed: _confirmMarkAllAsRead,
            tooltip: 'علامت‌گذاری همه به عنوان خوانده شده',
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppTheme.goldColor),
            onPressed: _deleteReadNotifications,
            tooltip: 'حذف اعلان‌های خوانده شده',
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings, color: AppTheme.goldColor),
            onPressed: () {
              Navigator.pushNamed(context, '/notification-settings');
            },
            tooltip: 'تنظیمات اعلان‌ها',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
          ? _buildErrorState()
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.goldColor),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 64.sp,
            color: Colors.red.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          Text(
            'خطا در بارگذاری اعلان‌ها',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.1),
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(
              LucideIcons.bell,
              size: 64.sp,
              color: AppTheme.goldColor.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'هیچ اعلانی وجود ندارد',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.1),
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'وقتی اعلان جدیدی دریافت کنید، اینجا نمایش داده می‌شود',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.1),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final isHighlighted = !notification.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppTheme.goldColor.withValues(alpha: 0.1)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isHighlighted
              ? AppTheme.goldColor.withValues(alpha: 0.1)
              : notification.isRead
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.goldColor.withValues(alpha: 0.1),
          width: isHighlighted ? 2 : (notification.isRead ? 1 : 2),
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? AppTheme.goldColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: isHighlighted ? 12 : 8,
            offset: Offset(0.w, 2.h),
            spreadRadius: isHighlighted ? 1 : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _handleNotificationTap(notification),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(
                      notification.type,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 20.sp,
                  ),
                ),
                const SizedBox(width: 12),
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: isHighlighted
                                    ? Colors.white
                                    : notification.isRead
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white,
                                fontSize: 16.sp,
                                fontWeight: isHighlighted
                                    ? FontWeight.bold
                                    : notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8.w,
                              height: 8.h,
                              decoration: const BoxDecoration(
                                color: AppTheme.goldColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: isHighlighted
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.1),
                          fontSize: 14.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: TextStyle(
                              color: isHighlighted
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.1),
                              fontSize: 12.sp,
                            ),
                          ),
                          if (notification.priority > 3) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                'مهم',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.welcome:
        return AppTheme.goldColor;
      case NotificationType.workout:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.achievement:
        return Colors.purple;
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.payment:
        return Colors.amber;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.welcome:
        return LucideIcons.userPlus;
      case NotificationType.workout:
        return LucideIcons.dumbbell;
      case NotificationType.reminder:
        return LucideIcons.clock;
      case NotificationType.achievement:
        return LucideIcons.trophy;
      case NotificationType.message:
        return LucideIcons.messageCircle;
      case NotificationType.payment:
        return LucideIcons.creditCard;
      case NotificationType.system:
        return LucideIcons.settings;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'همین الان';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} دقیقه پیش';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    // فقط اعلان را به عنوان خوانده شده علامت‌گذاری کن
    if (!notification.isRead) {
      _markAsRead(notification);
    }

    // Handle action URL if available
    if (notification.actionUrl != null && notification.actionUrl!.isNotEmpty) {
      // Navigate to the action URL
      Navigator.pushNamed(context, notification.actionUrl!);
    }
  }

  Future<void> _confirmMarkAllAsRead() async {
    // نمایش دیالوگ تایید
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'علامت‌گذاری همه اعلان‌ها',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید تمام اعلان‌ها را به عنوان خوانده شده علامت‌گذاری کنید؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'تایید',
              style: TextStyle(color: AppTheme.goldColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    try {
      final count = await NotificationDataService.markAllAsRead();
      if (count > 0) {
        if (!mounted) return;

        setState(() {
          for (final notification in _notifications) {
            notification.isRead = true;
          }
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count اعلان به عنوان خوانده شده علامت‌گذاری شد'),
            backgroundColor: AppTheme.goldColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در علامت‌گذاری اعلان‌ها'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (notification.isRead) return;

    try {
      final success = await NotificationDataService.markAsRead(notification.id);
      if (success) {
        if (!mounted) return;

        setState(() {
          notification.isRead = true;
        });
      }
    } catch (e) {
      if (!mounted) return;

      // Show error message if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در به‌روزرسانی اعلان'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteReadNotifications() async {
    // نمایش دیالوگ تایید
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'حذف اعلان‌های خوانده شده',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید تمام اعلان‌های خوانده شده را حذف کنید؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final deletedCount =
          await NotificationDataService.deleteReadNotifications();
      if (deletedCount > 0) {
        // به‌روزرسانی لیست اعلان‌ها
        await _loadNotifications();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deletedCount اعلان خوانده شده حذف شد'),
            backgroundColor: AppTheme.goldColor,
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هیچ اعلان خوانده شده‌ای برای حذف وجود ندارد'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در حذف اعلان‌ها'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
