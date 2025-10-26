import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
      final json =
          await Supabase.instance.client
              .from('profiles')
              .select(
                'monthly_training_cost, monthly_diet_cost, package_discount_pct, service_training_enabled, service_diet_enabled, service_consulting_enabled, service_package_enabled',
              )
              .eq('id', user.id)
              .maybeSingle() ??
          {};
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
    if (_loading) {
      return const Center(
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
              onToggleEnabled: (v) {
                setState(() {
                  _enableWorkout = v;
                  _enforcePackageRule();
                });
              },
            ),
            const SizedBox(height: 12),
            _buildEditableService(
              icon: LucideIcons.apple,
              title: 'برنامه رژیم غذایی',
              controller: _dietPriceCtr,
              hint: 'هزینه ماهانه برنامه رژیم غذایی',
              color: Colors.purple,
              enabled: _enableDiet,
              onToggleEnabled: (v) {
                setState(() {
                  _enableDiet = v;
                  _enforcePackageRule();
                });
              },
            ),
            const SizedBox(height: 12),
            _buildReadonlyService(
              icon: LucideIcons.headphones,
              title: 'مشاوره و نظارت',
              value: _consultPrice,
              description: 'نصف هزینه برنامه تمرینی به صورت ماهانه',
              color: Colors.blue,
              enabled: _enableConsult,
              onToggleEnabled: (v) => setState(() => _enableConsult = v),
            ),
            const SizedBox(height: 12),
            _buildDiscountCard(),
            const SizedBox(height: 16),
            _buildPackageSummary(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(LucideIcons.save),
                label: const Text('ذخیره قیمت‌ها'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
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
    required ValueChanged<bool> onToggleEnabled,
  }) {
    final dim = enabled ? 1.0 : 0.4;
    return Opacity(
      opacity: dim,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8.r,
              offset: Offset(0.w, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        hint,
                        style: TextStyle(
                          color: Colors.white54,
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
                    style: const TextStyle(color: Colors.white),
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
                      setState(() {});
                      _isFormatting = false;
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: _toPersianDigits('0'),
                      hintStyle: TextStyle(
                        color: Colors.white38,
                        fontSize: 12.sp,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(color: AppTheme.goldColor),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 10.h,
                      ),
                      suffixIconConstraints: const BoxConstraints(),
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(right: 4.w, left: 5),
                        child: const Text(
                          'تومان',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ماهانه',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
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
    required ValueChanged<bool> onToggleEnabled,
  }) {
    final dim = enabled ? 1.0 : 0.4;
    return Opacity(
      opacity: dim,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8.r,
              offset: Offset(0.w, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
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
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'تومان ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 6),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            _formatAmountFa(value),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'ماهانه',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
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

  Widget _buildDiscountCard() {
    final dim = _enablePackage ? 1.0 : 0.4;
    return Opacity(
      opacity: dim,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.percent, color: AppTheme.goldColor),
                SizedBox(width: 8),
                Text(
                  'تخفیف بسته کامل',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
              style: const TextStyle(color: Colors.white),
              onTap: _discountPctCtr.clear,
              decoration: InputDecoration(
                hintText: _toPersianDigits('0'),
                hintStyle: const TextStyle(color: Colors.white54),
                suffixText: '%',
                suffixStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppTheme.goldColor),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSummary() {
    final dim = _enablePackage ? 1.0 : 0.4;
    return Opacity(
      opacity: dim,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.goldColor.withValues(alpha: 0.2),
              AppTheme.goldColor.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'بسته کامل',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                const Text(
                  'قیمت قبل از تخفیف',
                  style: TextStyle(color: Colors.white70),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'تومان ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        _formatAmountFa(_packageBeforeDiscount),
                        style: const TextStyle(color: Colors.white),
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
                const Text('تخفیف', style: TextStyle(color: Colors.white70)),
                Text(
                  '% ${_toPersianDigits(_discountPct.toStringAsFixed(0))}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'مبلغ نهایی بسته',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'تومان ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        _formatAmountFa(_packageFinal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
