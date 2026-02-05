import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/exercise_sync_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// صفحه sync تمرین‌ها از WordPress به Supabase
class AdminExerciseSyncScreen extends StatefulWidget {
  const AdminExerciseSyncScreen({super.key});

  @override
  State<AdminExerciseSyncScreen> createState() => _AdminExerciseSyncScreenState();
}

class _AdminExerciseSyncScreenState extends State<AdminExerciseSyncScreen> {
  final ExerciseSyncService _syncService = ExerciseSyncService();
  bool _isLoading = false;
  bool _isLoadingCounts = true;
  int _wordpressCount = 0;
  int _supabaseCount = 0;
  String? _lastSyncMessage;
  SyncResult? _lastSyncResult;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoadingCounts = true);
    try {
      final wpCount = await _syncService.getWordPressExerciseCount();
      final sbCount = await _syncService.getSupabaseExerciseCount();
      setState(() {
        _wordpressCount = wpCount;
        _supabaseCount = sbCount;
        _isLoadingCounts = false;
      });
    } catch (e) {
      setState(() => _isLoadingCounts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در دریافت تعداد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncExercises() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _lastSyncMessage = null;
      _lastSyncResult = null;
    });

    try {
      final result = await _syncService.syncExercises(
        onProgress: (current, total, exerciseName) {
          if (mounted) {
            setState(() {
              _lastSyncMessage = 'در حال sync: $exerciseName ($current/$total)';
            });
          }
        },
      );

      setState(() {
        _isLoading = false;
        _lastSyncResult = result;
        _lastSyncMessage = result.message;
      });

      // Refresh counts
      await _loadCounts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastSyncMessage = 'خطا: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در sync: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.refreshCw,
                          color: AppTheme.goldColor,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Sync تمرین‌ها',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'این بخش برای sync تمرین‌ها از WordPress به Supabase استفاده می‌شود. '
                      'پس از sync، تمام تمرین‌ها در Supabase ذخیره می‌شوند و اپ فقط از Supabase استفاده می‌کند.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Counts
            if (_isLoadingCounts)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: _buildCountCard(
                      isDark,
                      'WordPress',
                      _wordpressCount,
                      LucideIcons.globe,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildCountCard(
                      isDark,
                      'Supabase',
                      _supabaseCount,
                      LucideIcons.database,
                      AppTheme.goldColor,
                    ),
                  ),
                ],
              ),

            SizedBox(height: 24.h),

            // Sync Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _syncExercises,
              icon: _isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Icon(LucideIcons.refreshCw, size: 20.sp),
              label: Text(
                _isLoading ? 'در حال sync...' : 'شروع Sync',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),

            // Progress Message
            if (_lastSyncMessage != null) ...[
              SizedBox(height: 16.h),
              Card(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isLoading
                                ? LucideIcons.loader
                                : (_lastSyncResult?.success ?? false
                                    ? LucideIcons.checkCircle
                                    : LucideIcons.alertCircle),
                            color: _isLoading
                                ? AppTheme.goldColor
                                : (_lastSyncResult?.success ?? false
                                    ? Colors.green
                                    : Colors.orange),
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _isLoading ? 'در حال sync...' : 'نتیجه Sync',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _lastSyncMessage!,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14.sp,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      if (_lastSyncResult != null) ...[
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            _buildStatChip(
                              isDark,
                              'موفق',
                              '${_lastSyncResult!.syncedCount}',
                              Colors.green,
                            ),
                            SizedBox(width: 8.w),
                            if (_lastSyncResult!.failedCount > 0)
                              _buildStatChip(
                                isDark,
                                'ناموفق',
                                '${_lastSyncResult!.failedCount}',
                                Colors.red,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 16.h),

            // Info Card
            Card(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      color: Colors.blue,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'توجه: این عملیات ممکن است چند دقیقه طول بکشد. لطفاً صبور باشید.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.sp,
                          color: isDark ? Colors.grey[300] : Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard(
    bool isDark,
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'تمرین',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(bool isDark, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              color: color,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

