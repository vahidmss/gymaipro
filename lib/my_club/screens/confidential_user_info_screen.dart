import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gymaipro/my_club/services/confidential_user_info_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';

/// صفحه اطلاعات محرمانه کاربر
/// این صفحه برای مدیریت اطلاعات شخصی و حساس کاربر استفاده می‌شود
class ConfidentialUserInfoScreen extends StatefulWidget {
  /// سازنده صفحه اطلاعات محرمانه
  const ConfidentialUserInfoScreen({super.key, this.embedded = false});

  /// آیا صفحه به صورت embedded نمایش داده می‌شود
  final bool embedded;

  @override
  State<ConfidentialUserInfoScreen> createState() =>
      _ConfidentialUserInfoScreenState();
}

/// کلاس state برای صفحه اطلاعات محرمانه
class _ConfidentialUserInfoScreenState
    extends State<ConfidentialUserInfoScreen> {
  /// وضعیت ثبت‌شده در پایگاه‌داده؛ تغییر صفحه بر اساس این مقدار است
  bool _hasConsented = false;

  /// وضعیت تیک چک‌باکس برای فعال‌سازی دکمه
  bool _agreeChecked = false;

  /// وضعیت بارگذاری
  bool _isLoading = false;

  /// وضعیت بررسی
  bool _isChecking = true;

  /// آلبوم عکس و تنظیم نمایش برای مربی
  bool _photosVisibleToTrainer = false;

  /// لیست عکس‌های آلبوم
  final List<_AlbumPhoto> _photos = [];

  /// زمان آخرین عکس برای هر نوع
  final Map<_PhotoType, DateTime?> _lastPhotoAt = {};

  /// نوع عکس انتخاب شده
  _PhotoType _selectedType = _PhotoType.front;

  /// انتخابگر عکس
  final ImagePicker _picker = ImagePicker();

  /// فرم: وضعیت و کنترلرها
  /// کنترلرهای فیلدهای فرم
  final Map<String, TextEditingController> _controllers = {};

  /// تنظیمات سبک زندگی
  Map<String, dynamic> _lifestylePrefs = {};

  /// تایمر ذخیره خودکار
  Timer? _saveDebounce;

  /// وضعیت باز/بسته بودن بخش‌های بازشونده
  final Map<String, bool> _expansionStates = {
    'health': true, // تب اول به صورت پیش‌فرض باز است
    'preferences': false,
    'fitness': false,
  };

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
    _loadUserData();
  }

  /// بارگذاری وضعیت رضایت کاربر
  Future<void> _loadConsentStatus() async {
    try {
      final ok = await ConfidentialUserInfoService.getConsentStatus();
      if (!mounted) return;
      setState(() {
        _hasConsented = ok;
        _isChecking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
      });
    }
  }

  /// بارگذاری اطلاعات کاربر
  Future<void> _loadUserData() async {
    try {
      final data = await ConfidentialUserInfoService.loadUserData();
      if (!mounted || data == null) return;

      setState(() {
        _photosVisibleToTrainer =
            (data['photos_visible_to_trainer'] as bool?) ?? false;

        // Load last photo times for each type
        final album = data['photo_album'] as List<dynamic>? ?? [];
        _lastPhotoAt.clear(); // Clear existing data
        for (final photoData in album) {
          final photo = photoData as Map<String, dynamic>;
          final type = _PhotoType.values.firstWhere(
            (e) => e.name == photo['type'],
            orElse: () => _PhotoType.front,
          );
          final takenAt = DateTime.parse(photo['taken_at'] as String);
          if (_lastPhotoAt[type] == null ||
              takenAt.isAfter(_lastPhotoAt[type]!)) {
            _lastPhotoAt[type] = takenAt;
          }
        }

        // Load photos from album
        _photos.clear();
        for (final photoData in album) {
          final photo = photoData as Map<String, dynamic>;
          _photos.add(
            _AlbumPhoto(
              url: (photo['url'] as String?) ?? '',
              takenAt: DateTime.parse(photo['taken_at'] as String),
              label: photo['notes'] as String?,
              type: _PhotoType.values.firstWhere(
                (e) => e.name == photo['type'],
                orElse: () => _PhotoType.front,
              ),
            ),
          );
        }

        // Load lifestyle/preferences
        _lifestylePrefs = Map<String, dynamic>.from(
          data['lifestyle_preferences'] as Map<String, dynamic>? ?? {},
        );
        _initOrUpdateControllersWithPrefs();
      });
    } catch (e) {
      // Error loading user data - handled silently
    }
  }

  /// مقداردهی اولیه کنترلرها با تنظیمات
  void _initOrUpdateControllersWithPrefs() {
    String get(String key) => (_lifestylePrefs[key] ?? '').toString();

    void ensure(String key) {
      _controllers.putIfAbsent(key, TextEditingController.new);
      _controllers[key]!.text = get(key);
    }

    // Health
    ensure('medical_conditions');
    ensure('medications');
    ensure('allergies');
    ensure('emergency_contact');
    ensure('doctor_name');
    ensure('doctor_phone');
    ensure('health_notes');

    // Fitness goals
    ensure('primary_goals');
    ensure('secondary_goals');
    ensure('target_weight');
    ensure('target_body_fat');
    ensure('motivation');

    // Preferences/lifestyle
    ensure('life_conditions');
    ensure('food_preferences');
    ensure('sleep_pattern');
    ensure('smoking');
    ensure('alcohol');
    ensure('additional_info');
  }

  /// تغییر فیلد فرم
  void _onFieldChanged(String key, String value) {
    _lifestylePrefs[key] = value;
    _scheduleAutoSave();
  }

  /// زمان‌بندی ذخیره خودکار
  void _scheduleAutoSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), _saveForm);
  }

  /// ذخیره فرم
  Future<void> _saveForm() async {
    if (!mounted) return;

    final ok = await ConfidentialUserInfoService.updateLifestylePreferences(
      _lifestylePrefs,
    );
    
    if (!mounted) return;

    if (ok) {
      // نمایش feedback موفق با SnackBar
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.checkCircle,
                color: Colors.green.shade700,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'ذخیره شد',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: Colors.green.shade900,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade50,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: Colors.green.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          margin: EdgeInsets.all(16.w),
          elevation: 4,
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.alertCircle,
                color: AppTheme.errorColor,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'ذخیره اطلاعات ناموفق بود',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: context.cardColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: AppTheme.errorColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          margin: EdgeInsets.all(16.w),
          elevation: 4,
        ),
      );
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// نمایش صفحه پردازش عکس
  Future<XFile?> _showImageProcessingDialog(XFile originalImage) async {
    return showDialog<XFile?>(
      context: context,
      builder: (context) =>
          _ImageProcessingDialog(originalImage: originalImage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _isChecking
        ? const Center(
            child: CircularProgressIndicator(color: AppTheme.goldColor),
          )
        : _hasConsented
        ? _buildMainContent()
        : _buildConsentScreen();

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        title: Text(
          'اطلاعات محرمانه کاربر',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: context.textColor),
      ),
      body: body,
    );
  }

  Widget _buildConsentScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هشدار مهم
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  LucideIcons.alertTriangle,
                  color: AppTheme.errorColor,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'هشدار: اطلاعات فوق‌العاده محرمانه',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // متن قانونی
          Text(
            'موافقت‌نامه دسترسی به اطلاعات محرمانه',
            style: TextStyle(
              color: AppTheme.goldColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),

          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعهدات و مسئولیت‌های کاربر:',
                  style: TextStyle(
                    color: AppTheme.goldColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 12),

                _buildConsentItem(
                  '1. من متعهد می‌شوم که تمام اطلاعات ارائه شده در این بخش '
                  'کاملاً واقعی و دقیق باشد.',
                ),
                _buildConsentItem(
                  '2. من آگاه هستم که این اطلاعات شامل عکس‌های بدن، '
                  'اطلاعات پزشکی حساس، و سایر داده‌های شخصی فوق‌العاده محرمانه است.',
                ),
                _buildConsentItem(
                  '3. من مسئولیت کامل حفظ حریم خصوصی و امنیت این اطلاعات '
                  'را بر عهده می‌گیرم.',
                ),
                _buildConsentItem(
                  '4. من موافقت می‌کنم که این اطلاعات فقط در صورت انتخاب '
                  'صریح من و پس از بررسی دقیق صلاحیت مربی، در اختیار مربی قرار گیرد.',
                ),
                _buildConsentItem(
                  '5. من آگاه هستم که هرگونه سوءاستفاده از این اطلاعات '
                  'کاملاً بر عهده خود من است و تیم GymAI هیچ مسئولیتی در قبال آن ندارد.',
                ),
                _buildConsentItem(
                  '6. من متعهد می‌شوم که در صورت تغییر در شرایط، فوراً '
                  'این اطلاعات را به‌روزرسانی کنم.',
                ),
                _buildConsentItem(
                  '7. من آگاه هستم که این اطلاعات ممکن است برای ارائه '
                  'خدمات بهتر و شخصی‌سازی برنامه‌های تمرینی استفاده شود.',
                ),

                SizedBox(height: 16.h),

                Text(
                  'تعهدات GymAI:',
                  style: TextStyle(
                    color: AppTheme.goldColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                SizedBox(height: 12.h),

                _buildConsentItem(
                  '1. ما متعهد می‌شویم که تمام اطلاعات شما را با بالاترین '
                  'استانداردهای امنیتی محافظت کنیم.',
                ),
                _buildConsentItem(
                  '2. هیچ‌یک از اطلاعات شما بدون رضایت صریح شما در اختیار '
                  'شخص ثالث قرار نخواهد گرفت.',
                ),
                _buildConsentItem(
                  '3. ما از این اطلاعات فقط برای بهبود خدمات و ارائه '
                  'برنامه‌های شخصی‌سازی شده استفاده خواهیم کرد.',
                ),
                _buildConsentItem(
                  '4. در صورت درخواست شما، تمام اطلاعات شما فوراً حذف '
                  'خواهد شد.',
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // چک‌باکس تایید
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.veryDarkBackground,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _agreeChecked,
                  onChanged: (value) {
                    setState(() {
                      _agreeChecked = value ?? false;
                    });
                  },
                  activeColor: AppTheme.goldColor,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'من تمام شرایط و تعهدات فوق را خوانده و کاملاً درک کرده‌ام '
                    'و با آن‌ها موافقت دارم.',
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // دکمه‌های عملیات
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.textSecondary,
                    foregroundColor: context.backgroundColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'انصراف',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _agreeChecked ? _proceedToMainContent : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _agreeChecked
                        ? AppTheme.goldColor
                        : context.textSecondary,
                    foregroundColor: _agreeChecked
                        ? AppTheme.onGoldColor
                        : context.backgroundColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            color: AppTheme.onGoldColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'تایید و ادامه',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت آیتم تعهد
  Widget _buildConsentItem(String text, {TextStyle? style}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h, left: 8.w),
            width: 4.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppTheme.goldColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style:
                  style ??
                  TextStyle(
                    color: context.textSecondary,
                    fontSize: 12.sp,
                    height: 1.5,
                    fontFamily: AppTheme.fontFamily,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// ساخت محتوای اصلی
  Widget _buildMainContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر اصلی
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppTheme.goldColor.withValues(alpha: 0.15),
                        AppTheme.goldColor.withValues(alpha: 0.1),
                      ]
                    : [
                        AppTheme.lightGoldGradient.withValues(alpha: 0.3),
                        AppTheme.lightGoldGradient.withValues(alpha: 0.2),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.shield,
                  size: 32.sp,
                  color: AppTheme.goldColor,
                ),
                SizedBox(height: 6.h),
                Text(
                  'اطلاعات محرمانه',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'مدیریت اطلاعات شخصی و حساس شما',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // تیپس راهنما
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.blue.withValues(alpha: 0.15)
                  : Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(LucideIcons.info, color: Colors.blue, size: 16.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'هرچه دقیق‌تر و شفاف‌تر توضیح بدهید، اطلاعات دقیق‌تری '
                    'به مربی‌تان منتقل می‌شود و تصمیم‌گیری او بهتر خواهد بود.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12.sp,
                      fontFamily: AppTheme.fontFamily,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // اطلاعات سلامت (بازشونده)
          _buildExpansion(
            key: 'health',
            icon: LucideIcons.heart,
            title: 'اطلاعات سلامت',
            child: _buildHealthForm(),
          ),

          // علایق و سبک زندگی (بازشونده)
          _buildExpansion(
            key: 'preferences',
            icon: LucideIcons.list,
            title: 'علایق و سبک زندگی',
            child: _buildPreferencesForm(),
          ),

          // اهداف تناسب اندام (بازشونده)
          _buildExpansion(
            key: 'fitness',
            icon: LucideIcons.target,
            title: 'اهداف تناسب اندام',
            child: _buildFitnessGoalsForm(),
          ),

          // آلبوم عکس‌ها + تیک نمایش برای مربی
          _buildAlbumSection(),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  /// ساخت بخش بازشونده
  Widget _buildExpansion({
    required String key,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expansionStates[key] ?? false;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isExpanded
            ? (isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.08)
                  : AppTheme.goldColor.withValues(alpha: 0.05))
            : context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isExpanded
              ? AppTheme.goldColor
              : AppTheme.goldColor.withValues(alpha: 0.2),
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  blurRadius: 8.r,
                  spreadRadius: 0,
                  offset: Offset(0, 2.h),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
                  blurRadius: 2.r,
                  spreadRadius: 0,
                  offset: Offset(0, 1.h),
                ),
              ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppTheme.goldColor.withValues(alpha: 0.1),
          highlightColor: AppTheme.goldColor.withValues(alpha: 0.05),
        ),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          iconColor: AppTheme.goldColor,
          collapsedIconColor: AppTheme.goldColor,
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          title: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: isExpanded
                      ? AppTheme.goldColor.withValues(alpha: 0.25)
                      : AppTheme.goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: AppTheme.goldColor, size: 16.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: isExpanded ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: child,
            ),
          ],
          onExpansionChanged: (expanded) {
            HapticFeedback.selectionClick();
            setState(() {
              _expansionStates[key] = expanded;
            });
          },
        ),
      ),
    );
  }

  /// فرم اطلاعات سلامت
  Widget _buildHealthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBoundDropdown(
          'شرایط پزشکی',
          'medical_conditions',
          [
            'هیچکدام',
            'دیابت',
            'فشار خون بالا',
            'فشار خون پایین',
            'آسم',
            'بیماری قلبی',
            'مشکلات مفصلی',
            'کمردرد',
            'زانو درد',
            'مشکلات تیروئید',
            'کم خونی',
            'مشکلات گوارشی',
            'سایر',
          ],
          hint: 'انتخاب کنید',
          allowMultiple: true,
        ),
        _buildBoundDropdown(
          'داروهای مصرفی',
          'medications',
          [
            'هیچکدام',
            'داروهای فشار خون',
            'داروهای دیابت',
            'داروهای تیروئید',
            'مکمل‌های ویتامین',
            'مکمل‌های پروتئین',
            'داروهای ضد التهاب',
            'سایر',
          ],
          hint: 'انتخاب کنید',
          allowMultiple: true,
        ),
        _buildBoundDropdown(
          'آلرژی‌ها',
          'allergies',
          [
            'هیچکدام',
            'آلرژی غذایی',
            'آلرژی دارویی',
            'آلرژی فصلی',
            'آلرژی به لاکتوز',
            'آلرژی به گلوتن',
            'آلرژی به بادام زمینی',
            'سایر',
          ],
          hint: 'انتخاب کنید',
          allowMultiple: true,
        ),
        _buildBoundTextField('تماس اضطراری', 'emergency_contact'),
        _buildBoundTextField('نام پزشک', 'doctor_name'),
        _buildBoundTextField('تلفن پزشک', 'doctor_phone'),
        _buildBoundTextArea('یادداشت‌ها', 'health_notes'),
      ],
    );
  }

  /// فرم اهداف تناسب اندام
  Widget _buildFitnessGoalsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBoundDropdown(
          'اهداف اصلی',
          'primary_goals',
          [
            'کاهش وزن',
            'افزایش وزن',
            'عضله‌سازی',
            'کاهش چربی',
            'افزایش قدرت',
            'افزایش استقامت',
            'بهبود فرم بدن',
            'سلامت عمومی',
            'آماده‌سازی مسابقه',
            'سایر',
          ],
          hint: 'انتخاب کنید',
          allowMultiple: true,
        ),
        _buildBoundDropdown(
          'اهداف فرعی',
          'secondary_goals',
          [
            'افزایش انعطاف',
            'بهبود تعادل',
            'کاهش استرس',
            'بهبود خواب',
            'افزایش انرژی',
            'بهبود اعتماد به نفس',
            'سایر',
          ],
          hint: 'انتخاب کنید',
          allowMultiple: true,
        ),
        _buildBoundTextField('وزن هدف (کیلوگرم)', 'target_weight'),
        _buildBoundTextField('درصد چربی هدف (%)', 'target_body_fat'),
        _buildBoundTextArea('انگیزه/چالش‌ها', 'motivation'),
      ],
    );
  }

  /// فرم علایق و سبک زندگی
  Widget _buildPreferencesForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBoundDropdown(
          'شرایط خاص زندگی',
          'life_conditions',
          [
            'هیچکدام',
            'کار شیفتی',
            'سفر زیاد',
            'استرس شغلی بالا',
            'زندگی پرتحرک',
            'زندگی کم‌تحرک',
            'مشغله زیاد',
            'سایر',
          ],
          hint: 'انتخاب کنید',
          allowMultiple: true,
        ),
        _buildBoundDropdown(
          'علایق غذایی',
          'food_preferences',
          [
            'هیچ محدودیتی',
            'گیاهخواری',
            'وگان',
            'بدون گلوتن',
            'بدون لاکتوز',
            'کم کربوهیدرات',
            'پروتئین بالا',
            'کم چربی',
            'کم نمک',
            'سایر',
          ],
          hint: 'انتخاب کنید',
          allowMultiple: true,
        ),
        _buildBoundDropdown(
          'الگوی خواب',
          'sleep_pattern',
          [
            'کمتر از 6 ساعت',
            '6-7 ساعت',
            '7-8 ساعت',
            '8-9 ساعت',
            'بیش از 9 ساعت',
            'خواب نامنظم',
            'کیفیت خواب پایین',
            'کیفیت خواب خوب',
          ],
          hint: 'انتخاب کنید',
        ),
        _buildBoundDropdown(
          'مصرف سیگار',
          'smoking',
          [
            'مصرف نمی‌کنم',
            'ترک کرده‌ام',
            'گاهی (کمتر از 5 عدد در روز)',
            'متوسط (5-10 عدد در روز)',
            'زیاد (بیش از 10 عدد در روز)',
          ],
          hint: 'انتخاب کنید',
        ),
        _buildBoundDropdown(
          'مصرف الکل',
          'alcohol',
          [
            'مصرف نمی‌کنم',
            'خیلی کم (ماهانه)',
            'کم (هفتگی)',
            'متوسط (چند بار در هفته)',
            'زیاد (روزانه)',
          ],
          hint: 'انتخاب کنید',
        ),
        _buildBoundTextArea(
          'اطلاعات اضافی که مربی باید بداند',
          'additional_info',
        ),
      ],
    );
  }

  /// آلبوم عکس‌ها + تیک نمایش برای مربی
  Widget _buildAlbumSection() {
    final canAdd = _canAddNewPhoto();
    final remainingDays = _daysUntilNextPhoto();

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  LucideIcons.camera,
                  color: AppTheme.goldColor,
                  size: 14.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'آلبوم عکس‌ها',
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // انتخاب نوع عکس (کشویی/تب‌گونه)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip(_PhotoType.front, 'جلو'),
                _buildTypeChip(_PhotoType.back, 'پشت'),
                _buildTypeChip(_PhotoType.side, 'کنار'),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // تیک نمایش برای مربی
          CheckboxListTile(
            value: _photosVisibleToTrainer,
            onChanged: (v) async {
              final newVal = v ?? false;
              final ok =
                  await ConfidentialUserInfoService.updatePhotosVisibility(
                    newVal,
                  );
              if (ok) {
                setState(() => _photosVisibleToTrainer = newVal);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'ثبت تغییرات ناموفق بود',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor,
                      ),
                    ),
                    backgroundColor: context.cardColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(
                        color: AppTheme.errorColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                );
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.goldColor,
            title: Text(
              'قابل نمایش برای مربی',
              style: TextStyle(
                color: context.textColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            subtitle: Text(
              'می‌توانید هر زمان این گزینه را تغییر دهید',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11.sp,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),

          // نکته درباره مات‌سازی صورت
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, color: Colors.orange, size: 14.sp),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'برای حفظ حریم خصوصی، صورت خود را تا حد امکان '
                    'مات یا برش دهید.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11.sp,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          if (!canAdd)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                'تا $remainingDays روز دیگر می‌توانید عکس جدید اضافه کنید',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11.sp,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),

          SizedBox(height: 8.h),

          // گرید عکس‌ها (نوع منتخب) + مربع افزودن
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8.w,
              crossAxisSpacing: 8.w,
              childAspectRatio: 0.78,
            ),
            itemCount: 1 + _photos.where((p) => p.type == _selectedType).length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _AddPhotoTile(
                  enabled: canAdd,
                  onTap: canAdd ? _onAddPhoto : null,
                );
              }
              final filtered = _photos
                  .where((p) => p.type == _selectedType)
                  .toList();
              final p = filtered[index - 1];
              return _PhotoGridItem(photo: p);
            },
          ),
        ],
      ),
    );
  }

  /// ساخت چیپ نوع عکس
  Widget _buildTypeChip(_PhotoType type, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool selected = _selectedType == type;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Container(
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.4),
                    blurRadius: 8.r,
                    spreadRadius: 0,
                    offset: Offset(0, 2.h),
                  ),
                ],
              )
            : null,
        child: ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          selected: selected,
          onSelected: (_) => setState(() => _selectedType = type),
          selectedColor: AppTheme.goldColor,
          backgroundColor: isDark
              ? context.veryDarkBackground
              : context.cardColor,
          labelStyle: TextStyle(
            color: selected
                ? (isDark ? Colors.white : AppTheme.onGoldColor)
                : context.textSecondary,
            fontSize: 11.sp,
          ),
          shape: StadiumBorder(
            side: BorderSide(
              color: selected
                  ? AppTheme.goldColor
                  : AppTheme.goldColor.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        ),
      ),
    );
  }

  /// ورودی‌های باند شده با ذخیره خودکار
  Widget _buildBoundTextField(String label, String keyName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _controllers.putIfAbsent(keyName, TextEditingController.new);
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label جداگانه برای جلوگیری از بریده شدن
          Padding(
            padding: EdgeInsets.only(bottom: 8.h, right: 4.w),
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.goldColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
                height: 1.3,
              ),
            ),
          ),
          TextField(
            controller: _controllers[keyName],
            onChanged: (v) => _onFieldChanged(keyName, v),
            style: TextStyle(
              color: context.textColor,
              fontSize: 13.sp,
              fontFamily: AppTheme.fontFamily,
            ),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(
                color: context.textSecondary.withValues(alpha: 0.5),
                fontSize: 13.sp,
                fontFamily: AppTheme.fontFamily,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              filled: true,
              fillColor: isDark
                  ? context.veryDarkBackground
                  : context.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.separatorColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppTheme.goldColor, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ورودی dropdown باند شده با ذخیره خودکار
  Widget _buildBoundDropdown(
    String label,
    String keyName,
    List<String> options, {
    String? hint,
    bool allowMultiple = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentValue = (_lifestylePrefs[keyName] ?? '').toString();
    final selectedValues = allowMultiple && currentValue.isNotEmpty
        ? currentValue.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : currentValue.isNotEmpty
            ? [currentValue]
            : <String>[];

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8.h, right: 4.w),
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.goldColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
                height: 1.3,
              ),
            ),
          ),
          if (allowMultiple)
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: options.map((option) {
                final isSelected = selectedValues.contains(option);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // فضای ثابت برای تیک - همیشه وجود دارد
                      SizedBox(
                        width: 18.w,
                        child: isSelected
                            ? Icon(
                                LucideIcons.check,
                                size: 14.sp,
                                color: isDark ? Colors.white : AppTheme.onGoldColor,
                              )
                            : const SizedBox.shrink(),
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : AppTheme.onGoldColor)
                                : context.textColor,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  showCheckmark: false, // غیرفعال کردن تیک پیش‌فرض
                  onSelected: (selected) {
                    HapticFeedback.selectionClick();
                    final newValues = List<String>.from(selectedValues);
                    if (selected) {
                      if (!newValues.contains(option)) {
                        newValues.add(option);
                      }
                    } else {
                      newValues.remove(option);
                    }
                    final value = newValues.join(', ');
                    _onFieldChanged(keyName, value);
                    SafeSetState.call(this, () {});
                  },
                  selectedColor: AppTheme.goldColor,
                  backgroundColor: isDark
                      ? context.veryDarkBackground
                      : context.cardColor,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.goldColor
                        : AppTheme.goldColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? context.veryDarkBackground
                    : context.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: currentValue.isNotEmpty
                      ? AppTheme.goldColor
                      : context.separatorColor,
                  width: currentValue.isNotEmpty ? 2 : 1.5,
                ),
                boxShadow: currentValue.isNotEmpty
                    ? [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.1),
                          blurRadius: 4.r,
                          spreadRadius: 0,
                          offset: Offset(0, 1.h),
                        ),
                      ]
                    : null,
              ),
              child: DropdownButtonFormField<String>(
                value: currentValue.isNotEmpty && options.contains(currentValue)
                    ? currentValue
                    : null,
                decoration: InputDecoration(
                  hintText: hint ?? label,
                  hintStyle: TextStyle(
                    color: context.textSecondary.withValues(alpha: 0.5),
                    fontSize: 13.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 13.sp,
                  fontFamily: AppTheme.fontFamily,
                ),
                dropdownColor: isDark
                    ? context.veryDarkBackground
                    : context.cardColor,
                icon: Icon(
                  LucideIcons.chevronDown,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      hint ?? 'انتخاب کنید',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13.sp,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                  ...options.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 13.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  _onFieldChanged(keyName, value ?? '');
                  SafeSetState.call(this, () {});
                },
              ),
            ),
        ],
      ),
    );
  }

  /// ورودی متن چندخطی باند شده
  Widget _buildBoundTextArea(String label, String keyName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _controllers.putIfAbsent(keyName, TextEditingController.new);
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label جداگانه برای جلوگیری از بریده شدن
          Padding(
            padding: EdgeInsets.only(bottom: 8.h, right: 4.w),
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.goldColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
                height: 1.3,
              ),
            ),
          ),
          TextField(
            controller: _controllers[keyName],
            onChanged: (v) {
              _onFieldChanged(keyName, v);
            },
            style: TextStyle(
              color: context.textColor,
              fontSize: 14.sp,
              fontFamily: AppTheme.fontFamily,
              height: 1.5,
            ),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(
                color: context.textSecondary.withValues(alpha: 0.5),
                fontSize: 14.sp,
                fontFamily: AppTheme.fontFamily,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              filled: true,
              fillColor: isDark
                  ? context.veryDarkBackground
                  : context.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.separatorColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppTheme.goldColor, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بررسی امکان افزودن عکس جدید
  bool _canAddNewPhoto() {
    final lastPhotoAt = _lastPhotoAt[_selectedType];
    if (lastPhotoAt == null) return true;
    final days = DateTime.now().difference(lastPhotoAt).inDays;
    return days >= 30;
  }

  /// محاسبه روزهای باقی‌مانده تا عکس بعدی
  int _daysUntilNextPhoto() {
    final lastPhotoAt = _lastPhotoAt[_selectedType];
    if (lastPhotoAt == null) return 0;
    final days = DateTime.now().difference(lastPhotoAt).inDays;
    final remain = 30 - days;
    return remain > 0 ? remain : 0;
  }

  /// افزودن عکس جدید
  Future<void> _onAddPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return;

      // نمایش صفحه پردازش عکس
      final processedImage = await _showImageProcessingDialog(picked);
      if (processedImage == null) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'برای آپلود لازم است وارد حساب شوید',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final now = DateTime.now();
      final ext = processedImage.name.split('.').last.toLowerCase();
      final fileName =
          '${userId}_${_selectedType.name}_'
          '${now.millisecondsSinceEpoch}.$ext';
      final filePath = 'public/$fileName'; // مسیر کامل مثل profile_images

      // Upload to Supabase Storage (bucket: confidential_photos)
      try {
        _openUploadingDialog(processedImage);
        await Supabase.instance.client.storage
            .from('confidential_photos')
            .upload(filePath, File(processedImage.path));
      } catch (e) {
        // اگر فایل وجود داشت، با upsert سعی می‌کنیم
        try {
          await Supabase.instance.client.storage
              .from('confidential_photos')
              .upload(
                filePath,
                File(processedImage.path),
                fileOptions: const FileOptions(upsert: true),
              );
        } catch (e2) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).maybePop();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'آپلود ناموفق بود: $e2',
                  style: TextStyle(fontFamily: AppTheme.fontFamily),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }

      final publicUrl = Supabase.instance.client.storage
          .from('confidential_photos')
          .getPublicUrl(filePath);

      // ثبت در دیتابیس
      final ok = await ConfidentialUserInfoService.appendPhotoToAlbum(
        url: publicUrl,
        type: _selectedType.name,
        takenAt: now,
        isVisibleToTrainer: _photosVisibleToTrainer,
      );

      if (!mounted) return;

      if (ok) {
        setState(() {
          _photos.add(
            _AlbumPhoto(
              url: publicUrl,
              takenAt: now,
              label: 'عکس جدید',
              type: _selectedType,
            ),
          );
          _lastPhotoAt[_selectedType] = now;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ثبت عکس در دیتابیس ناموفق بود',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: context.cardColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در انتخاب یا آپلود عکس: $e',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: context.cardColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
      );
    }
  }

  /// نمایش دیالوگ آپلود
  void _openUploadingDialog(XFile image) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: isDark
          ? context.backgroundColor.withValues(alpha: 0.85)
          : AppTheme.lightTextColor.withValues(alpha: 0.4),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: Container(
            constraints: BoxConstraints(maxWidth: 420.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.1 : 0.2,
                  ),
                  blurRadius: 20.r,
                  spreadRadius: 2.r,
                  offset: Offset(0.w, 6.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'در حال آپلود عکس',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(image.path), fit: BoxFit.cover),
                            Container(
                              color: Colors.black.withValues(alpha: 0.1),
                            ),
                            Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.goldColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'لطفاً منتظر بمانید...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 15.sp,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// ادامه به محتوای اصلی
  Future<void> _proceedToMainContent() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final ok = await ConfidentialUserInfoService.saveConsentAccepted();

      setState(() {
        _isLoading = false;
        _hasConsented = ok;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// کلاس عکس آلبوم
class _AlbumPhoto {
  /// سازنده عکس آلبوم
  _AlbumPhoto({
    required this.url,
    required this.takenAt,
    this.label,
    this.type = _PhotoType.front,
    this.isAsset = false,
  });

  /// URL عکس
  final String url;

  /// زمان گرفته شدن عکس
  final DateTime takenAt;

  /// برچسب عکس
  final String? label;

  /// آیا عکس از assets است
  final bool isAsset;

  /// نوع عکس
  final _PhotoType type;
}

/// کارت نمایش عکس
class _PhotoCard extends StatelessWidget {
  /// سازنده کارت عکس
  const _PhotoCard({required this.photo});

  /// عکس آلبوم
  final _AlbumPhoto photo;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.veryDarkBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            Positioned.fill(
              child: photo.isAsset
                  ? Image.asset(photo.url, fit: BoxFit.cover)
                  : Image.network(
                      photo.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'images/food_placeholder.png',
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            Positioned(
              right: 6.w,
              top: 6.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _formatJalali(photo.takenAt),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// فرمت تاریخ شمسی
  static String _formatJalali(DateTime dt) {
    // استفاده از کتابخانه shamsi_date مثل بخش ثبت تمرین
    final jalali = Gregorian.fromDateTime(dt).toJalali();
    final monthNames = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    return '${jalali.day} ${monthNames[jalali.month]} ${jalali.year}';
  }
}

/// صفحه پردازش عکس با ابزار مات‌سازی موضعی
class _ImageProcessingDialog extends StatefulWidget {
  /// سازنده دیالوگ پردازش عکس
  const _ImageProcessingDialog({required this.originalImage});

  /// عکس اصلی
  final XFile originalImage;

  @override
  State<_ImageProcessingDialog> createState() => _ImageProcessingDialogState();
}

/// کلاس state برای دیالوگ پردازش عکس
class _ImageProcessingDialogState extends State<_ImageProcessingDialog> {
  /// عکس پردازش شده
  XFile? _processedImage;

  /// اندازه قلم
  double _brushSize = 20;

  /// رنگ قلم
  final Color _brushColor = const Color.fromARGB(255, 206, 191, 191);

  /// نقاشی‌های قلم
  final List<Offset> _brushStrokes = [];

  /// عکس اصلی
  ui.Image? _originalImage;

  /// وضعیت بارگذاری
  bool _isLoading = true;

  /// کلید repaint
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _processedImage = widget.originalImage;
    _loadImage();
  }

  /// بارگذاری عکس
  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.originalImage.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _originalImage = frame.image;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500.w,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.2),
              blurRadius: 20.r,
              spreadRadius: 2.r,
              offset: Offset(0.w, 6.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // هدر
                Row(
                  children: [
                    Icon(
                      LucideIcons.paintbrush,
                      color: AppTheme.goldColor,
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'مات‌سازی موضعی',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(LucideIcons.x, color: context.textColor),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // نمایش عکس با قابلیت نقاشی
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.goldColor,
                              ),
                            )
                          : RepaintBoundary(
                              key: _repaintKey,
                              child: GestureDetector(
                                onPanStart: _onPanStart,
                                onPanUpdate: _onPanUpdate,
                                child: CustomPaint(
                                  painter: _ImagePainter(
                                    image: _originalImage,
                                    brushStrokes: _brushStrokes,
                                    brushSize: _brushSize,
                                    brushColor: _brushColor,
                                  ),
                                  size: Size.infinite,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // کنترل‌های ابزار
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: context.veryDarkBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // اندازه قلم
                      Row(
                        children: [
                          Icon(
                            LucideIcons.circle,
                            color: AppTheme.goldColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'اندازه قلم:',
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      Row(
                        children: [
                          Text(
                            'کوچک',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13.sp,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _brushSize,
                              min: 5,
                              max: 50,
                              divisions: 9,
                              activeColor: AppTheme.goldColor,
                              onChanged: (value) {
                                setState(() {
                                  _brushSize = value;
                                });
                              },
                            ),
                          ),
                          Text(
                            'بزرگ',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13.sp,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // دکمه‌های عملیات
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _clearStrokes,
                              icon: Icon(LucideIcons.eraser, size: 16.sp),
                              label: Text(
                                'پاک کردن',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _resetImage,
                              icon: Icon(LucideIcons.rotateCcw, size: 16.sp),
                              label: Text(
                                'بازنشانی',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // دکمه‌های نهایی
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.textSecondary,
                          foregroundColor: context.backgroundColor,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'انصراف',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldColor,
                          foregroundColor: AppTheme.onGoldColor,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'تایید و آپلود',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// شروع کشیدن قلم
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _brushStrokes.add(details.localPosition);
    });
  }

  /// به‌روزرسانی کشیدن قلم
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _brushStrokes.add(details.localPosition);
    });
  }

  /// پاک کردن نقاشی‌ها
  void _clearStrokes() {
    setState(_brushStrokes.clear);
  }

  /// بازنشانی عکس
  void _resetImage() {
    setState(_brushStrokes.clear);
  }

  /// تایید عکس
  Future<void> _confirmImage() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.of(context).pop(_processedImage);
        return;
      }

      final ui.Image combinedImage = await boundary.toImage(
        pixelRatio: ui.window.devicePixelRatio,
      );
      final byteData = await combinedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        Navigator.of(context).pop(_processedImage);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/edited_'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      final editedXFile = XFile(
        file.path,
        mimeType: 'image/png',
        name: 'edited.png',
      );

      Navigator.of(context).pop(editedXFile);
    } catch (_) {
      Navigator.of(context).pop(_processedImage);
    }
  }
}

/// Painter برای نمایش عکس و نقاشی
class _ImagePainter extends CustomPainter {
  /// سازنده painter
  _ImagePainter({
    required this.image,
    required this.brushStrokes,
    required this.brushSize,
    required this.brushColor,
  });

  /// عکس اصلی
  final ui.Image? image;

  /// نقاشی‌های قلم
  final List<Offset> brushStrokes;

  /// اندازه قلم
  final double brushSize;

  /// رنگ قلم
  final Color brushColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    // محاسبه نسبت تصویر
    final imageAspectRatio = image!.width / image!.height;
    final canvasAspectRatio = size.width / size.height;

    double drawWidth;
    double drawHeight;
    double offsetX;
    double offsetY;

    if (imageAspectRatio > canvasAspectRatio) {
      drawWidth = size.width;
      drawHeight = size.width / imageAspectRatio;
      offsetX = 0;
      offsetY = (size.height - drawHeight) / 2;
    } else {
      drawHeight = size.height;
      drawWidth = size.height * imageAspectRatio;
      offsetX = (size.width - drawWidth) / 2;
      offsetY = 0;
    }

    // رسم تصویر
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight),
      Paint(),
    );

    // رسم نقاشی‌های کاربر
    final paint = Paint()
      ..color = brushColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < brushStrokes.length; i++) {
      final point = brushStrokes[i];
      canvas.drawCircle(
        Offset(point.dx - offsetX, point.dy - offsetY),
        brushSize / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// نوع عکس
enum _PhotoType {
  /// جلو
  front,

  /// پشت
  back,

  /// کنار
  side,
}

/// تایل افزودن عکس
class _AddPhotoTile extends StatelessWidget {
  /// سازنده تایل افزودن عکس
  const _AddPhotoTile({required this.enabled, this.onTap});

  /// آیا فعال است
  final bool enabled;

  /// callback کلیک
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.veryDarkBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: enabled
                      ? AppTheme.goldColor.withValues(alpha: 0.5)
                      : context.separatorColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.plus,
                  color: enabled ? AppTheme.goldColor : context.textSecondary,
                  size: 28.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'افزودن',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 11.sp,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

/// آیتم گرید عکس
class _PhotoGridItem extends StatelessWidget {
  /// سازنده آیتم گرید عکس
  const _PhotoGridItem({required this.photo});

  /// عکس آلبوم
  final _AlbumPhoto photo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _openPreview(context),
            borderRadius: BorderRadius.circular(12.r),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: photo.isAsset
                  ? Image.asset(photo.url, fit: BoxFit.cover)
                  : Image.network(
                      photo.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Image.asset(
                        'images/food_placeholder.png',
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _PhotoCard._formatJalali(photo.takenAt),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 12.sp,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }

  /// باز کردن پیش‌نمایش عکس
  void _openPreview(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      barrierColor: isDark
          ? context.backgroundColor.withValues(alpha: 0.85)
          : AppTheme.lightTextColor.withValues(alpha: 0.4),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 24.h),
          child: Container(
            constraints: BoxConstraints(maxWidth: 0.98.sw, maxHeight: 0.9.sh),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.1 : 0.2,
                  ),
                  blurRadius: 20.r,
                  spreadRadius: 2.r,
                  offset: Offset(0.w, 6.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'نمایش عکس',
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(LucideIcons.x, color: context.textColor),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: ColoredBox(
                          color: context.veryDarkBackground,
                          child: InteractiveViewer(
                            maxScale: 4,
                            child: photo.isAsset
                                ? Image.asset(photo.url, fit: BoxFit.contain)
                                : Image.network(
                                    photo.url,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.goldColor,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stack) =>
                                        Image.asset(
                                          'images/food_placeholder.png',
                                          fit: BoxFit.contain,
                                        ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
