import 'package:shamsi_date/shamsi_date.dart';

String toJalali(DateTime date) {
  final j = Jalali.fromDateTime(date);

  // نام ماه‌های فارسی
  final persianMonths = [
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
    'اسفند'
  ];

  // برگرداندن تاریخ به صورت مینیمال: "3 بهمن"
  return '${j.day} ${persianMonths[j.month]}';
}

// تابع کمکی برای دریافت فاصله زمانی به صورت متنی
String getTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 365) {
    final years = (difference.inDays / 365).floor();
    return '$years سال پیش';
  } else if (difference.inDays > 30) {
    final months = (difference.inDays / 30).floor();
    return '$months ماه پیش';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} روز پیش';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} ساعت پیش';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} دقیقه پیش';
  } else {
    return 'همین الان';
  }
}
