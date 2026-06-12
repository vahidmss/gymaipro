/// ثابت‌های کانال مربی
class TrainerChannelConstants {
  TrainerChannelConstants._();

  /// حداکثر پست در هر روز (تقویم محلی دستگاه مربی)
  static const int maxPostsPerDay = 20;

  /// تعداد پست در هر بار بارگذاری فید
  static const int feedPageSize = 50;

  /// context آپلود روی هاست دانلود
  static const String uploadContext = 'trainer_channel';

  /// حداکثر طول متن پست
  static const int maxTextLength = 2000;

  /// حداکثر طول ویس (ثانیه)
  static const int maxVoiceDurationSeconds = 120;

  /// حداکثر مدت ویدیو انتخاب‌شده (دقیقه)
  static const int maxVideoPickMinutes = 5;

  /// حداکثر حجم ویدیو برای آپلود (مگابایت)
  static const int maxVideoSizeMb = 80;

  /// حداکثر حجم فایل صوتی (پادکست) — همان سقف upload-music.php
  static const int maxAudioFileSizeMb = 50;
}
