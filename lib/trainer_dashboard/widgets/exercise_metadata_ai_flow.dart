import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/models/exercise_metadata_ai_models.dart';
import 'package:gymaipro/ai/services/ai_exercise_metadata_service.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/exercise_muscle_heatmap_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نتیجه فلو AI — فقط نقشه عضلانی.
typedef ExerciseMuscleAiResult = GeneratedMuscleProfile?;

/// شناسایی → انتخاب → تولید heatmap → پیش‌نمایش.
Future<ExerciseMuscleAiResult> runExerciseMuscleAiFlow({
  required BuildContext context,
  required String title,
  required String name,
  String? hint,
  AIExerciseMetadataService? service,
}) async {
  final ai = service ?? AIExerciseMetadataService();

  if (!ai.isAvailable) {
    if (context.mounted) {
      _showSnack(
        context,
        'هوش مصنوعی در دسترس نیست. عضله را دستی انتخاب کنید.',
        isError: true,
      );
    }
    return null;
  }

  if (!context.mounted) return null;

  FocusManager.instance.primaryFocus?.unfocus();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCardColor
            : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.goldColor),
            SizedBox(height: 16.h),
            Text(
              'در حال شناسایی تمرین...',
              style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    ),
  );

  List<ExerciseIdentityOption> options;
  try {
    options = await ai.identifyExerciseOptions(
      title: title,
      name: name,
      hint: hint,
    );
  } on OpenAIException catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack(context, e.message, isError: true);
    }
    return null;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack(context, 'خطا: $e', isError: true);
    }
    return null;
  }

  if (!context.mounted) return null;
  Navigator.of(context, rootNavigator: true).pop();

  final selected = await showModalBottomSheet<ExerciseIdentityOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _IdentityPickerSheet(
      title: title,
      options: options,
    ),
  );

  if (selected == null || !context.mounted) return null;

  FocusManager.instance.primaryFocus?.unfocus();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCardColor
            : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.goldColor),
            SizedBox(height: 16.h),
            Text(
              'در حال ساخت نقشه عضلانی...',
              style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    ),
  );

  GeneratedMuscleProfile profile;
  try {
    profile = await ai.generateMuscleProfile(
      title: title,
      name: name,
      selectedOption: selected,
      hint: hint,
    );
  } on OpenAIException catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack(context, e.message, isError: true);
    }
    return null;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack(context, 'خطا: $e', isError: true);
    }
    return null;
  }

  if (!context.mounted) return null;
  Navigator.of(context, rootNavigator: true).pop();

  return showModalBottomSheet<GeneratedMuscleProfile>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MusclePreviewSheet(profile: profile),
  );
}

void _showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: AppTheme.fontFamily)),
      backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
    ),
  );
}

class _IdentityPickerSheet extends StatefulWidget {
  const _IdentityPickerSheet({
    required this.title,
    required this.options,
  });

  final String title;
  final List<ExerciseIdentityOption> options;

  @override
  State<_IdentityPickerSheet> createState() => _IdentityPickerSheetState();
}

class _IdentityPickerSheetState extends State<_IdentityPickerSheet> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: EdgeInsets.only(top: 48.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'کدام تمرین مدنظر شماست؟',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '«${widget.title}» — برای ساخت نقشه عضلانی، یکی از گزینه‌ها را انتخاب کنید.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              SizedBox(height: 16.h),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.options.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final id = option.id.isNotEmpty ? option.id : '${index + 1}';
                    final selected = _selectedId == id;

                    return InkWell(
                      onTap: () => setState(() => _selectedId = id),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.goldColor.withValues(alpha: 0.12)
                              : (isDark
                                  ? AppTheme.veryDarkBackground.withValues(alpha: 0.4)
                                  : Colors.grey[50]),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: selected
                                ? AppTheme.goldColor
                                : AppTheme.goldColor.withValues(alpha: 0.25),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              selected
                                  ? LucideIcons.checkCircle2
                                  : LucideIcons.circle,
                              color: selected
                                  ? AppTheme.goldColor
                                  : Colors.grey,
                              size: 22.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.standardNameFa,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                      color: isDark
                                          ? AppTheme.darkTextColor
                                          : AppTheme.veryDarkBackground,
                                    ),
                                  ),
                                  if (option.standardNameEn.isNotEmpty) ...[
                                    SizedBox(height: 2.h),
                                    Text(
                                      option.standardNameEn,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 12.sp,
                                        color: AppTheme.goldColor,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 6.h),
                                  Text(
                                    option.summary,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12.sp,
                                      color: isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Wrap(
                                    spacing: 8.w,
                                    runSpacing: 4.h,
                                    children: [
                                      _chip(option.mainMuscleGroup, isDark),
                                      _chip(option.equipmentHint, isDark),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('انصراف'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedId == null
                          ? null
                          : () {
                              ExerciseIdentityOption? match;
                              for (var i = 0; i < widget.options.length; i++) {
                                final o = widget.options[i];
                                final id =
                                    o.id.isNotEmpty ? o.id : '${i + 1}';
                                if (id == _selectedId) {
                                  match = o;
                                  break;
                                }
                              }
                              Navigator.pop(
                                context,
                                match ?? widget.options.first,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: AppTheme.veryDarkBackground,
                      ),
                      child: const Text('تأیید و ادامه'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11.sp,
          color: isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground,
        ),
      ),
    );
  }
}

class _MusclePreviewSheet extends StatelessWidget {
  const _MusclePreviewSheet({required this.profile});

  final GeneratedMuscleProfile profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Icon(LucideIcons.activity,
                          color: AppTheme.goldColor, size: 24.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'پیش‌نمایش نقشه عضلانی',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h + bottom),
                    children: [
                      Text(
                        'فقط عضلات درگیر پر می‌شوند. توضیحات و نکات را خودتان در تب «توضیحات» بنویسید.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.sp,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _previewRow('عضله اصلی', profile.mainMuscle, isDark),
                      _previewRow('عضلات فرعی', profile.secondaryMuscles, isDark),
                      if (MuscleTargets.hasData(profile.muscleTargets)) ...[
                        SizedBox(height: 16.h),
                        const Text(
                          'نقشه عضلانی',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.goldColor,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ExerciseMuscleHeatmapWidget(
                          muscleTargets: profile.muscleTargets,
                          compact: true,
                          embedded: true,
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('انصراف'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, profile),
                          icon: Icon(LucideIcons.check, size: 18.sp),
                          label: const Text('اعمال نقشه'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldColor,
                            foregroundColor: AppTheme.veryDarkBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _previewRow(String label, String value, bool isDark) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90.w,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
