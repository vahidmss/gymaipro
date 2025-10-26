import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WeightWidgets {
  static String _toPersianNumber(String number) {
    const Map<String, String> persianNumbers = {
      '0': '۰',
      '1': '۱',
      '2': '۲',
      '3': '۳',
      '4': '۴',
      '5': '۵',
      '6': '۶',
      '7': '۷',
      '8': '۸',
      '9': '۹',
    };

    String result = number;
    persianNumbers.forEach((english, persian) {
      result = result.replaceAll(english, persian);
    });
    return result;
  }

  static String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) {
        return 'امروز';
      } else if (difference == 1) {
        return 'دیروز';
      } else if (difference < 7) {
        return '${_toPersianNumber(difference.toString())} روز پیش';
      } else {
        final persianDate =
            '${_toPersianNumber(date.day.toString())}/${_toPersianNumber(date.month.toString())}/${_toPersianNumber(date.year.toString())}';
        return persianDate;
      }
    } catch (e) {
      return dateString;
    }
  }

  static void showWeightGuidanceDialog(
    BuildContext context,
    Function(String) onWeightSubmitted,
  ) {
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'ثبت وزن جدید',
            style: GoogleFonts.vazirmatn(
              textStyle: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'وزن فعلی خود را وارد کنید:',
                  style: GoogleFonts.vazirmatn(
                    textStyle: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'مثال: 75.5',
                    hintStyle: GoogleFonts.vazirmatn(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.scale,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'انصراف',
                style: GoogleFonts.vazirmatn(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final weight = weightController.text.trim();
                if (weight.isNotEmpty) {
                  onWeightSubmitted(weight);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'ثبت',
                style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showWeightHistoryDialog(
    BuildContext context,
    List<Map<String, dynamic>> weightHistory,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'تاریخچه وزن',
            style: GoogleFonts.vazirmatn(
              textStyle: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300.h,
            child: weightHistory.isEmpty
                ? Center(
                    child: Text(
                      'هنوز وزنی ثبت نشده است',
                      style: GoogleFonts.vazirmatn(
                        color: Colors.grey,
                        fontSize: 16.sp,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: weightHistory.length,
                    itemBuilder: (context, index) {
                      final record = weightHistory[index];
                      final weight = record['weight']?.toString() ?? '';
                      final date = record['recorded_at']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.h,
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(50),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Center(
                                child: Text(
                                  _toPersianNumber((index + 1).toString()),
                                  style: GoogleFonts.vazirmatn(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_toPersianNumber(weight)}  کیلوگرم',
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  Text(
                                    _formatDate(date),
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.grey,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              LucideIcons.lineChart,
                              color: Colors.orange.withAlpha(150),
                              size: 20.sp,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'بستن',
                style: GoogleFonts.vazirmatn(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }
}
