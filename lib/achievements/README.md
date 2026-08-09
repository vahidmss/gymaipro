# سیستم دستاوردها

دستاورد = بج + بونوس امتیاز لیگ (نه ارز جدا).

## مدل

- جدول `achievements`: پیشرفت هر کاربر (`current_value`, `unlocked_at`, `bonus_points`)
- در لحظه unlock مقدار `points` کاتالوگ یک‌بار در `bonus_points` قفل می‌شود
- `RankingScoreService` جمع `bonus_points` را به `total_score` لیگ اضافه می‌کند

مایگریشن: `sql/migrate_gamification_single_currency.sql`

## کاتالوگ فعال

فقط دستاوردهای سیم‌کشی‌شده نمایش داده می‌شوند (پروفایل، ورود، عضویت، استریک، دعوت، برنامه، لاگ تمرین/رژیم/کالری).

## فایل‌ها

- `achievement_service.dart` — کاتالوگ + unlock
- `achievement_database_service.dart` — Supabase + cache
- `achievement_hooks.dart` — هوک از سرویس‌های دامنه
- `achievements_screen.dart` / widgets — UI

## نکته

جدول `point_history` توسط اپ استفاده نمی‌شود؛ ردیف‌های نمایشی از `RankingScoreBreakdown` ساخته می‌شوند.
