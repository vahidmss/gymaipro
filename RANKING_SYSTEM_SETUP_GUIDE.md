# 🏆 راهنمای نصب و راه‌اندازی سیستم رتبه‌بندی

## 📋 فهرست مطالب

1. [نصب دیتابیس](#نصب-دیتابیس)
2. [داده تستی برای صفحه رتبه‌بندی](#داده-تستی-برای-صفحه-رتبهبندی)
3. [اتصال به سیستم‌های موجود](#اتصال-به-سیستمهای-موجود)
4. [تست سیستم](#تست-سیستم)
5. [نکات مهم](#نکات-مهم)

---

## 🗄️ نصب دیتابیس

### مرحله 1: ایجاد جداول

در Supabase Dashboard، به بخش SQL Editor بروید و فایل‌های زیر را به ترتیب اجرا کنید:

1. **ایجاد جدول ردیابی فعالیت‌ها**:
   ```sql
   -- اجرای فایل
   sql/create_user_activity_tracking_table.sql
   ```

2. **ایجاد جدول رتبه‌بندی**:
   ```sql
   -- اجرای فایل
   sql/create_user_rankings_table.sql
   ```

### مرحله 2: بررسی RLS Policies

مطمئن شوید که RLS Policies به درستی تنظیم شده‌اند:

- کاربران می‌توانند فعالیت‌های خود را مشاهده و ویرایش کنند
- Leaderboard برای همه قابل مشاهده است
- فقط سیستم می‌تواند رتبه‌ها را به‌روزرسانی کند

---

## 🧪 داده تستی برای صفحه رتبه‌بندی

برای تست صفحه Leaderboard بدون انتظار برای پر شدن واقعی داده‌ها:

### روش ۱: اجرای اسکریپت SQL (پیشنهادی)

1. در **Supabase Dashboard** برو به **SQL Editor**.
2. فایل **`sql/seed_ranking_test_data.sql`** را باز کن و تمام محتوای آن را کپی کن.
3. در SQL Editor paste کن و **Run** بزن.

این اسکریپت:

- برای حداکثر **۳۰ کاربر** از جدول `profiles` (با `role = 'athlete'`) یک رکورد در `user_rankings` می‌سازد (یا به‌روزرسانی می‌کند).
- به هر کدام **امتیاز و لیگ تصادفی** (از برنز تا الماس) می‌دهد.
- **رتب سراسری** (`global_rank`) و **رتب در هر لیگ** (`league_rank`) را محاسبه و ست می‌کند.

اگر خطای دسترسی (RLS) دیدی، همان کوئریها را با **Service Role** (یا از طریق Run as owner) اجرا کن.

**نسخهٔ ثابت (پیشنهادی برای تست اول):** اگر می‌خواهی امتیازها و لیگ‌ها ثابت و قابل پیش‌بینی باشند، به‌جای اسکریپت بالا فایل **`sql/seed_ranking_test_data_deterministic.sql`** را اجرا کن. این اسکریپت تا ۲۰ کاربر اول با نقش `athlete` را می‌گیرد و به آن‌ها امتیاز و لیگ ثابت می‌دهد (۲ الماس، ۳ پلاتین، ۳ طلا، ۳ نقره، بقیه برنز) تا همهٔ لیگ‌ها در صفحه پر شوند.

### روش ۲: فقط یک کاربر (خودتان)

اگر فقط می‌خواهید خودتان در جدول رتبه‌بندی باشید:

1. در Supabase به **Table Editor** > **user_rankings** برو.
2. **Insert row** بزن.
3. مقادیر را پر کن:
   - **user_id**: همان `id` پروفایل خودتان از جدول **profiles** (یا از auth.users).
   - **total_score**: مثلاً `2500`
   - **current_league**: `silver`
   - **league_points**: مثلاً `1499`
   - **league_rank**: `1` (اگر تنها نفر در این لیگ هستید)
   - **global_rank**: هر عدد (مثلاً 1)

بعد از ذخیره، صفحه رتبه‌بندی را رفرش کن تا خودتان را در لیگ نقره ببینی.

### روش ۳: چند رکورد دستی برای تست لیگ‌ها

اگر چند تا `user_id` از جدول **profiles** داری، می‌توانی در SQL Editor این را اجرا کنی (مقادیر را با UUID واقعی عوض کن):

```sql
INSERT INTO public.user_rankings (user_id, total_score, current_league, league_points, league_rank, global_rank)
VALUES
  ('UUID_کاربر_۱', 500, 'bronze', 500, 1, 10),
  ('UUID_کاربر_۲', 2000, 'silver', 999, 1, 5),
  ('UUID_کاربر_۳', 5500, 'gold', 2499, 2, 3),
  ('UUID_کاربر_۴', 12000, 'platinum', 4999, 1, 2),
  ('UUID_کاربر_۵', 20000, 'diamond', 4999, 1, 1)
ON CONFLICT (user_id) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  current_league = EXCLUDED.current_league,
  league_points = EXCLUDED.league_points,
  league_rank = EXCLUDED.league_rank,
  global_rank = EXCLUDED.global_rank;
```

بعد از هر روش، اپ را باز کن، به **داشبورد** > **رتبه‌بندی** برو و لیگ‌های مختلف را عوض کن تا لیست و کارت «رتبه شما» را ببینی.

---

## 🔗 اتصال به سیستم‌های موجود

### 1. ردیابی خواندن مقاله

در فایل `lib/academy/widgets/article_content.dart` یا `lib/academy/screens/article_detail_screen.dart`:

```dart
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';
import 'dart:async';

// در State class
Timer? _articleReadingTimer;

@override
void initState() {
  super.initState();
  // شروع ردیابی هر 5 دقیقه
  _articleReadingTimer = Timer.periodic(
    const Duration(minutes: 5),
    (_) {
      RankingTrackerHelper().trackArticleReading(minutes: 5);
    },
  );
}

@override
void dispose() {
  _articleReadingTimer?.cancel();
  super.dispose();
}
```

### 2. ردیابی گوش دادن موزیک

در فایل `lib/academy/services/music_player_service.dart`:

```dart
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';

// در متد init()، بعد از setup listeners
_audioPlayer.onPositionChanged.listen((position) {
  _position = position;
  notifyListeners();
  
  // ردیابی هر 10 دقیقه
  if (position.inMinutes % 10 == 0 && position.inSeconds < 5) {
    RankingTrackerHelper().trackMusicListening(minutes: 10);
  }
  
  // کدهای موجود...
});
```

### 3. ردیابی تماشای ویدیو

در فایل `lib/academy/screens/motivational_video_detail_screen.dart`:

```dart
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';
import 'dart:async';

// در State class
Timer? _videoWatchingTimer;

@override
void initState() {
  super.initState();
  _initializeVideo();
  _incrementViewCount();
  
  // شروع ردیابی هر 5 دقیقه
  _videoWatchingTimer = Timer.periodic(
    const Duration(minutes: 5),
    (_) {
      if (_chewieController?.isPlaying == true) {
        RankingTrackerHelper().trackVideoWatching(minutes: 5);
      }
    },
  );
}

@override
void dispose() {
  _videoWatchingTimer?.cancel();
  _chewieController?.dispose();
  _videoPlayerController?.dispose();
  super.dispose();
}
```

### 4. ردیابی ثبت تمرین

در فایل `lib/workout_log/services/workout_program_log_service.dart` یا جایی که تمرین ثبت می‌شود:

```dart
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';

// هنگام ثبت تمرین
Future<WorkoutDailyLog?> saveDailyLog(WorkoutDailyLog log) async {
  // کدهای موجود...
  
  // ردیابی برای رتبه‌بندی
  await RankingTrackerHelper().trackWorkoutLog();
  
  // ادامه کد...
}
```

### 5. ردیابی ثبت رژیم

در فایل `lib/meal_log/services/meal_log_service.dart` یا جایی که وعده ثبت می‌شود:

```dart
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';

// هنگام ثبت وعده
Future<void> saveMealLog(...) async {
  // کدهای موجود...
  
  // ردیابی برای رتبه‌بندی
  await RankingTrackerHelper().trackMealLog();
  
  // ادامه کد...
}
```

### 6. ردیابی کالری‌شماری

در جایی که کالری شماری می‌شود (مثلاً در Dashboard یا Meal Log):

```dart
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';

// هنگام ثبت کالری
Future<void> saveCalories(...) async {
  // کدهای موجود...
  
  // ردیابی برای رتبه‌بندی
  await RankingTrackerHelper().trackCalorieCounting();
  
  // ادامه کد...
}
```

---

## 🧪 تست سیستم

### 1. تست ردیابی فعالیت‌ها

```dart
// تست ردیابی خواندن مقاله
await RankingTrackerHelper().trackArticleReading(minutes: 5);

// تست ردیابی گوش دادن موزیک
await RankingTrackerHelper().trackMusicListening(minutes: 10);

// تست ردیابی تماشای ویدیو
await RankingTrackerHelper().trackVideoWatching(minutes: 5);

// تست ردیابی ثبت تمرین
await RankingTrackerHelper().trackWorkoutLog();

// تست ردیابی ثبت رژیم
await RankingTrackerHelper().trackMealLog();
```

### 2. تست محاسبه امتیاز

```dart
import 'package:gymaipro/ranking/services/ranking_score_service.dart';

final scoreService = RankingScoreService();
final userId = 'your-user-id';
final score = await scoreService.calculateTotalScore(userId);
print('Total Score: $score');
```

### 3. تست Leaderboard

```dart
import 'package:gymaipro/ranking/screens/leaderboard_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const LeaderboardScreen(),
  ),
);
```

### 4. تست به‌روزرسانی رتبه‌ها

```dart
import 'package:gymaipro/ranking/services/ranking_service.dart';

final rankingService = RankingService();

// به‌روزرسانی رتبه کاربر فعلی
await rankingService.updateCurrentUserRanking();

// به‌روزرسانی رتبه همه کاربران (برای cron job)
await rankingService.updateAllRankings();
```

---

## ⚙️ تنظیمات پیشنهادی

### 1. به‌روزرسانی دوره‌ای رتبه‌ها

برای به‌روزرسانی خودکار رتبه‌ها، می‌توانید یک cron job یا scheduled task ایجاد کنید:

```dart
// در main.dart یا یک service جداگانه
Timer.periodic(const Duration(hours: 1), (_) async {
  await RankingService().updateAllRankings();
});
```

### 2. به‌روزرسانی رتبه کاربر هنگام فعالیت

برای به‌روزرسانی فوری رتبه کاربر پس از فعالیت:

```dart
// بعد از هر فعالیت
await RankingTrackerHelper().trackWorkoutLog();
await RankingService().updateCurrentUserRanking();
```

---

## 📝 نکات مهم

### 1. امنیت

- ✅ تمام فعالیت‌ها به صورت خودکار ردیابی می‌شوند و قابل دستکاری نیستند
- ✅ کاربران نمی‌توانند امتیاز خود را دستی تغییر دهند
- ✅ RLS Policies از دسترسی غیرمجاز جلوگیری می‌کند

### 2. عملکرد

- ✅ برای عملکرد بهتر، از Cache استفاده می‌شود
- ✅ رتبه‌ها به صورت دوره‌ای به‌روزرسانی می‌شوند (نه real-time)
- ✅ Leaderboard فقط 20 تای برتر را نمایش می‌دهد

### 3. مقیاس‌پذیری

- ✅ با افزایش کاربران، نیاز به بهینه‌سازی بیشتر است
- ✅ استفاده از Materialized Views برای Leaderboard پیشنهاد می‌شود
- ✅ محاسبه رتبه‌ها در background انجام می‌شود

---

## 🐛 عیب‌یابی

### مشکل: فعالیت‌ها ردیابی نمی‌شوند

1. بررسی کنید که جداول در دیتابیس ایجاد شده‌اند
2. بررسی کنید که RLS policies درست تنظیم شده‌اند
3. لاگ‌های کنسول را بررسی کنید
4. مطمئن شوید که `RankingTrackerHelper` به درستی فراخوانی می‌شود

### مشکل: رتبه‌ها به‌روزرسانی نمی‌شوند

1. بررسی کنید که `updateAllRankings()` فراخوانی می‌شود
2. بررسی کنید که امتیازها درست محاسبه می‌شوند
3. لاگ‌های کنسول را بررسی کنید
4. بررسی کنید که کاربر لاگین است

### مشکل: Leaderboard خالی است

1. بررسی کنید که کاربران فعالیت داشته‌اند
2. بررسی کنید که رتبه‌ها به‌روزرسانی شده‌اند
3. بررسی کنید که لیگ انتخاب شده درست است

---

## ✅ چک‌لیست نصب

- [ ] جداول دیتابیس ایجاد شده‌اند
- [ ] RLS Policies تنظیم شده‌اند
- [ ] ردیابی خواندن مقاله اضافه شده است
- [ ] ردیابی گوش دادن موزیک اضافه شده است
- [ ] ردیابی تماشای ویدیو اضافه شده است
- [ ] ردیابی ثبت تمرین اضافه شده است
- [ ] ردیابی ثبت رژیم اضافه شده است
- [ ] ردیابی کالری‌شماری اضافه شده است
- [ ] Route برای Leaderboard اضافه شده است
- [ ] تست‌ها انجام شده‌اند

---

## 🚀 آماده استفاده!

پس از انجام تمام مراحل بالا، سیستم رتبه‌بندی آماده استفاده است. کاربران می‌توانند از طریق مسیر `/leaderboard` یا `/ranking` به صفحه Leaderboard دسترسی پیدا کنند.
