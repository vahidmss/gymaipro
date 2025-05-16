import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/date_utils.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class WeightChart extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final Function() onWeightAdded;

  const WeightChart({
    Key? key,
    required this.profileData,
    required this.onWeightAdded,
  }) : super(key: key);

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart>
    with SingleTickerProviderStateMixin {
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color cardColor = Color(0xFF1E1E1E);
  final TextEditingController _weightController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.value = 0.0;
    _animationController.forward();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getWeightHistory() {
    if (widget.profileData['weight_history'] == null) {
      return [];
    }

    try {
      // اگر weight_history یک لیست باشد
      if (widget.profileData['weight_history'] is List) {
        final List<dynamic> rawHistory =
            widget.profileData['weight_history'] as List<dynamic>;
        return rawHistory.map((item) => item as Map<String, dynamic>).toList();
      }
      // اگر weight_history یک رشته باشد (در این حالت لیست خالی برمی‌گردانیم)
      else if (widget.profileData['weight_history'] is String) {
        print(
            'weight_history به صورت String است: ${widget.profileData['weight_history']}');
        return [];
      }
      // در حالات دیگر نیز لیست خالی برمی‌گردانیم
      else {
        print(
            'weight_history به فرمت ناشناخته است: ${widget.profileData['weight_history'].runtimeType}');
        return [];
      }
    } catch (e) {
      print('خطا در پردازش تاریخچه وزن: $e');
      return [];
    }
  }

  List<FlSpot> _getSpots() {
    final weightHistory = _getWeightHistory();

    final spots = weightHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['weight'] as double);
    }).toList();

    if (spots.isEmpty) {
      final currentWeight =
          double.tryParse(widget.profileData['weight'] ?? '') ?? 0;
      if (currentWeight > 0) {
        spots.add(FlSpot(0, currentWeight));
      }
    }

    return spots;
  }

  void _showAddWeightDialog() {
    _weightController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: goldColor.withOpacity(0.3), width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.monitor_weight_outlined, color: goldColor),
            SizedBox(width: 8),
            Text(
              'ثبت وزن جدید',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              decoration: InputDecoration(
                hintText: 'وزن خود را وارد کنید',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                labelText: 'وزن (کیلوگرم)',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: goldColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: goldColor),
                  borderRadius: BorderRadius.circular(15),
                ),
                prefixIcon: const Icon(Icons.scale, color: goldColor),
                filled: true,
                fillColor: Colors.black12,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: goldColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: goldColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'نکته: فقط هر ۷ روز یکبار می‌توانید وزن جدید ثبت کنید',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _addWeight(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: goldColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('ثبت'),
          ),
        ],
      ),
    );
  }

  Future<void> _addWeight(BuildContext context) async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً یک وزن معتبر وارد کنید')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final supabaseService = SupabaseService();
        await supabaseService.addWeightRecord(user.id, weight);
        // Update profile weight
        await supabaseService
            .updateProfile(user.id, {'weight': weight.toString()});
        if (mounted) {
          Navigator.pop(context);
          widget.onWeightAdded();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('وزن جدید با موفقیت ثبت شد'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Format the error message
        String errorMsg = e.toString();
        if (errorMsg.contains('7 days')) {
          errorMsg = 'شما فقط هر ۷ روز یکبار می‌توانید وزن جدید ثبت کنید';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getSpots();
    final weightHistory = _getWeightHistory();

    // Calculate min and max for Y axis with proper padding
    double minY = spots.isNotEmpty
        ? spots.map((e) => e.y).reduce((a, b) => a < b ? a : b)
        : 0;
    double maxY = spots.isNotEmpty
        ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 100;

    // Add padding to min and max
    minY = (minY - 10).clamp(0, double.infinity);
    maxY = maxY + 10;

    // Calculate Y axis interval based on range
    double yInterval = (maxY - minY) / 5;
    yInterval =
        yInterval < 5 ? 5 : (yInterval > 10 ? 10 : yInterval.roundToDouble());

    // استفاده از FadeIn به جای انیمیشن سفارشی
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: goldColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: goldColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: goldColor.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.area_chart,
                              color: goldColor, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'نمودار وزن',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // نمایش آخرین وزن ثبت شده و دکمه افزودن
                  Row(
                    children: [
                      // دکمه اضافه کردن داده‌های فرضی برای تست (فقط در حالت توسعه)
                      if (true) // این مقدار را می‌توانید به `false` تغییر دهید در حالت تولید
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _addSampleData,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.purple.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.science_outlined,
                                    color: Colors.purple.shade300,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'داده آزمایشی',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // بخش نمایش آخرین وزن و دکمه افزودن
                      Container(
                        decoration: BoxDecoration(
                          color: goldColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // نمایش نمادین وزن کنونی
                            if (widget.profileData['weight'] != null &&
                                widget.profileData['weight']
                                    .toString()
                                    .isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: goldColor.withOpacity(0.2),
                                  borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(20)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.profileData['weight'] ?? '-',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      ' kg',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // دکمه افزودن وزن جدید
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showAddWeightDialog,
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(20)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_circle,
                                        color: goldColor,
                                        size: 18,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'ثبت وزن',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 320,
              padding: const EdgeInsets.all(16),
              child: spots.isEmpty
                  ? _buildEmptyChart()
                  : _buildChart(spots, weightHistory, minY, maxY, yInterval),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_chart,
            size: 60,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'هنوز وزنی ثبت نشده است',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddWeightDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'ثبت وزن جدید',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: goldColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    List<FlSpot> spots,
    List<Map<String, dynamic>> weightHistory,
    double minY,
    double maxY,
    double yInterval,
  ) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.05),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= spots.length) {
                  return const SizedBox();
                }

                // نمایش تاریخ بجای شماره ایندکس برای هر 2 نقطه
                if (value.toInt() % 2 == 0 &&
                    weightHistory.isNotEmpty &&
                    value.toInt() < weightHistory.length) {
                  final date = DateTime.parse(
                      weightHistory[value.toInt()]['recorded_at']);
                  final jalaliDate = toJalali(date);

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: goldColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        jalaliDate,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 40, // Increased to accommodate 3-digit numbers
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: spots.length > 1 ? spots.length - 1.0 : 6,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: goldColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: goldColor,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white70,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  goldColor.withOpacity(0.2),
                  goldColor.withOpacity(0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            tooltipRoundedRadius: 10,
            tooltipMargin: 10,
            tooltipPadding: const EdgeInsets.all(12),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.spotIndex >= weightHistory.length &&
                    spots.length == 1) {
                  // Handle the case where we only have the current weight
                  return LineTooltipItem(
                    'وزن فعلی: ${spot.y.toStringAsFixed(1)} کیلوگرم',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }

                final record = weightHistory[spot.spotIndex];
                final recordDate = DateTime.parse(record['recorded_at']);
                final jalaliDate = toJalali(recordDate);
                final timeAgo = getTimeAgo(recordDate);

                return LineTooltipItem(
                  'وزن: ${spot.y.toStringAsFixed(1)} کیلوگرم\n'
                  'تاریخ: $jalaliDate\n'
                  '$timeAgo',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                const FlLine(
                  color: Colors.white,
                  strokeWidth: 2,
                  dashArray: [3, 3],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: goldColor,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchCallback:
              (FlTouchEvent event, LineTouchResponse? touchResponse) {},
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  // افزودن داده‌های فرضی برای تست
  Future<void> _addSampleData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final supabaseService = SupabaseService();
        await supabaseService.addSampleWeightData(user.id);
        if (mounted) {
          widget.onWeightAdded();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('داده‌های آزمایشی با موفقیت اضافه شدند'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در افزودن داده‌های آزمایشی: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
