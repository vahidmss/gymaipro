import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/my_club/services/my_club_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RecentActivitiesWidget extends StatefulWidget {
  const RecentActivitiesWidget({super.key});

  @override
  State<RecentActivitiesWidget> createState() => _RecentActivitiesWidgetState();
}

class _RecentActivitiesWidgetState extends State<RecentActivitiesWidget> {
  final MyClubService _clubService = MyClubService();
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFromCacheThenFetch();
  }

  Future<void> _loadFromCacheThenFetch() async {
    final cached = await CacheService.getJsonList('recent_activities_cache');
    if (cached != null) {
      final activities = cached
          .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
          .toList();
      SafeSetState.call(this, () {
        _activities = activities;
        _isLoading = false;
      });
    }
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _clubService.getRecentActivities();
      SafeSetState.call(this, () {
        _activities = activities;
        _isLoading = false;
      });
      await CacheService.setJson('recent_activities_cache', activities);
    } catch (e) {
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200.h,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.goldColor),
        ),
      );
    }

    if (_activities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[600]!),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.activity, size: 48.sp, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              'هنوز فعالیتی ندارید',
              style: GoogleFonts.vazirmatn(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'با مربی‌ها و دوستان خود شروع کنید',
              style: GoogleFonts.vazirmatn(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
                Icon(
                  LucideIcons.activity,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
                const SizedBox(width: 8),
                Text(
                  'فعالیت‌های اخیر',
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
            itemCount: _activities.length > 5 ? 5 : _activities.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.grey[700], height: 1),
            itemBuilder: (context, index) {
              final activity = _activities[index];
              return _ActivityItem(
                activity: activity,
                onTap: () => _handleActivityTap(activity),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleActivityTap(Map<String, dynamic> activity) {
    // Handle activity tap based on type
    switch (activity['type']) {
      case 'program':
        Navigator.pushNamed(context, '/my-programs');
      case 'trainer':
        Navigator.pushNamed(context, '/my-club');
      case 'friend':
        Navigator.pushNamed(context, '/my-club');
    }
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.activity, required this.onTap});
  final Map<String, dynamic> activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(
      activity['created_at']?.toString() ?? '',
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
                color: _getActivityColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: _getActivityColor().withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                _getActivityIcon(),
                color: _getActivityColor(),
                size: 20.sp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (activity['title'] as String?) ?? '',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (activity['subtitle'] as String?) ?? '',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 12.sp,
                      color: Colors.grey[400],
                    ),
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

  IconData _getActivityIcon() {
    switch (activity['type']) {
      case 'program':
        return LucideIcons.clipboardList;
      case 'trainer':
        return LucideIcons.userCheck;
      case 'friend':
        return LucideIcons.userPlus;
      default:
        return LucideIcons.activity;
    }
  }

  Color _getActivityColor() {
    switch (activity['type']) {
      case 'program':
        return Colors.purple;
      case 'trainer':
        return Colors.green;
      case 'friend':
        return Colors.blue;
      default:
        return AppTheme.goldColor;
    }
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
