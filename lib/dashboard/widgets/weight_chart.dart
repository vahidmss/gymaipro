import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:shamsi_date/shamsi_date.dart';

class WeightChart extends StatefulWidget {
  const WeightChart({
    required this.userId,
    super.key,
    this.currentWeight,
    /// فقط وقتی تعداد ثبت‌ها از این عدد بیشتر باشد نمایش داده می‌شود.
    this.minPointsExclusive = 3,
  });
  final String userId;
  final double? currentWeight;
  final int minPointsExclusive;

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _weightData = [];
  bool _isLoading = true;
  final String _selectedPeriod = 'ALL';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadWeightData();
  }

  @override
  void didUpdateWidget(WeightChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // اگر userId یا currentWeight تغییر کرد، داده‌ها را دوباره لود کن
    if (oldWidget.userId != widget.userId ||
        oldWidget.currentWeight != widget.currentWeight) {
      _loadWeightData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeightData() async {
    try {
      // بررسی اینکه userId خالی نباشد
      if (widget.userId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final cache = DashboardCacheService();
      final cached = cache.getWeightHistory();
      if (cached != null) {
        if (mounted) {
          setState(() {
            _weightData = cached;
            _isLoading = false;
          });
          _animationController.safeForward();
        }
        return;
      }

      final data = await WeeklyWeightService.getFullWeightHistory(
        widget.userId,
      );
      cache.setWeightHistory(data);

      if (mounted) {
        setState(() {
          _weightData = data;
          _isLoading = false;
        });

        _animationController.safeForward();
      }
    } catch (e) {
      // Error loading weight data - handled silently
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredData() {
    if (_weightData.isEmpty) return [];

    // اگر همیشگی انتخاب شده، همه داده‌ها رو برگردون
    if (_selectedPeriod == 'ALL') {
      return _weightData;
    }

    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case '3M':
        startDate = now.subtract(const Duration(days: 90));
      case '6M':
        startDate = now.subtract(const Duration(days: 180));
      case '1Y':
        startDate = now.subtract(const Duration(days: 365));
      default:
        startDate = now.subtract(const Duration(days: 90)); // پیش‌فرض 3 ماه
    }

    return _weightData.where((record) {
      final dateString = record['recorded_at'];
      if (dateString == null) {
        return false;
      }
      try {
        final recordDate = DateTime.parse(dateString as String);
        return recordDate.isAfter(startDate);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var output = input;
    for (var i = 0; i < english.length; i++) {
      output = output.replaceAll(english[i], persian[i]);
    }
    return output;
  }

  String _formatJalaliFull(DateTime date) {
    final j = Jalali.fromDateTime(date);
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
    final monthName = monthNames[j.month];
    return '\u200F${_toPersianDigits(j.day.toString())} $monthName ${_toPersianDigits(j.year.toString())}';
  }

  String _formatJalaliShort(DateTime date) {
    final j = Jalali.fromDateTime(date);
    final m = j.month.toString().padLeft(2, '0');
    final d = j.day.toString().padLeft(2, '0');
    return '${_toPersianDigits(m)}/${_toPersianDigits(d)}';
  }

  Map<String, dynamic> _calculateWeightChange() {
    final filteredData = _getFilteredData();
    if (filteredData.length < 2) {
      return {'change': 0.0, 'isIncrease': false, 'hasChange': false};
    }

    final firstWeight = filteredData.first['weight'];
    final lastWeight = filteredData.last['weight'];

    if (firstWeight == null || lastWeight == null) {
      return {'change': 0.0, 'isIncrease': false, 'hasChange': false};
    }

    final first = firstWeight is double
        ? firstWeight
        : double.tryParse(firstWeight.toString());
    final last = lastWeight is double
        ? lastWeight
        : double.tryParse(lastWeight.toString());

    if (first == null || last == null) {
      return {'change': 0.0, 'isIncrease': false, 'hasChange': false};
    }

    final change = last - first;
    return {
      'change': change.abs(),
      'isIncrease': change > 0,
      'hasChange': change != 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 48.h,
        child: Center(
          child: SizedBox(
            width: 22.w,
            height: 22.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.textSecondary,
            ),
          ),
        ),
      );
    }

    if (_weightData.length <= widget.minPointsExclusive) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: context.separatorColor),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: 10.h),
              SizedBox(
                height: 110.h,
                child: _buildChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final weightChange = _calculateWeightChange();
    final hasChange = weightChange['hasChange'] as bool;
    final isIncrease = weightChange['isIncrease'] as bool;
    final change = weightChange['change'] as double;

    String? changeText;
    Color? changeColor;
    if (hasChange) {
      if (isIncrease) {
        changeText =
            'افزایش ${_toPersianDigits(change.toStringAsFixed(1))} کیلوگرم';
        changeColor = AppTheme.successColor;
      } else {
        changeText =
            'کاهش ${_toPersianDigits(change.toStringAsFixed(1))} کیلوگرم';
        changeColor = AppTheme.errorColor;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'روند وزن',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 15.sp,
            color: context.textColor,
            height: 1.2,
          ),
        ),
        if (changeText != null) ...[
          SizedBox(height: 3.h),
          Text(
            changeText,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
              color: changeColor,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChart() {
    final filteredData = _getFilteredData();

    if (filteredData.isEmpty) {
      return _buildEmptyState();
    }

    final spots = <FlSpot>[];

    for (int i = 0; i < filteredData.length; i++) {
      final record = filteredData[i];
      final weight = record['weight'];

      // بررسی اینکه weight null نباشد و قابل تبدیل به double باشد
      if (weight != null) {
        final weightValue = weight is double
            ? weight
            : double.tryParse(weight.toString());
        if (weightValue != null) {
          spots.add(FlSpot(i.toDouble(), weightValue));
        }
      }
    }

    // اگر هیچ نقطه معتبری نداریم، حالت خالی نمایش دهیم
    if (spots.isEmpty) {
      return _buildEmptyState();
    }

    // بررسی اینکه آیا فقط یک نقطه داریم
    final isSinglePoint = spots.length == 1;

    // محاسبه minY و maxY
    final double minYValue, maxYValue;
    if (isSinglePoint) {
      // برای یک نقطه، یک range مناسب تعریف می‌کنیم
      final singleWeight = spots[0].y;
      minYValue = singleWeight - 5; // 5 کیلوگرم پایین‌تر
      maxYValue = singleWeight + 5; // 5 کیلوگرم بالاتر
    } else {
      minYValue =
          spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 2;
      maxYValue =
          spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 2;
    }

    // محاسبه minX و maxX
    final double minXValue, maxXValue;
    if (isSinglePoint) {
      // نقطه در x=0 قرار می‌گیره
      minXValue = 0;
      maxXValue = 0.5;
    } else {
      minXValue = 0;
      maxXValue = (spots.length - 1).toDouble();
    }

    final chartWidget = LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: false, // گریدهای وسط چارت نمایش داده نمیشن
          drawVerticalLine: false,
          drawHorizontalLine: false,
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: isSinglePoint, // فقط وقتی یک نقطه هست اعداد نمایش بده
              reservedSize: isSinglePoint ? 50 : 0,
              interval: isSinglePoint ? 2.5 : 1,
              getTitlesWidget: (value, meta) {
                if (isSinglePoint) {
                  return Text(
                    _toPersianDigits(value.toStringAsFixed(1)),
                    style: context.bodyStyle.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.6)
                          : context.textSecondary,
                      fontSize: 10,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: isSinglePoint, // فقط وقتی یک نقطه هست تاریخ نمایش بده
              reservedSize: 0, // حاشیه زیر نمودار حذف شد
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (!isSinglePoint) {
                  return const SizedBox.shrink();
                }
                // برای یک نقطه، فقط وقتی value برابر 0 باشه تاریخ نمایش بده
                if (value != 0) {
                  return const SizedBox.shrink();
                }
                if (filteredData.isEmpty) {
                  return const SizedBox.shrink();
                }
                final record = filteredData[0];
                final dateString = record['recorded_at'];
                if (dateString == null) {
                  return const SizedBox.shrink();
                }
                try {
                  final date = DateTime.parse(dateString as String);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatJalaliShort(date),
                      style: context.bodyStyle.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.6)
                            : context.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                } catch (e) {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(
          show: isSinglePoint, // فقط وقتی یک نقطه هست border نمایش بده
          border: isSinglePoint
              ? Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : context.separatorColor,
                )
              : null,
        ),
        minX: minXValue,
        maxX: maxXValue,
        minY: minYValue,
        maxY: maxYValue,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((touched) {
                final index = touched.x.toInt();
                final record = filteredData[index];
                final date = DateTime.parse(record['recorded_at'] as String);
                final dateFa = _formatJalaliFull(date);
                final weightFa = _toPersianDigits(touched.y.toStringAsFixed(1));
                return LineTooltipItem(
                  '$dateFa\n$weightFa کیلوگرم',
                  TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : context.textColor,
                    fontSize: 12.sp,
                    height: 1.6,
                    fontFamily: AppTheme.fontFamily,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      AppTheme.goldColor.withValues(alpha: 0.8),
                      AppTheme.goldColor.withValues(alpha: 0.4),
                    ]
                  : [
                      context.textColor.withValues(alpha: 0.8),
                      context.textColor.withValues(alpha: 0.4),
                    ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.goldColor
                      : context.textColor,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : context.cardColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseWidthPerPoint = 40.w;
        final minWidth = constraints.maxWidth;
        final targetWidth = spots.length * baseWidthPerPoint;
        final width = targetWidth < minWidth ? minWidth : targetWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: RepaintBoundary(child: chartWidget),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'هنوز وزنی ثبت نشده',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
              color: context.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            'اولین ثبت، شروع روند وزن است',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 11.sp,
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
