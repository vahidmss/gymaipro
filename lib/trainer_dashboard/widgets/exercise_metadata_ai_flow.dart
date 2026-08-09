import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/models/exercise_metadata_ai_models.dart';
import 'package:gymaipro/ai/services/ai_exercise_metadata_service.dart';
import 'package:gymaipro/ai/services/catalog_exercise_matcher.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';
import 'package:gymaipro/models/exercise_meta_normalizer.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/exercise_muscle_heatmap_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نتیجهٔ فلو AI برای ادیتور.
class ExerciseMuscleAiOutcome {
  const ExerciseMuscleAiOutcome({
    required this.profile,
    this.openManualEditor = false,
  });

  final GeneratedMuscleProfile profile;
  final bool openManualEditor;
}

typedef ExerciseMuscleAiResult = ExerciseMuscleAiOutcome?;

/// شناسایی → انتخاب → ترجیح کاتالوگ علمی → در صورت نیاز fallback AI → پیش‌نمایش.
Future<ExerciseMuscleAiResult> runExerciseMuscleAiFlow({
  required BuildContext context,
  required String title,
  required String name,
  String? hint,
  AIExerciseMetadataService? service,
  ExerciseService? exerciseService,
}) async {
  final ai = service ?? AIExerciseMetadataService();
  final exercises = exerciseService ?? ExerciseService();

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

  final progress = ValueNotifier<String>('در حال شناسایی تمرین...');
  _showProgressDialog(context, progress);

  List<ExerciseIdentityOption> options;
  try {
    options = await ai.identifyExerciseOptions(
      title: title,
      name: name,
      hint: hint,
    );
  } on OpenAIException catch (e) {
    progress.dispose();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack(context, e.message, isError: true);
    }
    return null;
  } catch (e) {
    progress.dispose();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack(context, 'خطا: $e', isError: true);
    }
    return null;
  }

  if (!context.mounted) {
    progress.dispose();
    return null;
  }

  ExerciseIdentityOption? selected;

  if (options.length == 1) {
    selected = options.first;
    progress.value = 'در حال تطبیق با کاتالوگ علمی...';
  } else {
    Navigator.of(context, rootNavigator: true).pop();
    progress.dispose();

    selected = await showModalBottomSheet<ExerciseIdentityOption>(
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
    final progress2 =
        ValueNotifier<String>('در حال تطبیق با کاتالوگ علمی...');
    _showProgressDialog(context, progress2);

    return _finishResolveAndPreview(
      context: context,
      ai: ai,
      exercises: exercises,
      title: title,
      name: name,
      selected: selected,
      hint: hint,
      progress: progress2,
    );
  }

  return _finishResolveAndPreview(
    context: context,
    ai: ai,
    exercises: exercises,
    title: title,
    name: name,
    selected: selected,
    hint: hint,
    progress: progress,
  );
}

Future<ExerciseMuscleAiResult> _finishResolveAndPreview({
  required BuildContext context,
  required AIExerciseMetadataService ai,
  required ExerciseService exercises,
  required String title,
  required String name,
  required ExerciseIdentityOption selected,
  required String? hint,
  required ValueNotifier<String> progress,
}) async {
  GeneratedMuscleProfile profile;
  try {
    profile = await _resolveScientificProfile(
      ai: ai,
      exercises: exercises,
      title: title,
      name: name,
      selected: selected,
      hint: hint,
    );
  } on OpenAIException catch (e) {
    progress.dispose();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack(context, e.message, isError: true);
    }
    return null;
  } catch (e) {
    progress.dispose();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack(context, 'خطا: $e', isError: true);
    }
    return null;
  }

  if (!context.mounted) {
    progress.dispose();
    return null;
  }
  Navigator.of(context, rootNavigator: true).pop();
  progress.dispose();

  return showModalBottomSheet<ExerciseMuscleAiOutcome>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MusclePreviewSheet(profile: profile),
  );
}

