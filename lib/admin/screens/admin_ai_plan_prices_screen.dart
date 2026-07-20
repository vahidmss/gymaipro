import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/ai_coach_plan_price.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/payment/services/ai_coach_plan_price_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه تنظیم قیمت پلن‌های مربی هوشمند
class AdminAiPlanPricesScreen extends StatefulWidget {
  const AdminAiPlanPricesScreen({super.key});

  @override
  State<AdminAiPlanPricesScreen> createState() =>
      _AdminAiPlanPricesScreenState();
}

class _AdminAiPlanPricesScreenState extends State<AdminAiPlanPricesScreen> {
  final AiCoachPlanPriceService _service = AiCoachPlanPriceService();
  final Map<String, _PlanFormControllers> _forms = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _savingPlanId;

  @override
  void initState() {
    super.initState();
    for (final planId in CoachPlanCatalog.sellablePlanIds) {
      _forms[planId] = _PlanFormControllers();
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final form in _forms.values) {
      form.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      for (final planId in CoachPlanCatalog.sellablePlanIds) {
        final price = await _service.getActivePrice(planId);
        _forms[planId]?.apply(price);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری قیمت‌ها: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save(String planId) async {
    final form = _forms[planId];
    if (form == null) return;

    final priceRial = int.tryParse(form.priceController.text.trim());
    final validityDays = int.tryParse(form.daysController.text.trim());
    final title = form.titleController.text.trim();
    final description = form.descriptionController.text.trim();
    final features = form.featuresController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (title.isEmpty) {
      _showError('عنوان پلن الزامی است');
      return;
    }
    if (priceRial == null || priceRial < 0) {
      _showError('قیمت باید عدد صحیح غیرمنفی باشد (ریال)');
      return;
    }
    if (validityDays == null || validityDays <= 0) {
      _showError('مدت اعتبار باید عدد مثبت باشد');
      return;
    }

    setState(() {
      _isSaving = true;
      _savingPlanId = planId;
    });
    try {
      final saved = await _service.upsertActivePrice(
        planId: planId,
        title: title,
        description: description,
        priceRial: priceRial,
        validityDays: validityDays,
        features: features,
        isActive: form.isActive,
      );
      if (!mounted) return;
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('قیمت ${CoachPlanCatalog.persianTitleForId(planId)} ذخیره شد'),
            backgroundColor: Colors.green,
          ),
        );
        await _load();
      } else {
        _showError('ذخیره ناموفق بود');
      }
    } catch (e) {
      if (mounted) _showError('خطا در ذخیره: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _savingPlanId = null;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Text(
          'هزینه هوش مصنوعی',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'قیمت فروش پلن‌های مربی هوشمند به کاربر (نه هزینه توکن OpenAI).',
          style: TextStyle(
            fontSize: 13.sp,
            color: isDark
                ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                : AppTheme.lightTextSecondary,
          ),
        ),
        SizedBox(height: 20.h),
        ...CoachPlanCatalog.sellablePlanIds.map((planId) {
          final form = _forms[planId]!;
          return _PlanPriceCard(
            planId: planId,
            form: form,
            isSaving: _isSaving && _savingPlanId == planId,
            onSave: () => _save(planId),
            onActiveChanged: (value) {
              setState(() => form.isActive = value);
            },
          );
        }),
      ],
    );
  }
}

class _PlanFormControllers {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController daysController = TextEditingController();
  final TextEditingController featuresController = TextEditingController();
  bool isActive = true;

  void apply(AiCoachPlanPrice price) {
    titleController.text = price.title;
    descriptionController.text = price.description;
    priceController.text = price.priceRial.toString();
    daysController.text = price.validityDays.toString();
    featuresController.text = price.features.join('\n');
    isActive = price.isActive;
  }

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    daysController.dispose();
    featuresController.dispose();
  }
}

class _PlanPriceCard extends StatelessWidget {
  const _PlanPriceCard({
    required this.planId,
    required this.form,
    required this.isSaving,
    required this.onSave,
    required this.onActiveChanged,
  });

  final String planId;
  final _PlanFormControllers form;
  final bool isSaving;
  final VoidCallback onSave;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark
        ? AppTheme.goldColor.withValues(alpha: 0.25)
        : Colors.black12;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, color: AppTheme.goldColor, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  CoachPlanCatalog.persianTitleForId(planId),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.darkTextColor
                        : AppTheme.lightTextColor,
                  ),
                ),
              ),
              Switch(
                value: form.isActive,
                activeThumbColor: AppTheme.goldColor,
                onChanged: onActiveChanged,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: form.titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: form.descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'توضیح',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: form.priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'قیمت (ریال)',
              helperText: form.priceController.text.isEmpty
                  ? null
                  : PaymentConstants.formatAmount(
                      int.tryParse(form.priceController.text) ?? 0,
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: form.daysController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'مدت اعتبار (روز)',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: form.featuresController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'امکانات (هر خط یک مورد)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save),
            label: Text(isSaving ? 'در حال ذخیره...' : 'ذخیره'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }
}
