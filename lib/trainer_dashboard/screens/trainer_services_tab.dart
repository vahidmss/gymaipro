import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerServicesTab extends StatefulWidget {
  const TrainerServicesTab({super.key});

  @override
  State<TrainerServicesTab> createState() => _TrainerServicesTabState();
}

class _TrainerServicesTabState extends State<TrainerServicesTab> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _trainingPriceCtr = TextEditingController();
  final TextEditingController _dietPriceCtr = TextEditingController();
  final TextEditingController _discountPctCtr = TextEditingController(
    text: '0',
  );

  bool _loading = true;
  bool _isSaving = false;
  bool _isFormatting = false;

  // enable/disable toggles
  bool _enableWorkout = true;
  bool _enableDiet = true;
  bool _enableConsult = true;
  bool _enablePackage = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _trainingPriceCtr.dispose();
    _dietPriceCtr.dispose();
    _discountPctCtr.dispose();
    super.dispose();
  }

  // Helpers: formatting/parsing
  String _normalizeDigits(String input) {
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String s = input
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('،', '')
        .replaceAll(' ', '');
    for (int i = 0; i < persian.length; i++) {
      s = s.replaceAll(persian[i], i.toString());
    }
    return s;
  }

  String _toPersianDigits(String input) {
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      final d = int.tryParse(ch);
      buffer.write(d == null ? ch : persian[d]);
    }
    return buffer.toString();
  }

  String _formatWithSeparators(String digitsAscii) {
    if (digitsAscii.isEmpty) return '';
    final chars = digitsAscii.split('').reversed.toList();
    final out = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i != 0 && i % 3 == 0) out.write(',');
      out.write(chars[i]);
    }
    return out.toString().split('').reversed.join();
  }

  String _formatPriceFa(String raw) {
    final asciiDigits = _normalizeDigits(raw).replaceAll(RegExp('[^0-9]'), '');
    final withSep = _formatWithSeparators(asciiDigits);
    return _toPersianDigits(withSep);
  }

  double _parsePriceToDouble(String formatted) {
    final asciiDigits = _normalizeDigits(
      formatted,
    ).replaceAll(RegExp('[^0-9]'), '');
    if (asciiDigits.isEmpty) return 0;
    return double.tryParse(asciiDigits) ?? 0;
  }

  String _formatAmountFa(num value) {
    final ascii = value.toStringAsFixed(0);
    final withSep = _formatWithSeparators(ascii);
    return _toPersianDigits(withSep);
  }

  // Derived values
  double get _trainingPrice =>
      _enableWorkout ? _parsePriceToDouble(_trainingPriceCtr.text) : 0;
  double get _dietPrice =>
      _enableDiet ? _parsePriceToDouble(_dietPriceCtr.text) : 0;
  double get _consultPrice => _enableConsult
      ? (_parsePriceToDouble(_trainingPriceCtr.text) / 2).floorToDouble()
      : 0;
  // Full package EXCLUDES consulting (consulting is embedded)
  double get _packageBeforeDiscount =>
      !_enablePackage ? 0 : (_trainingPrice + _dietPrice);
  double get _discountPct =>
      (double.tryParse(_normalizeDigits(_discountPctCtr.text)) ?? 0).clamp(
        0,
        100,
      );
  double get _packageFinal => !_enablePackage
      ? 0
      : (_packageBeforeDiscount * (1 - _discountPct / 100)).floorToDouble();

  void _enforcePackageRule() {
    if (!_enableWorkout || !_enableDiet) {
      _enablePackage = false;
    }
  }

  Future<void> _load() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }
      // IMPORTANT: read raw columns to include custom fields not modeled in UserProfile
      final profile = await SimpleProfileService.queryCurrentUserProfile(
        select: 'monthly_training_cost, monthly_diet_cost, package_discount_pct, service_training_enabled, service_diet_enabled, service_consulting_enabled, service_package_enabled',
      );
      final json = profile ?? {};
      setState(() {
        final trainingNum = (json['monthly_training_cost'] as num?) ?? 0;
        final dietNum = (json['monthly_diet_cost'] as num?) ?? 0;
        final discount = (json['package_discount_pct'] ?? 0).toString();
        _enableWorkout = (json['service_training_enabled'] ?? true) == true;
        _enableDiet = (json['service_diet_enabled'] ?? true) == true;
        _enableConsult = (json['service_consulting_enabled'] ?? true) == true;
        _enablePackage = (json['service_package_enabled'] ?? true) == true;
        _enforcePackageRule();
        _trainingPriceCtr.text = _formatAmountFa(trainingNum);
        _dietPriceCtr.text = _formatAmountFa(dietNum);
        _discountPctCtr.text = _toPersianDigits(discount);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _canUsePackage => _enableWorkout && _enableDiet;

  double get _packageSavings =>
      _enablePackage ? (_packageBeforeDiscount - _packageFinal) : 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = {
      'monthly_training_cost': _parsePriceToDouble(_trainingPriceCtr.text),
      'monthly_diet_cost': _parsePriceToDouble(_dietPriceCtr.text),
      'monthly_consulting_cost': _enableConsult
          ? (_parsePriceToDouble(_trainingPriceCtr.text) / 2).floorToDouble()
          : 0,
      'package_discount_pct': _enablePackage ? _discountPct : 0,
      'package_final_cost': _enablePackage ? _packageFinal : 0,
      'service_training_enabled': _enableWorkout,
      'service_diet_enabled': _enableDiet,
      'service_consulting_enabled': _enableConsult,
      'service_package_enabled': _enablePackage,
      'role': 'trainer',
    };

    setState(() => _isSaving = true);
    try {
      await SimpleProfileService.updateProfile(data);
      if (!mounted) return;
      _showFeedbackSnackBar(
        message: 'تعرفه‌ها ذخیره شد',
        subtitle: 'شاگردان می‌توانند خدمات را با قیمت جدید ببینند',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      _showFeedbackSnackBar(
        message: 'ذخیره ناموفق بود',
        subtitle: 'لطفاً دوباره تلاش کنید',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showFeedbackSnackBar({
    required String message,
    required bool isSuccess,
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isSuccess ? AppTheme.successColor : AppTheme.errorColor;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 88.h),
          padding: EdgeInsets.zero,
          duration: Duration(seconds: isSuccess ? 3 : 4),
          content: DecoratedBox(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Icon(
                    isSuccess ? LucideIcons.check : LucideIcons.alertCircle,
                    color: accent,
                    size: 22.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12.sp,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: _isSaving,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(isDark),
                  SizedBox(height: 16.h),
                  _buildEditableService(
                    icon: LucideIcons.dumbbell,
                    title: 'برنامه تمرینی',
                    controller: _trainingPriceCtr,
                    hint: 'هزینه ماهانه برنامه تمرینی',
                    color: AppTheme.fatColor,
                    enabled: _enableWorkout,
                    isDark: isDark,
                    onToggleEnabled: (v) {
                      setState(() {
                        _enableWorkout = v;
                        _enforcePackageRule();
                      });
                    },
                  ),
                  SizedBox(height: 12.h),
                  _buildEditableService(
                    icon: LucideIcons.apple,
                    title: 'برنامه رژیم غذایی',
                    controller: _dietPriceCtr,
                    hint: 'هزینه ماهانه برنامه رژیم غذایی',
                    color: Colors.purple,
                    enabled: _enableDiet,
                    isDark: isDark,
                    onToggleEnabled: (v) {
                      setState(() {
                        _enableDiet = v;
                        _enforcePackageRule();
                      });
                    },
                  ),
                  SizedBox(height: 12.h),
                  _buildReadonlyService(
                    icon: LucideIcons.headphones,
                    title: 'مشاوره و نظارت',
                    value: _consultPrice,
                    description: 'نصف هزینه برنامه تمرینی به صورت ماهانه',
                    color: AppTheme.carbsColor,
                    enabled: _enableConsult,
                    isDark: isDark,
                    onToggleEnabled: (v) => setState(() => _enableConsult = v),
                  ),
                  SizedBox(height: 12.h),
                  _buildFullPackageSection(isDark),
                  SizedBox(height: 24.h),
                  _buildSaveButton(isDark),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntroCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.28 : 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.wallet, color: AppTheme.goldColor, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'تعرفه‌ها به تومان و به‌صورت ماهانه است. بسته کامل شامل تمرین و رژیم است؛ مشاوره جداگانه محاسبه می‌شود.',
              style: TextStyle(
                color: context.textColor,
                fontSize: 12.5.sp,
                height: 1.5,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _isSaving
            ? LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.5),
                  AppTheme.darkGold.withValues(alpha: 0.5),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.goldColor, AppTheme.darkGold],
              ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: _isSaving
            ? null
            : [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.25),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _save,
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            width: double.infinity,
            height: 52.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSaving) ...[
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.onGoldColor,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'در حال ذخیره...',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onGoldColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ] else ...[
                  Icon(LucideIcons.save, size: 20.sp, color: AppTheme.onGoldColor),
                  SizedBox(width: 8.w),
                  Text(
                    'ذخیره تعرفه‌ها',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onGoldColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableService({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required String hint,
    required Color color,
    required bool enabled,
    required bool isDark,
    required ValueChanged<bool> onToggleEnabled,
  }) {
    final dim = enabled ? 1.0 : 0.4;
    return Opacity(
      opacity: dim,
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.cardColor,
                    context.cardColor.withValues(alpha: 0.95),
                    context.veryDarkBackground,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.cardColor,
                    context.cardColor.withValues(alpha: 0.98),
                    AppTheme.lightGradientStart.withValues(alpha: 0.1),
                  ],
                ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.25),
              blurRadius: 16.r,
              offset: Offset(0.w, 6.h),
              spreadRadius: 1.r,
            ),
            BoxShadow(
              color: isDark
                  ? AppTheme.veryDarkBackground.withValues(alpha: 0.3)
                  : AppTheme.lightTextColor.withValues(alpha: 0.08),
              blurRadius: 8.r,
              offset: Offset(0.w, 2.h),
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
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                      width: 1.w,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        hint,
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          color: context.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  activeThumbColor: AppTheme.goldColor,
                  onChanged: onToggleEnabled,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 14.sp,
                    ),
                    onChanged: (val) {
                      if (_isFormatting) return;
                      _isFormatting = true;
                      final formatted = _formatPriceFa(val);
                      controller.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                      SafeSetState.call(this, () {});
                      _isFormatting = false;
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: _toPersianDigits('0'),
                      hintStyle: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: context.textSecondary.withValues(alpha: 0.5),
                        fontSize: 12.sp,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? context.veryDarkBackground
                          : AppTheme.lightCardColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppTheme.goldColor.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppTheme.goldColor,
                          width: 2.w,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                      suffixIconConstraints: const BoxConstraints(),
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(right: 4.w, left: 5),
                        child: Text(
                          'تومان',
                          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                            color: context.textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'ماهانه',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._featuresFor(title).map((f) => _featureRow(color, f)),
          ],
        ),
      ),
    );
  }

  List<String> _featuresFor(String title) {
    if (title == 'برنامه تمرینی') {
      return const [
        'برنامه ی تمرینی روزانه',
        'شامل ۴ هفته تمرین',
        'راهنمایی تکنیک ها و حرکات',
        'پشتیبانی آنلاین',
        'بررسی پیشرفت شما',
        'چت نامحدود با مربی',
      ];
    }
    return const [
      'برنامه ی غذایی روزانه',
      'شامل ۴ هفته رژیم',
      'محاسبه ی کالری و درشت مغذی ها',
      'پشتیبانی آنلاین',
      'بررسی پیشرفت شما',
      'چت نامحدود با مربی',
    ];
  }

  Widget _buildReadonlyService({
    required IconData icon,
    required String title,
    required double value,
    required String description,
    required Color color,
    required bool enabled,
    required bool isDark,
    required ValueChanged<bool> onToggleEnabled,
  }) {
    final dim = enabled ? 1.0 : 0.4;
    return Opacity(
      opacity: dim,
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.cardColor,
                    context.cardColor.withValues(alpha: 0.95),
                    context.veryDarkBackground,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.cardColor,
                    context.cardColor.withValues(alpha: 0.98),
                    AppTheme.lightGradientStart.withValues(alpha: 0.1),
                  ],
                ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.25),
              blurRadius: 16.r,
              offset: Offset(0.w, 6.h),
              spreadRadius: 1.r,
            ),
            BoxShadow(
              color: isDark
                  ? AppTheme.veryDarkBackground.withValues(alpha: 0.3)
                  : AppTheme.lightTextColor.withValues(alpha: 0.08),
              blurRadius: 8.r,
              offset: Offset(0.w, 2.h),
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
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                      width: 1.w,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: enabled,
                  activeThumbColor: AppTheme.goldColor,
                  onChanged: onToggleEnabled,
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'تومان ',
                          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                            color: context.textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            _formatAmountFa(value),
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              color: AppTheme.goldColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ماهانه',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: context.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _featureRow(color, description),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPackageSection(bool isDark) {
    final active = _enablePackage && _canUsePackage;

    return Opacity(
      opacity: _canUsePackage ? 1.0 : 0.55,
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: active
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.55 : 0.5)
                : context.separatorColor,
            width: active ? 2 : 1.5,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.12),
                blurRadius: 14.r,
                offset: Offset(0, 4.h),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: isDark ? 0.18 : 0.14),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    LucideIcons.package,
                    color: AppTheme.goldColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بسته کامل',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'تمرین + رژیم با یک تخفیف',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textSecondary,
                          fontSize: 12.5.sp,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enablePackage,
                  activeThumbColor: AppTheme.goldColor,
                  onChanged: _canUsePackage
                      ? (v) => setState(() => _enablePackage = v)
                      : null,
                ),
              ],
            ),
            if (!_canUsePackage) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.orange.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      color: Colors.orange.shade700,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'برای فعال‌سازی بسته کامل، هر دو سرویس تمرین و رژیم باید فعال باشند.',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 12.sp,
                          height: 1.4,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_enablePackage && _canUsePackage) ...[
              SizedBox(height: 16.h),
              _packagePriceRow(
                label: 'برنامه تمرینی',
                amount: _trainingPrice,
                enabled: _enableWorkout,
              ),
              SizedBox(height: 8.h),
              _packagePriceRow(
                label: 'برنامه رژیم غذایی',
                amount: _dietPrice,
                enabled: _enableDiet,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Divider(color: context.separatorColor, height: 1),
              ),
              _packagePriceRow(
                label: 'جمع قبل از تخفیف',
                amount: _packageBeforeDiscount,
                emphasized: true,
              ),
              SizedBox(height: 14.h),
              Text(
                'درصد تخفیف بسته',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _discountPctCtr,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.fontFamily,
                ),
                onChanged: (val) {
                  if (_isFormatting) return;
                  _isFormatting = true;
                  final digits = _normalizeDigits(val).replaceAll(RegExp('[^0-9]'), '');
                  final n = (int.tryParse(digits) ?? 0).clamp(0, 100);
                  final formatted = _toPersianDigits(n.toString());
                  _discountPctCtr.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                  SafeSetState.call(this, () {});
                  _isFormatting = false;
                },
                decoration: InputDecoration(
                  hintText: _toPersianDigits('0'),
                  hintStyle: TextStyle(
                    color: context.textSecondary.withValues(alpha: 0.6),
                    fontFamily: AppTheme.fontFamily,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.percent,
                    color: AppTheme.goldColor,
                    size: 20.sp,
                  ),
                  suffixText: '%',
                  suffixStyle: TextStyle(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? context.veryDarkBackground
                      : AppTheme.lightCardColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: context.separatorColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              if (_discountPct > 0 && _packageSavings > 0) ...[
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: isDark ? 0.12 : 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.badgePercent,
                        color: AppTheme.successColor,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '${_formatAmountFa(_packageSavings)} تومان صرفه‌جویی برای شاگرد',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: isDark ? 0.35 : 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مبلغ نهایی ماهانه',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${_formatAmountFa(_packageFinal)} تومان',
                        style: TextStyle(
                          color: AppTheme.goldColor,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'مشاوره و نظارت به‌صورت جداگانه (نصف قیمت تمرین) قابل خرید است.',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11.5.sp,
                  height: 1.45,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              SizedBox(height: 10.h),
              ...const [
                'شامل برنامه تمرینی ۴ هفته‌ای',
                'شامل برنامه رژیم ۴ هفته‌ای',
                'پشتیبانی آنلاین و چت با مربی',
              ].map((f) => _featureRow(AppTheme.goldColor, f)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _packagePriceRow({
    required String label,
    required double amount,
    bool enabled = true,
    bool emphasized = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: enabled ? context.textSecondary : context.textSecondary.withValues(alpha: 0.5),
            fontSize: emphasized ? 14.sp : 13.sp,
            fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            enabled && amount > 0
                ? '${_formatAmountFa(amount)} تومان'
                : _toPersianDigits('۰'),
            style: TextStyle(
              color: emphasized ? context.textColor : context.textColor.withValues(alpha: 0.9),
              fontSize: emphasized ? 14.sp : 13.sp,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureRow(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(LucideIcons.check, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
