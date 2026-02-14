-- افزودن فیلدهای مدیریت بلاک چت عمومی به جدول profiles
-- این اسکریپت را در Supabase Studio > SQL Editor اجرا کنید.

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS public_chat_blocked_until TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS public_chat_block_reason TEXT,
ADD COLUMN IF NOT EXISTS public_chat_block_created_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS public_chat_block_created_by UUID REFERENCES public.profiles(id);

-- ایندکس برای جستجوی سریع کاربران مسدود در چت عمومی
CREATE INDEX IF NOT EXISTS idx_profiles_public_chat_blocked_until
  ON public.profiles(public_chat_blocked_until)
  WHERE public_chat_blocked_until IS NOT NULL;

SELECT 'Public chat block fields added to profiles' AS status;

