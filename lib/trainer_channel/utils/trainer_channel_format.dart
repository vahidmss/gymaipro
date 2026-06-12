import 'package:shamsi_date/shamsi_date.dart';

String formatChannelPostTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inMinutes < 1) return 'همین الان';
  if (diff.inHours < 1) return '${diff.inMinutes} دقیقه پیش';
  if (diff.inDays < 1) return '${diff.inHours} ساعت پیش';
  if (diff.inDays < 7) return '${diff.inDays} روز پیش';

  final j = Jalali.fromDateTime(dateTime.toLocal());
  return '${j.formatter.yyyy}/${j.formatter.mm}/${j.formatter.dd}';
}

String formatVoiceDuration(int? seconds) {
  if (seconds == null || seconds <= 0) return '۰:۰۰';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// برچسب جداکننده تاریخ بین پست‌ها (مثل تلگرام)
String formatChannelDateDivider(DateTime dateTime) {
  final local = dateTime.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) return 'امروز';
  if (day == today.subtract(const Duration(days: 1))) return 'دیروز';

  final j = Jalali.fromDateTime(local);
  const months = [
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
  return '${j.day} ${months[j.month]} ${j.year}';
}

String formatChannelPostClock(DateTime dateTime) {
  final local = dateTime.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
