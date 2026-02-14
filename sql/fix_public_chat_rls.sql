-- اصلاح RLS برای جدول public_chat_messages
-- این اسکریپت را در Supabase Studio > SQL Editor اجرا کنید.
-- هدف:
-- 1) اجازه‌ی INSERT پیام عمومی فقط برای کاربری که واقعاً صاحب آن پروفایل است
-- 2) جلوگیری از خطای:
--    PostgrestException: new row violates row-level security policy for table "public_chat_messages"

-- مطمئن شو RLS فعال است
ALTER TABLE public.public_chat_messages ENABLE ROW LEVEL SECURITY;

-- Policyهای قدیمی INSERT را (اگر وجود دارند) حذف کن
DROP POLICY IF EXISTS "Users can insert public chat messages" ON public.public_chat_messages;

-- Policy جدید: کاربر احراز هویت‌شده می‌تواند فقط برای پروفایل خودش پیام ثبت کند
CREATE POLICY "Users can insert public chat messages"
ON public.public_chat_messages
FOR INSERT
WITH CHECK (
  auth.role() = 'authenticated'
  AND EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = public_chat_messages.sender_id
      -- پشتیبانی از هر دو حالت:
      -- 1) قدیمی: profiles.id == auth.users.id
      -- 2) جدید: profiles.auth_user_id == auth.users.id
      AND (
        p.id = auth.uid()
        OR p.auth_user_id = auth.uid()
      )
  )
);

-- (اختیاری ولی پیشنهادی) Policy SELECT برای همه‌ی کاربران احراز هویت‌شده
-- فقط اگر قبلاً Policy مناسب SELECT برای این جدول نداری، این بخش را هم اجرا کن.
--DROP POLICY IF EXISTS "Authenticated users can view public chat messages" ON public.public_chat_messages;
--
--CREATE POLICY "Authenticated users can view public chat messages"
--ON public.public_chat_messages
--FOR SELECT
--USING (auth.role() = 'authenticated');

-- بررسی نتیجه
SELECT 'RLS for public_chat_messages updated successfully' AS status;

