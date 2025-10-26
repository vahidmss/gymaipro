import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

class SavedProgramsDrawer extends StatelessWidget {
  const SavedProgramsDrawer({
    required this.savedPrograms,
    required this.isLoading,
    required this.onSelect,
    required this.onCreateNew,
    required this.onClose,
    super.key,
  });
  final List<WorkoutProgram> savedPrograms;
  final bool isLoading;
  final void Function(String programId) onSelect;
  final VoidCallback onCreateNew;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.1),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 320.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0A0A),
                  Color(0xFF1A1A1A),
                  Color(0xFF2A2A2A),
                ],
              ),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(24.r),
              ),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20.r,
                  offset: const Offset(-6, 0),
                ),
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                  blurRadius: 10.r,
                  offset: const Offset(-3, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'برنامه‌های تمرینی ذخیره‌شده',
                          style: TextStyle(
                            color: Colors.amber[200],
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.amber[700]?.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.amber[700]!.withValues(alpha: 0.1),
                              width: 1.5.w,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(LucideIcons.x, color: Colors.amber[700]),
                            onPressed: onClose,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : savedPrograms.isEmpty
                        ? Center(
                            child: Text(
                              'برنامه‌ای ذخیره نشده',
                              style: TextStyle(
                                color: Colors.amber[300],
                                fontSize: 16.sp,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: savedPrograms.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.amber, height: 1),
                            itemBuilder: (context, index) {
                              final program = savedPrograms[index];
                              final j = Jalali.fromDateTime(program.createdAt);
                              final dateLabel =
                                  '${j.day} ${j.formatter.mN} ${j.year}';
                              // محاسبه مهلت ویرایش باقی‌مانده (۳ روز پس از ایجاد) با نرمال‌سازی تاریخ‌ها به شروع روز
                              final now = DateTime.now();
                              final today = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              final created = program.createdAt;
                              final createdDay = DateTime(
                                created.year,
                                created.month,
                                created.day,
                              );
                              final daysPassed = today
                                  .difference(createdDay)
                                  .inDays;
                              final remaining = 3 - daysPassed;
                              final canEdit = remaining > 0;

                              return ListTile(
                                title: Text(
                                  program.name,
                                  style: const TextStyle(color: Colors.amber),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateLabel,
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      canEdit
                                          ? 'مهلت ویرایش: $remaining روز'
                                          : 'مهلت ویرایش به پایان رسیده',
                                      style: TextStyle(
                                        color: canEdit
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: !canEdit
                                    ? Icon(
                                        LucideIcons.lock,
                                        color: Colors.redAccent,
                                        size: 18.sp,
                                      )
                                    : null,
                                onTap: () async {
                                  if (canEdit) {
                                    onSelect(program.id);
                                    return;
                                  }
                                  // Show a friendly dialog: edit window expired
                                  await showDialog<void>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: const Color(0xFF1A1A1A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      title: const Text(
                                        'عدم دسترسی',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Text(
                                        'مهلت ویرایش این برنامه به پایان رسیده است و امکان دسترسی برای ویرایش وجود ندارد.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('بستن'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('برنامه جدید'),
                      onPressed: onCreateNew,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
