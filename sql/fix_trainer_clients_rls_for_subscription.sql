-- رفع خطای RLS جدول trainer_clients هنگام خرید اشتراک توسط شاگرد
--
-- مشکل: پالیسی "Trainers can create relationships" فقط به مربی اجازه INSERT می‌داد
-- (auth.uid() = trainer_id). بعد از پرداخت، درخواست از طرف شاگرد (auth.uid() = شاگرد)
-- با client_id = profile شاگرد ارسال می‌شود و RLS رد می‌کند (42501 Forbidden).
--
-- راه‌حل: اجازه INSERT هم به مربی (trainer_id) و هم به شاگرد (client_id) وقتی
-- پروفایل جاری کاربر برابر client_id است (با تابع current_user_profile_id).
--
-- پیش‌نیاز: تابع public.current_user_profile_id() و ستون profiles.auth_user_id
-- (از fix_wallet_and_trainer_subscription_rls_for_profiles.sql و fix_profile_auth_link_and_rls.sql)
--
-- این اسکریپت را در Supabase Dashboard > SQL Editor اجرا کنید.

-- حذف پالیسی قبلی
DROP POLICY IF EXISTS "Trainers can create relationships" ON public.trainer_clients;

-- پالیسی جدید: مربی یا شاگرد می‌تواند رابطه را ایجاد کند
-- - مربی: وقتی auth.uid() = trainer_id یا پروفایل جاری = trainer_id
-- - شاگرد: وقتی پروفایل جاری = client_id (مثلاً بعد از خرید اشتراک)
CREATE POLICY "Trainers can create relationships" ON public.trainer_clients
  FOR INSERT
  WITH CHECK (
    auth.uid() = trainer_id
    OR public.current_user_profile_id() = trainer_id
    OR public.current_user_profile_id() = client_id
  );

SELECT 'trainer_clients RLS: INSERT policy updated (trainer or client can create).' AS status;
