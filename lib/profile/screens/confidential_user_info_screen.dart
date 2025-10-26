import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gymaipro/profile/services/confidential_user_info_service.dart';
import 'package:gymaipro/theme/app_theme.dart';

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
    final ok = await ConfidentialUserInfoService.updateLifestylePreferences(
      _lifestylePrefs,
    );
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ذخیره اطلاعات ناموفق بود',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'اطلاعات محرمانه کاربر',
          style: GoogleFonts.vazirmatn(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: body,
    );
  }

  Widget _buildConsentScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هشدار مهم
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.alertTriangle,
                  color: Colors.red,
                  size: 24,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'هشدار: اطلاعات فوق‌العاده محرمانه',
                    style: GoogleFonts.vazirmatn(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // متن قانونی
          Text(
            'موافقت‌نامه دسترسی به اطلاعات محرمانه',
            style: GoogleFonts.vazirmatn(
              color: AppTheme.goldColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعهدات و مسئولیت‌های کاربر:',
                  style: GoogleFonts.vazirmatn(
                    color: AppTheme.goldColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

                const SizedBox(height: 16),

                Text(
                  'تعهدات GymAI:',
                  style: GoogleFonts.vazirmatn(
                    color: AppTheme.goldColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

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

          const SizedBox(height: 24),

          // چک‌باکس تایید
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.1),
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
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // دکمه‌های عملیات
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'انصراف',
                    style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _agreeChecked ? _proceedToMainContent : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _agreeChecked
                        ? AppTheme.goldColor
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'تایید و ادامه',
                          style: GoogleFonts.vazirmatn(
                            fontWeight: FontWeight.bold,
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
  Widget _buildConsentItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, left: 8),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppTheme.goldColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.vazirmatn(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ساخت محتوای اصلی
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر اصلی
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.1),
                  AppTheme.goldColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.shield,
                  size: 48,
                  color: AppTheme.goldColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'اطلاعات محرمانه',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'مدیریت اطلاعات شخصی و حساس شما',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // تیپس راهنما
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.info, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'هرچه دقیق‌تر و شفاف‌تر توضیح بدهید، اطلاعات دقیق‌تری '
                    'به مربی‌تان منتقل می‌شود و تصمیم‌گیری او بهتر خواهد بود.',
                    style: GoogleFonts.vazirmatn(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // اطلاعات سلامت (بازشونده)
          _buildExpansion(
            icon: LucideIcons.heart,
            title: 'اطلاعات سلامت',
            child: _buildHealthForm(),
          ),

          // علایق و سبک زندگی (بازشونده)
          _buildExpansion(
            icon: LucideIcons.list,
            title: 'علایق و سبک زندگی',
            child: _buildPreferencesForm(),
          ),

          // اهداف تناسب اندام (بازشونده)
          _buildExpansion(
            icon: LucideIcons.target,
            title: 'اهداف تناسب اندام',
            child: _buildFitnessGoalsForm(),
          ),

          // آلبوم عکس‌ها + تیک نمایش برای مربی
          _buildAlbumSection(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// ساخت بخش بازشونده
  Widget _buildExpansion({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: AppTheme.goldColor,
          collapsedIconColor: AppTheme.goldColor,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.goldColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [child],
        ),
      ),
    );
  }

  /// فرم اطلاعات سلامت
  Widget _buildHealthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBoundTextField(
          'شرایط پزشکی (با ویرگول جدا کنید)',
          'medical_conditions',
        ),
        _buildBoundTextField('داروهای مصرفی', 'medications'),
        _buildBoundTextField('آلرژی‌ها', 'allergies'),
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
        _buildBoundTextField(
          'اهداف اصلی (با ویرگول جدا کنید)',
          'primary_goals',
        ),
        _buildBoundTextField('اهداف فرعی', 'secondary_goals'),
        _buildBoundTextField('وزن هدف', 'target_weight'),
        _buildBoundTextField('درصد چربی هدف', 'target_body_fat'),
        _buildBoundTextArea('انگیزه/چالش‌ها', 'motivation'),
      ],
    );
  }

  /// فرم علایق و سبک زندگی
  Widget _buildPreferencesForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBoundTextField(
          'شرایط خاص زندگی (مثل شیفتی بودن، سفر زیاد، استرس شغلی)',
          'life_conditions',
        ),
        _buildBoundTextField(
          'علایق غذایی/غذاهای محبوب/غذاهای ناسازگار',
          'food_preferences',
        ),
        _buildBoundTextField(
          'الگوی خواب (میانگین ساعت خواب/کیفیت خواب)',
          'sleep_pattern',
        ),
        _buildBoundTextField(
          'مصرف سیگار (مقدار/تعداد در روز یا ترک)',
          'smoking',
        ),
        _buildBoundTextField(
          'مصرف الکل (مقدار/مناسبت‌ها یا عدم مصرف)',
          'alcohol',
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.camera,
                  color: AppTheme.goldColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'آلبوم عکس‌ها',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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

          const SizedBox(height: 12),

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
                      style: GoogleFonts.vazirmatn(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.goldColor,
            title: Text(
              'قابل نمایش برای مربی',
              style: GoogleFonts.vazirmatn(color: Colors.white),
            ),
            subtitle: Text(
              'می‌توانید هر زمان این گزینه را تغییر دهید',
              style: GoogleFonts.vazirmatn(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),

          // نکته درباره مات‌سازی صورت
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.info, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'برای حفظ حریم خصوصی، صورت خود را تا حد امکان '
                    'مات یا برش دهید.',
                    style: GoogleFonts.vazirmatn(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (!canAdd)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'تا $remainingDays روز دیگر می‌توانید عکس جدید اضافه کنید',
                style: GoogleFonts.vazirmatn(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // گرید عکس‌ها (نوع منتخب) + مربع افزودن
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
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
    final bool selected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: GoogleFonts.vazirmatn()),
        selected: selected,
        onSelected: (_) => setState(() => _selectedType = type),
        selectedColor: AppTheme.goldColor,
        backgroundColor: const Color(0xFF111111),
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.grey[300],
        ),
        shape: StadiumBorder(
          side: BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.1)),
        ),
      ),
    );
  }

  /// ورودی‌های باند شده با ذخیره خودکار
  Widget _buildBoundTextField(String label, String keyName) {
    _controllers.putIfAbsent(keyName, TextEditingController.new);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controllers[keyName],
        onChanged: (v) => _onFieldChanged(keyName, v),
        style: GoogleFonts.vazirmatn(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
          ),
        ),
      ),
    );
  }

  /// ورودی متن چندخطی باند شده
  Widget _buildBoundTextArea(String label, String keyName) {
    _controllers.putIfAbsent(keyName, TextEditingController.new);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controllers[keyName],
        onChanged: (v) => _onFieldChanged(keyName, v),
        style: GoogleFonts.vazirmatn(color: Colors.white),
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
          ),
        ),
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
              style: GoogleFonts.vazirmatn(),
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
                  style: GoogleFonts.vazirmatn(),
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
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
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
            style: GoogleFonts.vazirmatn(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// نمایش دیالوگ آپلود
  void _openUploadingDialog(XFile image) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'در حال آپلود عکس',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(image.path), fit: BoxFit.cover),
                        Container(color: Colors.black.withValues(alpha: 0.1)),
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.goldColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'لطفاً منتظر بمانید...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vazirmatn(color: Colors.white70),
                ),
              ],
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
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatJalali(photo.takenAt),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
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
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // هدر
            Row(
              children: [
                const Icon(
                  LucideIcons.paintbrush,
                  color: AppTheme.goldColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'مات‌سازی موضعی',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // نمایش عکس با قابلیت نقاشی
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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

            const SizedBox(height: 16),

            // کنترل‌های ابزار
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
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
                        style: GoogleFonts.vazirmatn(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text(
                        'کوچک',
                        style: GoogleFonts.vazirmatn(color: Colors.white70),
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
                        style: GoogleFonts.vazirmatn(color: Colors.white70),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // دکمه‌های عملیات
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _clearStrokes,
                          icon: Icon(LucideIcons.eraser, size: 16.sp),
                          label: Text(
                            'پاک کردن',
                            style: GoogleFonts.vazirmatn(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _resetImage,
                          icon: const Icon(LucideIcons.rotateCcw, size: 16),
                          label: Text(
                            'بازنشانی',
                            style: GoogleFonts.vazirmatn(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // دکمه‌های نهایی
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'انصراف',
                      style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'تایید و آپلود',
                      style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled ? AppTheme.goldColor : Colors.grey,
                ),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.plus,
                  color: enabled ? AppTheme.goldColor : Colors.grey,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'افزودن',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(color: Colors.grey[400], fontSize: 11),
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
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 4),
        Text(
          _PhotoCard._formatJalali(photo.takenAt),
          textAlign: TextAlign.center,
          style: GoogleFonts.vazirmatn(color: Colors.grey[400], fontSize: 11),
        ),
      ],
    );
  }

  /// باز کردن پیش‌نمایش عکس
  void _openPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 0.98.sw,
            height: 0.9.sh,
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'نمایش عکس',
                      style: GoogleFonts.vazirmatn(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      color: const Color(0xFF111111),
                      child: InteractiveViewer(
                        maxScale: 4,
                        child: photo.isAsset
                            ? Image.asset(photo.url, fit: BoxFit.contain)
                            : Image.network(
                                photo.url,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
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
        );
      },
    );
  }
}
