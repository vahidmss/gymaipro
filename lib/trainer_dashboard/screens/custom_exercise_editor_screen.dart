import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/models/exercise_metadata_ai_models.dart';
import 'package:gymaipro/ai/services/ai_exercise_metadata_service.dart';
import 'package:gymaipro/models/custom_exercise.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';
import 'package:gymaipro/models/exercise_meta_normalizer.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/services/custom_exercise_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/widgets/exercise_metadata_ai_flow.dart';
import 'package:gymaipro/trainer_dashboard/widgets/manual_exercise_meta_sheet.dart';
import 'package:gymaipro/trainer_dashboard/widgets/muscle_targets_editor_sheet.dart';
import 'package:gymaipro/utils/web_safe_xfile_image.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/widgets/exercise_muscle_heatmap_widget.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه ساخت/ویرایش تمرین اختصاصی — مسیر کوتاه: عنوان → عضله → کاور → AI → ثبت
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

  final _titleController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailedDescriptionController = TextEditingController();
  final _secondaryMusclesController = TextEditingController();
  final _muscleHintController = TextEditingController();
  final _tipsControllers = <TextEditingController>[];
  final _scrollController = ScrollController();
  final _muscleSectionKey = GlobalKey();
  final _coverSectionKey = GlobalKey();
  final Map<String, bool> _expansionStates = {};

  String _mainMuscle = '';
  String _difficulty = 'متوسط';
  String _equipment = 'بدون تجهیزات';
  String _exerciseType = 'قدرتی';
  String _visibility = 'private';
  bool _sharedWithClients = true;
  bool _isLoading = false;
  bool _isAiRunning = false;
  double _uploadProgress = 0;
  String _saveStatus = '';
  Map<String, int> _muscleTargets = {};
  double? _met;
  double? _typicalRpe;
  String _movementPattern = '';
  String _bodyEngagement = '';
  String _mechanicsType = '';
  String _forceType = '';
  int? _caloriesPer1000kg;
  List<String> _otherNames = [];
  int _estimatedDuration = 0;

  final List<String> _committedImageUrls = [];
  final List<XFile> _newImageFiles = [];
  final List<String> _committedVideoUrls = [];
  final List<XFile> _newVideoFiles = [];

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

  static const List<String> _durationLabels = [
    'نامشخص',
    '۳۰ ثانیه',
    '۴۵ ثانیه',
    '۶۰ ثانیه',
    '۹۰ ثانیه',
    '۱۲۰ ثانیه',
  ];

  static const Map<String, int> _durationSeconds = {
    'نامشخص': 0,
    '۳۰ ثانیه': 30,
    '۴۵ ثانیه': 45,
    '۶۰ ثانیه': 60,
    '۹۰ ثانیه': 90,
    '۱۲۰ ثانیه': 120,
  };

  @override
  void initState() {
    super.initState();
    _initExpansionStates();
    _initializeForm();
  }

  void _initExpansionStates() {
    // فقط مسیر کوتاه باز است؛ بقیه تاشو.
    final editing = widget.exercise != null;
    _expansionStates['specs'] = editing;
    _expansionStates['access'] = false;
    _expansionStates['more'] = editing;
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
      _met = ex.met;
      _typicalRpe = ex.typicalRpe;
      _movementPattern = ex.movementPattern.trim().isEmpty
          ? ''
          : ExerciseMetaNormalizer.movementPattern(ex.movementPattern);
      _bodyEngagement = ex.bodyEngagement.trim().isEmpty
          ? ''
          : ExerciseMetaNormalizer.bodyEngagement(ex.bodyEngagement);
      _mechanicsType = ex.mechanicsType.trim().isEmpty
          ? ''
          : ExerciseMetaNormalizer.mechanicsType(ex.mechanicsType);
      _forceType = ex.forceType.trim().isEmpty
          ? ''
          : ExerciseMetaNormalizer.forceType(ex.forceType);
      _caloriesPer1000kg = ex.caloriesPer1000kg;
      _otherNames = List<String>.from(ex.otherNames);
      _estimatedDuration = ex.estimatedDuration;

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

  void _scrollToMuscleSection() {
    final ctx = _muscleSectionKey.currentContext;
    if (ctx == null) {
      _scrollToTop();
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.1,
    );
  }

  void _scrollToCoverSection() {
    final ctx = _coverSectionKey.currentContext;
    if (ctx == null) {
      _scrollToTop();
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.15,
    );
  }

  /// فقط گام بعدیِ لازم — بدون jargon.
  String? _nextStepHint() {
    if (_titleController.text.trim().isEmpty) {
      return 'اول عنوان تمرین را بنویس';
    }
    if (_mainMuscle.isEmpty) return 'عضله اصلی را انتخاب کن';
    if (!MuscleTargets.hasData(_muscleTargets) || !_hasCoreMetrics) {
      return 'نقشه عضلانی را با AI یا دستی پر کن';
    }
    if (_imageCount < 1) return 'یک تصویر کاور اضافه کن';
    return null;
  }

  bool get _canSaveReady =>
      _titleController.text.trim().isNotEmpty &&
      _mainMuscle.isNotEmpty &&
      _imageCount >= 1 &&
      MuscleTargets.hasData(_muscleTargets) &&
      _hasCoreMetrics;

  Color _mutedText(bool isDark) =>
      isDark ? Colors.grey[400]! : const Color(0xFF5A5A5A);

  Color _bodyText(bool isDark) =>
      isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uploading = _isLoading;

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
        automaticallyImplyLeading: !uploading,
      ),
      body: uploading
          ? _buildSavingOverlay(isDark)
          : Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                children: [
                  _buildEssentialsCard(isDark),
                  SizedBox(height: 10.h),
                  _buildMuscleFocusCard(isDark),
                  SizedBox(height: 10.h),
                  _buildExpandableSection(
                    isDark: isDark,
                    sectionKey: 'specs',
                    title: 'مشخصات بیشتر',
                    subtitle: '$_difficulty · $_equipment · $_exerciseType',
                    icon: LucideIcons.slidersHorizontal,
                    child: _buildExtraSpecsContent(isDark),
                  ),
                  SizedBox(height: 10.h),
                  KeyedSubtree(
                    key: _muscleSectionKey,
                    child: _buildAiCoreCard(isDark),
                  ),
                  SizedBox(height: 10.h),
                  KeyedSubtree(
                    key: _coverSectionKey,
                    child: _buildCoverCard(isDark),
                  ),
                  SizedBox(height: 10.h),
                  _buildExpandableSection(
                    isDark: isDark,
                    sectionKey: 'access',
                    title: 'دسترسی',
                    subtitle: _accessSubtitle(),
                    icon: LucideIcons.lock,
                    child: _buildAccessSection(isDark),
                  ),
                  SizedBox(height: 10.h),
                  _buildExpandableSection(
                    isDark: isDark,
                    sectionKey: 'more',
                    title: 'جزئیات بیشتر',
                    subtitle: _moreDetailsSubtitle(),
                    icon: LucideIcons.fileText,
                    child: _buildMoreDetailsContent(isDark),
                  ),
                  if (widget.exercise != null) ...[
                    SizedBox(height: 16.h),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _deleteExercise,
                      icon: Icon(LucideIcons.trash2, size: 18.sp),
                      label: const Text('حذف تمرین'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                ],
              ),
            ),
      bottomNavigationBar: uploading ? null : _buildStickySaveBar(isDark),
    );
  }

  Widget _buildSavingOverlay(bool isDark) {
    final hasProgress = _uploadProgress > 0.01;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56.w,
              height: 56.w,
              child: CircularProgressIndicator(
                value: hasProgress ? _uploadProgress.clamp(0.0, 1.0) : null,
                color: AppTheme.goldColor,
                strokeWidth: 3.5,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              _saveStatus.isEmpty ? 'در حال ذخیره…' : _saveStatus,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: _bodyText(isDark),
              ),
            ),
            if (hasProgress) ...[
              SizedBox(height: 8.h),
              Text(
                '${(_uploadProgress * 100).clamp(0, 100).toStringAsFixed(0)}٪',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  color: _mutedText(isDark),
                ),
              ),
            ] else ...[
              SizedBox(height: 8.h),
              Text(
                'لطفاً صبر کن — قطع نکن',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5.sp,
                  color: _mutedText(isDark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _moreDetailsSubtitle() {
    final parts = <String>[];
    if (_videoCount > 0) parts.add('$_videoCount ویدیو');
    final content = _hasContentSummary();
    if (content != null) parts.add(content);
    return parts.isEmpty ? 'ویدیو، توضیحات و نکات' : parts.join(' · ');
  }

  String? _hasContentSummary() {
    if (_descriptionController.text.trim().isNotEmpty) return 'توضیح دارد';
    final tips = _tipsControllers.where((c) => c.text.trim().isNotEmpty).length;
    if (tips > 0) return '$tips نکته';
    return null;
  }

  String _accessSubtitle() {
    if (_visibility == 'public') return 'عمومی';
    if (_sharedWithClients) return 'شاگردان';
    return 'فقط من';
  }

  // ─── Essentials: title + cover ───────────────────────────────────────────

  Widget _buildEssentialsCard(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.star, color: AppTheme.goldColor, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'اطلاعات اصلی',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: _bodyText(isDark),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildTextField(
            controller: _titleController,
            label: 'عنوان تمرین',
            hint: 'مثال: پرس سینه با هالتر',
            icon: LucideIcons.type,
            isDark: isDark,
            validator: (v) => v?.isEmpty ?? true ? 'عنوان الزامی است' : null,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // ─── Primary muscle (always visible) ─────────────────────────────────────

  Widget _buildMuscleFocusCard(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.target, color: AppTheme.goldColor, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'عضله اصلی',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: _bodyText(isDark),
                ),
              ),
              if (_mainMuscle.isEmpty) ...[
                const Spacer(),
                Text(
                  'انتخاب کنید',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.5.sp,
                    color: _mutedText(isDark),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 10.h),
          _buildChoiceChips(
            isDark: isDark,
            options: _muscleGroups,
            selected: _mainMuscle,
            onSelected: (v) => setState(() => _mainMuscle = v),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverCard(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      child: _buildImagesMediaSection(isDark),
    );
  }

  Widget _buildExtraSpecsContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('سطح دشواری', isDark),
        SizedBox(height: 8.h),
        _buildChoiceChips(
          isDark: isDark,
          options: _difficulties,
          selected: _difficulty,
          onSelected: (v) => setState(() => _difficulty = v),
        ),
        SizedBox(height: 14.h),
        _buildFieldLabel('تجهیزات', isDark),
        SizedBox(height: 8.h),
        _buildChoiceChips(
          isDark: isDark,
          options: _equipments,
          selected: _equipment,
          onSelected: (v) => setState(() => _equipment = v),
        ),
        SizedBox(height: 14.h),
        _buildFieldLabel('نوع تمرین', isDark),
        SizedBox(height: 8.h),
        _buildChoiceChips(
          isDark: isDark,
          options: _exerciseTypes,
          selected: _exerciseType,
          onSelected: (v) => setState(() => _exerciseType = v),
        ),
        SizedBox(height: 14.h),
        _buildFieldLabel('مدت تخمینی', isDark),
        SizedBox(height: 8.h),
        _buildChoiceChips(
          isDark: isDark,
          options: [
            ..._durationLabels,
            if (_estimatedDuration > 0 &&
                !_durationSeconds.containsValue(_estimatedDuration))
              '$_estimatedDuration ثانیه',
          ],
          selected: _durationLabelFor(_estimatedDuration),
          onSelected: (label) {
            setState(() => _estimatedDuration = _durationSecondsFor(label));
          },
        ),
      ],
    );
  }

  String _durationLabelFor(int seconds) {
    if (seconds <= 0) return 'نامشخص';
    for (final e in _durationSeconds.entries) {
      if (e.value == seconds) return e.key;
    }
    return '$seconds ثانیه';
  }

  int _durationSecondsFor(String label) {
    return _durationSeconds[label] ??
        (int.tryParse(label.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0);
  }

  // ─── AI Core (signature block) ───────────────────────────────────────────

  bool get _hasCoreMetrics =>
      _met != null &&
      _typicalRpe != null &&
      _movementPattern.isNotEmpty &&
      _bodyEngagement.isNotEmpty &&
      _mechanicsType.isNotEmpty &&
      _forceType.isNotEmpty &&
      _caloriesPer1000kg != null;

  Widget _buildAiCoreCard(bool isDark) {
    final hasMap = MuscleTargets.hasData(_muscleTargets);
    final hasCore = _hasCoreMetrics;
    final ready = hasMap && hasCore;
    final muted = _mutedText(isDark);

    return _buildSectionCard(
      isDark: isDark,
      highlight: !ready,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.goldColor.withValues(alpha: 0.28),
                      AppTheme.goldColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  LucideIcons.sparkles,
                  color: AppTheme.goldColor,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نقشه عضلانی خودکار',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: _bodyText(isDark),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      ready
                          ? 'پر شد — می‌تونی ذخیره کنی'
                          : 'AI نزدیک‌ترین حرکت را پیدا می‌کند و نقشه + کالری را پر می‌کند',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: ready ? const Color(0xFF2E7D32) : muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (ready)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'آماده',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
            ],
          ),
          if (ready) ...[
            SizedBox(height: 12.h),
            _buildCoreMetricsChips(isDark),
            if (hasMap) ...[
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: ExerciseMuscleHeatmapWidget(
                  muscleTargets: _muscleTargets,
                  compact: true,
                  embedded: true,
                ),
              ),
            ],
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAiRunning ? null : _openManualFullEditor,
                    icon: Icon(LucideIcons.pencil, size: 15.sp),
                    label: const Text('ویرایش همه'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.goldColor,
                      side: BorderSide(
                        color: AppTheme.goldColor.withValues(alpha: 0.45),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAiRunning ? null : _promptAndRunMuscleAi,
                    icon: _isAiRunning
                        ? SizedBox(
                            width: 14.w,
                            height: 14.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(LucideIcons.refreshCw, size: 15.sp),
                    label: const Text('ساخت مجدد AI'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: muted,
                      side: BorderSide(color: muted.withValues(alpha: 0.35)),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: 14.h),
            if (_aiMetadataService.isAvailable)
              ElevatedButton(
                onPressed: _isAiRunning ? null : _promptAndRunMuscleAi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: AppTheme.veryDarkBackground,
                  disabledBackgroundColor:
                      AppTheme.goldColor.withValues(alpha: 0.45),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isAiRunning
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppTheme.veryDarkBackground,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.sparkles, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'ساخت خودکار با AI',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              )
            else
              const SizedBox.shrink(),
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              onPressed: _isAiRunning ? null : _openManualFullEditor,
              icon: Icon(LucideIcons.slidersHorizontal, size: 16.sp),
              label: Text(
                    _aiMetadataService.isAvailable
                        ? 'ثبت دستی همه اطلاعات'
                        : 'ثبت دستی نقشه عضلانی',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _bodyText(isDark),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.shade300,
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
            if (!_aiMetadataService.isAvailable) ...[
              SizedBox(height: 6.h),
              Text(
                'AI در دسترس نیست — همه فیلدها را دستی پر کنید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.5.sp,
                  color: muted,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCoreMetricsChips(bool isDark) {
    final chips = <(String, String)>[
      if (_met != null) ('MET', _met!.toStringAsFixed(1)),
      if (_typicalRpe != null) ('RPE', _typicalRpe!.toStringAsFixed(1)),
      if (_movementPattern.isNotEmpty)
        ('الگو', ExerciseDisplayLabels.movement(_movementPattern)),
      if (_bodyEngagement.isNotEmpty)
        ('درگیری', ExerciseDisplayLabels.engagement(_bodyEngagement)),
      if (_mechanicsType.isNotEmpty)
        ('مکانیک', ExerciseDisplayLabels.mechanics(_mechanicsType)),
      if (_forceType.isNotEmpty)
        ('نیرو', ExerciseDisplayLabels.force(_forceType)),
      if (_caloriesPer1000kg != null)
        ('کالری/۱۰۰۰kg', '$_caloriesPer1000kg'),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: chips.map((c) {
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
                  text: '${c.$1} ',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10.5.sp,
                    color: _mutedText(isDark),
                  ),
                ),
                TextSpan(
                  text: c.$2,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: _bodyText(isDark),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Access (compact segment) ────────────────────────────────────────────

  Widget _buildAccessSection(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildAccessPill(
            isDark: isDark,
            label: 'فقط من',
            icon: LucideIcons.lock,
            selected: _visibility == 'private' && !_sharedWithClients,
            onTap: () => setState(() {
              _visibility = 'private';
              _sharedWithClients = false;
            }),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: _buildAccessPill(
            isDark: isDark,
            label: 'شاگردان',
            icon: LucideIcons.users,
            selected: _visibility == 'private' && _sharedWithClients,
            onTap: () => setState(() {
              _visibility = 'private';
              _sharedWithClients = true;
            }),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: _buildAccessPill(
            isDark: isDark,
            label: 'عمومی',
            icon: LucideIcons.globe,
            selected: _visibility == 'public',
            onTap: () => setState(() {
              _visibility = 'public';
              _sharedWithClients = true;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessPill({
    required bool isDark,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.16)
                : (isDark
                    ? AppTheme.veryDarkBackground.withValues(alpha: 0.3)
                    : Colors.grey[100]),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected
                  ? AppTheme.goldColor
                  : AppTheme.goldColor.withValues(alpha: 0.18),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: selected ? AppTheme.goldColor : Colors.grey,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: selected ? _bodyText(isDark) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shared chrome ───────────────────────────────────────────────────────

  Widget _buildExpandableSection({
    required bool isDark,
    required String sectionKey,
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
  }) {
    final isExpanded = _expansionStates[sectionKey] ?? false;

    return _buildSectionCard(
      isDark: isDark,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('$sectionKey-$isExpanded'),
          initiallyExpanded: isExpanded,
          iconColor: AppTheme.goldColor,
          collapsedIconColor: AppTheme.goldColor,
          tilePadding: EdgeInsets.symmetric(horizontal: 2.w),
          childrenPadding: EdgeInsets.fromLTRB(2.w, 0, 2.w, 12.h),
          onExpansionChanged: (expanded) {
            setState(() => _expansionStates[sectionKey] = expanded);
          },
          title: Row(
            children: [
              Icon(icon, color: AppTheme.goldColor, size: 18.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: _bodyText(isDark),
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11.5.sp,
                          color: _mutedText(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry? padding,
    bool highlight = false,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: highlight
              ? AppTheme.goldColor.withValues(alpha: 0.45)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
          width: highlight ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(14.w),
        child: child,
      ),
    );
  }

  Widget _buildMoreDetailsContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'نام لاتین (اختیاری)',
          hint: 'Bench Press',
          icon: LucideIcons.tag,
          isDark: isDark,
          compact: true,
        ),
        SizedBox(height: 14.h),
        _buildFieldLabel('ویدیو', isDark),
        SizedBox(height: 8.h),
        _buildVideosMediaSection(isDark),
        SizedBox(height: 16.h),
        _buildFieldLabel('توضیحات و نکات', isDark),
        SizedBox(height: 8.h),
        _buildContentSection(isDark),
      ],
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[300] : const Color(0xFF444444),
      ),
    );
  }

  Widget _buildChoiceChips({
    required bool isDark,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: options.map((option) {
        final isSelected = selected == option;
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11.5.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppTheme.veryDarkBackground
                : _bodyText(isDark),
          ),
          backgroundColor: isDark
              ? AppTheme.veryDarkBackground.withValues(alpha: 0.35)
              : Colors.grey[100],
          selectedColor: AppTheme.goldColor,
          side: BorderSide(
            color: isSelected
                ? AppTheme.goldColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.grey.shade300),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 2.w),
        );
      }).toList(),
    );
  }

  Widget _buildContentSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _descriptionController,
          label: 'توضیح کوتاه',
          hint: 'سبک اجرای شما',
          icon: LucideIcons.fileText,
          isDark: isDark,
          maxLines: 2,
          compact: true,
        ),
        SizedBox(height: 10.h),
        _buildTextField(
          controller: _detailedDescriptionController,
          label: 'توضیح تکمیلی',
          hint: 'جزئیات اجرا، تنفس، خطاهای رایج',
          icon: LucideIcons.bookOpen,
          isDark: isDark,
          maxLines: 4,
          compact: true,
        ),
        SizedBox(height: 12.h),
        _buildFieldLabel('نکات', isDark),
        SizedBox(height: 8.h),
        ...List.generate(_tipsControllers.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _tipsControllers[index],
                    label: 'نکته ${index + 1}',
                    hint: 'نکته مهم',
                    icon: LucideIcons.lightbulb,
                    isDark: isDark,
                    compact: true,
                  ),
                ),
                if (_tipsControllers.length > 1)
                  IconButton(
                    icon: Icon(
                      LucideIcons.trash2,
                      color: AppTheme.errorColor,
                      size: 18.sp,
                    ),
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
            icon: Icon(LucideIcons.plus, size: 16.sp),
            label: const Text('افزودن نکته'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.goldColor),
          ),
        ),
      ],
    );
  }

  Widget _buildStickySaveBar(bool isDark) {
    final muted = _mutedText(isDark);
    final next = _nextStepHint();

    return Material(
      elevation: 8,
      color: isDark ? AppTheme.darkCardColor : Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (next != null) ...[
                Text(
                  next,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
                SizedBox(height: 8.h),
              ],
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveExercise,
                icon: Icon(
                  widget.exercise == null
                      ? LucideIcons.plus
                      : LucideIcons.save,
                  size: 20.sp,
                ),
                label: Text(
                  widget.exercise == null ? 'ساخت تمرین' : 'ذخیره تغییرات',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: AppTheme.veryDarkBackground,
                  disabledBackgroundColor:
                      AppTheme.goldColor.withValues(alpha: 0.45),
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AI / muscle actions ─────────────────────────────────────────────────

  Future<void> _promptAndRunMuscleAi() async {
    if (_titleController.text.trim().isEmpty) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'ابتدا عنوان تمرین را وارد کنید.',
        backgroundColor: AppTheme.errorColor,
      );
      _scrollToTop();
      return;
    }

    if (!_aiMetadataService.isAvailable) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'هوش مصنوعی در دسترس نیست. تنظیم دستی را امتحان کنید.',
        backgroundColor: AppTheme.errorColor,
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCardColor : Colors.white,
          title: Text(
            'ساخت با AI',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'عنوان «${_titleController.text.trim()}» را با کاتالوگ تطبیق می‌دهیم و نقشه عضلانی را پیشنهاد می‌کنیم.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  height: 1.4,
                  color: isDark ? Colors.grey[300] : const Color(0xFF444444),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'اگر حرکت مبهم است، یک توضیح کوتاه بده تا دقیق‌تر پیدا شود:',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  color: _mutedText(isDark),
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _muscleHintController,
                maxLines: 2,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: _bodyText(isDark),
                ),
                decoration: InputDecoration(
                  labelText: 'توضیح کمکی (اختیاری)',
                  hintText: 'مثال: با هالتر، میز شیب‌دار، دست جمع',
                  prefixIcon: const Icon(
                    LucideIcons.messageSquare,
                    color: AppTheme.goldColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.veryDarkBackground,
              ),
              child: const Text('شروع جستجو'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _runMuscleAiFlow();
    }
  }

  Future<void> _openManualFullEditor() async {
    final result = await showManualExerciseMetaSheet(
      context: context,
      initialMuscleTargets: _muscleTargets,
      met: _met,
      typicalRpe: _typicalRpe,
      movementPattern: _movementPattern,
      bodyEngagement: _bodyEngagement,
      mechanicsType: _mechanicsType,
      forceType: _forceType,
      caloriesPer1000kg: _caloriesPer1000kg,
      secondaryMuscles: _secondaryMusclesController.text,
    );
    if (result == null || !mounted) return;

    _applyMuscleTargets(result.muscleTargets);
    setState(() {
      _met = result.met;
      _typicalRpe = result.typicalRpe;
      _movementPattern = result.movementPattern;
      _bodyEngagement = result.bodyEngagement;
      _mechanicsType = result.mechanicsType;
      _forceType = result.forceType;
      _caloriesPer1000kg = result.caloriesPer1000kg;
      if (result.secondaryMuscles.isNotEmpty) {
        _secondaryMusclesController.text = result.secondaryMuscles;
      }
    });

    WidgetSafetyUtils.safeShowSnackBar(
      context,
      _imageCount < 1
          ? 'نقشه عضلانی ذخیره شد — کاور را اضافه کن و ذخیره کن.'
          : 'نقشه عضلانی دستی ذخیره شد.',
      backgroundColor: AppTheme.successColor,
    );
    _scrollToMuscleSection();
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
        name: _nameController.text.trim().isEmpty
            ? _titleController.text.trim()
            : _nameController.text.trim(),
        hint: hint.isEmpty ? null : hint,
        service: _aiMetadataService,
      );

      if (result != null && mounted) {
        _applyMuscleProfile(result.profile);
        HapticFeedback.lightImpact();
        _scrollToMuscleSection();
        final needsCover = _imageCount < 1;
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          result.profile.isFromCatalog
              ? (needsCover
                  ? 'نقشه عضلانی اعمال شد — کاور را اضافه کن و ذخیره کن.'
                  : 'نقشه عضلانی از کاتالوگ اعمال شد.')
              : (needsCover
                  ? 'تخمین AI اعمال شد — کاور را اضافه کن و ذخیره کن.'
                  : 'تخمین AI اعمال شد.'),
          backgroundColor: AppTheme.successColor,
        );
        if (result.openManualEditor) {
          await _openManualFullEditor();
        }
      }
    } finally {
      if (mounted) setState(() => _isAiRunning = false);
    }
  }

  void _applyMuscleTargets(Map<String, int> targets) {
    setState(() {
      _muscleTargets = Map<String, int>.from(targets);
      final group = mainMuscleGroupFromTargets(_muscleTargets);
      if (group != null && _muscleGroups.contains(group)) {
        _mainMuscle = group;
      }
      final secondary = secondaryMusclesTextFromTargets(_muscleTargets);
      if (secondary.isNotEmpty) {
        _secondaryMusclesController.text = secondary;
      }
    });
  }

  void _applyMuscleProfile(GeneratedMuscleProfile profile) {
    final normalized = ExerciseMetaNormalizer.normalizeProfile(profile);
    setState(() {
      if (_muscleGroups.contains(normalized.mainMuscle)) {
        _mainMuscle = normalized.mainMuscle;
      }
      if (normalized.secondaryMuscles.isNotEmpty) {
        _secondaryMusclesController.text = normalized.secondaryMuscles;
      }
      if (MuscleTargets.hasData(normalized.muscleTargets)) {
        _muscleTargets = Map<String, int>.from(normalized.muscleTargets);
        final group = mainMuscleGroupFromTargets(_muscleTargets);
        if (group != null &&
            !_muscleGroups.contains(normalized.mainMuscle) &&
            _muscleGroups.contains(group)) {
          _mainMuscle = group;
        }
      }
      _met = normalized.met;
      _typicalRpe = normalized.typicalRpe;
      _movementPattern = normalized.movementPattern;
      _bodyEngagement = normalized.bodyEngagement;
      _mechanicsType = normalized.mechanicsType;
      _forceType = normalized.forceType;
      _caloriesPer1000kg = normalized.caloriesPer1000kg;
    });
  }

  // ─── Fields & media ──────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    bool compact = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: compact ? 13.sp : 14.sp,
        color: _bodyText(isDark),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: compact,
        prefixIcon: Icon(icon, color: AppTheme.goldColor, size: compact ? 18.sp : 20.sp),
        filled: true,
        fillColor: isDark ? AppTheme.darkCardColor : AppTheme.darkTextColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: compact ? 12.h : 14.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.grey.shade300,
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
    final muted = _mutedText(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(LucideIcons.image, color: AppTheme.goldColor, size: 18.sp),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                'کاور ($_imageCount / $_maxImages)',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: _bodyText(isDark),
                ),
              ),
            ),
            if (_imageCount > 0 && _imageCount < _maxImages)
              TextButton.icon(
                onPressed: _pickImages,
                icon: Icon(LucideIcons.plus, size: 16.sp),
                label: const Text('افزودن'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.goldColor,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        if (_imageCount == 0)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(12.r),
              child: Ink(
                height: 96.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.veryDarkBackground.withValues(alpha: 0.35)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.grey.shade300,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.camera,
                      color: AppTheme.goldColor,
                      size: 26.sp,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'افزودن تصویر کاور',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: _bodyText(isDark),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'قبل از ذخیره لازم است',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.sp,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 88.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...List.generate(_committedImageUrls.length, (i) {
                  final url = _committedImageUrls[i];
                  return Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: _mediaThumb(
                      isDark,
                      isCover: i == 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: GymaiNetworkImage(
                          imageUrl: url,
                          width: 88.w,
                          height: 88.w,
                          errorWidget: ColoredBox(
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
                  final isCover = _committedImageUrls.isEmpty && i == 0;
                  return Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: _mediaThumb(
                      isDark,
                      isCover: isCover,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: SizedBox(
                          width: 88.w,
                          height: 88.w,
                          child: WebSafeXFileImage(
                            file: f,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      onRemove: () {
                        setState(() => _newImageFiles.removeAt(i));
                      },
                    ),
                  );
                }),
                if (_imageCount < _maxImages)
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: InkWell(
                      onTap: _pickImages,
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        width: 88.w,
                        height: 88.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppTheme.goldColor.withValues(alpha: 0.35),
                          ),
                          color: isDark
                              ? AppTheme.veryDarkBackground.withValues(
                                  alpha: 0.3,
                                )
                              : Colors.grey[100],
                        ),
                        child: Icon(
                          LucideIcons.plus,
                          color: AppTheme.goldColor,
                          size: 22.sp,
                        ),
                      ),
                    ),
                  ),
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
        if (_videoCount > 0)
          Column(
            children: [
              ...List.generate(_committedVideoUrls.length, (i) {
                return _videoListRow(
                  isDark,
                  label: 'ویدیو ${i + 1}',
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
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _videoCount >= _maxVideos ? null : _pickVideo,
            icon: Icon(LucideIcons.plus, size: 16.sp),
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
    bool isCover = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isCover
                  ? AppTheme.goldColor
                  : AppTheme.goldColor.withValues(alpha: 0.35),
              width: isCover ? 2 : 1,
            ),
          ),
          child: child,
        ),
        if (isCover)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.goldColor,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'کاور',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.veryDarkBackground,
                ),
              ),
            ),
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
                child: Icon(LucideIcons.x, size: 14.sp, color: Colors.white),
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
    required VoidCallback onRemove,
    String? subtitle,
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
            Icon(LucideIcons.film, color: AppTheme.goldColor, size: 20.sp),
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
                      color: _bodyText(isDark),
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
                        color: _mutedText(isDark),
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
    if (kIsWeb) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'آپلود ویدیو تمرین روی وب‌اپ پشتیبانی نمی‌شود. از اپ اندروید استفاده کنید.',
        backgroundColor: AppTheme.goldColor,
      );
      return;
    }
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

    if (_mainMuscle.isEmpty) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'عضله اصلی را انتخاب کنید.',
        backgroundColor: AppTheme.errorColor,
      );
      return;
    }

    if (!MuscleTargets.hasData(_muscleTargets) || !_hasCoreMetrics) {
      _scrollToMuscleSection();
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'نقشه عضلانی هنوز کامل نیست — با AI یا دستی پر کن.',
        backgroundColor: AppTheme.errorColor,
      );
      return;
    }

    if (_imageCount < 1) {
      _scrollToCoverSection();
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'قبل از ذخیره، یک تصویر کاور اضافه کنید.',
        backgroundColor: AppTheme.errorColor,
      );
      return;
    }

    WidgetSafetyUtils.safeSetState(this, () {
      _isLoading = true;
      _uploadProgress = 0;
      _saveStatus = _newImageFiles.isNotEmpty
          ? 'در حال آپلود تصویر کاور…'
          : (_newVideoFiles.isNotEmpty
              ? 'در حال آپلود ویدیو…'
              : 'در حال ذخیره تمرین…');
    });

    try {
      final imageUrls = List<String>.from(_committedImageUrls);
      final totalImages = _newImageFiles.length;
      for (var i = 0; i < totalImages; i++) {
        WidgetSafetyUtils.safeSetState(this, () {
          _saveStatus = totalImages == 1
              ? 'در حال آپلود تصویر کاور…'
              : 'آپلود تصویر ${i + 1} از $totalImages…';
          _uploadProgress = totalImages == 0 ? 0 : i / (totalImages + 1);
        });
        final url = await _service.uploadExerciseImage(_newImageFiles[i]);
        imageUrls.add(url);
      }

      final videoUrls = List<String>.from(_committedVideoUrls);
      final totalNewVideos = _newVideoFiles.length;
      for (var i = 0; i < totalNewVideos; i++) {
        WidgetSafetyUtils.safeSetState(this, () {
          _saveStatus = totalNewVideos == 1
              ? 'در حال آپلود ویدیو…'
              : 'آپلود ویدیو ${i + 1} از $totalNewVideos…';
        });
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

      WidgetSafetyUtils.safeSetState(this, () {
        _saveStatus = widget.exercise == null
            ? 'در حال ساخت تمرین…'
            : 'در حال ذخیره تغییرات…';
        _uploadProgress = 0;
      });

      final tips = _tipsControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final title = _titleController.text.trim();
      final name = _nameController.text.trim().isEmpty
          ? title
          : _nameController.text.trim();

      // قبل از ذخیره همهٔ متا را به کلید canonical اپ تبدیل کن
      final normalized = ExerciseMetaNormalizer.normalizeProfile(
        GeneratedMuscleProfile(
          mainMuscle: _mainMuscle,
          secondaryMuscles: _secondaryMusclesController.text.trim(),
          muscleTargets: _muscleTargets,
          met: _met,
          typicalRpe: _typicalRpe,
          movementPattern: _movementPattern,
          bodyEngagement: _bodyEngagement,
          mechanicsType: _mechanicsType,
          forceType: _forceType,
          caloriesPer1000kg: _caloriesPer1000kg,
        ),
      );
      _mainMuscle = normalized.mainMuscle;
      _movementPattern = normalized.movementPattern;
      _bodyEngagement = normalized.bodyEngagement;
      _mechanicsType = normalized.mechanicsType;
      _forceType = normalized.forceType;
      _met = normalized.met;
      _typicalRpe = normalized.typicalRpe;
      _caloriesPer1000kg = normalized.caloriesPer1000kg;

      CustomExercise? result;

      if (widget.exercise == null) {
        result = await _service.createExercise(
          title: title,
          name: name,
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
          met: _met,
          typicalRpe: _typicalRpe,
          movementPattern: _movementPattern,
          bodyEngagement: _bodyEngagement,
          mechanicsType: _mechanicsType,
          forceType: _forceType,
          caloriesPer1000kg: _caloriesPer1000kg,
        );
      } else {
        result = await _service.updateExercise(
          widget.exercise!.id,
          title: title,
          name: name,
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
          met: _met,
          typicalRpe: _typicalRpe,
          movementPattern: _movementPattern,
          bodyEngagement: _bodyEngagement,
          mechanicsType: _mechanicsType,
          forceType: _forceType,
          caloriesPer1000kg: _caloriesPer1000kg,
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
        final msg = e.toString();
        final hint = (msg.contains('muscle_targets') ||
                msg.contains('PGRST') ||
                msg.contains('column') ||
                msg.contains('schema cache'))
            ? '\nاگر ستون متا روی دیتابیس نیست، migration را اعمال کنید.'
            : '';
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در ذخیره$hint\n$msg',
          backgroundColor: AppTheme.errorColor,
        );
      }
    } finally {
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoading = false;
        _uploadProgress = 0.0;
        _saveStatus = '';
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
