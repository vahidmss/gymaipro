import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainersChatSection extends StatefulWidget {
  const TrainersChatSection({super.key});

  @override
  State<TrainersChatSection> createState() => _TrainersChatSectionState();
}

class _TrainersChatSectionState extends State<TrainersChatSection> {
  List<UserProfile> _trainers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // _supabaseService removed - not used
    unawaited(_loadTrainers());
  }

  Future<void> _loadTrainers() async {
    try {
      SafeSetState.call(this, () {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get all trainers (users with role = 'trainer')
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'trainer')
          .limit(10);

      final trainers = response.map(UserProfile.fromJson).toList();

      SafeSetState.call(this, () {
        _trainers = trainers;
        _isLoading = false;
      });
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _errorMessage = 'خطا در بارگیری مربیان';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 200.h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              width: 1.w,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.goldColor),
                SizedBox(height: 12),
                Text(
                  'در حال بارگیری مربیان...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 200.h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.2),
              width: 1.w,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  color: Colors.red.withValues(alpha: 0.5),
                  size: 32.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                ElevatedButton.icon(
                  onPressed: _loadTrainers,
                  icon: Icon(LucideIcons.refreshCw, size: 14.sp),
                  label: Text('تلاش مجدد', style: TextStyle(fontSize: 12.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_trainers.isEmpty) {
      return SizedBox(
        height: 200.h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              width: 1.w,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.users,
                  color: AppTheme.goldColor.withValues(alpha: 0.5),
                  size: 32.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  'هیچ مربی‌ای یافت نشد',
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.1),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          // Header
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.withValues(alpha: 0.1),
                  Colors.purple.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 4.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(
                        LucideIcons.users,
                        color: Colors.purple,
                        size: 18.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'مربیان قابل چت',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.purple.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      child: Text(
                        '${_trainers.length}',
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trainers List
          SizedBox(
            height: 140.h,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              scrollDirection: Axis.horizontal,
              itemCount: _trainers.length,
              itemBuilder: (context, index) {
                final trainer = _trainers[index];
                return _buildTrainerCard(trainer);
              },
            ),
          ),

          // Footer
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.info,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 14.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'برای شروع چت روی مربی کلیک کنید',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerCard(UserProfile trainer) {
    final isOnline =
        trainer.lastSeenAt != null &&
        DateTime.now().difference(trainer.lastSeenAt!).inMinutes < 5;

    return GestureDetector(
      onTap: () {
        unawaited(
          Navigator.of(context).pushNamed(
            '/chat',
            arguments: {
              'otherUserId': trainer.id,
              'otherUserName': trainer.firstName ?? 'مربی',
            },
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(right: 12.w),
        child: SizedBox(
          width: 120.w,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.3),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.1),
                  blurRadius: 8.r,
                  offset: Offset(0.w, 2.h),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 25.r,
                      backgroundColor: Colors.purple.withValues(alpha: 0.2),
                      child: Icon(
                        LucideIcons.user,
                        color: Colors.purple,
                        size: 25.sp,
                      ),
                    ),
                    // Online indicator
                    if (isOnline)
                      Positioned(
                        right: 0.w,
                        bottom: 0.h,
                        child: Container(
                          width: 12.r,
                          height: 12.r,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.backgroundColor,
                              width: 2.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 4.r,
                                offset: Offset(0.w, 1.h),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  trainer.firstName ?? 'مربی',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.messageCircle,
                        color: Colors.purple,
                        size: 10.sp,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'چت',
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                        ),
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
}
