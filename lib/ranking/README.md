# سیستم رتبه‌بندی و لیگ‌بندی کاربران

## 📋 معرفی

سیستم رتبه‌بندی و لیگ‌بندی کاربران یک سیستم کامل برای رتبه‌بندی کاربران بر اساس فعالیت‌های خودکار و غیرقابل دستکاری است.

## ✨ ویژگی‌ها

- ✅ ردیابی خودکار فعالیت‌ها (خواندن مقاله، گوش دادن موزیک، تماشای ویدیو)
- ✅ ردیابی ثبت تمرین و رژیم
- ✅ سیستم لیگ‌بندی (برنز، نقره، طلا، پلاتینیوم، الماس)
- ✅ Leaderboard با امکان انتخاب لیگ
- ✅ نمایش رتبه کاربر
- ✅ محاسبه خودکار امتیاز بر اساس فعالیت‌ها

## 🗄️ ساختار دیتابیس

### جداول مورد نیاز

1. **user_activity_tracking**: ردیابی فعالیت‌های روزانه کاربران
2. **user_rankings**: رتبه‌بندی و لیگ کاربران

برای ایجاد جداول، فایل‌های SQL زیر را در Supabase اجرا کنید:

```sql
-- اجرای فایل‌های SQL
sql/create_user_activity_tracking_table.sql
sql/create_user_rankings_table.sql
```

## 📁 ساختار فایل‌ها

```
lib/ranking/
├── models/
│   ├── league.dart              # مدل لیگ
│   ├── user_activity.dart       # مدل فعالیت کاربر
│   └── user_ranking.dart        # مدل رتبه کاربر
├── services/
│   ├── activity_tracking_service.dart    # ردیابی فعالیت‌ها
│   ├── ranking_score_service.dart        # محاسبه امتیاز
│   ├── ranking_service.dart              # سرویس اصلی رتبه‌بندی
│   └── ranking_tracker_helper.dart       # Helper برای ردیابی
├── screens/
│   └── leaderboard_screen.dart           # صفحه Leaderboard
├── widgets/
│   ├── league_badge.dart                # نشان لیگ
│   ├── leaderboard_item.dart            # آیتم Leaderboard
│   └── user_rank_card.dart              # کارت رتبه کاربر
├── index.dart                           # Export همه چیز
└── README.md                            # این فایل
```

## 🚀 نحوه استفاده

### 1. راه‌اندازی دیتابیس

ابتدا جداول را در Supabase ایجاد کنید:

```bash
# در Supabase SQL Editor
# اجرای فایل‌های SQL
```

### 2. ردیابی فعالیت‌ها

برای ردیابی فعالیت‌ها، از `RankingTrackerHelper` استفاده کنید:

```dart
import 'package:gymaipro/ranking/ranking_tracker_helper.dart';

// ردیابی خواندن مقاله (هر 5 دقیقه)
await RankingTrackerHelper().trackArticleReading(minutes: 5);

// ردیابی گوش دادن موزیک (هر 10 دقیقه)
await RankingTrackerHelper().trackMusicListening(minutes: 10);

// ردیابی تماشای ویدیو (هر 5 دقیقه)
await RankingTrackerHelper().trackVideoWatching(minutes: 5);

// ردیابی ثبت تمرین
await RankingTrackerHelper().trackWorkoutLog();

// ردیابی ثبت رژیم
await RankingTrackerHelper().trackMealLog();

// ردیابی کالری‌شماری
await RankingTrackerHelper().trackCalorieCounting();
```

### 3. نمایش Leaderboard

```dart
import 'package:gymaipro/ranking/screens/leaderboard_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const LeaderboardScreen(),
  ),
);
```

### 4. دریافت رتبه کاربر

```dart
import 'package:gymaipro/ranking/services/ranking_service.dart';

final rankingService = RankingService();
final userRanking = await rankingService.getCurrentUserRanking();
```

## 📊 معیارهای امتیازدهی

### فعالیت‌های روزانه (از 30 روز گذشته)

