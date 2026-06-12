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

    try {
      await SimpleProfileService.updateProfile(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('قیمت‌ها با موفقیت ذخیره شد'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ذخیره قیمت‌ها: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEditableService(
              icon: LucideIcons.dumbbell,
              title: 'برنامه تمرینی',
              controller: _trainingPriceCtr,
              hint: 'هزینه ماهانه برنامه تمرینی',
              color: Colors.orange,
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
              color: Colors.blue,
              enabled: _enableConsult,
              isDark: isDark,
              onToggleEnabled: (v) => setState(() => _enableConsult = v),
            ),
            SizedBox(height: 12.h),
            _buildDiscountCard(isDark),
            SizedBox(height: 16.h),
            _buildPackageSummary(isDark),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(LucideIcons.save),
                label: Text(
                  'ذخیره قیمت‌ها',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: AppTheme.onGoldColor,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  elevation: 4,
                  shadowColor: AppTheme.goldColor.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ),
          ],
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
                  ? Colors.black.withValues(alpha: 0.3)
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
                    onTap: () {
                      controller.clear();
                    },
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
                          : AppTheme.lightSurfaceColor,
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
                  ? Colors.black.withValues(alpha: 0.3)
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
                              fontSize: 16.sp,
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

  Widget _buildDiscountCard(bool isDark) {
    final dim = _enablePackage ? 1.0 : 0.4;
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
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.percent, color: AppTheme.goldColor),
                SizedBox(width: 8.w),
                Text(
                  'تخفیف بسته کامل',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _discountPctCtr,
              enabled: _enablePackage,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.rtl,
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                color: context.textColor,
                fontSize: 14.sp,
              ),
              onTap: _discountPctCtr.clear,
              decoration: InputDecoration(
                hintText: _toPersianDigits('0'),
                hintStyle: TextStyle(
    fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary.withValues(alpha: 0.5),
                  fontSize: 12.sp,
                ),
                suffixText: '%',
                suffixStyle: TextStyle(
    fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 12.sp,
                ),
                filled: true,
                fillColor: isDark
                    ? context.veryDarkBackground
                    : AppTheme.lightSurfaceColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.goldColor, width: 2.w),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
              ),
              onChanged: (_) => SafeSetState.call(this, () {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSummary(bool isDark) {
    final dim = _enablePackage ? 1.0 : 0.4;
    return Opacity(
      opacity: dim,
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.goldColor.withValues(alpha: isDark ? 0.25 : 0.3),
              AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.2),
              AppTheme.darkGold.withValues(alpha: isDark ? 0.1 : 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.5),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
              blurRadius: 16.r,
              offset: Offset(0.w, 6.h),
              spreadRadius: 1.r,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'بسته کامل',
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                Switch(
                  value: _enablePackage,
                  activeThumbColor: AppTheme.goldColor,
                  onChanged: (!_enableWorkout || !_enableDiet)
                      ? null
                      : (v) => setState(() => _enablePackage = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'قیمت قبل از تخفیف',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
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
                        _formatAmountFa(_packageBeforeDiscount),
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
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تخفیف',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  '% ${_toPersianDigits(_discountPct.toStringAsFixed(0))}',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              height: 1.h,
              margin: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.goldColor.withValues(alpha: 0.3),
                    AppTheme.goldColor.withValues(alpha: 0.5),
                    AppTheme.goldColor.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مبلغ نهایی بسته',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
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
                        _formatAmountFa(_packageFinal),
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          color: AppTheme.goldColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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
