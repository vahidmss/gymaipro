import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/models/exercise_metadata_ai_models.dart';
import 'package:gymaipro/ai/services/ai_exercise_metadata_service.dart';
import 'package:gymaipro/models/custom_exercise.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/services/custom_exercise_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/widgets/exercise_metadata_ai_flow.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/widgets/exercise_muscle_heatmap_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه ساخت/ویرایش تمرین اختصاصی
class CustomExerciseEditorScreen extends StatefulWidget {

  const CustomExerciseEditorScreen({super.key, this.exercise});
  final CustomExercise? exercise;

  @override
  State<CustomExerciseEditorScreen> createState() =>
      _CustomExerciseEditorScreenState();
}

class _CustomExerciseEditorScreenState extends State<CustomExerciseEditorScreen> {
  static const int _maxImages = 24;
  static const int _maxVideos = 8;

  final _formKey = GlobalKey<FormState>();
  final _service = CustomExerciseService();
  final _aiMetadataService = AIExerciseMetadataService();
  final _picker = ImagePicker();

  // Controllers
  final _titleController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailedDescriptionController = TextEditingController();
  final _secondaryMusclesController = TextEditingController();
  final _muscleHintController = TextEditingController();
  final _tipsControllers = <TextEditingController>[];
  final _scrollController = ScrollController();
  final Map<String, bool> _expansionStates = {};

  // State
  String _mainMuscle = 'سینه';
  String _difficulty = 'متوسط';
  String _equipment = 'بدون تجهیزات';
  String _exerciseType = 'قدرتی';
  String _visibility = 'private';
  bool _sharedWithClients = true;
  bool _isLoading = false;
  bool _isAiRunning = false;
  double _uploadProgress = 0;
  Map<String, int> _muscleTargets = {};
  List<String> _otherNames = [];
  int _estimatedDuration = 0;

  final List<String> _committedImageUrls = [];
  final List<XFile> _newImageFiles = [];
  final List<String> _committedVideoUrls = [];
  final List<XFile> _newVideoFiles = [];

  // Lists
  final List<String> _muscleGroups = [
    'سینه',
    'پشت',
    'شانه',
    'پا',
    'بازو',
    'شکم',
    'سرینی',
    'ساعد',
    'کاردیو',
    'کل بدن',
  ];

  final List<String> _difficulties = ['آسان', 'متوسط', 'سخت', 'حرفه‌ای'];
  final List<String> _equipments = [
    'بدون تجهیزات',
    'هالتر',
    'دمبل',
    'دستگاه',
    'کابل',
    'کتل‌بل',
    'کش',
  ];

  final List<String> _exerciseTypes = [
    'قدرتی',
    'کاردیو',
    'کششی',
    'تعادلی',
    'انعطاف‌پذیری',
  ];

  static const Map<String, IconData> _muscleIcons = {
    'سینه': LucideIcons.heart,
    'پشت': LucideIcons.arrowLeftRight,
    'شانه': LucideIcons.move,
    'پا': LucideIcons.footprints,
    'بازو': LucideIcons.dumbbell,
    'شکم': LucideIcons.circleDot,
    'سرینی': LucideIcons.trendingUp,
    'ساعد': LucideIcons.hand,
    'کاردیو': LucideIcons.heartPulse,
    'کل بدن': LucideIcons.user,
  };

  @override
  void initState() {
    super.initState();
    _initExpansionStates();
    _initializeForm();
  }

  void _initExpansionStates() {
    final ex = widget.exercise;
    _expansionStates['category'] = ex != null;
    _expansionStates['videos'] =
        ex != null && ex.videoUrls.isNotEmpty;
    _expansionStates['content'] = ex != null &&
        ((ex.description?.isNotEmpty ?? false) ||
            (ex.detailedDescription?.isNotEmpty ?? false) ||
            ex.tips.isNotEmpty);
    _expansionStates['muscles'] = true;
    _expansionStates['access'] = true;
  }

