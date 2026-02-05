import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerSupervisionCard extends StatefulWidget {
  const TrainerSupervisionCard({
    required this.mealPlanId,
    required this.selectedPlan,
    required this.selectedSession,
    required this.onSessionSelected,
    super.key,
  });

  final String mealPlanId;
  final MealPlan? selectedPlan;
  final int? selectedSession;
  final void Function(int) onSessionSelected;

  @override
  State<TrainerSupervisionCard> createState() => _TrainerSupervisionCardState();
}

class _TrainerSupervisionCardState extends State<TrainerSupervisionCard> {
  Map<String, dynamic>? _trainerInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainerInfo();
  }

  Future<void> _loadTrainerInfo() async {
    try {
      debugPrint('=== شروع بارگذاری اطلاعات مربی ===');
      debugPrint('Meal Plan ID: ${widget.mealPlanId}');

      // خواندن اطلاعات meal plan از دیتابیس برای گرفتن trainer_id
      final client = Supabase.instance.client;
      Map<String, dynamic>? response;
      
      try {
        final result = await client
            .from('meal_plans')
            .select('trainer_id, user_id')
            .eq('id', widget.mealPlanId)
            .maybeSingle();
        response = result != null ? Map<String, dynamic>.from(result as Map) : null;
      } catch (e) {
        // اگر ستون trainer_id وجود نداشت، بدون آن بخوانیم
        debugPrint('خطا در خواندن meal plan با trainer_id: $e');
        try {
          final result = await client
              .from('meal_plans')
              .select('user_id')
              .eq('id', widget.mealPlanId)
              .maybeSingle();
          response = result != null ? Map<String, dynamic>.from(result as Map) : null;
        } catch (e2) {
          debugPrint('خطا در خواندن meal plan: $e2');
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      if (response == null) {
        debugPrint('meal plan یافت نشد');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final trainerId = response['trainer_id'] as String?;
      final userId = response['user_id'] as String?;
      
      debugPrint('Trainer ID: $trainerId');
      debugPrint('User ID: $userId');

      // تعیین ID سازنده برنامه (مربی)
      // اگر trainer_id وجود دارد، از آن استفاده می‌کنیم (مربی برنامه را نوشته)
      // اگر trainer_id null است، از user_id استفاده می‌کنیم (خود کاربر برنامه را نوشته)
      String? targetTrainerId = trainerId ?? userId;

      if (targetTrainerId != null && targetTrainerId.isNotEmpty) {
        debugPrint('در حال خواندن پروفایل مربی با ID: $targetTrainerId');
        final trainerProfile = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .eq('id', targetTrainerId)
            .maybeSingle();

        if (trainerProfile != null && mounted) {
          debugPrint('اطلاعات مربی بارگذاری شد: ${trainerProfile['first_name']} ${trainerProfile['last_name']}');
          setState(() {
            _trainerInfo = Map<String, dynamic>.from(trainerProfile as Map);
            _isLoading = false;
          });
        } else {
          debugPrint('پروفایل مربی یافت نشد');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        debugPrint('trainer_id یافت نشد');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('خطا در بارگذاری اطلاعات مربی: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTrainerName() {
    if (_trainerInfo == null) return 'مربی شما';
    final first = _trainerInfo!['first_name'] as String? ?? '';
    final last = _trainerInfo!['last_name'] as String? ?? '';
    final username = _trainerInfo!['username'] as String? ?? '';
    
    if ((first + last).trim().isNotEmpty) {
      return '$first $last'.trim();
    } else if (username.isNotEmpty) {
      return username;
    }
    return 'مربی شما';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // استفاده از MediaQuery برای اندازه واقعی صفحه
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        // محاسبه responsive margin و padding بر اساس اندازه واقعی
        final bottomMargin = screenWidth > 600 ? 20.0 : 16.0;
        final containerMargin = EdgeInsets.only(bottom: bottomMargin);
        
        final containerPadding = screenWidth > 600 ? 24.0 : 20.0;
        final borderRadius = screenWidth > 600 ? 20.0 : 16.0;
        
        if (_isLoading) {
          return Container(
            margin: containerMargin,
            padding: EdgeInsets.all(containerPadding),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            width: 1.5.w,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.goldColor,
            strokeWidth: 2.w,
          ),
        ),
          );
        }

        return Container(
          margin: containerMargin,
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      context.cardColor,
                      context.backgroundColor.withValues(alpha: 0.8),
                      context.cardColor,
                    ]
                  : [
                      AppTheme.goldColor.withValues(alpha: 0.15),
                      context.cardColor,
                      AppTheme.goldColor.withValues(alpha: 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : AppTheme.lightTextColor.withValues(alpha: 0.08),
            blurRadius: 20.r,
            offset: Offset(0.w, 8.h),
          ),
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
            blurRadius: 10.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بخش مربی
          Row(
            children: [
              // عکس مربی
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.5),
                    width: 2.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.2),
                      blurRadius: 8.r,
                      offset: Offset(0.w, 2.h),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _trainerInfo?['avatar_url'] != null &&
                          (_trainerInfo!['avatar_url'] as String).isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _trainerInfo!['avatar_url'] as String,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.goldColor.withValues(alpha: 0.1),
                            child: Icon(
                              LucideIcons.user,
                              color: AppTheme.goldColor,
                              size: 30.sp,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.goldColor.withValues(alpha: 0.1),
                            child: Icon(
                              LucideIcons.user,
                              color: AppTheme.goldColor,
                              size: 30.sp,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.goldColor.withValues(alpha: 0.1),
                          child: Icon(
                            LucideIcons.user,
                            color: AppTheme.goldColor,
                            size: 30.sp,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحت نظارت مربی',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark
                            ? AppTheme.goldColor
                            : AppTheme.darkGold,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _getTrainerName(),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // بخش انتخاب روز
          if (widget.selectedPlan != null) ...[
            SizedBox(height: 20.h),
            Divider(
              color: AppTheme.goldColor.withValues(alpha: 0.2),
              thickness: 1,
            ),
            SizedBox(height: 16.h),
            Text(
              'امروز میخوای کدوم روز برنامه رو اجرا کنی!؟',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark
                    ? AppTheme.goldColor
                    : AppTheme.darkGold,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                height: 1.4,
                letterSpacing: 0.1,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 40.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.selectedPlan!.days.length,
                itemBuilder: (context, index) {
                  final isSelected = widget.selectedSession == index;
                  return Container(
                    margin: EdgeInsets.only(left: 8.w),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () => widget.onSessionSelected(index),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? [
                                            AppTheme.goldColor.withValues(
                                              alpha: 0.25,
                                            ),
                                            AppTheme.darkGold.withValues(
                                              alpha: 0.15,
                                            ),
                                          ]
                                        : [
                                            AppTheme.goldColor.withValues(
                                              alpha: 0.3,
                                            ),
                                            AppTheme.lightGradientEnd
                                                .withValues(alpha: 0.2),
                                          ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.goldColor.withValues(alpha: 0.1),
                                      AppTheme.darkGold.withValues(alpha: 0.05),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                      ? AppTheme.goldColor
                                      : AppTheme.darkGold)
                                  : AppTheme.goldColor.withValues(alpha: 0.3),
                              width: isSelected ? 2.w : 1.5.w,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.goldColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8.r,
                                      offset: Offset(0.w, 2.h),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            'روز ${index + 1}',
                            style: TextStyle(
                              color: isSelected
                                  ? (isDark
                                      ? AppTheme.onGoldColor
                                      : AppTheme.lightTextColor)
                                  : (isDark
                                      ? AppTheme.goldColor
                                      : AppTheme.darkGold),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppTheme.fontFamily,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // نمایش کامنت روز (اگر وجود داشته باشد)
            if (widget.selectedSession != null) ...[
              const SizedBox(height: 16),
              _buildDayComment(isDark),
            ],
          ],
        ],
      ),
        );
      },
    );
  }

  Widget _buildDayComment(bool isDark) {
    if (widget.selectedPlan == null || widget.selectedSession == null) {
      return const SizedBox.shrink();
    }

    try {
      final planDay = widget.selectedPlan!.days.firstWhere(
        (d) => d.dayOfWeek == widget.selectedSession,
      );

      if (planDay.comment == null || planDay.comment!.isEmpty) {
        return const SizedBox.shrink();
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.messageCircle,
            color: AppTheme.goldColor,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              planDay.comment!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark
                    ? AppTheme.goldColor.withValues(alpha: 0.9)
                    : AppTheme.lightTextColor,
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}

