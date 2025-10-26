import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/my_club/services/my_club_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClubStatsWidget extends StatefulWidget {
  const ClubStatsWidget({super.key});

  @override
  State<ClubStatsWidget> createState() => _ClubStatsWidgetState();
}

class _ClubStatsWidgetState extends State<ClubStatsWidget> {
  final MyClubService _clubService = MyClubService();
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFromCacheThenFetch();
  }

  Future<void> _loadFromCacheThenFetch() async {
    final cached = await CacheService.getJsonMap('club_stats_cache');
    if (cached != null) {
      SafeSetState.call(this, () {
        _stats = cached.map((k, v) => MapEntry(k, (v as num).toInt()));
        _isLoading = false;
      });
    }
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _clubService.getClubStats();
      SafeSetState.call(this, () {
        _stats = stats;
        _isLoading = false;
      });
      await CacheService.setJson('club_stats_cache', stats);
    } catch (e) {
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.goldColor),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.barChart3,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
              const SizedBox(width: 8),
              Text(
                'آمار باشگاه من',
                style: GoogleFonts.vazirmatn(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: LucideIcons.userCheck,
                  label: 'مربی‌ها',
                  value: _stats['active_trainers'] ?? 0,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  icon: LucideIcons.users,
                  label: 'دوستان',
                  value: _stats['friends'] ?? 0,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: LucideIcons.clipboardList,
                  label: 'برنامه‌ها',
                  value: _stats['programs'] ?? 0,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  icon: LucideIcons.bell,
                  label: 'درخواست‌ها',
                  value: _stats['total_requests'] ?? 0,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: GoogleFonts.vazirmatn(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.vazirmatn(
              fontSize: 12.sp,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