  void _initializeForm() {
    if (widget.exercise != null) {
      final ex = widget.exercise!;
      _titleController.text = ex.title;
      _nameController.text = ex.name;
      _descriptionController.text = ex.description ?? '';
      _detailedDescriptionController.text = ex.detailedDescription ?? '';
      _secondaryMusclesController.text = ex.secondaryMuscles;
      _mainMuscle = ex.mainMuscle;
      _difficulty = ex.difficulty;
      _equipment = ex.equipment;
      _exerciseType = ex.exerciseType;
      _visibility = ex.visibility;
      _sharedWithClients = ex.sharedWithClients;
      _committedVideoUrls
        ..clear()
        ..addAll(ex.videoUrls);
      _committedImageUrls
        ..clear()
        ..addAll(ex.imageUrls);
      _muscleTargets = Map<String, int>.from(ex.muscleTargets);
      _otherNames = List<String>.from(ex.otherNames);
      _estimatedDuration = ex.estimatedDuration;

      // Tips
      _tipsControllers.clear();
      for (final tip in ex.tips) {
        _tipsControllers.add(TextEditingController(text: tip));
      }
      if (_tipsControllers.isEmpty) {
        _tipsControllers.add(TextEditingController());
      }
    } else {
      _tipsControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _detailedDescriptionController.dispose();
    _secondaryMusclesController.dispose();
    _muscleHintController.dispose();
    for (final controller in _tipsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.exercise == null ? 'تمرین جدید' : 'ویرایش تمرین',
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkCardColor : AppTheme.darkTextColor,
        elevation: 0,
      ),
      body: _isLoading && _uploadProgress > 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _uploadProgress,
                    color: AppTheme.goldColor,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'در حال آپلود... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground,
                    ),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                children: [
                  _buildHintCard(isDark),
                  SizedBox(height: 16.h),
                  _buildRequiredCard(isDark),
                  SizedBox(height: 12.h),
                  _buildExpandableSection(
                    isDark: isDark,
                    sectionKey: 'category',
                    title: 'دسته‌بندی',
                    subtitle: _mainMuscle,
                    icon: LucideIcons.layoutGrid,
                    optional: true,
                    child: _buildCategoryContent(isDark),
                  ),
                  SizedBox(height: 12.h),
                  _buildExpandableSection(
                    isDark: isDark,
                    sectionKey: 'videos',
                    title: 'ویدیو',
                    subtitle: _videoCount > 0 ? '$_videoCount ویدیو' : null,
                    icon: LucideIcons.video,
                    optional: true,
                    child: _buildVideosMediaSection(isDark),
                  ),
                  SizedBox(height: 12.h),
                  _buildExpandableSection(
                    isDark: isDark,
                    sectionKey: 'content',
                    title: 'توضیحات و نکات',
                    subtitle: _hasContentSummary(),
                    icon: LucideIcons.fileText,
                    optional: true,
                    child: _buildContentSection(isDark),
                  ),
                  SizedBox(height: 12.h),
                  _buildExpandableSection(
                    isDark: isDark,
                    sectionKey: 'muscles',
                    title: 'نقشه عضلانی',
                    subtitle: MuscleTargets.hasData(_muscleTargets)
                        ? 'heatmap آماده'
                        : null,
                    icon: LucideIcons.activity,
                    optional: true,
                    child: _buildMuscleSection(isDark),
                  ),
                  SizedBox(height: 12.h),
                  _buildExpandableSection(
                    isDark: isDark,
                    sectionKey: 'access',
                    title: 'دسترسی',
                    subtitle: _visibility == 'public' ? 'عمومی' : 'خصوصی',
                    icon: LucideIcons.lock,
                    optional: true,
                    child: _buildAccessSection(isDark),
                  ),
                  SizedBox(height: 24.h),
                  _buildSaveButtons(isDark),
                ],
              ),
            ),
    );
  }

  String? _hasContentSummary() {
    if (_descriptionController.text.trim().isNotEmpty) return 'توضیح دارد';
    final tips = _tipsControllers.where((c) => c.text.trim().isNotEmpty).length;
    if (tips > 0) return '$tips نکته';
    return null;
  }

  Widget _buildHintCard(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.goldColor.withValues(alpha: 0.08)
            : AppTheme.goldColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, color: AppTheme.goldColor, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'برای ذخیره: عنوان، نام و یک تصویر. بقیه بخش‌ها اختیاری‌اند — '
              'باز کنید و پر کنید.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                height: 1.5,
                color: isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredCard(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            isDark: isDark,
            icon: LucideIcons.star,
            title: 'اطلاعات ضروری',
            badge: 'الزامی',
            badgeColor: AppTheme.goldColor,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _titleController,
            label: 'عنوان تمرین',
            hint: 'مثال: پرس سینه با هالتر',
            icon: LucideIcons.type,
            isDark: isDark,
            validator: (v) => v?.isEmpty ?? true ? 'عنوان الزامی است' : null,
          ),
          SizedBox(height: 12.h),
          _buildTextField(
            controller: _nameController,
            label: 'نام تمرین',
            hint: 'مثال: Bench Press',
            icon: LucideIcons.tag,
            isDark: isDark,
            validator: (v) => v?.isEmpty ?? true ? 'نام الزامی است' : null,
          ),
          SizedBox(height: 16.h),
          _buildImagesMediaSection(isDark),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required bool isDark,
    required String sectionKey,
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
    bool optional = false,
  }) {
    final isExpanded = _expansionStates[sectionKey] ?? false;

    return _buildSectionCard(
      isDark: isDark,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('$sectionKey-${_expansionStates[sectionKey]}'),
          initiallyExpanded: isExpanded,
          iconColor: AppTheme.goldColor,
          collapsedIconColor: AppTheme.goldColor,
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.only(top: 4.h),
          onExpansionChanged: (expanded) {
            setState(() => _expansionStates[sectionKey] = expanded);
          },
          title: _buildSectionHeader(
            isDark: isDark,
            icon: icon,
            title: title,
            subtitle: subtitle,
            badge: optional ? 'اختیاری' : null,
            badgeColor: isDark ? Colors.grey[600]! : Colors.grey[500]!,
            compact: true,
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader({
    required bool isDark,
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeColor,
    bool compact = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 8.w : 10.w),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppTheme.goldColor, size: compact ? 18.sp : 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: compact ? 15.sp : 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? AppTheme.goldColor).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: badgeColor ?? AppTheme.goldColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.sp,
                    color: AppTheme.goldColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('عضله اصلی', isDark),
        SizedBox(height: 10.h),
        _buildMuscleGrid(isDark),
        SizedBox(height: 20.h),
        _buildFieldLabel('سطح دشواری', isDark),
        SizedBox(height: 10.h),
        _buildChoiceChips(
          isDark: isDark,
          options: _difficulties,
          selected: _difficulty,
          onSelected: (v) => setState(() => _difficulty = v),
        ),
        SizedBox(height: 20.h),
        _buildFieldLabel('تجهیزات', isDark),
        SizedBox(height: 10.h),
        _buildChoiceChips(
          isDark: isDark,
          options: _equipments,
          selected: _equipment,
          onSelected: (v) => setState(() => _equipment = v),
        ),
        SizedBox(height: 20.h),
        _buildFieldLabel('نوع تمرین', isDark),
        SizedBox(height: 10.h),
        _buildChoiceChips(
          isDark: isDark,
          options: _exerciseTypes,
          selected: _exerciseType,
          onSelected: (v) => setState(() => _exerciseType = v),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[300] : Colors.grey[700],
      ),
    );
  }

  Widget _buildMuscleGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 3;
        final spacing = 8.w;
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _muscleGroups.map((muscle) {
            final selected = _mainMuscle == muscle;
            final icon = _muscleIcons[muscle] ?? LucideIcons.target;

            return SizedBox(
              width: itemWidth,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _mainMuscle = muscle),
                  borderRadius: BorderRadius.circular(12.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.18)
                          : (isDark
                              ? AppTheme.veryDarkBackground.withValues(alpha: 0.35)
                              : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: selected
                            ? AppTheme.goldColor
                            : AppTheme.goldColor.withValues(alpha: 0.2),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 20.sp,
                          color: selected ? AppTheme.goldColor : Colors.grey,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          muscle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.sp,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            color: selected
                                ? (isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground)
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildChoiceChips({
    required bool isDark,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: options.map((option) {
        final isSelected = selected == option;
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          showCheckmark: false,
          labelStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? AppTheme.veryDarkBackground
                : (isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground),
          ),
          backgroundColor: isDark ? AppTheme.veryDarkBackground.withValues(alpha: 0.35) : Colors.grey[100],
          selectedColor: AppTheme.goldColor,
          side: BorderSide(
            color: isSelected
                ? AppTheme.goldColor
                : AppTheme.goldColor.withValues(alpha: 0.25),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          padding: EdgeInsets.symmetric(horizontal: 4.w),
        );
      }).toList(),
    );
  }

  Widget _buildContentSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'سبک اجرا و نکات خودتان — هوش مصنوعی این بخش را پر نمی‌کند.',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.sp,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        SizedBox(height: 14.h),
        _buildTextField(
          controller: _descriptionController,
          label: 'توضیح کوتاه',
          hint: 'یک یا دو جمله دربارهٔ سبک اجرای شما',
          icon: LucideIcons.fileText,
          isDark: isDark,
          maxLines: 3,
        ),
        SizedBox(height: 12.h),
        _buildTextField(
          controller: _detailedDescriptionController,
          label: 'توضیح تکمیلی',
          hint: 'جزئیات اجرا، تنفس، خطاهای رایج',
          icon: LucideIcons.bookOpen,
          isDark: isDark,
          maxLines: 5,
        ),
        SizedBox(height: 16.h),
        _buildFieldLabel('نکات', isDark),
        SizedBox(height: 10.h),
        ...List.generate(_tipsControllers.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _tipsControllers[index],
                    label: 'نکته ${index + 1}',
                    hint: 'نکته مهم درباره تمرین',
                    icon: LucideIcons.lightbulb,
                    isDark: isDark,
                  ),
                ),
                if (_tipsControllers.length > 1)
                  IconButton(
                    icon: Icon(LucideIcons.trash2, color: AppTheme.errorColor, size: 20.sp),
                    onPressed: () {
                      setState(() {
                        _tipsControllers[index].dispose();
                        _tipsControllers.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() => _tipsControllers.add(TextEditingController()));
            },
            icon: Icon(LucideIcons.plus, size: 18.sp),
            label: const Text('افزودن نکته'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.goldColor),
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleSection(bool isDark) {
    final canRunAi = _titleController.text.trim().isNotEmpty &&
        _nameController.text.trim().isNotEmpty &&
        _aiMetadataService.isAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _secondaryMusclesController,
          label: 'عضلات فرعی',
          hint: 'با کاما جدا کنید — مثال: سرشانه، پشت بازو',
          icon: LucideIcons.activity,
          isDark: isDark,
        ),
        if (MuscleTargets.hasData(_muscleTargets)) ...[
          SizedBox(height: 16.h),
          _buildFieldLabel('پیش‌نمایش heatmap', isDark),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: ExerciseMuscleHeatmapWidget(
              muscleTargets: _muscleTargets,
              compact: true,
              embedded: true,
            ),
          ),
        ],
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.veryDarkBackground.withValues(alpha: 0.35)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.sparkles, color: AppTheme.goldColor, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'ساخت heatmap با AI',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                'اختیاری — فقط عضلات درگیر. توضیحات و نکات دستی می‌مانند.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.sp,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _muscleHintController,
                label: 'راهنمای کوتاه',
                hint: 'مثال: نسخه دست جمع، میز شیب‌دار',
                icon: LucideIcons.messageSquare,
                isDark: isDark,
                maxLines: 2,
              ),
              SizedBox(height: 10.h),
              OutlinedButton.icon(
                onPressed: (!_isAiRunning && canRunAi) ? _runMuscleAiFlow : null,
                icon: _isAiRunning
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(LucideIcons.wand2, size: 16.sp),
                label: Text(
                  MuscleTargets.hasData(_muscleTargets)
                      ? 'ساخت مجدد heatmap'
                      : 'ساخت heatmap',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.goldColor,
                  side: BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.5)),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
              if (!_aiMetadataService.isAvailable)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    'AI در دسترس نیست — عضلات را دستی وارد کنید.',
                    style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 11.sp, color: Colors.grey),
                  ),
                )
              else if (!canRunAi && !_isAiRunning)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    'ابتدا عنوان و نام را در بخش ضروری وارد کنید.',
                    style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 11.sp, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildVisibilityCard(
                isDark: isDark,
                value: 'private',
                label: 'خصوصی',
                description: 'من و شاگردانم',
                icon: LucideIcons.users,
                selected: _visibility == 'private',
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildVisibilityCard(
                isDark: isDark,
                value: 'public',
                label: 'عمومی',
                description: 'در دسترس همه',
                icon: LucideIcons.globe,
                selected: _visibility == 'public',
              ),
            ),
          ],
        ),
        if (_visibility == 'private') ...[
          SizedBox(height: 12.h),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('اشتراک با شاگردان'),
            subtitle: const Text('شاگردان می‌توانند این تمرین را ببینند'),
            value: _sharedWithClients,
            onChanged: (v) => setState(() => _sharedWithClients = v),
            activeThumbColor: AppTheme.goldColor,
          ),
        ],
      ],
    );
  }

  Widget _buildVisibilityCard({
    required bool isDark,
    required String value,
    required String label,
    required String description,
    required IconData icon,
    required bool selected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _visibility = value),
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.18 : 0.15)
                : (isDark
                    ? AppTheme.veryDarkBackground.withValues(alpha: 0.35)
                    : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? AppTheme.goldColor : AppTheme.goldColor.withValues(alpha: 0.2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppTheme.goldColor : Colors.grey, size: 22.sp),
              SizedBox(height: 8.h),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10.sp,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButtons(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _saveExercise,
          icon: Icon(
            widget.exercise == null ? LucideIcons.plus : LucideIcons.save,
            size: 20.sp,
          ),
          label: Text(
            widget.exercise == null ? 'ساخت تمرین' : 'ذخیره تغییرات',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.goldColor,
            foregroundColor: AppTheme.veryDarkBackground,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        ),
        if (widget.exercise != null) ...[
          SizedBox(height: 10.h),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _deleteExercise,
            icon: Icon(LucideIcons.trash2, size: 18.sp),
            label: const Text('حذف تمرین'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _runMuscleAiFlow() async {
    if (_isAiRunning) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isAiRunning = true);
    try {
      final hint = _muscleHintController.text.trim();
      final result = await runExerciseMuscleAiFlow(
        context: context,
        title: _titleController.text.trim(),
        name: _nameController.text.trim(),
        hint: hint.isEmpty ? null : hint,
        service: _aiMetadataService,
      );

      if (result != null && mounted) {
        _applyMuscleProfile(result);
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'نقشه عضلانی اعمال شد — در صورت نیاز ویرایش کنید.',
          backgroundColor: AppTheme.successColor,
        );
      }
    } finally {
      if (mounted) setState(() => _isAiRunning = false);
    }
  }

  void _applyMuscleProfile(GeneratedMuscleProfile profile) {
    setState(() {
      if (_muscleGroups.contains(profile.mainMuscle)) {
        _mainMuscle = profile.mainMuscle;
      }
      if (profile.secondaryMuscles.isNotEmpty) {
        _secondaryMusclesController.text = profile.secondaryMuscles;
      }
      if (MuscleTargets.hasData(profile.muscleTargets)) {
        _muscleTargets = Map<String, int>.from(profile.muscleTargets);
      }
      _expansionStates['muscles'] = true;
      _expansionStates['category'] = true;
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.goldColor),
        filled: true,
        fillColor: isDark ? AppTheme.darkCardColor : AppTheme.darkTextColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
        ),
      ),
    );
  }

  int get _imageCount => _committedImageUrls.length + _newImageFiles.length;

  int get _videoCount => _committedVideoUrls.length + _newVideoFiles.length;

  Widget _buildImagesMediaSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(LucideIcons.image, color: AppTheme.goldColor, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'تصاویر ($_imageCount / $_maxImages)',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.darkTextColor
                      : AppTheme.veryDarkBackground,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _imageCount >= _maxImages ? null : _pickImages,
              icon: Icon(LucideIcons.plus, size: 18.sp),
              label: const Text('افزودن'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.goldColor),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (_imageCount == 0)
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.veryDarkBackground.withValues(alpha: 0.35)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.imagePlus, color: Colors.grey, size: 28.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'حداقل یک تصویر کاور لازم است',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 104.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                  ...List.generate(_committedImageUrls.length, (i) {
                    final url = _committedImageUrls[i];
                    return Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: _mediaThumb(
                        isDark,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Image.network(
                            url,
                            width: 96.w,
                            height: 96.w,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: Colors.grey[800]!,
                              child: Icon(
                                LucideIcons.imageOff,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                        onRemove: () {
                          setState(() => _committedImageUrls.removeAt(i));
                        },
                      ),
                    );
                  }),
                  ...List.generate(_newImageFiles.length, (i) {
                    final f = _newImageFiles[i];
                    return Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: _mediaThumb(
                        isDark,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Image.file(
                            File(f.path),
                            width: 96.w,
                            height: 96.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                        onRemove: () {
                          setState(() => _newImageFiles.removeAt(i));
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildVideosMediaSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_videoCount == 0)
          Text(
            'می‌توانید چند ویدیو از گالری اضافه کنید.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          )
        else
          Column(
            children: [
                ...List.generate(_committedVideoUrls.length, (i) {
                  return _videoListRow(
                    isDark,
                    label: 'ویدیو ${i + 1} (آپلودشده)',
                    onRemove: () {
                      setState(() => _committedVideoUrls.removeAt(i));
                    },
                  );
                }),
                ...List.generate(_newVideoFiles.length, (i) {
                  return _videoListRow(
                    isDark,
                    label: 'ویدیو جدید ${i + 1}',
                    subtitle: _newVideoFiles[i].name,
                    onRemove: () {
                      setState(() => _newVideoFiles.removeAt(i));
                    },
                  );
                }),
              ],
            ),
        SizedBox(height: 8.h),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _videoCount >= _maxVideos ? null : _pickVideo,
            icon: Icon(LucideIcons.plus, size: 18.sp),
            label: Text('افزودن ویدیو ($_videoCount / $_maxVideos)'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.goldColor),
          ),
        ),
      ],
    );
  }

  Widget _mediaThumb(
    bool isDark, {
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.4)),
          ),
          child: child,
        ),
        Positioned(
          top: -4,
          right: -4,
          child: Material(
            color: AppTheme.errorColor,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(LucideIcons.x, size: 16.sp, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _videoListRow(
    bool isDark, {
    required String label,
    required VoidCallback onRemove, String? subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.veryDarkBackground.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.film, color: AppTheme.goldColor, size: 22.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextColor
                          : AppTheme.veryDarkBackground,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.sp,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppTheme.errorColor),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    if (_videoCount >= _maxVideos) return;
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (video != null) {
        WidgetSafetyUtils.safeSetState(this, () {
          _newVideoFiles.add(video);
        });
      }
    } catch (e) {
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در انتخاب ویدیو: $e',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  Future<void> _pickImages() async {
    if (_imageCount >= _maxImages) return;
    try {
      final images = await _picker.pickMultiImage();
      if (images.isEmpty) return;
      WidgetSafetyUtils.safeSetState(this, () {
        for (final img in images) {
          if (_imageCount >= _maxImages) break;
          _newImageFiles.add(img);
        }
      });
    } catch (e) {
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در انتخاب تصویر: $e',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToTop();
      return;
    }

    if (_imageCount < 1) {
      _scrollToTop();
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'حداقل یک تصویر کاور الزامی است. می‌توانید بعداً تصاویر بیشتری برای نمایش در جزئیات اضافه کنید.',
        backgroundColor: AppTheme.errorColor,
      );
      return;
    }

    WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);

    try {
      final imageUrls = List<String>.from(_committedImageUrls);
      for (final file in _newImageFiles) {
        final url = await _service.uploadExerciseImage(file);
        imageUrls.add(url);
      }

      final videoUrls = List<String>.from(_committedVideoUrls);
      final totalNewVideos = _newVideoFiles.length;
      for (var i = 0; i < totalNewVideos; i++) {
        final file = _newVideoFiles[i];
        final url = await _service.uploadVideo(
          file,
          onProgress: (progress) {
            final base = totalNewVideos == 0 ? 0.0 : i / totalNewVideos;
            final slice = totalNewVideos == 0 ? 1.0 : 1.0 / totalNewVideos;
            WidgetSafetyUtils.safeSetState(
              this,
              () => _uploadProgress = base + progress * slice,
            );
          },
        );
        videoUrls.add(url);
      }

      // جمع‌آوری نکات
      final tips = _tipsControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      CustomExercise? result;

      if (widget.exercise == null) {
        // ساخت جدید
        result = await _service.createExercise(
          title: _titleController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          detailedDescription:
              _detailedDescriptionController.text.trim().isEmpty
                  ? null
                  : _detailedDescriptionController.text.trim(),
          mainMuscle: _mainMuscle,
          secondaryMuscles: _secondaryMusclesController.text.trim(),
          difficulty: _difficulty,
          equipment: _equipment,
          exerciseType: _exerciseType,
          videoUrls: videoUrls,
          imageUrls: imageUrls,
          tips: tips,
          visibility: _visibility,
          sharedWithClients: _sharedWithClients,
          otherNames: _otherNames,
          estimatedDuration: _estimatedDuration,
          muscleTargets: _muscleTargets,
        );
      } else {
        // ویرایش
        result = await _service.updateExercise(
          widget.exercise!.id,
          title: _titleController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          detailedDescription:
              _detailedDescriptionController.text.trim().isEmpty
                  ? null
                  : _detailedDescriptionController.text.trim(),
          mainMuscle: _mainMuscle,
          secondaryMuscles: _secondaryMusclesController.text.trim(),
          difficulty: _difficulty,
          equipment: _equipment,
          exerciseType: _exerciseType,
          videoUrls: videoUrls,
          imageUrls: imageUrls,
          tips: tips,
          visibility: _visibility,
          sharedWithClients: _sharedWithClients,
          otherNames: _otherNames,
          estimatedDuration: _estimatedDuration,
          muscleTargets: _muscleTargets,
        );
      }

      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          widget.exercise == null
              ? 'تمرین با موفقیت ساخته شد'
              : 'تمرین با موفقیت به‌روزرسانی شد',
          backgroundColor: AppTheme.successColor,
        );
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا: $e',
          backgroundColor: AppTheme.errorColor,
        );
      }
    } finally {
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<void> _deleteExercise() async {
    if (widget.exercise == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف تمرین'),
        content: const Text('آیا از حذف این تمرین اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);

    try {
      final success = await _service.deleteExercise(widget.exercise!.id);
      if (mounted) {
        if (success) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'تمرین با موفقیت حذف شد',
            backgroundColor: AppTheme.successColor,
          );
          Navigator.pop(context, widget.exercise);
        } else {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'خطا در حذف تمرین',
            backgroundColor: AppTheme.errorColor,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا: $e',
          backgroundColor: AppTheme.errorColor,
        );
      }
    } finally {
      WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
    }
  }
}