- **خواندن مقاله**: هر 5 دقیقه = 1 امتیاز (حداکثر 10 امتیاز در روز)
- **گوش دادن موزیک**: هر 10 دقیقه = 1 امتیاز (حداکثر 5 امتیاز در روز)
- **تماشای ویدیو**: هر 5 دقیقه = 1 امتیاز (حداکثر 10 امتیاز در روز)
- **ثبت تمرین**: هر تمرین = 5 امتیاز (حداکثر 20 امتیاز در روز)
- **ثبت رژیم**: هر وعده = 2 امتیاز (حداکثر 10 امتیاز در روز)
- **کالری‌شماری**: هر روز = 3 امتیاز

### امتیازهای کلی

- **Streak (روزهای متوالی)**: هر روز = 10 امتیاز (حداکثر 500)
- **Longest Streak**: هر روز = 5 امتیاز (حداکثر 250)
- **روزهای فعال**: هر روز فعال = 5 امتیاز (حداکثر 150)
- **تعداد کل تمرینات**: هر 10 تمرین = 20 امتیاز (حداکثر 1000)
- **تعداد کل وعده‌ها**: هر 20 وعده = 10 امتیاز (حداکثر 500)

## 🏆 سیستم لیگ‌بندی

| لیگ | امتیاز مورد نیاز | رنگ |
|-----|------------------|-----|
| 🥉 برنز | 0 - 1,000 | #CD7F32 |
| 🥈 نقره | 1,001 - 3,000 | #C0C0C0 |
| 🥇 طلا | 3,001 - 7,000 | #FFD700 |
| 💎 پلاتینیوم | 7,001 - 15,000 | #E5E4E2 |
| 💠 الماس | 15,001+ | #B9F2FF |

## 🔧 اتصال به سیستم‌های موجود

### 1. ردیابی خواندن مقاله

در `ArticleDetailScreen` یا `ArticleContent`:

```dart
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';

// هر 5 دقیقه یکبار فراخوانی کنید
Timer.periodic(const Duration(minutes: 5), (timer) {
  RankingTrackerHelper().trackArticleReading(minutes: 5);
});
```

### 2. ردیابی گوش دادن موزیک

در `MusicPlayerService`:

```dart
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';

// در onPositionChanged listener
_audioPlayer.onPositionChanged.listen((position) {
  // هر 10 دقیقه یکبار
  if (position.inMinutes % 10 == 0 && position.inSeconds == 0) {
    RankingTrackerHelper().trackMusicListening(minutes: 10);
  }
});
```

### 3. ردیابی تماشای ویدیو

در `MotivationalVideoDetailScreen`:

```dart
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';

// هر 5 دقیقه یکبار
Timer.periodic(const Duration(minutes: 5), (timer) {
  if (_chewieController?.isPlaying == true) {
    RankingTrackerHelper().trackVideoWatching(minutes: 5);
  }
});
```

### 4. ردیابی ثبت تمرین

در سرویس ثبت تمرین:

```dart
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';

// هنگام ثبت تمرین
await RankingTrackerHelper().trackWorkoutLog();
```

### 5. ردیابی ثبت رژیم

در سرویس ثبت رژیم:

```dart
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';

// هنگام ثبت وعده
await RankingTrackerHelper().trackMealLog();
```

## 📝 نکات مهم

1. **ردیابی خودکار**: تمام فعالیت‌ها به صورت خودکار ردیابی می‌شوند و قابل دستکاری نیستند
2. **به‌روزرسانی رتبه**: رتبه‌ها به صورت دوره‌ای (هر ساعت) به‌روزرسانی می‌شوند
3. **Cache**: برای عملکرد بهتر، از Cache استفاده می‌شود
4. **RLS**: تمام جداول با RLS محافظت می‌شوند

## 🐛 عیب‌یابی

### مشکل: فعالیت‌ها ردیابی نمی‌شوند

1. بررسی کنید که جداول در دیتابیس ایجاد شده‌اند
2. بررسی کنید که RLS policies درست تنظیم شده‌اند
3. لاگ‌های کنسول را بررسی کنید

### مشکل: رتبه‌ها به‌روزرسانی نمی‌شوند

1. بررسی کنید که `updateAllRankings()` فراخوانی می‌شود
2. بررسی کنید که امتیازها درست محاسبه می‌شوند
3. لاگ‌های کنسول را بررسی کنید

## 🚀 بهبودهای آینده

- [ ] Leaderboard دوستان
- [ ] Leaderboard هفتگی/ماهانه
- [ ] جوایز و چالش‌ها
- [ ] آمار پیشرفته‌تر
- [ ] اعلان‌های ارتقا لیگ
