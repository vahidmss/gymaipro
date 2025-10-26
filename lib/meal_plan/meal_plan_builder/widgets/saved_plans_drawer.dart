import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SavedPlansDrawerMealPlanBuilder extends StatelessWidget {
  const SavedPlansDrawerMealPlanBuilder({
    required this.savedPlans,
    required this.onSelect,
    required this.onDelete,
    required this.onNewPlan,
    required this.onClose,
    super.key,
  });
  final List<MealPlan> savedPlans;
  final void Function(MealPlan) onSelect;
  final void Function(String) onDelete;
  final VoidCallback onNewPlan;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 320.w,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.horizontal(left: Radius.circular(20.r)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18.r,
              offset: const Offset(-8, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'برنامه‌های ذخیره‌شده',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(
                            0xFFD4AF37,
                          ).withValues(alpha: 0.35),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: const Color(0xFFD4AF37),
                          size: 20.sp,
                        ),
                        onPressed: onClose,
                        tooltip: 'بستن',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: savedPlans.isEmpty
                    ? Center(
                        child: Text(
                          'برنامه‌ای ذخیره نشده',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(12.w, 0.h, 12.w, 0.h),
                        itemCount: savedPlans.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withValues(alpha: 0.06),
                          height: 12.h,
                          thickness: 0.8,
                        ),
                        itemBuilder: (context, idx) {
                          final plan = savedPlans[idx];
                          return Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1A1A1A), Color(0xFF161616)],
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: const Color(
                                  0xFFD4AF37,
                                ).withValues(alpha: 0.15),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10.r,
                                  offset: Offset(0.w, 3.h),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              title: Text(
                                plan.planName.isEmpty
                                    ? 'بدون نام'
                                    : plan.planName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                'تاریخ: ${plan.createdAt.toString().substring(0, 10)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12.sp,
                                ),
                              ),
                              onTap: () => onSelect(plan),
                              trailing: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red,
                                    size: 18.sp,
                                  ),
                                  onPressed: () => onDelete(plan.id),
                                  tooltip: 'حذف',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(
                      LucideIcons.plus,
                      color: const Color(0xFFD4AF37),
                      size: 18.sp,
                    ),
                    label: Text(
                      'برنامه جدید',
                      style: TextStyle(
                        color: const Color(0xFFD4AF37),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: const Color(0xFFD4AF37),
                        width: 1.2.w,
                      ),
                      foregroundColor: const Color(0xFFD4AF37),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 14.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    onPressed: onNewPlan,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
