import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:responsive_framework/responsive_framework.dart';

class WeightChart extends StatefulWidget {
  const WeightChart({required this.userId, super.key, this.currentWeight});
  final String userId;
  final double? currentWeight;

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _weightData = [];
  bool _isLoading = true;
  String _selectedPeriod = '3M';

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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeightData() async {
    try {
      // بررسی اینکه userId خالی نباشد
      if (widget.userId.isEmpty) {
        debugPrint('خطا: userId خالی است');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final data = await WeeklyWeightService.getFullWeightHistory(
        widget.userId,
      );

      if (mounted) {
        setState(() {
          _weightData = data;
          _isLoading = false;
        });

        _animationController.forward();
      }
    } catch (e) {
      debugPrint('خطا در بارگیری داده‌های وزن: $e');
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
        debugPrint('خطا: تاریخ رکورد null است');
        return false;
      }
      try {
        final recordDate = DateTime.parse(dateString as String);
        return recordDate.isAfter(startDate);
      } catch (e) {
        debugPrint('خطا در پارس کردن تاریخ: $e');
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF252525)],
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: 20.h),
              _buildPeriodSelector(),
              SizedBox(height: 20.h),
              SizedBox(
                height: 200.h,
                child: _isLoading ? _buildLoadingIndicator() : _buildChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final filteredData = _getFilteredData();
    final hasData = filteredData.isNotEmpty;

    double? avgWeight;
    double? weightChange;

    if (hasData) {
      final validWeights = <double>[];

      for (final record in filteredData) {
        final weight = record['weight'];
        if (weight != null) {
          final weightValue = weight is double
              ? weight
              : double.tryParse(weight.toString());
          if (weightValue != null) {
            validWeights.add(weightValue);
          }
        }
      }

      if (validWeights.isNotEmpty) {
        avgWeight = validWeights.reduce((a, b) => a + b) / validWeights.length;

        if (validWeights.length > 1) {
          weightChange = validWeights.last - validWeights.first;
        }
      }
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.goldColor.withValues(alpha: 0.2),
                AppTheme.goldColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            Icons.trending_up,
            color: AppTheme.goldColor,
            size: ResponsiveValue(
              context,
              defaultValue: 24.sp,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 22.sp),
                Condition.largerThan(name: TABLET, value: 26.sp),
              ],
            ).value,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'روند وزن',
                style: GoogleFonts.vazirmatn(
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              if (hasData) ...[
                Row(
                  children: [
                    Text(
                      'میانگین: ',
                      style: GoogleFonts.vazirmatn(
                        textStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                    Text(
                      '${avgWeight!.toStringAsFixed(1)} kg',
                      style: GoogleFonts.vazirmatn(
                        textStyle: TextStyle(
                          color: AppTheme.goldColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (weightChange != null) ...[
                      SizedBox(width: 12.w),
                      Icon(
                        weightChange > 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: weightChange > 0 ? Colors.red : Colors.green,
                        size: 14.sp,
                      ),
                      Text(
                        '${weightChange.abs().toStringAsFixed(1)} kg',
                        style: GoogleFonts.vazirmatn(
                          textStyle: TextStyle(
                            color: weightChange > 0 ? Colors.red : Colors.green,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ] else ...[
                Text(
                  'داده‌ای موجود نیست',
                  style: GoogleFonts.vazirmatn(
                    textStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'key': '3M', 'label': '۳ ماه'},
      {'key': '6M', 'label': '۶ ماه'},
      {'key': '1Y', 'label': '۱ سال'},
      {'key': 'ALL', 'label': 'همیشگی'},
    ];

    return Row(
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period['key'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period['key']!;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.goldColor, Color(0xFFD4AF37)],
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.goldColor
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                period['label']!,
                textAlign: TextAlign.center,
                style: GoogleFonts.vazirmatn(
                  textStyle: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 30.w,
            height: 30.h,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'در حال بارگیری...',
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.vazirmatn(
                    textStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (filteredData.length / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= filteredData.length) {
                  return const SizedBox.shrink();
                }
                final record = filteredData[value.toInt()];
                final dateString = record['recorded_at'];
                if (dateString == null) {
                  return const SizedBox.shrink();
                }
                try {
                  final date = DateTime.parse(dateString as String);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: GoogleFonts.vazirmatn(
                        textStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
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
          show: true,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 2,
        maxY: spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.goldColor.withValues(alpha: 0.8),
                AppTheme.goldColor.withValues(alpha: 0.4),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.goldColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.3),
                  AppTheme.goldColor.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.trending_up,
              color: AppTheme.goldColor.withValues(alpha: 0.7),
              size: 30.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'هنوز داده‌ای ثبت نشده',
            style: GoogleFonts.vazirmatn(
              textStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            'برای مشاهده روند وزن، ابتدا وزن خود را ثبت کنید',
            style: GoogleFonts.vazirmatn(
              textStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10.sp,
              ),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
