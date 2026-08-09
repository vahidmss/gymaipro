import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/services/fitness_calculator.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// آمار بدن — فشرده، عددی، بدون گیج.
class DashboardStatsStrip extends StatefulWidget {
  const DashboardStatsStrip({required this.profileData, super.key});

  final Map<String, dynamic> profileData;

  @override
  State<DashboardStatsStrip> createState() => _DashboardStatsStripState();
}

class _DashboardStatsStripState extends State<DashboardStatsStrip> {
  double? _latestWeight;
  final DashboardCacheService _cacheService = DashboardCacheService();

  @override
  void initState() {
    super.initState();
    _loadLatestWeight();
  }

  @override
  void didUpdateWidget(DashboardStatsStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileData != widget.profileData) {
      _loadLatestWeight();
    }
  }

  Future<void> _loadLatestWeight() async {
    try {
      final cachedWeight = _cacheService.getLatestWeight();
      if (cachedWeight != null) {
        if (mounted) setState(() => _latestWeight = cachedWeight);
        return;
      }

      final history = _cacheService.getWeightHistory();
      if (history != null && history.isNotEmpty) {
        final latest = history.last['weight'];
        if (latest is num) {
          final value = latest.toDouble();
          _cacheService.setLatestWeight(value);
          if (mounted) setState(() => _latestWeight = value);
          return;
        }
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final latestWeight = await WeeklyWeightService.getLatestWeight(user.id);
        if (latestWeight != null) {
          _cacheService.setLatestWeight(latestWeight);
        }
        if (mounted) setState(() => _latestWeight = latestWeight);
      }
    } catch (_) {}
  }

  static String _bmiLabel(String category) {
    return switch (category) {
      'Underweight' => 'کم‌وزن',
      'Normal' => 'نرمال',
      'Overweight' => 'بالای نرمال',
      'Obese' => 'نیاز به توجه',
      _ => category,
    };
  }

  @override
  Widget build(BuildContext context) {
    final m = _computeMetrics();

    // Home فقط ۳ متریک روزمره؛ بقیه در پروفایل.
    final items = <_StatCell>[
      _StatCell(
        label: 'وزن',
        value: m.weight > 0 ? m.weight.toStringAsFixed(1) : '—',
        hint: 'کیلوگرم',
      ),
      _StatCell(
        label: 'شاخص توده',
        value: m.bmi > 0 ? m.bmi.toStringAsFixed(1) : '—',
        hint: m.bmi > 0 ? _bmiLabel(m.bmiCategory) : '—',
      ),
      _StatCell(
        label: 'کالری روزانه',
        value: m.tdee > 0 ? m.tdee.round().toString() : '—',
        hint: 'کیلوکالری',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                'وضعیت بدن',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.sp,
                  color: context.textColor,
                  height: 1.2,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
                child: Text(
                  'جزئیات',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: context.separatorColor),
          ),
          child: _StatRow(left: items[0], middle: items[1], right: items[2]),
        ),
      ],
    );
  }

  _BodyMetrics _computeMetrics() {
    final height =
        double.tryParse((widget.profileData['height'] as String?) ?? '') ?? 0;
    final weight =
        _latestWeight ??
        double.tryParse((widget.profileData['weight'] as String?) ?? '') ??
        0;
    final birthDateStr = widget.profileData['birth_date'] as String?;
    final isMale = (widget.profileData['gender'] as String?) == 'male';

    var age = 25;
    if (birthDateStr != null && birthDateStr.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(birthDateStr);
        final now = DateTime.now();
        age = now.year -
            birthDate.year -
            ((now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day))
                ? 1
                : 0);
      } catch (_) {}
    }

    final neck = double.tryParse(
          (widget.profileData['neck_circumference'] as String?) ?? '',
        ) ??
        (isMale ? 35 : 32);
    final waist = double.tryParse(
          (widget.profileData['waist_circumference'] as String?) ?? '',
        ) ??
        0;
    final hip = double.tryParse(
          (widget.profileData['hip_circumference'] as String?) ?? '',
        ) ??
        0;

    var bmi = 0.0;
    var bmiCategory = 'Normal';
    if (height > 0 && weight > 0) {
      bmi = FitnessCalculator.calculateBMI(weight, height);
      bmiCategory = FitnessCalculator.getBMICategory(bmi);
    }

    var bodyFat = 0.0;
    if (height > 0 && weight > 0 && waist > 0) {
      bodyFat = FitnessCalculator.calculateBodyFatPercentage(
        waist,
        neck,
        height,
        isMale,
        hip,
      );
    }

    var bmr = 0.0;
    if (height > 0 && weight > 0 && age > 0) {
      bmr = FitnessCalculator.calculateBMR(weight, height, age, isMale);
    }

    var tdee = 0.0;
    if (bmr > 0) {
      final activityLevelStr =
          (widget.profileData['activity_level'] as String?) ?? 'moderate';
      tdee = FitnessCalculator.calculateTDEE(
        bmr,
        activityLevelStr.toActivityLevel(),
      );
    }

    return _BodyMetrics(
      height: height,
      weight: weight,
      bmi: bmi,
      bmiCategory: bmiCategory,
      bodyFat: bodyFat,
      bmr: bmr,
      tdee: tdee,
    );
  }
}

class _BodyMetrics {
  const _BodyMetrics({
    required this.height,
    required this.weight,
    required this.bmi,
    required this.bmiCategory,
    required this.bodyFat,
    required this.bmr,
    required this.tdee,
  });

  final double height;
  final double weight;
  final double bmi;
  final String bmiCategory;
  final double bodyFat;
  final double bmr;
  final double tdee;
}

class _StatCell {
  const _StatCell({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.left,
    required this.middle,
    required this.right,
  });

  final _StatCell left;
  final _StatCell middle;
  final _StatCell right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: _StatCellView(cell: left)),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: context.separatorColor,
          ),
          Expanded(child: _StatCellView(cell: middle)),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: context.separatorColor,
          ),
          Expanded(child: _StatCellView(cell: right)),
        ],
      ),
    );
  }
}

class _StatCellView extends StatelessWidget {
  const _StatCellView({required this.cell});

  final _StatCell cell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            cell.value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 16.sp,
              color: context.textColor,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 3.h),
          Text(
            cell.label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
              color: context.textSecondary,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            cell.hint,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 9.sp,
              color: context.textSecondary.withValues(alpha: 0.8),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
