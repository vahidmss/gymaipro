import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WorkoutSessionSelector extends StatelessWidget {
  const WorkoutSessionSelector({
    required this.programs,
    required this.selectedProgram,
    required this.selectedSession,
    required this.onProgramSelected,
    required this.onSessionSelected,
    super.key,
  });
  final List<WorkoutProgram> programs;
  final WorkoutProgram? selectedProgram;
  final WorkoutSession? selectedSession;
  final Function(WorkoutProgram?) onProgramSelected;
  final Function(WorkoutSession?) onSessionSelected;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (programs.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C1810), Color(0xFF3D2317)],
          ),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: Colors.amber[700]!.withValues(alpha: 0.3),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10.r,
              offset: Offset(0.w, 5.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.amber[700]?.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                LucideIcons.dumbbell,
                color: Colors.amber[700],
                size: 20.sp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'هیچ برنامه‌ای موجود نیست',
                style: TextStyle(
                  color: Colors.amber[100],
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (selectedProgram == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C1810), Color(0xFF3D2317)],
          ),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: Colors.amber[700]!.withValues(alpha: 0.3),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10.r,
              offset: Offset(0.w, 5.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        const Color(0xFFB8860B).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      width: 1.5.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        blurRadius: 8.r,
                        offset: Offset(0.w, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.dumbbell,
                    color: const Color(0xFFD4AF37),
                    size: 20.sp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'جلسه مورد نظر را انتخاب کنید',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedProgram!.sessions.length,
                itemBuilder: (context, index) {
                  final session = selectedProgram!.sessions[index];
                  final isSelected = selectedSession?.day == session.day;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () => onSessionSelected(session),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.2),
                                      const Color(
                                        0xFFB8860B,
                                      ).withValues(alpha: 0.1),
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.1),
                                      const Color(
                                        0xFFB8860B,
                                      ).withValues(alpha: 0.05),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD4AF37)
                                  : const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.3),
                              width: 1.5.w,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.2),
                                      blurRadius: 8.r,
                                      offset: Offset(0.w, 2.h),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            session.day,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFFD4AF37),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20.r,
            offset: Offset(0.w, 8.h),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.amber[700]?.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  LucideIcons.dumbbell,
                  color: Colors.amber[700],
                  size: 20.sp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'برنامه: ${selectedProgram!.name}',
                  style: TextStyle(
                    color: Colors.amber[100],
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedProgram!.sessions.length,
              itemBuilder: (context, index) {
                final session = selectedProgram!.sessions[index];
                final isSelected = selectedSession?.day == session.day;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () => onSessionSelected(session),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFD4AF37),
                                    Color(0xFFB8860B),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.1),
                                    const Color(
                                      0xFFB8860B,
                                    ).withValues(alpha: 0.05),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD4AF37)
                                : const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.3),
                            width: 1.5.w,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 8.r,
                                    offset: Offset(0.w, 4.h),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.1),
                                    blurRadius: 6.r,
                                    offset: Offset(0.w, 2.h),
                                  ),
                                ],
                        ),
                        child: Text(
                          session.day,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFD4AF37),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
