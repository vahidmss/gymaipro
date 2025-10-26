import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/my_club/services/my_club_service.dart';
import 'package:gymaipro/my_club/widgets/club_stats_widget.dart';
import 'package:gymaipro/my_club/widgets/recent_activities_widget.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MyClubOverviewScreen extends StatefulWidget {
  const MyClubOverviewScreen({super.key});

  @override
  State<MyClubOverviewScreen> createState() => _MyClubOverviewScreenState();
}

class _MyClubOverviewScreenState extends State<MyClubOverviewScreen>
    with AutomaticKeepAliveClientMixin<MyClubOverviewScreen> {
  final MyClubService _clubService = MyClubService();
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFromCacheThenFetch();
  }

  Future<void> _loadFromCacheThenFetch() async {
    // Load cached suggestions and notifications for instant render
    final cachedSuggestions = await CacheService.getJsonList(
      'club_overview_suggestions',
    );
    final cachedNotifications = await CacheService.getJsonList(
      'club_overview_notifications',
    );
    if (cachedSuggestions != null || cachedNotifications != null) {
      SafeSetState.call(this, () {
        if (cachedSuggestions != null) {
          _suggestions = cachedSuggestions
              .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
              .toList();
        }
        if (cachedNotifications != null) {
          _notifications = cachedNotifications
              .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
              .toList();
        }
        _isLoading = false;
      });
    }
    // Fetch latest in background
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading && _suggestions.isEmpty && _notifications.isEmpty) {
      SafeSetState.call(this, () => _isLoading = true);
    }
    try {
      final suggestions = await _clubService.getSuggestions();
      final notifications = await _clubService.getClubNotifications();

      SafeSetState.call(this, () {
        _suggestions = suggestions;
        _notifications = notifications;
        _isLoading = false;
      });
      await CacheService.setJson('club_overview_suggestions', suggestions);
      await CacheService.setJson('club_overview_notifications', notifications);
    } catch (e) {
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldColor),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.goldColor,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // آمار باشگاه
                    const ClubStatsWidget(),
                    const SizedBox(height: 20),

                    // فعالیت‌های اخیر
                    const RecentActivitiesWidget(),
                    const SizedBox(height: 20),

                    // پیشنهادات
                    if (_suggestions.isNotEmpty) ...[
                      _buildSuggestionsSection(),
                      const SizedBox(height: 20),
                    ],

                    // نوتیفیکیشن‌ها
                    if (_notifications.isNotEmpty) ...[
                      _buildNotificationsSection(),
                      const SizedBox(height: 20),
                    ],

                    // دکمه‌های سریع
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuggestionsSection() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                const Icon(LucideIcons.lightbulb, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'پیشنهادات',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggestions.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.grey[700], height: 1),
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return _SuggestionItem(
                suggestion: suggestion,
                onTap: () => _handleSuggestionTap(suggestion),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                const Icon(LucideIcons.bell, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'درخواست‌های جدید',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _notifications.length.toString(),
                    style: GoogleFonts.vazirmatn(
                      color: Colors.orange,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _notifications.length > 3 ? 3 : _notifications.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.grey[700], height: 1),
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return _NotificationItem(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
              );
            },
          ),
          if (_notifications.length > 3)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/my-club'),
                  child: Text(
                    'مشاهده همه درخواست‌ها',
                    style: GoogleFonts.vazirmatn(
                      color: AppTheme.goldColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(LucideIcons.zap, color: AppTheme.goldColor, size: 20.sp),
                const SizedBox(width: 8),
                Text(
                  'دسترسی سریع',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 16.h),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: LucideIcons.dumbbell,
                    label: 'برنامه‌ها',
                    onTap: () => Navigator.pushNamed(context, '/my-programs'),
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: LucideIcons.userCheck,
                    label: 'مربی‌ها',
                    onTap: () => Navigator.pushNamed(context, '/my-club'),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 16.h),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: LucideIcons.users,
                    label: 'دوستان',
                    onTap: () => Navigator.pushNamed(context, '/my-club'),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: LucideIcons.bell,
                    label: 'درخواست‌ها',
                    onTap: () => Navigator.pushNamed(context, '/my-club'),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSuggestionTap(Map<String, dynamic> suggestion) {
    switch (suggestion['action']) {
      case 'search_trainers':
        Navigator.pushNamed(context, '/trainers');
      case 'search_friends':
        Navigator.pushNamed(context, '/search-friends');
      case 'create_program':
        Navigator.pushNamed(context, '/workout-program-builder');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    Navigator.pushNamed(context, '/my-club');
  }

  @override
  bool get wantKeepAlive => true;
}

class _SuggestionItem extends StatelessWidget {
  const _SuggestionItem({required this.suggestion, required this.onTap});
  final Map<String, dynamic> suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
              ),
              child: Icon(
                LucideIcons.lightbulb,
                color: Colors.blue,
                size: 20.sp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (suggestion['title'] as String?) ?? '',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (suggestion['subtitle'] as String?) ?? '',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 12.sp,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.arrowLeft, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({required this.notification, required this.onTap});
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(
      notification['created_at']?.toString() ?? '',
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Icon(LucideIcons.bell, color: Colors.orange, size: 20.sp),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (notification['title'] as String?) ?? '',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (notification['subtitle'] as String?) ?? '',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 12.sp,
                      color: Colors.grey[400],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (createdAt != null)
              Text(
                _formatDate(createdAt),
                style: GoogleFonts.vazirmatn(
                  fontSize: 12.sp,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'امروز';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks هفته پیش';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ماه پیش';
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.vazirmatn(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
