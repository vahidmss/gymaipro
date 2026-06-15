import 'package:gymaipro/widgets/gymai_trainer_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:gymaipro/workout_log/widgets/session_heatmap_trainer_chip.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
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

  @override
  void didUpdateWidget(WorkoutTrainerSupervisionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programId != widget.programId) {
      setState(() {
        _trainerInfo = null;
        _isLoading = true;
      });
      _loadTrainerInfo();
    }
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
        final trainerProfile =
            await ProfileRepository.instance.fetchProfile(targetTrainerId);

        if (trainerProfile != null && mounted) {
          setState(() {
            _trainerInfo = trainerProfile;
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
        color: WorkoutLogColors.sectionBackground(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: WorkoutLogColors.chipBorder(context, selected: false),
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
                    color: WorkoutLogColors.chipBorder(
                      context,
                      selected: true,
                    ),
                    width: 1.5.w,
                  ),
                ),
                child: GymaiTrainerAvatar(
                  size: 48.w,
                  avatarUrl: _trainerInfo?['avatar_url'] as String?,
                  userId: _trainerInfo?['id'] as String?,
                  username: _trainerInfo?['username'] as String?,
                  firstName: _trainerInfo?['first_name'] as String?,
                  lastName: _trainerInfo?['last_name'] as String?,
                  fallback: Icon(
                    LucideIcons.user,
                    color: WorkoutLogColors.iconOnSurface(context),
                    size: 24.sp,
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
                      style: WorkoutLogTypography.trainerLabel(context),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getTrainerName(),
                      style: WorkoutLogTypography.trainerName(context),
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
              'امروز میخوای کدوم روز برنامه رو اجرا کنی؟',
              style: WorkoutLogTypography.sectionTitle(context),
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
                        onTap: widget.sessionsLocked
                            ? null
                            : () => widget.onSessionSelected(session),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: WorkoutLogColors.chipFill(
                                context,
                                selected: isSelected,
                              ).withValues(
                                alpha: widget.sessionsLocked && !isSelected
                                    ? 0.65
                                    : 1,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: WorkoutLogColors.chipBorder(
                                  context,
                                  selected: isSelected,
                                ),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.sessionsLocked && isSelected)
                                  Padding(
                                    padding: EdgeInsets.only(left: 5.w),
                                    child: SizedBox(
                                      width: 10.w,
                                      height: 10.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5.w,
                                        color: WorkoutLogColors.iconOnSurface(context),
                                      ),
                                    ),
                                  ),
                                Text(
                                  session.day,
                                  style: WorkoutLogTypography.chip(
                                    context,
                                    selected: isSelected,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
              
                },
              ),
            ),
            if (widget.selectedSession != null &&
                widget.viewModel != null &&
                widget.onSessionHeatmapTap != null) ...[
              SizedBox(height: 12.h),
              SessionHeatmapTrainerChip(
                viewModel: widget.viewModel!,
                onTap: widget.onSessionHeatmapTap!,
              ),
            ],
            // نمایش کامنت روز (اگر وجود داشته باشد)
            if (widget.selectedSession != null &&
                widget.selectedSession!.notes != null &&
                widget.selectedSession!.notes!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _buildDayComment(context),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDayComment(BuildContext context) {
    if (widget.selectedSession == null ||
        widget.selectedSession!.notes == null ||
        widget.selectedSession!.notes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: WorkoutLogColors.noteBackground(context),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: WorkoutLogColors.noteBorder(context),
          width: 0.8.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.messageCircle,
            color: WorkoutLogColors.noteText(context),
            size: 14.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              widget.selectedSession!.notes!,
              style: WorkoutLogTypography.note(context).copyWith(fontSize: 12.5.sp),
            ),
          ),
        ],
      ),
    );
  }
}
