import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutTrainerSupervisionCard extends StatefulWidget {
  const WorkoutTrainerSupervisionCard({
    required this.programId,
    required this.selectedProgram,
    required this.selectedSession,
    required this.onSessionSelected,
    super.key,
    this.viewModel,
    this.onSessionHeatmapTap,
    this.sessionsLocked = false,
  });

  final String programId;
  final WorkoutProgram? selectedProgram;
  final WorkoutSession? selectedSession;
  final void Function(WorkoutSession?) onSessionSelected;
  final WorkoutLogViewModel? viewModel;
  final VoidCallback? onSessionHeatmapTap;
  final bool sessionsLocked;

  @override
  State<WorkoutTrainerSupervisionCard> createState() =>
      _WorkoutTrainerSupervisionCardState();
}

class _WorkoutTrainerSupervisionCardState
    extends State<WorkoutTrainerSupervisionCard> {
  Map<String, dynamic>? _trainerInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainerInfo();
  }

  Future<void> _loadTrainerInfo() async {
    try {
      final client = Supabase.instance.client;
      Map<String, dynamic>? response;

      try {
        final result = await client
            .from('workout_programs')
            .select('trainer_id, user_id')
            .eq('id', widget.programId)
            .maybeSingle();
        response = result != null
            ? Map<String, dynamic>.from(result as Map)
            : null;
      } catch (e) {
        try {
          final result = await client
              .from('workout_programs')
              .select('user_id')
              .eq('id', widget.programId)
              .maybeSingle();
          response = result != null
              ? Map<String, dynamic>.from(result as Map)
              : null;
        } catch (e2) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      if (response == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final trainerId = response['trainer_id'] as String?;
      final userId = response['user_id'] as String?;
      final targetTrainerId = trainerId ?? userId;

      if (targetTrainerId != null && targetTrainerId.isNotEmpty) {
        final trainerProfile = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .eq('id', targetTrainerId)
            .maybeSingle();

        if (trainerProfile != null && mounted) {
          setState(() {
            _trainerInfo = Map<String, dynamic>.from(trainerProfile as Map);
            _isLoading = false;
          });
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading trainer info: $e');
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

    if (_isLoading) {
      return Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16.r),
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
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? context.cardColor
            : AppTheme.goldColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.25),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بخش مربی
          Row(
            children: [
              // عکس مربی
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.4),
                    width: 1.5.w,
                  ),
                ),
                child: ClipOval(
                  child:
                      _trainerInfo?['avatar_url'] != null &&
                          (_trainerInfo!['avatar_url'] as String).isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _trainerInfo!['avatar_url'] as String,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.goldColor.withValues(alpha: 0.1),
                            child: Icon(
                              LucideIcons.user,
                              color: AppTheme.goldColor,
                              size: 24.sp,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.goldColor.withValues(alpha: 0.1),
                            child: Icon(
                              LucideIcons.user,
                              color: AppTheme.goldColor,
                              size: 24.sp,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.goldColor.withValues(alpha: 0.1),
                          child: Icon(
                            LucideIcons.user,
                            color: AppTheme.goldColor,
                            size: 24.sp,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحت نظارت مربی',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark ? AppTheme.goldColor : AppTheme.darkGold,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getTrainerName(),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor,
                        fontSize: 15.sp,
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
          if (widget.selectedProgram != null) ...[
            SizedBox(height: 16.h),
            Divider(
              color: AppTheme.goldColor.withValues(alpha: 0.15),
              thickness: 0.5,
            ),
            SizedBox(height: 12.h),
            Text(
              'امروز میخوای کدوم روز برنامه رو اجرا کنی!؟',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? AppTheme.goldColor : AppTheme.darkGold,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              height: 36.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.selectedProgram!.sessions.length,
                itemBuilder: (context, index) {
                  final session = widget.selectedProgram!.sessions[index];
                  final isSelected = widget.selectedSession?.day == session.day;
                  return Container(
                    margin: EdgeInsets.only(left: 8.w),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => widget.onSessionSelected(session),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.goldColor.withValues(
                                    alpha: isDark ? 0.25 : 0.2,
                                  )
                                : AppTheme.goldColor.withValues(
                                    alpha: isDark ? 0.1 : 0.08,
                                  ),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.goldColor.withValues(alpha: 0.5)
                                  : AppTheme.goldColor.withValues(alpha: 0.3),
                              width: 1.w,
                            ),
                          ),
                          child: Text(
                            session.day,
                            style: TextStyle(
                              color: isSelected
                                  ? (isDark
                                        ? AppTheme.goldColor
                                        : AppTheme.darkGold)
                                  : (isDark
                                        ? AppTheme.goldColor.withValues(
                                            alpha: 0.8,
                                          )
                                        : AppTheme.darkGold.withValues(
                                            alpha: 0.7,
                                          )),
                              fontSize: 12.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontFamily: AppTheme.fontFamily,
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
            if (widget.selectedSession != null &&
                widget.selectedSession!.notes != null &&
                widget.selectedSession!.notes!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _buildDayComment(isDark),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDayComment(bool isDark) {
    if (widget.selectedSession == null ||
        widget.selectedSession!.notes == null ||
        widget.selectedSession!.notes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber[700]!.withValues(alpha: 0.1)
            : Colors.amber[800]!.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isDark
              ? Colors.amber[700]!.withValues(alpha: 0.25)
              : Colors.amber[800]!.withValues(alpha: 0.4),
          width: 0.8.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.messageCircle,
            color: isDark ? Colors.amber[700] : Colors.amber[900],
            size: 14.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              widget.selectedSession!.notes!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? Colors.amber[700] : Colors.black87,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
