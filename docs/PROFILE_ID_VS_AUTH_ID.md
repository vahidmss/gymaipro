# یکپارچگی user_id: profiles.id در مقابل auth.uid()

در این پروژه بعضی جداول با **profiles.id** (شناسه پروفایل) کار می‌کنند و بعضی با **auth.users.id** (شناسه احراز هویت). اگر در کد به‌جای `profiles.id` از `auth.currentUser?.id` استفاده شود، ممکن است خطای FK یا RLS رخ دهد.

## جداول با user_id = profiles.id (REFERENCES profiles(id))

| جدول | وضعیت کد | فیکس RLS |
|------|----------|----------|
| **food_logs** | ✅ MealLogService از `_getCurrentUserId()` (profile id) استفاده می‌کند | `sql/fix_food_logs_rls_for_profiles.sql` |
| **user_activity_tracking** | ✅ ActivityTrackingService از `profile?['id']` استفاده می‌کند | `sql/fix_user_activity_tracking_rls_for_profiles.sql` |
| **user_rankings** | ✅ RankingService و RankingScoreService از profile id استفاده می‌کنند | `sql/fix_user_rankings_rls_for_profiles.sql` |
| **achievements** | ✅ AchievementDatabaseService از `_getProfileId()` استفاده می‌کند | قبلاً در fix_achievements_rls / fix_profile_auth_link_and_rls |
| **point_history** | ✅ ScoreService از `profileId` استفاده می‌کند | قبلاً در fix_profile_auth_link_and_rls |

## جداول با user_id = auth.users.id (REFERENCES auth.users(id))

این جداول با **auth.uid()** کار می‌کنند؛ استفاده از `auth.currentUser?.id` در کد درست است:

- **workout_daily_logs**
- **notifications**
- **user_notification_settings**
- **chat_presence**
- **user_music_likes**
- **progress_analyses**
- **user_feature_usage**
- **meal_plans** (طبق RLS فعلی: auth.uid() = user_id)
- **user_food_favorites** / **user_food_likes** (در صورت وجود در دیتابیس؛ اگر FK به profiles بود باید مثل food_logs فیکس شود)

## قواعد برای توسعه‌دهندگان

1. **جدول جدید با user_id:** اگر FK به `profiles(id)` است، در کد حتماً از `SimpleProfileService.getCurrentProfile()` و سپس `profile['id']` استفاده کنید؛ و RLS را طوری بنویسید که هم `user_id = auth.uid()` و هم `user_id = profile.id` (با شرط `profiles.auth_user_id = auth.uid()`) مجاز باشد.
2. **جدول با FK به auth.users(id):** می‌توان از `Supabase.instance.client.auth.currentUser?.id` استفاده کرد.
3. **در صورت خطای FK یا RLS:** اول بررسی کنید جدول به کدام یک از جداول بالا اشاره می‌کند؛ بعد یا کد را به profile id تغییر دهید یا RLS را مطابق فیکسهای موجود به‌روز کنید.

## اجرای فیکسهای RLS برای جداول profile-based

**یک‌بار اجرا (پیشنهادی):** در Supabase → SQL Editor فایل **`sql/apply_all_profile_rls_fixes.sql`** را اجرا کنید. هر سه جدول food_logs، user_activity_tracking و user_rankings را یکجا درست می‌کند.

**یا به‌صورت جداگانه:** فایل‌های `fix_food_logs_rls_for_profiles.sql`، `fix_user_activity_tracking_rls_for_profiles.sql` و `fix_user_rankings_rls_for_profiles.sql` را به ترتیب اجرا کنید.