void _showProgressDialog(BuildContext context, ValueNotifier<String> message) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCardColor
            : Colors.white,
        content: ValueListenableBuilder<String>(
          valueListenable: message,
          builder: (context, text, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.goldColor),
                SizedBox(height: 16.h),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// اول کاتالوگ seeded؛ فقط اگر match علمی نبود → تخمین AI.
Future<GeneratedMuscleProfile> _resolveScientificProfile({
  required AIExerciseMetadataService ai,
  required ExerciseService exercises,
  required String title,
  required String name,
  required ExerciseIdentityOption selected,
  String? hint,
}) async {
  final catalog = await exercises.getExercises();
  final match = CatalogExerciseMatcher.findBest(
    catalog: catalog,
    option: selected,
  );

  if (match != null && match.isScientificallyReliable) {
    final detailed =
        await exercises.getExerciseById(match.exercise.id) ?? match.exercise;
    var profile = CatalogExerciseMatcher.toProfile(detailed);

    if (!profile.hasCoreMetrics) {
      try {
        final aiFill = await ai.generateMuscleProfile(
          title: title,
          name: name,
          selectedOption: selected,
          hint: hint,
        );
        profile = _mergePreferCatalog(profile, aiFill);
      } catch (_) {
        // کاتالوگ را نگه می‌داریم حتی اگر fill شکست بخورد.
      }
    }

    return profile;
  }

  return ExerciseMetaNormalizer.normalizeProfile(
    await ai.generateMuscleProfile(
      title: title,
      name: name,
      selectedOption: selected,
      hint: hint,
    ),
  );
}

GeneratedMuscleProfile _mergePreferCatalog(
  GeneratedMuscleProfile catalog,
  GeneratedMuscleProfile ai,
) {
  return ExerciseMetaNormalizer.normalizeProfile(
    GeneratedMuscleProfile(
      mainMuscle: catalog.mainMuscle.isNotEmpty
          ? catalog.mainMuscle
          : ai.mainMuscle,
      secondaryMuscles: catalog.secondaryMuscles.isNotEmpty
          ? catalog.secondaryMuscles
          : ai.secondaryMuscles,
      muscleTargets: MuscleTargets.hasData(catalog.muscleTargets)
          ? catalog.muscleTargets
          : ai.muscleTargets,
      met: catalog.met ?? ai.met,
      typicalRpe: catalog.typicalRpe ?? ai.typicalRpe,
      movementPattern: catalog.movementPattern.isNotEmpty
          ? catalog.movementPattern
          : ai.movementPattern,
      bodyEngagement: catalog.bodyEngagement.isNotEmpty
          ? catalog.bodyEngagement
          : ai.bodyEngagement,
      mechanicsType: catalog.mechanicsType.isNotEmpty
          ? catalog.mechanicsType
          : ai.mechanicsType,
      forceType:
          catalog.forceType.isNotEmpty ? catalog.forceType : ai.forceType,
      caloriesPer1000kg: catalog.caloriesPer1000kg ?? ai.caloriesPer1000kg,
      source: MuscleProfileSource.catalog,
      catalogExerciseId: catalog.catalogExerciseId,
      catalogExerciseName: catalog.catalogExerciseName,
    ),
  );
}

void _showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontFamily: AppTheme.fontFamily),
      ),
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
  void initState() {
    super.initState();
    if (widget.options.length == 1) {
      final o = widget.options.first;
      _selectedId = o.id.isNotEmpty ? o.id : '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final muted = isDark ? Colors.grey[400]! : const Color(0xFF5A5A5A);

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
                  color: isDark
                      ? AppTheme.darkTextColor
                      : AppTheme.veryDarkBackground,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '«${widget.title}» — یکی را انتخاب کن تا نقشه عضلانی اعمال شود.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  color: muted,
                ),
              ),
              SizedBox(height: 14.h),
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.goldColor.withValues(alpha: 0.12)
                              : (isDark
                                  ? AppTheme.veryDarkBackground
                                      .withValues(alpha: 0.4)
                                  : Colors.grey[50]),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: selected
                                ? AppTheme.goldColor
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.grey.shade300),
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
                                        color: muted,
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
                        padding: EdgeInsets.symmetric(vertical: 14.h),
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
    if (label.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade100,
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
    final fromCatalog = profile.isFromCatalog;
    final muted = isDark ? Colors.grey[400]! : const Color(0xFF5A5A5A);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.94,
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
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
                  child: Row(
                    children: [
                      Icon(
                        fromCatalog
                            ? LucideIcons.database
                            : LucideIcons.sparkles,
                        color: AppTheme.goldColor,
                        size: 22.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          fromCatalog
                              ? 'از کاتالوگ علمی'
                              : 'پیش‌نمایش تخمین AI',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: fromCatalog
                              ? AppTheme.goldColor.withValues(alpha: 0.18)
                              : Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          fromCatalog ? 'علمی' : 'تخمینی',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: fromCatalog
                                ? AppTheme.goldColor
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                    children: [
                      Text(
                        fromCatalog
                            ? (profile.catalogExerciseName != null &&
                                    profile.catalogExerciseName!.isNotEmpty
                                ? 'مقادیر استاندارد «${profile.catalogExerciseName}»'
                                : 'مقادیر استاندارد کاتالوگ GymAI')
                            : 'match علمی پیدا نشد — در صورت نیاز ویرایش کنید.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5.sp,
                          height: 1.35,
                          color: muted,
                        ),
                      ),
                      if (MuscleTargets.hasData(profile.muscleTargets)) ...[
                        SizedBox(height: 14.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14.r),
                          child: ExerciseMuscleHeatmapWidget(
                            muscleTargets: profile.muscleTargets,
                            compact: true,
                            embedded: true,
                          ),
                        ),
                      ],
                      SizedBox(height: 14.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: [
                          if (profile.mainMuscle.isNotEmpty)
                            _metricChip('عضله', profile.mainMuscle, isDark),
                          if (profile.met != null)
                            _metricChip(
                              'MET',
                              profile.met!.toStringAsFixed(1),
                              isDark,
                            ),
                          if (profile.typicalRpe != null)
                            _metricChip(
                              'RPE',
                              profile.typicalRpe!.toStringAsFixed(1),
                              isDark,
                            ),
                          if (profile.movementPattern.isNotEmpty)
                            _metricChip(
                              'الگو',
                              profile.movementPatternLabel,
                              isDark,
                            ),
                          if (profile.bodyEngagement.isNotEmpty)
                            _metricChip(
                              'درگیری',
                              profile.bodyEngagementLabel,
                              isDark,
                            ),
                          if (profile.mechanicsType.isNotEmpty)
                            _metricChip(
                              'مکانیک',
                              ExerciseDisplayLabels.mechanics(
                                profile.mechanicsType,
                              ),
                              isDark,
                            ),
                          if (profile.forceType.isNotEmpty)
                            _metricChip(
                              'نیرو',
                              ExerciseDisplayLabels.force(profile.forceType),
                              isDark,
                            ),
                          if (profile.caloriesPer1000kg != null)
                            _metricChip(
                              'کالری',
                              '${profile.caloriesPer1000kg}/۱۰۰۰kg',
                              isDark,
                            ),
                        ],
                      ),
                      if (profile.secondaryMuscles.trim().isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Text(
                          'فرعی: ${profile.secondaryMuscles}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h + bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(
                          context,
                          ExerciseMuscleAiOutcome(profile: profile),
                        ),
                        icon: Icon(LucideIcons.check, size: 18.sp),
                        label: Text(
                          fromCatalog ? 'اعمال دادهٔ علمی' : 'اعمال تخمین AI',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldColor,
                          foregroundColor: AppTheme.veryDarkBackground,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          elevation: 0,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(
                          context,
                          ExerciseMuscleAiOutcome(
                            profile: profile,
                            openManualEditor: true,
                          ),
                        ),
                        icon: Icon(LucideIcons.pencil, size: 16.sp),
                        label: const Text('ویرایش دستی قبل از اعمال'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppTheme.darkTextColor
                              : AppTheme.veryDarkBackground,
                          side: BorderSide(
                            color: AppTheme.goldColor.withValues(alpha: 0.4),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'انصراف',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: muted,
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

  Widget _metricChip(String label, String value, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.28),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10.5.sp,
                color: isDark ? Colors.grey[400] : const Color(0xFF5A5A5A),
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppTheme.darkTextColor
                    : AppTheme.veryDarkBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
